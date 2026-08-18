import 'package:family_tasks/features/tasks/data/task_new_assignment_notification_storage.dart';
import 'package:family_tasks/features/tasks/data/task_new_assignment_notifier.dart';
import 'package:family_tasks/features/tasks/data/task_notification_scheduler.dart';
import 'package:family_tasks/features/tasks/domain/task_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import '../helpers/fake_notification_scheduler.dart';
import '../helpers/task_fixtures.dart';

void main() {
  test('NOTIF-N-02: creator does not get a new-task alert', () {
    final clean = TaskNewAssignmentNotifier(
      notificationService: FakeNotificationService(),
      storage: _MemoryAssignmentStorage(),
    );
    final task = buildTask(id: 't1', createdBy: 'user-a', assigneeId: 'user-a');
    expect(clean.shouldNotifyAboutTask(task, 'user-a'), isFalse);
  });

  test('NOTIF-P-02: assignee who did not create the task is notified', () {
    final clean = TaskNewAssignmentNotifier(
      notificationService: FakeNotificationService(),
      storage: _MemoryAssignmentStorage(),
    );
    final task = buildTask(id: 't1', createdBy: 'user-a', assigneeId: 'user-b');
    expect(clean.shouldNotifyAboutTask(task, 'user-b'), isTrue);
  });

  test('NOTIF-N-01: notify off records seen ids but does not show alerts',
      () async {
    final service = FakeNotificationService();
    final storage = _MemoryAssignmentStorage()
      ..seedBaseline(scopeKey: 'solo', taskIds: {'old'});
    final clean = TaskNewAssignmentNotifier(
      notificationService: service,
      storage: storage,
    );
    final incoming = buildTask(
      id: 'new-1',
      createdBy: 'user-a',
      assigneeId: 'user-b',
    );

    await clean.processTasks(
      userId: 'user-b',
      scopeKey: 'solo',
      tasks: [incoming],
      emissionCount: 2,
      notifyEnabled: false,
    );

    expect(service.shownTitles, isEmpty);
  });

  test('NOTIF-P-02 process: enabled notify shows the assignment', () async {
    final service = FakeNotificationService();
    final storage = _MemoryAssignmentStorage()
      ..seedBaseline(scopeKey: 'solo', taskIds: {'old'});
    final clean = TaskNewAssignmentNotifier(
      notificationService: service,
      storage: storage,
    );

    await clean.processTasks(
      userId: 'user-b',
      scopeKey: 'solo',
      tasks: [
        buildTask(id: 'new-1', createdBy: 'user-a', assigneeId: 'user-b'),
      ],
      emissionCount: 2,
      notifyEnabled: true,
    );

    expect(service.shownTitles, ['Sample']);
  });

  test('NOTIF-P-01: scheduler notifies assignee of an upcoming reminder', () {
    final scheduler = TaskNotificationScheduler(FakeNotificationService());
    final task = buildTask(
      id: 't1',
      createdBy: 'user-a',
      assigneeId: 'user-b',
    );
    expect(scheduler.shouldNotifyUser(task, 'user-b'), isTrue);
    expect(
      scheduler.shouldNotifyUser(
        task.copyWith(status: TaskStatus.done),
        'user-b',
      ),
      isFalse,
    );
  });
}

class _MemoryAssignmentStorage extends TaskNewAssignmentNotificationStorage {
  _MemoryAssignmentStorage() : super(_UnusedBox());

  TaskNewAssignmentNotificationState? _state;

  void seedBaseline({
    required String scopeKey,
    required Set<String> taskIds,
  }) {
    _state = TaskNewAssignmentNotificationState.empty.withBaseline(
      scopeKey: scopeKey,
      taskIds: taskIds,
    );
  }

  @override
  TaskNewAssignmentNotificationState load(String userId) {
    return _state ?? TaskNewAssignmentNotificationState.empty;
  }

  @override
  Future<void> save(
    String userId,
    TaskNewAssignmentNotificationState state,
  ) async {
    _state = state;
  }
}

class _UnusedBox implements Box<dynamic> {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
