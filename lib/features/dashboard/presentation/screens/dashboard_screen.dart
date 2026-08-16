import 'package:family_tasks/core/router/routes.dart';
import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/core/theme/app_spacing.dart';
import 'package:family_tasks/features/dashboard/domain/dashboard_stats.dart';
import 'package:family_tasks/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:family_tasks/features/dashboard/presentation/utils/dashboard_overview_navigation.dart';
import 'package:family_tasks/features/dashboard/presentation/utils/family_summary_share.dart';
import 'package:family_tasks/features/dashboard/presentation/widgets/breakdown_list.dart';
import 'package:family_tasks/features/dashboard/presentation/widgets/completion_card.dart';
import 'package:family_tasks/features/dashboard/presentation/widgets/dashboard_section.dart';
import 'package:family_tasks/features/dashboard/presentation/widgets/member_activity_list.dart';
import 'package:family_tasks/features/dashboard/presentation/widgets/stat_grid.dart';
import 'package:family_tasks/features/dashboard/presentation/widgets/weekly_trend_chart.dart';
import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/family/presentation/providers/family_providers.dart';
import 'package:family_tasks/features/tasks/domain/task_priority.dart';
import 'package:family_tasks/features/tasks/domain/task_status.dart';
import 'package:family_tasks/features/tasks/presentation/providers/task_providers.dart';
import 'package:family_tasks/shared/widgets/empty_state.dart';
import 'package:family_tasks/shared/widgets/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasGroup =
        ref.watch(userProfileProvider).valueOrNull?.hasGroup ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My'),
            Tab(text: 'Family'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DashboardTabBody(
            statsAsync: ref.watch(myDashboardStatsProvider),
            mode: _DashboardTabMode.my,
            hasGroup: hasGroup,
          ),
          _DashboardTabBody(
            statsAsync: ref.watch(familyDashboardStatsProvider),
            mode: _DashboardTabMode.family,
            hasGroup: hasGroup,
          ),
        ],
      ),
    );
  }
}

enum _DashboardTabMode { my, family }

class _DashboardTabBody extends ConsumerWidget {
  const _DashboardTabBody({
    required this.statsAsync,
    required this.mode,
    required this.hasGroup,
  });

  final AsyncValue<DashboardStats> statsAsync;
  final _DashboardTabMode mode;
  final bool hasGroup;

  bool get _isFamily => mode == _DashboardTabMode.family;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return statsAsync.when(
      loading: () => const DashboardSkeleton(),
      error: (error, _) => EmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load dashboard',
        subtitle: error.toString(),
        compact: true,
        action: FilledButton(
          onPressed: () => ref.invalidate(tasksProvider),
          child: const Text('Retry'),
        ),
      ),
      data: (stats) {
        if (mode == _DashboardTabMode.family && !hasGroup) {
          final verified = ref.watch(emailVerifiedProvider);
          return EmptyState(
            icon: Icons.family_restroom_outlined,
            title: verified ? 'No family group' : 'Verify email for Family',
            subtitle: verified
                ? 'Create or join a family group to see family analytics.'
                : 'Confirm your email, then create or join a family.',
            compact: true,
            action: FilledButton(
              onPressed: () => context.go(AppRoutes.family),
              child: Text(verified ? 'Go to Family' : 'Verify email'),
            ),
          );
        }

        if (stats.isEmpty) {
          return EmptyState(
            icon: Icons.insights_outlined,
            title: 'No data yet',
            subtitle: mode == _DashboardTabMode.my
                ? 'Create personal tasks to see your stats.'
                : 'Create family tasks to see shared progress.',
            compact: true,
            action: FilledButton(
              onPressed: () => context.go(AppRoutes.tasks),
              child: const Text('Go to Tasks'),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(tasksProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.md,
              AppSpacing.screen,
              AppSpacing.scrollBottom,
            ),
            children: [
              DashboardSection(
                title: 'Overview',
                child: StatGrid(
                  items: [
                    StatTileData(
                      label: 'Total',
                      value: '${stats.total}',
                      icon: Icons.checklist_rounded,
                      onTap: () => onOverviewMetricTapped(
                        context: context,
                        ref: ref,
                        metric: OverviewMetric.total,
                        count: stats.total,
                        isFamilyTab: _isFamily,
                      ),
                    ),
                    StatTileData(
                      label: 'Open',
                      value: '${stats.open}',
                      icon: Icons.radio_button_unchecked_rounded,
                      accent: AppColors.accentWarm,
                      onTap: () => onOverviewMetricTapped(
                        context: context,
                        ref: ref,
                        metric: OverviewMetric.open,
                        count: stats.open,
                        isFamilyTab: _isFamily,
                      ),
                    ),
                    StatTileData(
                      label: 'Done',
                      value: '${stats.done}',
                      icon: Icons.check_circle_outline_rounded,
                      accent: AppColors.success,
                      onTap: () => onOverviewMetricTapped(
                        context: context,
                        ref: ref,
                        metric: OverviewMetric.done,
                        count: stats.done,
                        isFamilyTab: _isFamily,
                      ),
                    ),
                    StatTileData(
                      label: 'Overdue',
                      value: '${stats.overdue}',
                      icon: Icons.warning_amber_rounded,
                      accent: AppColors.danger,
                      onTap: () => onOverviewMetricTapped(
                        context: context,
                        ref: ref,
                        metric: OverviewMetric.overdue,
                        count: stats.overdue,
                        isFamilyTab: _isFamily,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.section),
              DashboardSection(
                title: 'Completion',
                child: CompletionCard(
                  rate: stats.completionRate,
                  done: stats.done,
                  total: stats.total,
                  weekComparison: stats.weekComparisonLabel,
                  onTap: () => onOverviewMetricTapped(
                    context: context,
                    ref: ref,
                    metric: OverviewMetric.total,
                    count: stats.total,
                    isFamilyTab: _isFamily,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.section),
              DashboardSection(
                title: 'By status',
                child: BreakdownList(
                  total: stats.total,
                  items: [
                    BreakdownItem(
                      label: TaskStatus.todo.label,
                      count: stats.todo,
                      color: TaskStatus.todo.color,
                      onTap: () => onStatusBreakdownTapped(
                        context: context,
                        ref: ref,
                        status: TaskStatus.todo,
                        count: stats.todo,
                        isFamilyTab: _isFamily,
                      ),
                    ),
                    BreakdownItem(
                      label: TaskStatus.inProgress.label,
                      count: stats.inProgress,
                      color: TaskStatus.inProgress.color,
                      onTap: () => onStatusBreakdownTapped(
                        context: context,
                        ref: ref,
                        status: TaskStatus.inProgress,
                        count: stats.inProgress,
                        isFamilyTab: _isFamily,
                      ),
                    ),
                    BreakdownItem(
                      label: TaskStatus.done.label,
                      count: stats.done,
                      color: TaskStatus.done.color,
                      onTap: () => onStatusBreakdownTapped(
                        context: context,
                        ref: ref,
                        status: TaskStatus.done,
                        count: stats.done,
                        isFamilyTab: _isFamily,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.section),
              DashboardSection(
                title: 'By priority',
                child: BreakdownList(
                  total: stats.total,
                  items: [
                    for (final level in TaskPriorityLevel.values.reversed)
                      BreakdownItem(
                        label: level.label,
                        count: stats.byPriority[level] ?? 0,
                        color: level.color,
                      ),
                  ],
                ),
              ),
              if (mode == _DashboardTabMode.my) ...[
                const SizedBox(height: AppSpacing.section),
                DashboardSection(
                  title: 'Your workload',
                  child: StatGrid(
                    items: [
                      StatTileData(
                        label: 'For me',
                        value: '${stats.assignedToMe}',
                        icon: Icons.person_outline_rounded,
                        onTap: () => onWorkloadViewTapped(
                          context: context,
                          ref: ref,
                          viewFilter: TaskViewFilter.assignedToMe,
                          count: stats.assignedToMe,
                          emptyMessage: 'No tasks assigned to you yet',
                        ),
                      ),
                      StatTileData(
                        label: 'By me',
                        value: '${stats.assignedByMe}',
                        icon: Icons.person_add_alt_1_outlined,
                        onTap: () => onWorkloadViewTapped(
                          context: context,
                          ref: ref,
                          viewFilter: TaskViewFilter.assignedByMe,
                          count: stats.assignedByMe,
                          emptyMessage: 'You have not assigned tasks to others',
                        ),
                      ),
                      StatTileData(
                        label: 'Open',
                        value: '${stats.open}',
                        icon: Icons.pending_actions_outlined,
                        onTap: () => onOverviewMetricTapped(
                          context: context,
                          ref: ref,
                          metric: OverviewMetric.open,
                          count: stats.open,
                          isFamilyTab: false,
                        ),
                      ),
                      StatTileData(
                        label: 'Streak',
                        value: '${stats.activityStreakDays}d',
                        icon: Icons.local_fire_department_outlined,
                        accent: AppColors.accentWarm,
                      ),
                    ],
                  ),
                ),
              ],
              if (mode == _DashboardTabMode.family) ...[
                const SizedBox(height: AppSpacing.section),
                DashboardSection(
                  title: 'Family progress',
                  subtitle: '${stats.done}/${stats.total} family tasks done',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CompletionCard(
                        title: 'Family completion',
                        rate: stats.completionRate,
                        done: stats.done,
                        total: stats.total,
                        weekComparison: stats.weekComparisonLabel,
                        onTap: () => onFamilyProgressTapped(
                          context: context,
                          ref: ref,
                          totalCount: stats.total,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: () => shareFamilySummary(stats),
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: const Text('Share family summary'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.section),
                DashboardSection(
                  title: 'Member activity',
                  subtitle:
                      'Open assigned · completed · created · Busy if open ≥ $kMemberOverloadThreshold',
                  child: MemberActivityList(
                    members: stats.memberActivities,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.section),
              DashboardSection(
                title: 'Last 7 days',
                subtitle: 'Created vs completed',
                child: WeeklyTrendChart(days: stats.last7Days),
              ),
              if (stats.overdueTasks.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.section),
                DashboardSection(
                  title: 'Overdue',
                  subtitle: 'Up to 5 soonest deadlines',
                  child: _OverdueList(
                    stats: stats,
                    isFamilyTab: _isFamily,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _OverdueList extends ConsumerWidget {
  const _OverdueList({
    required this.stats,
    required this.isFamilyTab,
  });

  final DashboardStats stats;
  final bool isFamilyTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final showSeeAll = stats.overdue > stats.overdueTasks.length;

    return DashboardCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < stats.overdueTasks.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: AppColors.onSurfaceMuted.withValues(alpha: 0.12),
              ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push(
                  AppRoutes.taskDetail(stats.overdueTasks[i].id),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 18,
                        color: AppColors.danger,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stats.overdueTasks[i].title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              stats.overdueTasks[i].deadline != null
                                  ? DateFormat('MMM d, HH:mm')
                                      .format(stats.overdueTasks[i].deadline!)
                                  : 'No deadline',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (showSeeAll) ...[
            Divider(
              height: 1,
              color: AppColors.onSurfaceMuted.withValues(alpha: 0.12),
            ),
            TextButton(
              onPressed: () => onOverviewMetricTapped(
                context: context,
                ref: ref,
                metric: OverviewMetric.overdue,
                count: stats.overdue,
                isFamilyTab: isFamilyTab,
              ),
              child: Text('See all ${stats.overdue} overdue'),
            ),
          ],
        ],
      ),
    );
  }
}
