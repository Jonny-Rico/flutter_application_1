import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/dashboard/presentation/widgets/dashboard_section.dart';
import 'package:flutter/material.dart';

class CompletionCard extends StatelessWidget {
  const CompletionCard({
    super.key,
    required this.rate,
    required this.done,
    required this.total,
    this.title = 'Completion rate',
    this.weekComparison,
    this.onTap,
  });

  final double rate;
  final int done;
  final int total;
  final String title;
  final String? weekComparison;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (rate * 100).round();

    final content = Row(
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: rate.clamp(0.0, 1.0),
                strokeWidth: 7,
                backgroundColor: AppColors.surfaceElevated,
                color: theme.colorScheme.primary,
                strokeCap: StrokeCap.round,
              ),
              Center(
                child: Text(
                  '$percent%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$done of $total tasks done',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
              ),
              if (weekComparison != null) ...[
                const SizedBox(height: 6),
                Text(
                  weekComparison!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onTap != null)
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.onSurfaceMuted,
          ),
      ],
    );

    return DashboardCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: content,
          ),
        ),
      ),
    );
  }
}
