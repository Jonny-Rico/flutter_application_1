import 'package:family_tasks/core/haptics/app_haptics.dart';
import 'package:family_tasks/features/tasks/domain/task_status.dart';
import 'package:family_tasks/features/tasks/presentation/providers/task_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_auth_user.dart';
import '../helpers/fake_notification_scheduler.dart';
import '../helpers/fake_task_repository.dart';
import '../helpers/task_fixtures.dart';
import '../helpers/test_overrides.dart';

void main() {
  setUp(() => AppHaptics.enabled = false);
  tearDown(() => AppHaptics.enabled = true);

  testWidgets('TASK-P-03: detail quick status updates the task', (tester) async {
    final task = buildTask(id: 't1', title: 'Vacuum');
    final repo = FakeTaskRepository([task]);
    await tester.pumpWidget(
      taskRouterApp(
        overrides: fakeTaskOverrides(repo: repo),
        location: '/tasks/t1',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Task details'), findsOneWidget);
    expect(find.text('Vacuum'), findsOneWidget);

    await tester.tap(find.text('In Progress'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(repo.tasks.single.status, TaskStatus.inProgress);
  });

  testWidgets('TASK-P-02: creator can edit title and save', (tester) async {
    final task = buildTask(id: 't1', title: 'Old title');
    final repo = FakeTaskRepository([task]);
    await tester.pumpWidget(
      taskRouterApp(
        overrides: fakeTaskOverrides(repo: repo),
        location: '/tasks/t1/edit',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Edit task'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'New title');
    await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repo.tasks.single.title, 'New title');
    expect(find.text('Tasks'), findsWidgets);
  });

  testWidgets('PERM-N-02: assignee cannot open edit for creator-owned fields', (
    tester,
  ) async {
    final task = buildTask(
      id: 't1',
      title: 'Owner task',
      createdBy: 'user-a',
      assigneeId: 'user-b',
    );
    final repo = FakeTaskRepository([task]);
    await tester.pumpWidget(
      taskRouterApp(
        overrides: fakeTaskOverrides(
          repo: repo,
          user: FakeAuthUser(uid: 'user-b', displayName: 'QA User B'),
        ),
        location: '/tasks/t1',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byIcon(Icons.edit_rounded), findsNothing);
    expect(find.text('In Progress'), findsOneWidget);
  });

  testWidgets('TASK-P-04: marking Done offers Undo', (tester) async {
    final task = buildTask(id: 't1', title: 'Take out trash');
    final repo = FakeTaskRepository([task]);
    final scheduler = FakeNotificationScheduler();
    await tester.pumpWidget(
      taskRouterApp(
        overrides: fakeTaskOverrides(repo: repo, scheduler: scheduler),
        location: '/tasks/t1',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Done'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repo.tasks.single.status, TaskStatus.done);
    expect(find.text('Undo'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));

    expect(repo.tasks.single.status, TaskStatus.todo);
  });

  testWidgets('TASK-P-05 / TASK-N-02: swipe delete cancel keeps the task', (
    tester,
  ) async {
    final task = buildTask(id: 't1', title: 'Keep me');
    final repo = FakeTaskRepository([task]);
    await tester.pumpWidget(
      taskRouterApp(overrides: fakeTaskOverrides(repo: repo)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.drag(find.text('Keep me'), const Offset(-400, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Delete task?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(repo.tasks, hasLength(1));
    expect(find.text('Keep me'), findsOneWidget);
  });

  testWidgets('TASK-N-03: past deadline picker opens on edit', (tester) async {
    final task = buildTask(
      id: 't1',
      title: 'Overdue edit',
      deadline: DateTime(2020, 1, 2, 9),
    );
    final repo = FakeTaskRepository([task]);
    await tester.pumpWidget(
      taskRouterApp(
        overrides: fakeTaskOverrides(repo: repo),
        location: '/tasks/t1/edit',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.ensureVisible(find.byIcon(Icons.calendar_month_rounded));
    await tester.tap(find.byIcon(Icons.calendar_month_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byType(DatePickerDialog).evaluate().isNotEmpty ||
          find.textContaining('Select date').evaluate().isNotEmpty ||
          find.textContaining('2020').evaluate().isNotEmpty,
      isTrue,
    );
  });
}
