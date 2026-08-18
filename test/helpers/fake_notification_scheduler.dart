import 'package:family_tasks/core/notifications/task_notification_service.dart';
import 'package:family_tasks/features/tasks/data/task_notification_scheduler.dart';
import 'package:family_tasks/features/tasks/domain/task.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeNotificationScheduler extends Fake
    implements TaskNotificationScheduler {
  final cancelledIds = <String>[];
  var permissionGranted = true;

  @override
  Future<void> cancelTask(String taskId) async {
    cancelledIds.add(taskId);
  }

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> syncTask(Task task, {required String userId}) async {}

  @override
  Future<void> syncTasksForUser({
    required List<Task> tasks,
    required String userId,
  }) async {}
}

class FakeNotificationService extends Fake implements TaskNotificationService {
  final shownTitles = <String>[];
  var permissionGranted = true;

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> showNewTaskAssignment({
    required String taskId,
    required String title,
    required bool isGroupTask,
  }) async {
    shownTitles.add(title);
  }
}
