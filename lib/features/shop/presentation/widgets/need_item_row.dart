import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/shop/domain/need_item.dart';
import 'package:family_tasks/features/shop/presentation/utils/shop_labels.dart';
import 'package:flutter/material.dart';

class NeedItemRow extends StatelessWidget {
  const NeedItemRow({
    super.key,
    required this.item,
    required this.onToggle,
    this.addedByInitial,
    this.onLongPress,
  });

  final NeedItem item;
  final VoidCallback onToggle;
  final String? addedByInitial;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qty = quantityLabel(item.quantity);

    return InkWell(
      onTap: onToggle,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Icon(
              item.bought
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: item.bought ? AppColors.success : AppColors.onSurfaceMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: item.bought ? AppColors.onSurfaceMuted : null,
                  decoration: item.bought ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (item.isStaple)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.seed.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'REGULAR',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.seed,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              )
            else if (qty.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  qty,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (item.bought)
              Text(
                'bought',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceMuted,
                  fontWeight: FontWeight.w600,
                ),
              )
            else if (addedByInitial != null)
              CircleAvatar(
                radius: 11,
                backgroundColor: AppColors.surfaceElevated,
                child: Text(
                  addedByInitial!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.seed,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
