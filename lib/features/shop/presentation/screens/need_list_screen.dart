import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/family/domain/group_member.dart';
import 'package:family_tasks/features/family/presentation/providers/family_providers.dart';
import 'package:family_tasks/features/shop/domain/need_item.dart';
import 'package:family_tasks/features/shop/domain/shop_category.dart';
import 'package:family_tasks/features/shop/presentation/providers/shop_providers.dart';
import 'package:family_tasks/features/shop/presentation/utils/shop_actions.dart';
import 'package:family_tasks/features/shop/presentation/utils/shop_labels.dart';
import 'package:family_tasks/features/shop/presentation/widgets/add_need_sheet.dart';
import 'package:family_tasks/features/shop/presentation/widgets/need_item_row.dart';
import 'package:family_tasks/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NeedListScreen extends ConsumerStatefulWidget {
  const NeedListScreen({super.key});

  @override
  ConsumerState<NeedListScreen> createState() => _NeedListScreenState();
}

class _NeedListScreenState extends ConsumerState<NeedListScreen> {
  final _searchController = TextEditingController();
  bool _searchOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(needItemsProvider).valueOrNull ?? const [];
    final query = ref.watch(needSearchQueryProvider).trim().toLowerCase();
    final members = ref.watch(groupMembersProvider).valueOrNull ?? [];
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final hasGroup = profile?.hasGroup ?? false;
    final me = ref.watch(authStateProvider).valueOrNull?.uid;
    final filtered = query.isEmpty
        ? items
        : items
            .where((item) => item.title.toLowerCase().contains(query))
            .toList();
    final toBuy = items.where((item) => !item.bought).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Need'),
        actions: [
          IconButton(
            tooltip: _searchOpen ? 'Close search' : 'Search',
            onPressed: () {
              if (_searchOpen) {
                _searchController.clear();
                ref.read(needSearchQueryProvider.notifier).state = '';
              }
              setState(() => _searchOpen = !_searchOpen);
            },
            icon: Icon(
              _searchOpen ? Icons.close_rounded : Icons.search_rounded,
            ),
          ),
          if (items.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (value) {
                if (value == 'clear') _confirmClear(items);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'clear',
                  child: Text('Clear list'),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add to Need',
        onPressed: () => _addItem(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              '$toBuy to buy · ${hasGroup ? 'family list' : 'personal list'}',
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
                  ref.read(needSearchQueryProvider.notifier).state = value;
                },
                decoration: const InputDecoration(hintText: 'Search Need'),
              ),
            ),
          Expanded(
            child: filtered.isEmpty
                ? EmptyState(
                    icon: query.isNotEmpty
                        ? Icons.search_off_rounded
                        : Icons.shopping_bag_outlined,
                    title: query.isNotEmpty ? 'No matches' : 'Need is empty',
                    subtitle: query.isNotEmpty
                        ? 'Nothing matches “$query”.'
                        : 'Add milk, soap, and the rest. They stay here until bought.',
                    compact: true,
                    action: query.isEmpty
                        ? FilledButton(
                            onPressed: () => _addItem(context),
                            child: const Text('Add item'),
                          )
                        : null,
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                    children: [
                      for (final category in ShopCategory.values)
                        ..._section(
                          filtered,
                          category,
                          members,
                          me,
                          profile?.displayName,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _section(
    List<NeedItem> items,
    ShopCategory category,
    List<GroupMember> members,
    String? currentUserId,
    String? currentUserName,
  ) {
    final rows = items.where((item) => item.category == category).toList()
      ..sort((a, b) {
        if (a.bought != b.bought) return a.bought ? 1 : -1;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    if (rows.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 4),
        child: Text(
          category.label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceMuted,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
              ),
        ),
      ),
      for (final item in rows)
        NeedItemRow(
          item: item,
          addedByInitial: memberInitial(
            memberDisplayName(
              userId: item.createdBy,
              members: members,
              currentUserId: currentUserId,
              currentUserName: currentUserName,
            ),
          ),
          onToggle: () => toggleNeedBoughtWithUndo(ref: ref, item: item),
          onLongPress: () => _confirmDelete(item),
        ),
    ];
  }

  Future<void> _addItem(BuildContext context) async {
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

  Future<void> _confirmDelete(NeedItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove item?'),
        content: Text('Remove “${item.title}” from Need.'),
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
    await ref.read(shopRepositoryProvider).deleteNeedItem(
          userId: scope.userId,
          groupId: scope.groupId,
          itemId: item.id,
        );
  }

  Future<void> _confirmClear(List<NeedItem> items) async {
    final boughtCount = items.where((item) => item.bought).length;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear list?'),
        content: const Text(
          'Clear bought removes checked items. Clear all removes everything, including Regular. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: boughtCount == 0
                ? null
                : () => Navigator.pop(context, 'bought'),
            child: const Text('Clear bought'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context, 'all'),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    final scope = ref.read(taskScopeProvider);
    if (scope == null) return;
    await ref.read(shopRepositoryProvider).clearNeedItems(
          userId: scope.userId,
          groupId: scope.groupId,
          boughtOnly: result == 'bought',
        );
  }
}
