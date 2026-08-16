import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.items});

  final List<StatTileData> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _StatTile(data: item),
              ),
          ],
        );
      },
    );
  }
}

class StatTileData {
  const StatTileData({
    required this.label,
    required this.value,
    required this.icon,
    this.accent,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? accent;
  final VoidCallback? onTap;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.data});

  final StatTileData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = data.accent ?? theme.colorScheme.primary;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.value,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      data.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceMuted,
                        fontWeight: FontWeight.w600,
                      ),
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
