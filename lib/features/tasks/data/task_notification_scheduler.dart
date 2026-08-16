import 'package:family_tasks/core/notifications/task_notification_service.dart';
import 'package:family_tasks/features/tasks/domain/task.dart';
import 'package:family_tasks/features/tasks/domain/task_status.dart';

class TaskNotificationScheduler {
  TaskNotificationScheduler(this._service);

  final TaskNotificationService _service;

  bool shouldNotifyUser(Task task, String userId) {
    if (task.status == TaskStatus.done) return false;
    if (task.isGroupTask) return true;
    return task.assigneeId == userId || task.createdBy == userId;
  }

  Future<void> syncTask(Task task, {required String userId}) async {
    if (!shouldNotifyUser(task, userId) ||
        task.reminderAt == null ||
        !task.reminderAt!.isAfter(DateTime.now())) {
      await _service.cancelTaskReminder(task.id);
      return;
    }

    await _service.scheduleTaskReminder(
      taskId: task.id,
      title: task.title,
      reminderAt: task.reminderAt!,
    );
  }

  Future<void> syncTasksForUser({
    required List<Task> tasks,
    required String userId,
  }) async {
    for (final task in tasks) {
      await syncTask(task, userId: userId);
    }
  }

  Future<void> cancelTask(String taskId) async {
    await _service.cancelTaskReminder(taskId);
  }

  Future<bool> requestPermission() => _service.requestPermission();
}