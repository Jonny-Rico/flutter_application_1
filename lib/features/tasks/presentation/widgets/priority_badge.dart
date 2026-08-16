import 'package:family_tasks/features/tasks/domain/task_priority.dart';
import 'package:flutter/material.dart';

class PriorityBadge extends StatelessWidget {
  const PriorityBadge({
    super.key,
    required this.priority,
    this.compact = false,
  });

  final TaskPriorityLevel priority;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: priority.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        priority.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: priority.color,
          fontWeight: FontWeight.w700,
          fontSize: compact ? 10 : null,
        ),
      ),
    );
  }
}