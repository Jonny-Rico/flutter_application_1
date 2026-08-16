import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_tasks/features/tasks/domain/task_permissions.dart';
import 'package:family_tasks/features/tasks/domain/task_priority.dart';
import 'package:family_tasks/features/tasks/domain/task_recurrence.dart';
import 'package:family_tasks/features/tasks/domain/task_status.dart';

class Task {
  const Task({
    required this.id,
    this.groupId,
    required this.createdBy,
    this.assigneeId,
    this.completedBy,
    required this.title,
    required this.description,
    required this.deadline,
    this.reminderAt,
    required this.priority,
    required this.status,
    required this.isGroupTask,
    required this.permissions,
    required this.createdAt,
    required this.updatedAt,
    this.recurrence = TaskRecurrence.none,
    this.spawnedFromTaskId,
  });

  final String id;
  final String? groupId;
  final String createdBy;
  final String? assigneeId;
  final String? completedBy;
  final String title;
  final String description;
  final DateTime? deadline;
  final DateTime? reminderAt;
  final TaskPriorityLevel priority;
  final TaskStatus status;
  final bool isGroupTask;
  final TaskPermissions permissions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TaskRecurrence recurrence;
  final String? spawnedFromTaskId;

  bool get isOverdue {
    if (deadline == null || status == TaskStatus.done) return false;
    return deadline!.isBefore(DateTime.now());
  }

  bool canEditFields(String userId) =>
      createdBy == userId || permissions.assigneeCanEdit;

  bool canDelete(String userId) =>
      createdBy == userId || permissions.assigneeCanDelete;

  bool canChangeStatus(String userId) {
    if (createdBy == userId) return true;
    if (isGroupTask) return true;
    return assigneeId == userId;
  }

  Task copyWith({
    String? title,
    String? description,
    DateTime? deadline,
    bool clearDeadline = false,
    DateTime? reminderAt,
    bool clearReminder = false,
    TaskPriorityLevel? priority,
    TaskStatus? status,
    String? completedBy,
    bool clearCompletedBy = false,
    DateTime? updatedAt,
    TaskRecurrence? recurrence,
    String? spawnedFromTaskId,
  }) {
    return Task(
      id: id,
      groupId: groupId,
      createdBy: createdBy,
      assigneeId: assigneeId,
      completedBy: clearCompletedBy ? null : (completedBy ?? this.completedBy),
      title: title ?? this.title,
      description: description ?? this.description,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      reminderAt: clearReminder ? null : (reminderAt ?? this.reminderAt),
      priority: priority ?? this.priority,
      status: status ?? this.status,
      isGroupTask: isGroupTask,
      permissions: permissions,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      recurrence: recurrence ?? this.recurrence,
      spawnedFromTaskId: spawnedFromTaskId ?? this.spawnedFromTaskId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'createdBy': createdBy,
      'assigneeId': assigneeId,
      'completedBy': completedBy,
      'title': title,
      'description': description,
      'deadline': deadline?.toIso8601String(),
      'reminderAt': reminderAt?.toIso8601String(),
      'priority': priority.value,
      'status': status.value,
      'isGroupTask': isGroupTask,
      'permissions': permissions.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'recurrence': recurrence.value,
      'spawnedFromTaskId': spawnedFromTaskId,
      // Legacy field for Hive entries from iteration 3.
      'userId': createdBy,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    final createdBy =
        map['createdBy'] as String? ?? map['userId'] as String? ?? '';

    return Task(
      id: map['id'] as String,
      groupId: map['groupId'] as String?,
      createdBy: createdBy,
      assigneeId: map['assigneeId'] as String?,
      completedBy: map['completedBy'] as String?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      deadline: _parseDateTime(map['deadline']),
      reminderAt: _parseDateTime(map['reminderAt']),
      priority: TaskPriorityLevel.fromValue(
        (map['priority'] as num?)?.toInt() ?? 2,
      ),
      status: TaskStatus.fromValue(map['status'] as String? ?? 'todo'),
      isGroupTask: map['isGroupTask'] as bool? ?? false,
      permissions: TaskPermissions.fromMap(map['permissions']),
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
      recurrence: TaskRecurrence.fromValue(map['recurrence'] as String?),
      spawnedFromTaskId: map['spawnedFromTaskId'] as String?,
    );
  }

  factory Task.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Task.fromMap({...data, 'id': doc.id});
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    return null;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'createdBy': createdBy,
      'assigneeId': assigneeId,
      'completedBy': completedBy,
      'title': title,
      'description': description,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'reminderAt':
          reminderAt != null ? Timestamp.fromDate(reminderAt!) : null,
      'priority': priority.value,
      'status': status.value,
      'isGroupTask': isGroupTask,
      'permissions': permissions.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'recurrence': recurrence.value,
      if (spawnedFromTaskId != null) 'spawnedFromTaskId': spawnedFromTaskId,
    };
  }
}
