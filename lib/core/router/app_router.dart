import 'package:family_tasks/core/router/router_refresh_notifier.dart';
import 'package:family_tasks/core/router/routes.dart';
import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/auth/presentation/screens/login_screen.dart';
import 'package:family_tasks/features/auth/presentation/screens/splash_screen.dart';
import 'package:family_tasks/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:family_tasks/features/family/presentation/screens/family_screen.dart';
import 'package:family_tasks/features/family/presentation/screens/invite_member_screen.dart';
import 'package:family_tasks/features/help/presentation/screens/help_screen.dart';
import 'package:family_tasks/features/settings/presentation/screens/settings_screen.dart';
import 'package:family_tasks/features/shell/presentation/screens/main_shell_screen.dart';
import 'package:family_tasks/features/tasks/presentation/screens/task_detail_screen.dart';
import 'package:family_tasks/features/tasks/presentation/screens/task_form_screen.dart';
import 'package:family_tasks/features/tasks/presentation/screens/tasks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorTasksKey = GlobalKey<NavigatorState>(debugLabel: 'tasks');
final _shellNavigatorFamilyKey = GlobalKey<NavigatorState>(debugLabel: 'family');
final _shellNavigatorDashboardKey =
    GlobalKey<NavigatorState>(debugLabel: 'dashboard');
final _shellNavigatorSettingsKey =
    GlobalKey<NavigatorState>(debugLabel: 'settings');

final routerRefreshNotifierProvider = Provider<RouterRefreshNotifier>((ref) {
  final notifier = RouterRefreshNotifier();
  ref.onDispose(notifier.dispose);
  ref.listen(authStateProvider, (_, _) => notifier.refresh());
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(routerRefreshNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final location = state.matchedLocation;
      final isSplash = location == AppRoutes.splash;
      final isLogin = location == AppRoutes.login;

      if (authState.isLoading) {
        return isSplash ? null : AppRoutes.splash;
      }

      final isLoggedIn = authState.valueOrNull != null;

      if (isLoggedIn) {
        if (isSplash || isLogin) return AppRoutes.tasks;
        return null;
      }

      if (isLogin) return null;
      return AppRoutes.login;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorTasksKey,
            routes: [
              GoRoute(
                path: AppRoutes.tasks,
                builder: (context, state) => const TasksScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const TaskFormScreen(),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return TaskFormScreen(taskId: id);
                    },
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return TaskDetailScreen(taskId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorFamilyKey,
            routes: [
              GoRoute(
                path: AppRoutes.family,
                builder: (context, state) => const FamilyScreen(),
                routes: [
                  GoRoute(
                    path: 'invite',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const InviteMemberScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorDashboardKey,
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSettingsKey,
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'help',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const HelpScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});