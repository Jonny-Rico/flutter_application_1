import 'package:family_tasks/core/haptics/app_haptics.dart';
import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/family/presentation/providers/family_providers.dart';
import 'package:family_tasks/features/shop/presentation/providers/shop_providers.dart';
import 'package:family_tasks/features/shop/presentation/utils/shop_labels.dart';
import 'package:family_tasks/features/shop/presentation/widgets/add_need_sheet.dart';
import 'package:family_tasks/features/shop/presentation/widgets/trip_item_row.dart';
import 'package:family_tasks/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ShopTripScreen extends ConsumerWidget {
  const ShopTripScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(shopTripByIdProvider(tripId));
    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip')),
        body: const EmptyState(
          icon: Icons.shopping_cart_outlined,
          title: 'Trip not found',
          subtitle: 'It may have been removed.',
          compact: true,
        ),
      );
    }

    final members = ref.watch(groupMembersProvider).valueOrNull ?? [];
    final me = ref.watch(authStateProvider).valueOrNull?.uid;
    final myName = ref.watch(userProfileProvider).valueOrNull?.displayName;
    final shopper = memberDisplayName(
      userId: trip.createdBy,
      members: members,
      currentUserId: me,
      currentUserName: myName,
    );
    final progress = trip.items.isEmpty
        ? 0.0
        : trip.boughtCount / trip.items.length;
    final readOnly = !trip.isActive;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          readOnly ? '${trip.storeName} · history' : trip.storeName,
        ),
        actions: [
          if (trip.isActive)
            TextButton(
              onPressed: () => _endTrip(context, ref),
              child: const Text('End'),
            ),
          if (trip.isActive)
            IconButton(
              tooltip: 'Add item',
              onPressed: () => _addItem(context, ref),
              icon: const Icon(Icons.add_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                if (trip.isActive)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentWarm.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.accentWarm.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 10,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$shopper is shopping · ${trip.boughtCount} of ${trip.items.length} bought',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: AppColors.accentWarm,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (trip.items.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      color: AppColors.accentWarm,
                      backgroundColor: AppColors.surfaceElevated,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: trip.items.isEmpty
                ? EmptyState(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Empty trip',
                    subtitle: readOnly
                        ? 'Nothing was added.'
                        : 'Add things as you walk the aisles.',
                    compact: true,
                    action: trip.isActive
                        ? FilledButton(
                            onPressed: () => _addItem(context, ref),
                            child: const Text('Add item'),
                          )
                        : null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
                    itemCount: trip.items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = trip.items[index];
                      return TripItemRow(
                        item: item,
                        readOnly: readOnly,
                        onToggle: readOnly
                            ? null
                            : () => _toggle(ref, item.id, !item.bought),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: trip.isActive
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentWarm,
                    foregroundColor: const Color(0xFF1A1403),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () => _completeTrip(context, ref),
                  child: const Text('Complete trip'),
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _toggle(WidgetRef ref, String itemId, bool bought) async {
    final scope = ref.read(taskScopeProvider);
    if (scope == null) return;
    await AppHaptics.light();
    await ref.read(shopRepositoryProvider).toggleTripItemBought(
          userId: scope.userId,
          groupId: scope.groupId,
          tripId: tripId,
          itemId: itemId,
          bought: bought,
        );
  }

  Future<void> _addItem(BuildContext context, WidgetRef ref) async {
    final result = await showAddNeedSheet(context, titleText: 'Add to this trip');
    if (result == null || !context.mounted) return;
    final scope = ref.read(taskScopeProvider);
    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    if (scope == null || userId == null) return;
    await ref.read(shopRepositoryProvider).addItemToActiveTrip(
          userId: scope.userId,
          groupId: scope.groupId,
          createdBy: userId,
          tripId: tripId,
          title: result.title,
          quantity: result.quantity,
          category: result.category,
        );
  }

  Future<void> _completeTrip(BuildContext context, WidgetRef ref) async {
    final scope = ref.read(taskScopeProvider);
    if (scope == null) return;
    await AppHaptics.medium();
    await ref.read(shopRepositoryProvider).completeTrip(
          userId: scope.userId,
          groupId: scope.groupId,
          tripId: tripId,
        );
    if (!context.mounted) return;
    context.pop();
  }

  Future<void> _endTrip(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End trip?'),
        content: const Text(
          'Need will not change. Checked items stay only in history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final scope = ref.read(taskScopeProvider);
    if (scope == null) return;
    await ref.read(shopRepositoryProvider).endTrip(
          userId: scope.userId,
          groupId: scope.groupId,
          tripId: tripId,
        );
    if (!context.mounted) return;
    context.pop();
  }
}
