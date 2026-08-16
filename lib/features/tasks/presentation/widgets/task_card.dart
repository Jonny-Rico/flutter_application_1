import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/tasks/domain/task.dart';
import 'package:family_tasks/features/tasks/domain/task_status.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Dense list row optimized for fast scanning and one-tap done.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.onLongPress,
    this.onToggleDone,
    this.canToggleDone = false,
    this.assigneeLabel,
    this.assigneePhotoUrl,
    this.createdByLabel,
  });

  final Task task;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggleDone;
  final bool canToggleDone;
  final String? assigneeLabel;
  final String? assigneePhotoUrl;
  final String? createdByLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = task.status == TaskStatus.done;
    final isOverdue = task.isOverdue;

    final deadlineLabel = task.deadline != null
        ? DateFormat('MMM d').format(task.deadline!)
        : 'No date';

    final showAssigneeAvatar =
        !task.isGroupTask && (assigneeLabel != null || assigneePhotoUrl != null);
    final fromLabel = createdByLabel != null && createdByLabel!.trim().isNotEmpty
        ? 'By: ${createdByLabel!.trim()}'
        : null;

    return Material(
      color: isOverdue
          ? AppColors.danger.withValues(alpha: 0.06)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DoneCheckbox(
                isDone: isDone,
                enabled: canToggleDone,
                onTap: canToggleDone ? onToggleDone : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isDone
                        ? _StrikethroughTitle(
                            title: task.title,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurfaceMuted,
                            ),
                          )
                        : Text(
                            task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Left: priority + deadline (+ overdue) — fixed to start
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: task.priority.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          deadlineLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isOverdue
                                ? AppColors.danger
                                : AppColors.onSurfaceMuted,
                            fontWeight:
                                isOverdue ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        if (isOverdue) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Overdue',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                        // Right: By: + avatar/Family — fixed to end
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (fromLabel != null) ...[
                                Flexible(
                                  child: Text(
                                    fromLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.onSurfaceMuted,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                if (task.isGroupTask || showAssigneeAvatar)
                                  const SizedBox(width: 8),
                              ],
                              if (task.isGroupTask)
                                Text(
                                  'Family',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              else if (showAssigneeAvatar)
                                _AssigneeAvatar(
                                  label: assigneeLabel ?? '?',
                                  photoUrl: assigneePhotoUrl,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssigneeAvatar extends StatelessWidget {
  const _AssigneeAvatar({
    required this.label,
    this.photoUrl,
  });

  final String label;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmed = label.trim();
    final initial =
        trimmed.isNotEmpty ? trimmed.substring(0, 1).toUpperCase() : '?';

    return Tooltip(
      message: label,
      child: CircleAvatar(
        radius: 11,
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.18),
        backgroundImage:
            photoUrl != null && photoUrl!.isNotEmpty
                ? NetworkImage(photoUrl!)
                : null,
        child: photoUrl == null || photoUrl!.isEmpty
            ? Text(
                initial,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  color: theme.colorScheme.primary,
                ),
              )
            : null,
      ),
    );
  }
}

class _DoneCheckbox extends StatelessWidget {
  const _DoneCheckbox({
    required this.isDone,
    required this.enabled,
    this.onTap,
  });

  final bool isDone;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isDone
                  ? AppColors.success
                  : AppColors.onSurfaceMuted.withValues(alpha: 0.7),
              width: 2,
            ),
            color: isDone
                ? AppColors.success.withValues(alpha: 0.2)
                : Colors.transparent,
          ),
          child: isDone
              ? const Icon(
                  Icons.check_rounded,
                  size: 14,
                  color: AppColors.success,
                )
              : null,
        ),
      ),
    );
  }
}

class _StrikethroughTitle extends StatelessWidget {
  const _StrikethroughTitle({
    required this.title,
    required this.style,
  });

  final String title;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final textStyle = (style ?? const TextStyle()).copyWith(
      color: AppColors.onSurfaceMuted,
      decoration: TextDecoration.none,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: title, style: textStyle),
          maxLines: 1,
          textDirection: Directionality.of(context),
          ellipsis: '…',
        )..layout(maxWidth: constraints.maxWidth);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
            Positioned(
              left: 0,
              top: painter.height / 2,
              width: painter.width,
              child: const SizedBox(
                height: 1.5,
                child: ColoredBox(color: AppColors.onSurfaceMuted),
              ),
            ),
          ],
        );
      },
    );
  }
}
