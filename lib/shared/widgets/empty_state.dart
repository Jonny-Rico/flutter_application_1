import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconSize = compact ? 56.0 : 88.0;
    final iconInner = compact ? 28.0 : 40.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 24 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(compact ? 16 : 28),
                border: compact
                    ? Border.all(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.2),
                      )
                    : null,
              ),
              child: Icon(
                icon,
                size: iconInner,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: compact ? 12 : 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: (compact
                      ? theme.textTheme.titleMedium
                      : theme.textTheme.titleLarge)
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceMuted,
                fontSize: compact ? 13.5 : null,
              ),
            ),
            if (action != null) ...[
              SizedBox(height: compact ? 16 : 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
