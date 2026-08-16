import 'package:family_tasks/core/constants/app_constants.dart';
import 'package:family_tasks/core/router/app_router.dart';
import 'package:family_tasks/core/theme/app_theme.dart';
import 'package:family_tasks/features/app_lock/presentation/widgets/app_lock_gate.dart';
import 'package:family_tasks/features/tasks/presentation/providers/task_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FamilyTasksApp extends ConsumerWidget {
  const FamilyTasksApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(taskFiltersPersistenceProvider);
    ref.watch(taskReminderSyncProvider);
    ref.watch(taskNewAssignmentNotificationProvider);
    ref.watch(notificationNavigationProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: AppConstants.scaffoldMessengerKey,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      builder: (context, child) {
        return AppLockGate(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}