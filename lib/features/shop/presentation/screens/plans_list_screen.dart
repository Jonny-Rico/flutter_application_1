import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/family/presentation/providers/family_providers.dart';
import 'package:family_tasks/features/shop/domain/plan_item.dart';
import 'package:family_tasks/features/shop/presentation/providers/shop_providers.dart';
import 'package:family_tasks/features/shop/presentation/utils/shop_actions.dart';
import 'package:family_tasks/features/shop/presentation/utils/shop_labels.dart';
import 'package:family_tasks/features/shop/presentation/widgets/add_plan_sheet.dart';
import 'package:family_tasks/features/shop/presentation/widgets/plan_item_row.dart';
import 'package:family_tasks/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlansListScreen extends ConsumerStatefulWidget {
  const PlansListScreen({super.key});

  @override
  ConsumerState<PlansListScreen> createState() => _PlansListScreenState();
}

class _PlansListScreenState extends ConsumerState<PlansListScreen> {
  final _searchController = TextEditingController();
  bool _searchOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(planItemsProvider).valueOrNull ?? const [];
    final query = ref.watch(planSearchQueryProvider).trim().toLowerCase();
    final members = ref.watch(groupMembersProvider).valueOrNull ?? [];
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final hasGroup = profile?.hasGroup ?? false;
    final me = ref.watch(authStateProvider).valueOrNull?.uid;
    final filtered = query.isEmpty
        ? items
        : items
            .where(
              (item) =>
                  item.title.toLowerCase().contains(query) ||
                  (item.note?.toLowerCase().contains(query) ?? false),
            )
            .toList();
    final open = items.where((item) => !item.bought).length;
    final rows = List<PlanItem>.from(filtered)
      ..sort((a, b) {
        if (a.bought != b.bought) return a.bought ? 1 : -1;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plans'),
        actions: [
          IconButton(
            tooltip: _searchOpen ? 'Close search' : 'Search',
            onPressed: () {
              if (_searchOpen) {
                _searchController.clear();
                ref.read(planSearchQueryProvider.notifier).state = '';
              }
              setState(() => _searchOpen = !_searchOpen);
            },
            icon: Icon(
              _searchOpen ? Icons.close_rounded : Icons.search_rounded,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add to Plans',
        onPressed: () => _addItem(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              '$open planned · ${hasGroup ? 'family list' : 'personal list'}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          if (_searchOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (value) {
                  ref.read(planSearchQueryProvider.notifier).state = value;
                },
                decoration: const InputDecoration(hintText: 'Search Plans'),
              ),
            ),
          Expanded(
            child: rows.isEmpty
                ? EmptyState(
                    icon: query.isNotEmpty
                        ? Icons.search_off_rounded
                        : Icons.weekend_outlined,
                    title: query.isNotEmpty ? 'No matches' : 'Nothing planned',
                    subtitle: query.isNotEmpty
                        ? 'Nothing matches “$query”.'
                        : 'Sofa, TV, a new table — things you buy later, not this week.',
                    compact: true,
                    action: query.isEmpty
                        ? FilledButton(
                            onPressed: () => _addItem(context),
                            child: const Text('Add plan'),
                          )
                        : null,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final item = rows[index];
                      return PlanItemRow(
                        item: item,
                        addedByInitial: memberInitial(
                          memberDisplayName(
                            userId: item.createdBy,
                            members: members,
                            currentUserId: me,
                            currentUserName: profile?.displayName,
                          ),
                        ),
                        onToggle: () =>
                            togglePlanBoughtWithUndo(ref: ref, item: item),
                        onLongPress: () => _confirmDelete(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _addItem(BuildContext context) async {
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

  Future<void> _confirmDelete(PlanItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove plan?'),
        content: Text('Remove “${item.title}” from Plans.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final scope = ref.read(taskScopeProvider);
    if (scope == null) return;
    await ref.read(shopRepositoryProvider).deletePlanItem(
          userId: scope.userId,
          groupId: scope.groupId,
          itemId: item.id,
        );
  }
}
