import 'package:family_tasks/core/haptics/app_haptics.dart';
import 'package:family_tasks/core/router/routes.dart';
import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/family/presentation/providers/family_providers.dart';
import 'package:family_tasks/features/tasks/domain/task.dart';
import 'package:family_tasks/features/tasks/domain/task_status.dart';
import 'package:family_tasks/features/tasks/presentation/providers/task_providers.dart';
import 'package:family_tasks/features/tasks/presentation/utils/task_done_actions.dart';
import 'package:family_tasks/features/tasks/presentation/utils/task_filter_actions.dart';
import 'package:family_tasks/features/tasks/presentation/widgets/task_card.dart';
import 'package:family_tasks/shared/widgets/empty_state.dart';
import 'package:family_tasks/shared/widgets/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _allStatusesFilterValue = '__all_statuses__';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final _listScrollController = ScrollController();
  final _searchController = TextEditingController();
  bool _searchOpen = false;

  @override
  void dispose() {
    _listScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String? _memberName(WidgetRef ref, String? userId) {
    if (userId == null) return null;
    final members = ref.watch(groupMembersProvider).valueOrNull ?? [];
    for (final member in members) {
      if (member.userId == userId) {
        return member.displayName.isNotEmpty ? member.displayName : 'Member';
      }
    }
    return null;
  }

  String? _memberPhoto(WidgetRef ref, String? userId) {
    if (userId == null) return null;
    final members = ref.watch(groupMembersProvider).valueOrNull ?? [];
    for (final member in members) {
      if (member.userId == userId) return member.photoUrl;
    }
    return null;
  }

  void _closeSearch() {
    setState(() => _searchOpen = false);
    _searchController.clear();
    ref.read(taskSearchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(filteredTasksProvider);
    final allTasks = ref.watch(tasksProvider).valueOrNull ?? [];
    final viewFilter = ref.watch(taskViewFilterProvider);
    final statusFilter = ref.watch(taskStatusFilterProvider);
    final metricFilter = ref.watch(taskMetricFilterProvider);
    final searchQuery = ref.watch(taskSearchQueryProvider);
    final hasGroup =
        ref.watch(userProfileProvider).valueOrNull?.hasGroup ?? false;
    final currentUserId = ref.watch(authStateProvider).valueOrNull?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            tooltip: _searchOpen ? 'Close search' : 'Search',
            onPressed: () {
              if (_searchOpen) {
                _closeSearch();
              } else {
                setState(() => _searchOpen = true);
              }
            },
            icon: Icon(
              _searchOpen ? Icons.close_rounded : Icons.search_rounded,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Filter by status',
            onSelected: (value) {
              if (value == _allStatusesFilterValue) {
                onTasksStatusFilterSelected(ref, null);
              } else {
                onTasksStatusFilterSelected(
                  ref,
                  TaskStatus.fromValue(value),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _allStatusesFilterValue,
                child: _filterMenuLabel(
                  label: 'All statuses',
                  selected: statusFilter == null,
                ),
              ),
              ...TaskStatus.values.map(
                (status) => PopupMenuItem(
                  value: status.value,
                  child: _filterMenuLabel(
                    label: status.label,
                    selected: statusFilter == status,
                  ),
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Material(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.12),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.28),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        statusFilterLabel(
                          statusFilter,
                          metric: metricFilter,
                        ),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_searchOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search title or description',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          tooltip: 'Clear',
                          onPressed: () {
                            _searchController.clear();
                            ref.read(taskSearchQueryProvider.notifier).state =
                                '';
                          },
                          icon: const Icon(Icons.clear_rounded, size: 20),
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: (value) {
                  ref.read(taskSearchQueryProvider.notifier).state = value;
                },
              ),
            ),
          if (hasGroup)
            _ViewFilterBar(
              selected: viewFilter,
              counts: _viewFilterCounts(allTasks, currentUserId),
              onSelected: (filter) {
                onTasksViewFilterSelected(ref, filter);
              },
            ),
          Expanded(
            child: tasksAsync.when(
              loading: () => const TaskListSkeleton(),
              error: (error, _) => EmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'Could not load tasks',
                subtitle: error.toString(),
                compact: true,
                action: FilledButton(
                  onPressed: () => ref.invalidate(tasksProvider),
                  child: const Text('Retry'),
                ),
              ),
              data: (tasks) {
                if (tasks.isEmpty) {
                  final hasSearch = searchQuery.trim().isNotEmpty;
                  final hasAnyTasks = allTasks.isNotEmpty;
                  return EmptyState(
                    icon: hasSearch
                        ? Icons.search_off_rounded
                        : Icons.task_alt_rounded,
                    title: hasSearch ? 'No matches' : 'Nothing here',
                    subtitle: hasSearch
                        ? 'No tasks match “${searchQuery.trim()}”.'
                        : hasAnyTasks
                            ? _filteredEmptySubtitle(
                                viewFilter,
                                statusFilter,
                                totalCount: allTasks.length,
                              )
                            : _emptySubtitle(viewFilter, statusFilter),
                    compact: true,
                    action: hasSearch
                        ? TextButton(
                            onPressed: _closeSearch,
                            child: const Text('Clear search'),
                          )
                        : hasAnyTasks
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FilledButton(
                                    onPressed: () {
                                      resetTaskFilters(ref);
                                      _searchController.clear();
                                      setState(() => _searchOpen = false);
                                    },
                                    child: const Text('Reset filters'),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () =>
                                        context.push(AppRoutes.taskCreate),
                                    child: const Text('New task'),
                                  ),
                                ],
                              )
                            : FilledButton(
                                onPressed: () =>
                                    context.push(AppRoutes.taskCreate),
                                child: const Text('New task'),
                              ),
                  );
                }

                return Scrollbar(
                  controller: _listScrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  interactive: true,
                  child: RefreshIndicator(
                    onRefresh: () async => ref.invalidate(tasksProvider),
                    child: ListView.builder(
                      controller: _listScrollController,
                      primary: false,
                      padding: const EdgeInsets.fromLTRB(10, 4, 10, 96),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                      final task = tasks[index];
                      final canDelete = currentUserId != null &&
                          task.canDelete(currentUserId);
                      final canMarkDone = currentUserId != null &&
                          task.canChangeStatus(currentUserId);
                      final canEdit = currentUserId != null &&
                          task.canEditFields(currentUserId);
                      final dismissDirection = switch (
                        (canMarkDone, canDelete)
                      ) {
                        (true, true) => DismissDirection.horizontal,
                        (true, false) => DismissDirection.startToEnd,
                        (false, true) => DismissDirection.endToStart,
                        _ => DismissDirection.none,
                      };

                      return Dismissible(
                        key: ValueKey('${task.id}_${task.status.name}'),
                        direction: dismissDirection,
                        background: canMarkDone
                            ? Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.success
                                      .withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Colors.white,
                                ),
                              )
                            : const SizedBox.shrink(),
                        secondaryBackground: canDelete
                            ? Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.danger
                                      .withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.white,
                                ),
                              )
                            : const SizedBox.shrink(),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            return _markTaskDone(context, ref, task);
                          }
                          return _deleteTask(context, ref, task);
                        },
                        child: TaskCard(
                          task: task,
                          assigneeLabel: _memberName(ref, task.assigneeId),
                          assigneePhotoUrl:
                              _memberPhoto(ref, task.assigneeId),
                          createdByLabel: _memberName(ref, task.createdBy),
                          canToggleDone: canMarkDone,
                          onToggleDone: () => toggleTaskDoneWithUndo(
                            context: context,
                            ref: ref,
                            task: task,
                          ),
                          onTap: () =>
                              context.push(AppRoutes.taskDetail(task.id)),
                          onLongPress: () => _showTaskActions(
                            context: context,
                            ref: ref,
                            task: task,
                            canMarkDone: canMarkDone,
                            canEdit: canEdit,
                            canDelete: canDelete,
                          ),
                        ),
                      );
                    },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.taskCreate),
        tooltip: 'New task',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Map<TaskViewFilter, int> _viewFilterCounts(
    List<Task> tasks,
    String? userId,
  ) {
    var forMe = 0;
    var byMe = 0;
    var group = 0;
    for (final task in tasks) {
      if (task.isGroupTask) {
        group++;
      } else if (task.assigneeId == userId) {
        forMe++;
      }
      if (!task.isGroupTask &&
          task.createdBy == userId &&
          task.assigneeId != userId) {
        byMe++;
      }
    }
    return {
      TaskViewFilter.assignedToMe: forMe,
      TaskViewFilter.assignedByMe: byMe,
      TaskViewFilter.group: group,
      TaskViewFilter.all: tasks.length,
    };
  }

  Future<bool> _deleteTask(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final scope = ref.read(taskScopeProvider);
    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    if (scope == null || userId == null) return false;

    if (!task.canDelete(userId)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You do not have permission to delete this task.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return false;
    }

    final confirmed = await _confirmDelete(context);
    if (!confirmed || !context.mounted) return false;

    try {
      await AppHaptics.medium();
      await ref.read(taskRepositoryProvider).deleteTask(
            userId: scope.userId,
            groupId: scope.groupId,
            taskId: task.id,
            currentUserId: userId,
            task: task,
          );
      await ref.read(taskNotificationSchedulerProvider).cancelTask(task.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted')),
        );
      }
      return true;
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$error'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return false;
    }
  }

  Future<bool> _markTaskDone(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    if (task.status == TaskStatus.done) {
      return false;
    }
    await markTaskDoneWithUndo(context: context, ref: ref, task: task);
    return false;
  }

  Future<void> _showTaskActions({
    required BuildContext context,
    required WidgetRef ref,
    required Task task,
    required bool canMarkDone,
    required bool canEdit,
    required bool canDelete,
  }) async {
    final isDone = task.status == TaskStatus.done;
    final showMarkDone = canMarkDone && !isDone;
    final theme = Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (!canEdit)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Only the creator can edit this task.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (showMarkDone)
                ListTile(
                  leading: const Icon(Icons.check_circle_outline_rounded),
                  title: const Text('Mark done'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await markTaskDoneWithUndo(
                      context: context,
                      ref: ref,
                      task: task,
                    );
                  },
                ),
              if (canEdit)
                ListTile(
                  leading: const Icon(Icons.edit_rounded),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push(AppRoutes.taskEdit(task.id));
                  },
                ),
              if (canDelete)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.danger,
                  ),
                  title: const Text(
                    'Delete',
                    style: TextStyle(color: AppColors.danger),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _deleteTask(context, ref, task);
                  },
                ),
              if (!showMarkDone && !canEdit && !canDelete)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'No actions available for this task.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  String _emptySubtitle(
    TaskViewFilter viewFilter,
    TaskStatus? statusFilter,
  ) {
    if (statusFilter != null) {
      return 'No ${statusFilter.label.toLowerCase()} tasks. Create one or switch filters.';
    }
    return switch (viewFilter) {
      TaskViewFilter.all => 'Create a task to get started.',
      TaskViewFilter.assignedToMe =>
        'No tasks for you. Create one or switch filters.',
      TaskViewFilter.assignedByMe => 'You have not assigned tasks to others.',
      TaskViewFilter.group => 'No family tasks yet.',
    };
  }

  String _filteredEmptySubtitle(
    TaskViewFilter viewFilter,
    TaskStatus? statusFilter, {
    required int totalCount,
  }) {
    final viewLabel = switch (viewFilter) {
      TaskViewFilter.all => 'All',
      TaskViewFilter.assignedToMe => 'For me',
      TaskViewFilter.assignedByMe => 'By me',
      TaskViewFilter.group => 'Family',
    };
    final statusLabel = statusFilterLabel(statusFilter);
    return 'No tasks match $viewLabel · $statusLabel. '
        'You have $totalCount task${totalCount == 1 ? '' : 's'} total.';
  }

  Widget _filterMenuLabel({
    required String label,
    required bool selected,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: selected ? const Icon(Icons.check, size: 18) : null,
        ),
        Text(label),
      ],
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _ViewFilterBar extends StatelessWidget {
  const _ViewFilterBar({
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final TaskViewFilter selected;
  final Map<TaskViewFilter, int> counts;
  final ValueChanged<TaskViewFilter> onSelected;

  String _label(TaskViewFilter filter) => switch (filter) {
        TaskViewFilter.all => 'All',
        TaskViewFilter.assignedToMe => 'For me',
        TaskViewFilter.assignedByMe => 'By me',
        TaskViewFilter.group => 'Family',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filters = taskViewFilterDisplayOrder;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: Row(
        children: [
          for (var i = 0; i < filters.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: _ViewFilterPill(
                label: _label(filters[i]),
                count: counts[filters[i]] ?? 0,
                selected: selected == filters[i],
                onTap: () => onSelected(filters[i]),
                theme: theme,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ViewFilterPill extends StatelessWidget {
  const _ViewFilterPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;

    return Material(
      color: selected
          ? primary.withValues(alpha: 0.14)
          : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected
              ? primary.withValues(alpha: 0.35)
              : AppColors.onSurfaceMuted.withValues(alpha: 0.12),
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: selected ? primary : AppColors.onSurfaceMuted,
                  ),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 5),
                Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(999),
                    color: selected
                        ? primary.withValues(alpha: 0.22)
                        : AppColors.surfaceElevated,
                    border: Border.all(
                      color: selected
                          ? primary.withValues(alpha: 0.4)
                          : AppColors.onSurfaceMuted.withValues(alpha: 0.16),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      height: 1,
                      color: selected ? primary : AppColors.onSurfaceMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

