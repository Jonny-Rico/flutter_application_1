import 'package:family_tasks/core/notifications/task_notification_service.dart';
import 'package:family_tasks/features/tasks/data/task_new_assignment_notification_storage.dart';
import 'package:family_tasks/features/tasks/domain/task.dart';

class TaskNewAssignmentNotifier {
  TaskNewAssignmentNotifier({
    required this.notificationService,
    required this.storage,
  });

  final TaskNotificationService notificationService;
  final TaskNewAssignmentNotificationStorage storage;

  static String scopeKey({String? groupId}) => groupId ?? 'solo';

  bool shouldNotifyAboutTask(Task task, String userId) {
    if (task.createdBy == userId) return false;
    if (task.isGroupTask) return true;
    return task.assigneeId == userId;
  }

  Future<void> processTasks({
    required String userId,
    required String scopeKey,
    required List<Task> tasks,
    required int emissionCount,
    required bool notifyEnabled,
  }) async {
    var state = storage.load(userId);

    if (!state.hasScopedBaseline(scopeKey)) {
      if (emissionCount < 2) return;

      state = state.withBaseline(
        scopeKey: scopeKey,
        taskIds: tasks.map((task) => task.id),
      );
      await storage.save(userId, state);
      return;
    }

    final pending = <Task>[];
    for (final task in tasks) {
      if (!shouldNotifyAboutTask(task, userId)) continue;
      if (state.notifiedTaskIds.contains(task.id)) continue;
      pending.add(task);
    }

    if (pending.isEmpty) return;

    // Always mark as seen so re-enabling later does not flood old alerts.
    final nextState =
        state.withNotifiedTaskIds(pending.map((task) => task.id));

    if (!notifyEnabled) {
      await storage.save(userId, nextState);
      return;
    }

    await notificationService.requestPermission();

    for (final task in pending) {
      await notificationService.showNewTaskAssignment(
        taskId: task.id,
        title: task.title,
        isGroupTask: task.isGroupTask,
      );
    }

    await storage.save(userId, nextState);
  }
}