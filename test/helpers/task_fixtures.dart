import 'package:family_tasks/features/tasks/domain/task.dart';
import 'package:family_tasks/features/tasks/domain/task_permissions.dart';
import 'package:family_tasks/features/tasks/domain/task_priority.dart';
import 'package:family_tasks/features/tasks/domain/task_status.dart';

Task buildTask({
  String id = 't1',
  String createdBy = 'user-a',
  String? assigneeId,
  String title = 'Sample',
  DateTime? deadline,
  TaskStatus status = TaskStatus.todo,
  bool isGroupTask = false,
  TaskPermissions permissions = const TaskPermissions(),
}) {
  final now = DateTime(2026, 6, 1, 12);
  return Task(
    id: id,
    createdBy: createdBy,
    assigneeId: assigneeId ?? createdBy,
    title: title,
    description: '',
    deadline: deadline,
    priority: TaskPriorityLevel.medium,
    status: status,
    isGroupTask: isGroupTask,
    permissions: permissions,
    createdAt: now,
    updatedAt: now,
  );
}
