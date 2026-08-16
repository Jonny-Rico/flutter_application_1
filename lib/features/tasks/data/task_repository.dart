import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_tasks/core/firebase/firestore_errors.dart';
import 'package:family_tasks/features/tasks/data/task_local_storage.dart';
import 'package:family_tasks/features/tasks/domain/task.dart';
import 'package:family_tasks/features/tasks/domain/task_permissions.dart';
import 'package:family_tasks/features/tasks/domain/task_priority.dart';
import 'package:family_tasks/features/tasks/domain/task_recurrence.dart';
import 'package:family_tasks/features/tasks/domain/task_status.dart';
import 'package:uuid/uuid.dart';

class TaskRepository {
  TaskRepository({
    FirebaseFirestore? firestore,
    this._localStorage,
    Uuid? uuid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _firestore;
  final TaskLocalStorage? _localStorage;
  final Uuid _uuid;
  final Map<String, List<Task>> _memoryTasks = {};

  String _cacheKey({required String userId, String? groupId}) {
    return groupId ?? 'user_$userId';
  }

  CollectionReference<Map<String, dynamic>> _personalTasksRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('tasks');
  }

  CollectionReference<Map<String, dynamic>> _groupTasksRef(String groupId) {
    return _firestore.collection('groups').doc(groupId).collection('tasks');
  }

  CollectionReference<Map<String, dynamic>> _tasksRef({
    required String userId,
    String? groupId,
  }) {
    return groupId != null
        ? _groupTasksRef(groupId)
        : _personalTasksRef(userId);
  }

  List<Task> _tasksFromMemoryOrHive({
    required String userId,
    String? groupId,
  }) {
    final cacheKey = _cacheKey(userId: userId, groupId: groupId);
    final memory = _memoryTasks[cacheKey];
    if (memory != null) return List<Task>.from(memory);

    final hiveTasks = _localStorage?.loadTasks(cacheKey) ?? [];
    _memoryTasks[cacheKey] = List<Task>.from(hiveTasks);
    return hiveTasks;
  }

  Future<void> _persistTasks({
    required String userId,
    String? groupId,
    required List<Task> tasks,
  }) async {
    final cacheKey = _cacheKey(userId: userId, groupId: groupId);
    _memoryTasks[cacheKey] = List<Task>.from(tasks);
    await _localStorage?.saveTasks(cacheKey, tasks);
  }

  List<Task> getCachedTasks({required String userId, String? groupId}) {
    return _tasksFromMemoryOrHive(userId: userId, groupId: groupId);
  }

  Stream<List<Task>> watchTasks({
    required String userId,
    String? groupId,
  }) {
    final cacheKey = _cacheKey(userId: userId, groupId: groupId);
    return _tasksRef(userId: userId, groupId: groupId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(Task.fromFirestore).toList(),
        )
        .asyncMap((tasks) async {
          _memoryTasks[cacheKey] = List<Task>.from(tasks);
          await _localStorage?.saveTasks(cacheKey, tasks);
          return tasks;
        })
        .ignoreFirestoreAuthLoss();
  }

  Future<Task?> getTask({
    required String userId,
    String? groupId,
    required String taskId,
    bool fromServer = false,
  }) async {
    if (!fromServer) {
      for (final task in _tasksFromMemoryOrHive(
        userId: userId,
        groupId: groupId,
      )) {
        if (task.id == taskId) return task;
      }
    }

    final doc = await _tasksRef(userId: userId, groupId: groupId)
        .doc(taskId)
        .get();
    if (!doc.exists) return null;

    final task = Task.fromFirestore(doc);
    await _upsertCachedTask(
      userId: userId,
      groupId: groupId,
      task: task,
    );
    return task;
  }

  Future<Task> createTask({
    required String userId,
    String? groupId,
    required String createdBy,
    String? assigneeId,
    required String title,
    required String description,
    DateTime? deadline,
    DateTime? reminderAt,
    TaskPriorityLevel priority = TaskPriorityLevel.medium,
    TaskStatus status = TaskStatus.todo,
    bool isGroupTask = false,
    TaskRecurrence recurrence = TaskRecurrence.none,
    String? spawnedFromTaskId,
  }) async {
    final now = DateTime.now();
    final task = Task(
      id: _uuid.v4(),
      groupId: groupId,
      createdBy: createdBy,
      assigneeId: isGroupTask ? null : assigneeId,
      completedBy: null,
      title: title.trim(),
      description: description.trim(),
      deadline: deadline,
      reminderAt: reminderAt,
      priority: priority,
      status: status,
      isGroupTask: isGroupTask,
      permissions: const TaskPermissions(),
      createdAt: now,
      updatedAt: now,
      recurrence: recurrence,
      spawnedFromTaskId: spawnedFromTaskId,
    );

    await _tasksRef(userId: userId, groupId: groupId)
        .doc(task.id)
        .set(task.toFirestore());
    await _upsertCachedTask(
      userId: userId,
      groupId: groupId,
      task: task,
    );
    return task;
  }

  Future<void> updateTaskStatus({
    required String userId,
    String? groupId,
    required String taskId,
    required TaskStatus newStatus,
    required String currentUserId,
    Task? task,
  }) async {
    // Prefer server snapshot so Undo/status changes are not based on a stale row.
    final existing = await getTask(
          userId: userId,
          groupId: groupId,
          taskId: taskId,
          fromServer: true,
        ) ??
        task;
    if (existing == null) throw Exception('Task not found');

    // No-op if already at target (avoids extra writes / recurrence edge cases).
    if (existing.status == newStatus) return;

    await _updateStatus(
      userId: userId,
      groupId: groupId,
      task: existing,
      newStatus: newStatus,
      currentUserId: currentUserId,
    );
  }

  Future<void> updateTask({
    required String userId,
    String? groupId,
    required Task task,
    required String currentUserId,
  }) async {
    final existing = await getTask(
      userId: userId,
      groupId: groupId,
      taskId: task.id,
      fromServer: true,
    );
    if (existing == null) throw Exception('Task not found');

    if (!existing.canEditFields(currentUserId) &&
        !_onlyStatusChanged(existing, task)) {
      throw Exception('You do not have permission to edit this task.');
    }

    if (!existing.canEditFields(currentUserId)) {
      await _updateStatus(
        userId: userId,
        groupId: groupId,
        task: task,
        newStatus: task.status,
        currentUserId: currentUserId,
      );
      return;
    }

    final wasDone = existing.status == TaskStatus.done;
    var updated = task.copyWith(updatedAt: DateTime.now());
    if (updated.status == TaskStatus.done) {
      if (updated.isGroupTask && updated.completedBy == null) {
        updated = updated.copyWith(completedBy: currentUserId);
      }
      updated = updated.copyWith(clearReminder: true);
    } else {
      updated = updated.copyWith(clearCompletedBy: true);
    }

    final firestoreData = updated.toFirestore();
    if (updated.status != TaskStatus.done) {
      firestoreData['completedBy'] = FieldValue.delete();
    }
    if (updated.reminderAt == null) {
      firestoreData['reminderAt'] = FieldValue.delete();
    }

    await _tasksRef(userId: userId, groupId: groupId)
        .doc(updated.id)
        .update(firestoreData);
    await _upsertCachedTask(
      userId: userId,
      groupId: groupId,
      task: updated,
    );

    if (!wasDone && updated.status == TaskStatus.done) {
      await _spawnNextOccurrenceIfNeeded(
        userId: userId,
        groupId: groupId,
        completed: updated,
      );
    }
  }

  Future<void> _updateStatus({
    required String userId,
    String? groupId,
    required Task task,
    required TaskStatus newStatus,
    required String currentUserId,
  }) async {
    if (!task.canChangeStatus(currentUserId)) {
      throw Exception('You do not have permission to update this task.');
    }

    final wasDone = task.status == TaskStatus.done;
    var updated = task.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );

    if (newStatus == TaskStatus.done) {
      if (task.isGroupTask && task.completedBy == null) {
        updated = updated.copyWith(completedBy: currentUserId);
      }
      updated = updated.copyWith(clearReminder: true);
    } else {
      updated = updated.copyWith(clearCompletedBy: true);
    }

    final firestoreUpdate = <String, dynamic>{
      'status': updated.status.value,
      'updatedAt': Timestamp.fromDate(updated.updatedAt),
    };
    if (newStatus == TaskStatus.done) {
      firestoreUpdate['completedBy'] = updated.completedBy;
      firestoreUpdate['reminderAt'] = FieldValue.delete();
    } else {
      firestoreUpdate['completedBy'] = FieldValue.delete();
    }

    await _tasksRef(userId: userId, groupId: groupId)
        .doc(updated.id)
        .update(firestoreUpdate);
    await _upsertCachedTask(
      userId: userId,
      groupId: groupId,
      task: updated,
    );

    if (!wasDone && newStatus == TaskStatus.done) {
      await _spawnNextOccurrenceIfNeeded(
        userId: userId,
        groupId: groupId,
        completed: updated,
      );
    }
  }

  /// Spawn next occurrence when a recurring task is completed.
  Future<void> _spawnNextOccurrenceIfNeeded({
    required String userId,
    String? groupId,
    required Task completed,
  }) async {
    if (!completed.recurrence.isRepeating) return;

    final baseDeadline = completed.deadline ?? DateTime.now();
    final nextDeadline = completed.recurrence.nextDeadlineFrom(baseDeadline);

    await createTask(
      userId: userId,
      groupId: groupId,
      createdBy: completed.createdBy,
      assigneeId: completed.assigneeId,
      title: completed.title,
      description: completed.description,
      deadline: nextDeadline,
      reminderAt: null,
      priority: completed.priority,
      status: TaskStatus.todo,
      isGroupTask: completed.isGroupTask,
      recurrence: completed.recurrence,
      spawnedFromTaskId: completed.id,
    );
  }

  /// Removes the To Do copy spawned from [parentTaskId] if it was not edited.
  Future<void> deleteUneditedSpawnedSuccessor({
    required String userId,
    String? groupId,
    required String parentTaskId,
    required String currentUserId,
  }) async {
    final snapshot = await _tasksRef(userId: userId, groupId: groupId).get();
    for (final doc in snapshot.docs) {
      final task = Task.fromFirestore(doc);
      if (task.spawnedFromTaskId != parentTaskId) continue;
      if (task.status != TaskStatus.todo) return;
      if (task.updatedAt.difference(task.createdAt).inSeconds.abs() > 2) {
        return;
      }
      if (!task.canDelete(currentUserId)) return;
      await deleteTask(
        userId: userId,
        groupId: groupId,
        taskId: task.id,
        currentUserId: currentUserId,
        task: task,
      );
      return;
    }
  }

  bool _onlyStatusChanged(Task existing, Task updated) {
    return existing.title == updated.title &&
        existing.description == updated.description &&
        existing.deadline == updated.deadline &&
        existing.reminderAt == updated.reminderAt &&
        existing.priority == updated.priority &&
        existing.recurrence == updated.recurrence &&
        existing.spawnedFromTaskId == updated.spawnedFromTaskId &&
        existing.status != updated.status;
  }

  Future<void> deleteTask({
    required String userId,
    String? groupId,
    required String taskId,
    required String currentUserId,
    Task? task,
  }) async {
    final existing = task ??
        await getTask(
          userId: userId,
          groupId: groupId,
          taskId: taskId,
          fromServer: true,
        );
    if (existing == null) return;
    if (!existing.canDelete(currentUserId)) {
      throw Exception('You do not have permission to delete this task.');
    }

    await _tasksRef(userId: userId, groupId: groupId).doc(taskId).delete();
    await _removeCachedTask(
      userId: userId,
      groupId: groupId,
      taskId: taskId,
    );
  }

  Future<void> _upsertCachedTask({
    required String userId,
    String? groupId,
    required Task task,
  }) async {
    final tasks = _tasksFromMemoryOrHive(userId: userId, groupId: groupId);
    final index = tasks.indexWhere((item) => item.id == task.id);
    if (index >= 0) {
      tasks[index] = task;
    } else {
      tasks.insert(0, task);
    }
    await _persistTasks(userId: userId, groupId: groupId, tasks: tasks);
  }

  Future<void> _removeCachedTask({
    required String userId,
    String? groupId,
    required String taskId,
  }) async {
    final tasks = _tasksFromMemoryOrHive(userId: userId, groupId: groupId)
        .where((task) => task.id != taskId)
        .toList();
    await _persistTasks(userId: userId, groupId: groupId, tasks: tasks);
  }
}