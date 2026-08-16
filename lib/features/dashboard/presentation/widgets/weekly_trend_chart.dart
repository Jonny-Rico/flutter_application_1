import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/dashboard/domain/dashboard_stats.dart';
import 'package:family_tasks/features/dashboard/presentation/widgets/dashboard_section.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeeklyTrendChart extends StatelessWidget {
  const WeeklyTrendChart({super.key, required this.days});

  final List<DayBucket> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxValue = days.fold<int>(
      1,
      (max, day) {
        final localMax = day.created > day.completed ? day.created : day.completed;
        return localMax > max ? localMax : max;
      },
    );

    return DashboardCard(
      child: Column(
        children: [
          Row(
            children: [
              _LegendDot(color: theme.colorScheme.primary, label: 'Created'),
              const SizedBox(width: 14),
              const _LegendDot(color: AppColors.success, label: 'Completed'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final day in days) ...[
                  Expanded(
                    child: _DayColumn(
                      day: day,
                      maxValue: maxValue,
                      theme: theme,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.onSurfaceMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.day,
    required this.maxValue,
    required this.theme,
  });

  final DayBucket day;
  final int maxValue;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final createdH = maxValue == 0 ? 0.0 : day.created / maxValue;
    final completedH = maxValue == 0 ? 0.0 : day.completed / maxValue;
    final label = DateFormat('E').format(day.day).substring(0, 1);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: day.created == 0
                        ? 0
                        : createdH.clamp(0.06, 1.0),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: day.completed == 0
                        ? 0
                        : completedH.clamp(0.06, 1.0),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.onSurfaceMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
