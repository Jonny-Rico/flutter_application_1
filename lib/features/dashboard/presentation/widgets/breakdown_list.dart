import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/dashboard/presentation/widgets/dashboard_section.dart';
import 'package:flutter/material.dart';

class BreakdownItem {
  const BreakdownItem({
    required this.label,
    required this.count,
    required this.color,
    this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final VoidCallback? onTap;
}

class BreakdownList extends StatelessWidget {
  const BreakdownList({
    super.key,
    required this.items,
    required this.total,
  });

  final List<BreakdownItem> items;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeTotal = total <= 0 ? 1 : total;

    return DashboardCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: AppColors.onSurfaceMuted.withValues(alpha: 0.1),
              ),
            _BreakdownRow(
              item: items[i],
              fraction: items[i].count / safeTotal,
              theme: theme,
            ),
          ],
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.item,
    required this.fraction,
    required this.theme,
  });

  final BreakdownItem item;
  final double fraction;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${item.count}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                  if (item.onTap != null) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.onSurfaceMuted,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: fraction.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceElevated,
                  color: item.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
