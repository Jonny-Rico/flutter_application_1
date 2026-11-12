import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/shop/domain/plan_item.dart';
import 'package:family_tasks/features/shop/presentation/providers/shop_providers.dart';
import 'package:family_tasks/features/shop/presentation/utils/shop_actions.dart';
import 'package:family_tasks/features/shop/presentation/widgets/add_plan_sheet.dart';
import 'package:family_tasks/features/shop/presentation/widgets/plan_item_row.dart';
import 'package:family_tasks/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PersonalListScreen extends ConsumerStatefulWidget {
  const PersonalListScreen({super.key});

  @override
  ConsumerState<PersonalListScreen> createState() => _PersonalListScreenState();
}

class _PersonalListScreenState extends ConsumerState<PersonalListScreen> {
  final _searchController = TextEditingController();
  bool _searchOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(personalItemsProvider).valueOrNull ?? const [];
    final query = ref.watch(personalSearchQueryProvider).trim().toLowerCase();
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
        title: const Text('Personal'),
        actions: [
          IconButton(
            tooltip: _searchOpen ? 'Close search' : 'Search',
            onPressed: () {
              if (_searchOpen) {
                _searchController.clear();
                ref.read(personalSearchQueryProvider.notifier).state = '';
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
        tooltip: 'Add to Personal',
        onPressed: () => _addItem(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              '$open to buy · just you',
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
                  ref.read(personalSearchQueryProvider.notifier).state = value;
                },
                decoration: const InputDecoration(hintText: 'Search Personal'),
              ),
            ),
          Expanded(
            child: rows.isEmpty
                ? EmptyState(
                    icon: query.isNotEmpty
                        ? Icons.search_off_rounded
                        : Icons.person_outline_rounded,
                    title: query.isNotEmpty ? 'No matches' : 'Your list is empty',
                    subtitle: query.isNotEmpty
                        ? 'Nothing matches “$query”.'
                        : 'A private shopping list. The family cannot see it.',
                    compact: true,
                    action: query.isEmpty
                        ? FilledButton(
                            onPressed: () => _addItem(context),
                            child: const Text('Add item'),
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
                        onToggle: () =>
                            togglePersonalBoughtWithUndo(ref: ref, item: item),
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

  Future<void> _confirmDelete(PlanItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove item?'),
        content: Text('Remove “${item.title}” from Personal.'),
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
    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    if (userId == null) return;
    await ref.read(shopRepositoryProvider).deletePersonalItem(
          userId: userId,
          itemId: item.id,
        );
  }
}
