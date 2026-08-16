import 'package:family_tasks/features/family/presentation/providers/family_providers.dart';
import 'package:family_tasks/features/tasks/domain/task_status.dart';
import 'package:family_tasks/features/tasks/presentation/providers/task_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resets view + status filters using Remember-task-filters defaults.
void resetTaskFilters(WidgetRef ref) {
  clearDashboardTaskFilters(ref);
  clearTaskSearch(ref);

  final persist = ref.read(taskPersistFiltersProvider);
  final hasGroup =
      ref.read(userProfileProvider).valueOrNull?.hasGroup ?? false;

  if (persist) {
    ref.read(taskViewFilterProvider.notifier).state = hasGroup
        ? TaskViewFilter.assignedToMe
        : TaskViewFilter.all;
    ref.read(taskStatusFilterProvider.notifier).state = TaskStatus.todo;
  } else {
    ref.read(taskViewFilterProvider.notifier).state = TaskViewFilter.all;
    ref.read(taskStatusFilterProvider.notifier).state = null;
  }
}

/// True while Tasks is showing a temporary list opened from Dashboard.
bool isDashboardTaskNavActive(WidgetRef ref) {
  if (ref.read(taskDashboardNavActiveProvider)) return true;
  if (ref.read(taskDashboardScopeProvider) != TaskDashboardScope.none) {
    return true;
  }
  if (ref.read(taskMetricFilterProvider) != TaskMetricFilter.none) {
    return true;
  }
  return false;
}

void clearDashboardTaskFilters(WidgetRef ref) {
  ref.read(taskDashboardScopeProvider.notifier).state =
      TaskDashboardScope.none;
  ref.read(taskMetricFilterProvider.notifier).state = TaskMetricFilter.none;
  ref.read(taskDashboardNavActiveProvider.notifier).state = false;
}

void clearTaskSearch(WidgetRef ref) {
  ref.read(taskSearchQueryProvider.notifier).state = '';
}

/// Applies Dashboard navigation into a temporary Tasks filter session.
void applyDashboardOverviewFilters({
  required WidgetRef ref,
  required TaskDashboardScope scope,
  required TaskMetricFilter metric,
  TaskStatus? statusFilter,
}) {
  ref.read(taskDashboardNavActiveProvider.notifier).state = true;
  ref.read(taskDashboardScopeProvider.notifier).state = scope;
  ref.read(taskMetricFilterProvider.notifier).state = metric;
  ref.read(taskStatusFilterProvider.notifier).state = statusFilter;

  // Align view chips with scope for visual consistency.
  ref.read(taskViewFilterProvider.notifier).state = switch (scope) {
    TaskDashboardScope.family => TaskViewFilter.group,
    TaskDashboardScope.my || TaskDashboardScope.none => TaskViewFilter.all,
  };
}

/// User changed a view pill (For me / By me / Family / All).
///
/// Exits temporary Dashboard list: drops scope/metric and, if coming from
/// Dashboard, resets status so Done/Open from Overview is not sticky.
void onTasksViewFilterSelected(WidgetRef ref, TaskViewFilter filter) {
  final fromDashboard = isDashboardTaskNavActive(ref);
  clearDashboardTaskFilters(ref);
  ref.read(taskViewFilterProvider.notifier).state = filter;

  if (fromDashboard) {
    final persist = ref.read(taskPersistFiltersProvider);
    ref.read(taskStatusFilterProvider.notifier).state =
        persist ? TaskStatus.todo : null;
  }
}

/// User changed status menu. Exits temporary Dashboard scope/metric.
void onTasksStatusFilterSelected(WidgetRef ref, TaskStatus? status) {
  clearDashboardTaskFilters(ref);
  ref.read(taskStatusFilterProvider.notifier).state = status;
}

String statusFilterLabel(
  TaskStatus? status, {
  TaskMetricFilter metric = TaskMetricFilter.none,
}) {
  return switch (metric) {
    TaskMetricFilter.openOnly => 'Open',
    TaskMetricFilter.overdueOnly => 'Overdue',
    TaskMetricFilter.none => status?.label ?? 'All statuses',
  };
}
