import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/shop/domain/trip_item.dart';
import 'package:family_tasks/features/shop/presentation/utils/shop_labels.dart';
import 'package:flutter/material.dart';

class TripItemRow extends StatelessWidget {
  const TripItemRow({
    super.key,
    required this.item,
    required this.onToggle,
    this.readOnly = false,
  });

  final TripItem item;
  final VoidCallback? onToggle;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qty = quantityLabel(item.quantity);
    final title = qty.isEmpty ? item.title : '${item.title} $qty';
    final meta = item.aisle?.trim().isNotEmpty == true
        ? item.aisle!
        : item.category.label.toLowerCase();

    return InkWell(
      onTap: readOnly ? null : onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            Icon(
              item.bought
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 28,
              color: item.bought ? AppColors.success : AppColors.onSurfaceMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: item.bought ? AppColors.onSurfaceMuted : null,
                  decoration: item.bought ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (item.addedDuringTrip)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.seed.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'NEW',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.seed,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            else
              Text(
                meta,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
