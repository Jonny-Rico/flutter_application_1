import 'package:family_tasks/core/router/routes.dart';
import 'package:family_tasks/core/haptics/app_haptics.dart';
import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/family/presentation/providers/family_providers.dart';
import 'package:family_tasks/features/tasks/domain/task_status.dart';
import 'package:family_tasks/features/tasks/presentation/providers/task_providers.dart';
import 'package:family_tasks/features/tasks/presentation/utils/task_done_actions.dart';
import 'package:family_tasks/features/tasks/presentation/widgets/priority_badge.dart';
import 'package:family_tasks/features/tasks/presentation/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  String? _memberName(WidgetRef ref, String? userId) {
    if (userId == null) return null;
    final members = ref.watch(groupMembersProvider).valueOrNull ?? [];
    for (final member in members) {
      if (member.userId == userId) {
        return member.displayName.isNotEmpty ? member.displayName : 'Member';
      }
    }
    return 'Member';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskAsync = ref.watch(taskByIdProvider(taskId));
    final userId = ref.watch(authStateProvider).valueOrNull?.uid;

    return taskAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $error')),
      ),
      data: (task) {
        if (task == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Task not found')),
          );
        }

        final canEdit = userId != null && task.canEditFields(userId);
        final canDelete = userId != null && task.canDelete(userId);
        final canChangeStatus =
            userId != null && task.canChangeStatus(userId);

        final deadlineLabel = task.deadline != null
            ? DateFormat('EEEE, MMM d, yyyy • HH:mm').format(task.deadline!)
            : 'No deadline';
        final reminderLabel = task.reminderAt != null
            ? DateFormat('EEEE, MMM d, yyyy • HH:mm').format(task.reminderAt!)
            : 'No reminder';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Task details'),
            actions: [
              if (canEdit)
                IconButton(
                  onPressed: () => context.push(AppRoutes.taskEdit(task.id)),
                  icon: const Icon(Icons.edit_rounded),
                ),
              if (canDelete)
                IconButton(
                  onPressed: () => _deleteTask(context, ref, task.id),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                task.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusBadge(status: task.status),
                  PriorityBadge(priority: task.priority),
                  if (task.isGroupTask)
                    Chip(label: Text(task.completedBy != null
                        ? 'Completed by ${_memberName(ref, task.completedBy)}'
                        : 'Family task')),
                ],
              ),
              if (userId != null &&
                  !canEdit &&
                  task.createdBy != userId) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Only the creator can edit this task. You can still update the status if allowed.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _DetailRow(
                icon: Icons.schedule_rounded,
                label: 'Deadline',
                value: deadlineLabel,
                valueColor: task.isOverdue ? AppColors.danger : null,
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.notifications_active_outlined,
                label: 'Reminder',
                value: reminderLabel,
              ),
              if (task.recurrence.isRepeating) ...[
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.repeat_rounded,
                  label: 'Repeat',
                  value: task.recurrence.detailLabel,
                ),
              ],
              if (!task.isGroupTask) ...[
                const SizedBox(height: 12),
                _DetailRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Assigned to',
                  value: _memberName(ref, task.assigneeId) ?? 'Unknown',
                ),
              ],
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.person_add_alt_1_outlined,
                label: 'Created by',
                value: _memberName(ref, task.createdBy) ?? 'Unknown',
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.notes_rounded,
                label: 'Description',
                value: task.description.isEmpty
                    ? 'No description'
                    : task.description,
              ),
              if (canChangeStatus) ...[
                const SizedBox(height: 24),
                Text(
                  'Quick status',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<TaskStatus>(
                  segments: TaskStatus.values
                      .map(
                        (status) => ButtonSegment(
                          value: status,
                          label: Text(status.label),
                          icon: Icon(status.icon, size: 18),
                        ),
                      )
                      .toList(),
                  selected: {task.status},
                  onSelectionChanged: (selection) async {
                    final scope = ref.read(taskScopeProvider);
                    if (scope == null) return;
                    final newStatus = selection.first;
                    if (newStatus == task.status) return;

                    if (newStatus == TaskStatus.done) {
                      await markTaskDoneWithUndo(
                        context: context,
                        ref: ref,
                        task: task,
                      );
                      return;
                    }

                    try {
                      await ref.read(taskRepositoryProvider).updateTaskStatus(
                            userId: scope.userId,
                            groupId: scope.groupId,
                            taskId: task.id,
                            newStatus: newStatus,
                            currentUserId: userId,
                            task: task,
                          );
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$error'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteTask(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
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
    if (confirmed != true || !context.mounted) return;

    final scope = ref.read(taskScopeProvider);
    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    if (scope == null || userId == null) return;

    try {
      await AppHaptics.medium();
      await ref.read(taskRepositoryProvider).deleteTask(
            userId: scope.userId,
            groupId: scope.groupId,
            taskId: id,
            currentUserId: userId,
          );
      await ref.read(taskNotificationSchedulerProvider).cancelTask(id);
      if (context.mounted) context.pop();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$error'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.onSurfaceMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: valueColor,
                  fontWeight: valueColor != null ? FontWeight.w700 : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}