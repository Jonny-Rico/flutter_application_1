import 'dart:async';

import 'package:family_tasks/features/tasks/data/task_repository.dart';
import 'package:family_tasks/features/tasks/domain/task.dart';
import 'package:family_tasks/features/tasks/domain/task_permissions.dart';
import 'package:family_tasks/features/tasks/domain/task_priority.dart';
import 'package:family_tasks/features/tasks/domain/task_recurrence.dart';
import 'package:family_tasks/features/tasks/domain/task_status.dart';

class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository([List<Task> seed = const []]) {
    tasks.addAll(seed);
  }

  final List<Task> tasks = [];
  final _controller = StreamController<List<Task>>.broadcast();
  var _nextId = 1;

  void _emit() => _controller.add(List<Task>.from(tasks));

  Task? _byId(String id) {
    for (final task in tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  void replace(Task task) {
    final index = tasks.indexWhere((item) => item.id == task.id);
    if (index >= 0) {
      tasks[index] = task;
    } else {
      tasks.insert(0, task);
    }
    _emit();
  }

  @override
  List<Task> getCachedTasks({required String userId, String? groupId}) {
    return List<Task>.from(tasks);
  }

  @override
  Stream<List<Task>> watchTasks({required String userId, String? groupId}) {
    return Stream<List<Task>>.multi((listener) {
      listener.add(List<Task>.from(tasks));
      final sub = _controller.stream.listen(
        listener.add,
        onError: listener.addError,
        onDone: listener.close,
      );
      listener
        ..onPause = sub.pause
        ..onResume = sub.resume
        ..onCancel = sub.cancel;
    });
  }

  @override
  Future<Task?> getTask({
    required String userId,
    String? groupId,
    required String taskId,
    bool fromServer = false,
  }) async {
    return _byId(taskId);
  }

  @override
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
      id: 'fake-${_nextId++}',
      groupId: groupId,
      createdBy: createdBy,
      assigneeId: isGroupTask ? null : assigneeId,
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
    tasks.insert(0, task);
    _emit();
    return task;
  }

  @override
  Future<void> updateTaskStatus({
    required String userId,
    String? groupId,
    required String taskId,
    required TaskStatus newStatus,
    required String currentUserId,
    Task? task,
  }) async {
    final existing = _byId(taskId) ?? task;
    if (existing == null) throw Exception('Task not found');
    if (!existing.canChangeStatus(currentUserId)) {
      throw Exception('You do not have permission to update this task.');
    }
    if (existing.status == newStatus) return;
    replace(existing.copyWith(status: newStatus, updatedAt: DateTime.now()));
  }

  @override
  Future<void> updateTask({
    required String userId,
    String? groupId,
    required Task task,
    required String currentUserId,
  }) async {
    final existing = _byId(task.id);
    if (existing == null) throw Exception('Task not found');
    if (!existing.canEditFields(currentUserId)) {
      throw Exception('You do not have permission to edit this task.');
    }
    replace(task.copyWith(updatedAt: DateTime.now()));
  }

  @override
  Future<void> deleteTask({
    required String userId,
    String? groupId,
    required String taskId,
    required String currentUserId,
    Task? task,
  }) async {
    final existing = _byId(taskId) ?? task;
    if (existing == null) return;
    if (!existing.canDelete(currentUserId)) {
      throw Exception('You do not have permission to delete this task.');
    }
    tasks.removeWhere((item) => item.id == taskId);
    _emit();
  }

  @override
  Future<void> deleteUneditedSpawnedSuccessor({
    required String userId,
    String? groupId,
    required String parentTaskId,
    required String currentUserId,
  }) async {
    tasks.removeWhere(
      (task) =>
          task.spawnedFromTaskId == parentTaskId &&
          task.status == TaskStatus.todo,
    );
    _emit();
  }
}
