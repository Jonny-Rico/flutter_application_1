import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/shop/domain/plan_item.dart';
import 'package:family_tasks/features/shop/presentation/utils/shop_labels.dart';
import 'package:flutter/material.dart';

class PlanItemRow extends StatelessWidget {
  const PlanItemRow({
    super.key,
    required this.item,
    required this.onToggle,
    this.addedByInitial,
    this.onLongPress,
  });

  final PlanItem item;
  final VoidCallback onToggle;
  final String? addedByInitial;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qty = quantityLabel(item.quantity);
    final note = item.note?.trim();

    return InkWell(
      onTap: onToggle,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                item.bought
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color:
                    item.bought ? AppColors.success : AppColors.onSurfaceMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: item.bought ? AppColors.onSurfaceMuted : null,
                      decoration:
                          item.bought ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (note != null && note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        note,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (qty.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: Text(
                  qty,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (item.bought)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'bought',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else if (addedByInitial != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: CircleAvatar(
                  radius: 11,
                  backgroundColor: AppColors.surfaceElevated,
                  child: Text(
                    addedByInitial!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.accentPlan,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
