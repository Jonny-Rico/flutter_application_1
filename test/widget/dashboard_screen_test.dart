import 'package:family_tasks/core/router/routes.dart';
import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:family_tasks/features/family/domain/group_role.dart';
import 'package:family_tasks/features/family/domain/user_profile.dart';
import 'package:family_tasks/features/family/presentation/providers/family_providers.dart';
import 'package:family_tasks/features/tasks/domain/task_status.dart';
import 'package:family_tasks/features/tasks/presentation/providers/task_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/fake_auth_user.dart';
import '../helpers/task_fixtures.dart';

void main() {
  const solo = UserProfile(
    userId: 'user-a',
    displayName: 'QA User A',
    email: 'qa.a.familytasks@example.com',
  );
  const inGroup = UserProfile(
    userId: 'user-a',
    displayName: 'QA User A',
    email: 'qa.a.familytasks@example.com',
    groupId: 'g1',
    groupRole: GroupRole.owner,
  );

  Future<void> pumpDashboard(
    WidgetTester tester, {
    required UserProfile profile,
    bool verified = true,
    List<Override> extra = const [],
  }) async {
    final router = GoRouter(
      initialLocation: AppRoutes.dashboard,
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.tasks,
          builder: (context, state) => const Scaffold(body: Text('Tasks')),
        ),
        GoRoute(
          path: AppRoutes.family,
          builder: (context, state) => const Scaffold(body: Text('Family')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(FakeAuthUser(uid: profile.userId)),
          ),
          userProfileProvider.overrideWith((ref) => Stream.value(profile)),
          emailVerifiedProvider.overrideWith((ref) => verified),
          groupMembersProvider.overrideWith((ref) => Stream.value([])),
          tasksProvider.overrideWith(
            (ref) => Stream.value([
              buildTask(id: 'open', title: 'Open one'),
              buildTask(
                id: 'done',
                title: 'Done one',
                status: TaskStatus.done,
              ),
            ]),
          ),
          ...extra,
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('DASH-P-01: My overview shows counts', (tester) async {
    await pumpDashboard(tester, profile: solo);

    expect(find.text('My'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('1'), findsWidgets);
    expect(find.text('Done'), findsWidgets);
    expect(find.text('Overdue'), findsOneWidget);
  });

  testWidgets('DASH-N-01: tap a zero tile shows empty copy', (tester) async {
    await pumpDashboard(tester, profile: solo);

    await tester.tap(find.text('Overdue'));
    await tester.pump();

    expect(find.text('No overdue tasks yet'), findsOneWidget);
  });

  testWidgets('DASH-P-02: Family tab with group shows family overview', (
    tester,
  ) async {
    await pumpDashboard(
      tester,
      profile: inGroup,
      extra: [
        tasksProvider.overrideWith(
          (ref) => Stream.value([
            buildTask(
              id: 'fam',
              title: 'Family chore',
              isGroupTask: true,
            ),
          ]),
        ),
      ],
    );

    await tester.tap(find.text('Family'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('No family group'), findsNothing);
  });

  testWidgets('VER-N-02 / DASH-N-02: Family tab without group', (tester) async {
    await pumpDashboard(tester, profile: solo, verified: false);

    await tester.tap(find.text('Family'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Verify email for Family'), findsOneWidget);
    expect(find.text('Verify email'), findsOneWidget);
  });
}
