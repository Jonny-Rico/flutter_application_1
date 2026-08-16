import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/dashboard/domain/dashboard_stats.dart';
import 'package:family_tasks/features/family/presentation/providers/family_providers.dart';
import 'package:family_tasks/features/tasks/domain/task.dart';
import 'package:family_tasks/features/tasks/presentation/providers/task_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Personal tasks involving the current user (not family-shared).
List<Task> myTasksForUser(List<Task> tasks, String userId) {
  return tasks
      .where(
        (task) =>
            !task.isGroupTask &&
            (task.assigneeId == userId || task.createdBy == userId),
      )
      .toList(growable: false);
}

/// Shared family tasks.
List<Task> familyTasks(List<Task> tasks) {
  return tasks.where((task) => task.isGroupTask).toList(growable: false);
}

final myDashboardStatsProvider = Provider<AsyncValue<DashboardStats>>((ref) {
  final userId = ref.watch(authStateProvider).valueOrNull?.uid;
  final tasksAsync = ref.watch(tasksProvider);

  if (userId == null) return const AsyncValue.loading();

  return tasksAsync.when(
    data: (tasks) => AsyncValue.data(
      DashboardStats.fromTasks(
        tasks: myTasksForUser(tasks, userId),
        userId: userId,
      ),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

final familyDashboardStatsProvider = Provider<AsyncValue<DashboardStats>>((ref) {
  final userId = ref.watch(authStateProvider).valueOrNull?.uid;
  final tasksAsync = ref.watch(tasksProvider);
  final members = ref.watch(groupMembersProvider).valueOrNull ?? const [];

  if (userId == null) return const AsyncValue.loading();

  return tasksAsync.when(
    data: (tasks) => AsyncValue.data(
      DashboardStats.fromTasks(
        tasks: familyTasks(tasks),
        userId: userId,
        members: members,
      ),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});
