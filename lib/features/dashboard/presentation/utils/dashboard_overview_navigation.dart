import 'package:family_tasks/core/router/routes.dart';
import 'package:family_tasks/features/tasks/domain/task_status.dart';
import 'package:family_tasks/features/tasks/presentation/providers/task_providers.dart';
import 'package:family_tasks/features/tasks/presentation/utils/task_filter_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum OverviewMetric { total, open, done, overdue }

/// Open assigned tasks threshold for "overloaded" highlight on Family tab.
const kMemberOverloadThreshold = 3;

String emptyOverviewMessage(OverviewMetric metric) => switch (metric) {
      OverviewMetric.total => 'No tasks yet',
      OverviewMetric.open => 'No open tasks yet',
      OverviewMetric.done => 'No done tasks yet',
      OverviewMetric.overdue => 'No overdue tasks yet',
    };

void _showEmptySnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    ),
  );
}

void _goTasks(BuildContext context) => context.go(AppRoutes.tasks);

/// Overview tile: Total / Open / Done / Overdue.
void onOverviewMetricTapped({
  required BuildContext context,
  required WidgetRef ref,
  required OverviewMetric metric,
  required int count,
  required bool isFamilyTab,
}) {
  if (count <= 0) {
    _showEmptySnack(context, emptyOverviewMessage(metric));
    return;
  }

  final scope =
      isFamilyTab ? TaskDashboardScope.family : TaskDashboardScope.my;

  final (metricFilter, status) = switch (metric) {
    OverviewMetric.total => (TaskMetricFilter.none, null),
    OverviewMetric.open => (TaskMetricFilter.openOnly, null),
    OverviewMetric.done => (TaskMetricFilter.none, TaskStatus.done),
    OverviewMetric.overdue => (TaskMetricFilter.overdueOnly, null),
  };

  applyDashboardOverviewFilters(
    ref: ref,
    scope: scope,
    metric: metricFilter,
    statusFilter: status,
  );
  _goTasks(context);
}

/// By status row (To Do / In Progress / Done).
void onStatusBreakdownTapped({
  required BuildContext context,
  required WidgetRef ref,
  required TaskStatus status,
  required int count,
  required bool isFamilyTab,
}) {
  if (count <= 0) {
    _showEmptySnack(
      context,
      'No ${status.label.toLowerCase()} tasks yet',
    );
    return;
  }

  applyDashboardOverviewFilters(
    ref: ref,
    scope: isFamilyTab ? TaskDashboardScope.family : TaskDashboardScope.my,
    metric: TaskMetricFilter.none,
    statusFilter: status,
  );
  _goTasks(context);
}

/// Workload tiles: For me / By me (standard view filters).
void onWorkloadViewTapped({
  required BuildContext context,
  required WidgetRef ref,
  required TaskViewFilter viewFilter,
  required int count,
  required String emptyMessage,
}) {
  if (count <= 0) {
    _showEmptySnack(context, emptyMessage);
    return;
  }

  // Workload uses normal Tasks filters (not temporary dashboard scope).
  clearDashboardTaskFilters(ref);
  ref.read(taskViewFilterProvider.notifier).state = viewFilter;
  ref.read(taskStatusFilterProvider.notifier).state = null;
  ref.read(taskDashboardNavActiveProvider.notifier).state = false;
  _goTasks(context);
}

/// Family completion card → Family total list.
void onFamilyProgressTapped({
  required BuildContext context,
  required WidgetRef ref,
  required int totalCount,
}) {
  onOverviewMetricTapped(
    context: context,
    ref: ref,
    metric: OverviewMetric.total,
    count: totalCount,
    isFamilyTab: true,
  );
}
