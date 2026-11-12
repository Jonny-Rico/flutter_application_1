import 'package:family_tasks/core/router/routes.dart';
import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/family/presentation/providers/family_providers.dart';
import 'package:family_tasks/features/shop/domain/need_item.dart';
import 'package:family_tasks/features/shop/domain/shop_trip.dart';
import 'package:family_tasks/features/shop/presentation/providers/shop_providers.dart';
import 'package:family_tasks/features/shop/presentation/utils/shop_labels.dart';
import 'package:family_tasks/shared/widgets/root_app_bar.dart';
import 'package:family_tasks/features/shop/presentation/widgets/add_need_sheet.dart';
import 'package:family_tasks/features/shop/presentation/widgets/add_plan_sheet.dart';
import 'package:family_tasks/features/shop/presentation/widgets/start_trip_sheet.dart';
import 'package:family_tasks/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ShopHubScreen extends ConsumerWidget {
  const ShopHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needAsync = ref.watch(needItemsProvider);
    final tripsAsync = ref.watch(shopTripsProvider);

    return Scaffold(
      appBar: const RootAppBar(title: 'Shop'),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('shop-fab'),
        tooltip: 'Add',
        onPressed: () => _onFab(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
      body: needAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Could not load lists',
          subtitle: error.toString(),
          compact: true,
        ),
        data: (needItems) {
          if (tripsAsync.hasError) {
            return EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Could not load lists',
              subtitle: tripsAsync.error.toString(),
              compact: true,
            );
          }
          final active = ref.watch(activeTripProvider);
          final recent = ref.watch(recentTripsProvider);
          final plans = ref.watch(planItemsProvider).valueOrNull ?? const [];
          final personal =
              ref.watch(personalItemsProvider).valueOrNull ?? const [];
          final toBuy = needItems.where((item) => !item.bought).length;
          final planned = plans.where((item) => !item.bought).length;
          final personalOpen = personal.where((item) => !item.bought).length;
          final members = ref.watch(groupMembersProvider).valueOrNull ?? [];
          final me = ref.watch(authStateProvider).valueOrNull?.uid;
          final myName =
              ref.watch(userProfileProvider).valueOrNull?.displayName;

          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 96),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _HubCard(
                      key: const ValueKey('shop-card-need'),
                      kicker: 'Need',
                      kickerColor: AppColors.seed,
                      value: '$toBuy',
                      subtitle: needPreview(needItems),
                      footer: 'Open list →',
                      onTap: () => context.push(AppRoutes.shopNeed),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HubCard(
                      key: const ValueKey('shop-card-trip'),
                      kicker: 'This trip',
                      kickerColor: AppColors.accentWarm,
                      value: active == null ? '—' : '${active.items.length}',
                      subtitle: active == null
                          ? 'No trip yet'
                          : '${active.storeName} · ${active.boughtCount}/${active.items.length}',
                      liveLabel: active == null
                          ? null
                          : '${memberDisplayName(userId: active.createdBy, members: members, currentUserId: me, currentUserName: myName)} is shopping',
                      footer: active == null ? 'Start trip →' : 'Open trip →',
                      onTap: () {
                        if (active != null) {
                          context.push(AppRoutes.shopTrip(active.id));
                        } else {
                          _startTrip(context, ref, needItems);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _HubCard(
                      key: const ValueKey('shop-card-plans'),
                      kicker: 'Plans',
                      kickerColor: AppColors.accentPlan,
                      value: '$planned',
                      subtitle: planPreview(plans),
                      footer: 'Open list →',
                      onTap: () => context.push(AppRoutes.shopPlans),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HubCard(
                      key: const ValueKey('shop-card-personal'),
                      kicker: 'Personal',
                      kickerColor: AppColors.accentMine,
                      value: '$personalOpen',
                      subtitle: personal.isEmpty
                          ? 'Just you — not the family'
                          : planPreview(personal),
                      footer: 'Open list →',
                      onTap: () => context.push(AppRoutes.shopPersonal),
                    ),
                  ),
                ],
              ),
              if (recent.isNotEmpty) ...[
                const SizedBox(height: 22),
                Text(
                  'RECENT TRIPS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceMuted,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                      ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      for (var i = 0; i < recent.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _RecentTripTile(trip: recent[i]),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _onFab(BuildContext context, WidgetRef ref) async {
    final active = ref.read(activeTripProvider);
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0x295EEAD4),
                  child: Icon(Icons.add_rounded, color: AppColors.seed),
                ),
                title: const Text('Add to Need'),
                subtitle: const Text('Stays until someone buys it'),
                onTap: () => Navigator.pop(context, 'need'),
              ),
              ListTile(
                key: const ValueKey('fab-personal'),
                leading: const CircleAvatar(
                  backgroundColor: Color(0x297DD3FC),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.accentMine,
                  ),
                ),
                title: const Text('Add to Personal'),
                subtitle: const Text('Just you — family cannot see it'),
                onTap: () => Navigator.pop(context, 'personal'),
              ),
              ListTile(
                key: const ValueKey('fab-plans'),
                leading: const CircleAvatar(
                  backgroundColor: Color(0x29C4B5FD),
                  child: Icon(
                    Icons.weekend_outlined,
                    color: AppColors.accentPlan,
                  ),
                ),
                title: const Text('Add to Plans'),
                subtitle: const Text('Bigger buys, later — not this trip'),
                onTap: () => Navigator.pop(context, 'plans'),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0x29FBBF24),
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    color: AppColors.accentWarm,
                  ),
                ),
                title: Text(active == null ? 'Start a trip' : 'Open trip'),
                subtitle: Text(
                  active == null
                      ? 'New list for this store run'
                      : '${active.storeName} is in progress',
                ),
                onTap: () => Navigator.pop(context, 'trip'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (!context.mounted || choice == null) return;

    if (choice == 'need') {
      await _addNeed(context, ref);
      return;
    }
    if (choice == 'personal') {
      await _addPersonal(context, ref);
      return;
    }
    if (choice == 'plans') {
      await _addPlan(context, ref);
      return;
    }
    if (active != null) {
      context.push(AppRoutes.shopTrip(active.id));
      return;
    }
    final need = ref.read(needItemsProvider).valueOrNull ?? const [];
    await _startTrip(context, ref, need);
  }

  Future<void> _addNeed(BuildContext context, WidgetRef ref) async {
    final result = await showAddNeedSheet(context);
    if (result == null || !context.mounted) return;
    final scope = ref.read(taskScopeProvider);
    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    if (scope == null || userId == null) return;
    await ref.read(shopRepositoryProvider).createNeedItem(
          userId: scope.userId,
          groupId: scope.groupId,
          createdBy: userId,
          title: result.title,
          quantity: result.quantity,
          category: result.category,
          isStaple: result.isStaple,
        );
  }

  Future<void> _addPersonal(BuildContext context, WidgetRef ref) async {
    final result = await showAddPlanSheet(
      context,
      titleText: 'Add to Personal',
      hintText: 'Headphones, a book, snacks…',
    );
    if (result == null || !context.mounted) return;
    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    if (userId == null) return;
    try {
      await ref.read(shopRepositoryProvider).createPersonalItem(
            userId: userId,
            createdBy: userId,
            title: result.title,
            quantity: result.quantity,
            note: result.note,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added to Personal: ${result.title}'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$error'),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _addPlan(BuildContext context, WidgetRef ref) async {
    final result = await showAddPlanSheet(context);
    if (result == null || !context.mounted) return;
    final scope = ref.read(taskScopeProvider);
    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    if (scope == null || userId == null) return;
    await ref.read(shopRepositoryProvider).createPlanItem(
          userId: scope.userId,
          groupId: scope.groupId,
          createdBy: userId,
          title: result.title,
          quantity: result.quantity,
          note: result.note,
        );
  }

  Future<void> _startTrip(
    BuildContext context,
    WidgetRef ref,
    List<NeedItem> needItems,
  ) async {
    final result = await showStartTripSheet(context, needItems: needItems);
    if (result == null || !context.mounted) return;
    final scope = ref.read(taskScopeProvider);
    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    if (scope == null || userId == null) return;
    final selected = needItems
        .where((item) => result.selectedIds.contains(item.id))
        .toList();
    final trip = await ref.read(shopRepositoryProvider).startTrip(
          userId: scope.userId,
          groupId: scope.groupId,
          createdBy: userId,
          storeName: result.storeName,
          selectedNeedItems: selected,
        );
    if (!context.mounted) return;
    context.push(AppRoutes.shopTrip(trip.id));
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    super.key,
    required this.kicker,
    required this.kickerColor,
    required this.value,
    required this.subtitle,
    required this.footer,
    required this.onTap,
    this.liveLabel,
  });

  final String kicker;
  final Color kickerColor;
  final String value;
  final String subtitle;
  final String footer;
  final String? liveLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: 168,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border(left: BorderSide(color: kickerColor, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kicker.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: kickerColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
              ),
              if (liveLabel != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        liveLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const Spacer(),
              Text(
                footer,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentTripTile extends StatelessWidget {
  const _RecentTripTile({required this.trip});

  final ShopTrip trip;

  @override
  Widget build(BuildContext context) {
    final when = DateFormat('d MMM').format(trip.completedAt ?? trip.createdAt);
    final score = '${trip.boughtCount}/${trip.items.length}';
    final complete = trip.boughtCount == trip.items.length && trip.items.isNotEmpty;

    return ListTile(
      title: Text(
        when,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(trip.storeName),
      trailing: Text(
        score,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: complete ? AppColors.success : AppColors.accentWarm,
        ),
      ),
      onTap: () => context.push(AppRoutes.shopTrip(trip.id)),
    );
  }
}
