import 'package:family_tasks/core/constants/app_constants.dart';
import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/family/domain/user_profile.dart';
import 'package:family_tasks/features/family/presentation/providers/family_providers.dart';
import 'package:family_tasks/features/tasks/presentation/providers/task_providers.dart';
import 'package:family_tasks/features/tasks/presentation/screens/task_detail_screen.dart';
import 'package:family_tasks/features/tasks/presentation/screens/task_form_screen.dart';
import 'package:family_tasks/features/tasks/presentation/screens/tasks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'fake_auth_user.dart';
import 'fake_notification_scheduler.dart';
import 'fake_task_repository.dart';

const testProfile = UserProfile(
  userId: 'user-a',
  displayName: 'QA User A',
  email: 'qa.a.familytasks@example.com',
);

List<Override> fakeTaskOverrides({
  required FakeTaskRepository repo,
  UserProfile profile = testProfile,
  FakeAuthUser? user,
  FakeNotificationScheduler? scheduler,
}) {
  final authUser = user ?? FakeAuthUser(uid: profile.userId);
  return [
    authStateProvider.overrideWith((ref) => Stream.value(authUser)),
    userProfileProvider.overrideWith((ref) => Stream.value(profile)),
    groupMembersProvider.overrideWith((ref) => Stream.value([])),
    taskRepositoryProvider.overrideWithValue(repo),
    taskScopeProvider.overrideWith(
      (ref) => TaskScope(userId: authUser.uid, groupId: profile.groupId),
    ),
    tasksProvider.overrideWith(
      (ref) => repo.watchTasks(userId: profile.userId, groupId: profile.groupId),
    ),
    taskViewFilterProvider.overrideWith((ref) => TaskViewFilter.all),
    taskStatusFilterProvider.overrideWith((ref) => null),
    if (scheduler != null)
      taskNotificationSchedulerProvider.overrideWithValue(scheduler),
  ];
}

Widget taskRouterApp({
  required List<Override> overrides,
  String location = '/tasks',
}) {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/tasks',
        builder: (context, state) => const TasksScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const TaskFormScreen(),
          ),
          GoRoute(
            path: ':id/edit',
            builder: (context, state) => TaskFormScreen(
              taskId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) => TaskDetailScreen(
              taskId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      scaffoldMessengerKey: AppConstants.scaffoldMessengerKey,
      routerConfig: router,
    ),
  );
}
