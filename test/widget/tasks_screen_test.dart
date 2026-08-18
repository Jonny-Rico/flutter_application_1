import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/family/domain/group_role.dart';
import 'package:family_tasks/features/family/domain/user_profile.dart';
import 'package:family_tasks/features/family/presentation/providers/family_providers.dart';
import 'package:family_tasks/features/tasks/domain/task_status.dart';
import 'package:family_tasks/features/tasks/presentation/providers/task_providers.dart';
import 'package:family_tasks/features/tasks/presentation/screens/tasks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_auth_user.dart';
import '../helpers/task_fixtures.dart';

const _profile = UserProfile(
  userId: 'user-a',
  displayName: 'QA User A',
  email: 'qa.a.familytasks@example.com',
);

final _todo = buildTask(id: 'todo', title: 'Take out trash');
final _done = buildTask(
  id: 'done',
  title: 'Wash dishes',
  status: TaskStatus.done,
);
final _overdue = buildTask(
  id: 'late',
  title: 'Pay rent',
  deadline: DateTime(2020, 1, 1),
);

Future<void> pumpTasks(
  WidgetTester tester, {
  UserProfile profile = _profile,
  List<Override> extra = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => Stream.value(FakeAuthUser()),
        ),
        userProfileProvider.overrideWith((ref) => Stream.value(profile)),
        groupMembersProvider.overrideWith((ref) => Stream.value([])),
        tasksProvider.overrideWith((ref) => Stream.value([_todo, _done])),
        taskViewFilterProvider.overrideWith((ref) => TaskViewFilter.all),
        taskStatusFilterProvider.overrideWith((ref) => null),
        ...extra,
      ],
      child: const MaterialApp(home: TasksScreen()),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('FILT-P-01: status filter To Do / Done / All', (tester) async {
    await pumpTasks(tester);

    expect(find.text('Take out trash'), findsOneWidget);
    expect(find.text('Wash dishes'), findsOneWidget);

    await tester.tap(find.byTooltip('Filter by status'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'To Do'));
    await tester.pump();

    expect(find.text('Take out trash'), findsOneWidget);
    expect(find.text('Wash dishes'), findsNothing);

    await tester.tap(find.byTooltip('Filter by status'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'Done'));
    await tester.pump();

    expect(find.text('Take out trash'), findsNothing);
    expect(find.text('Wash dishes'), findsOneWidget);

    await tester.tap(find.byTooltip('Filter by status'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'All statuses'));
    await tester.pump();

    expect(find.text('Take out trash'), findsOneWidget);
    expect(find.text('Wash dishes'), findsOneWidget);
  });

  testWidgets('FILT-N-01: view pills hidden without a group', (tester) async {
    await pumpTasks(tester);

    expect(find.text('For me'), findsNothing);
    expect(find.text('By me'), findsNothing);
    expect(find.text('Family'), findsNothing);
  });

  testWidgets('FILT-P-02: view pills visible with a group', (tester) async {
    await pumpTasks(
      tester,
      profile: const UserProfile(
        userId: 'user-a',
        displayName: 'QA User A',
        email: 'qa.a.familytasks@example.com',
        groupId: 'g1',
        groupRole: GroupRole.owner,
      ),
    );

    expect(find.text('For me'), findsOneWidget);
    expect(find.text('By me'), findsOneWidget);
    expect(find.text('Family'), findsOneWidget);
    expect(find.text('All'), findsWidgets);
  });

  testWidgets('TASK-P-06: overdue badge on open past-deadline row', (
    tester,
  ) async {
    await pumpTasks(
      tester,
      extra: [
        tasksProvider.overrideWith((ref) => Stream.value([_overdue])),
      ],
    );

    expect(find.text('Pay rent'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
  });

  testWidgets('TASK-P-07: Reset filters restores hidden tasks', (tester) async {
    await pumpTasks(
      tester,
      extra: [
        taskStatusFilterProvider.overrideWith((ref) => TaskStatus.done),
        tasksProvider.overrideWith((ref) => Stream.value([_todo])),
      ],
    );

    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Reset filters'), findsOneWidget);

    await tester.tap(find.text('Reset filters'));
    await tester.pump();

    expect(find.text('Take out trash'), findsOneWidget);
    expect(find.text('Nothing here'), findsNothing);
  });

  testWidgets('TASK-P-08: search filters the list and clear restores it', (
    tester,
  ) async {
    await pumpTasks(tester);

    await tester.tap(find.byTooltip('Search'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Wash');
    await tester.pump();

    expect(find.text('Wash dishes'), findsOneWidget);
    expect(find.text('Take out trash'), findsNothing);

    await tester.tap(find.byTooltip('Clear'));
    await tester.pump();

    expect(find.text('Wash dishes'), findsOneWidget);
    expect(find.text('Take out trash'), findsOneWidget);
  });
}
