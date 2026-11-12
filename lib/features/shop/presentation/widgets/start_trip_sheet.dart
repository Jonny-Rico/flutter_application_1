import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/shop/domain/need_item.dart';
import 'package:family_tasks/features/shop/domain/shop_stores.dart';
import 'package:flutter/material.dart';

class StartTripResult {
  const StartTripResult({
    required this.storeName,
    required this.selectedIds,
  });

  final String storeName;
  final Set<String> selectedIds;
}

Future<StartTripResult?> showStartTripSheet(
  BuildContext context, {
  required List<NeedItem> needItems,
}) {
  return showModalBottomSheet<StartTripResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _StartTripSheet(needItems: needItems),
  );
}

class _StartTripSheet extends StatefulWidget {
  const _StartTripSheet({required this.needItems});

  final List<NeedItem> needItems;

  @override
  State<_StartTripSheet> createState() => _StartTripSheetState();
}

class _StartTripSheetState extends State<_StartTripSheet> {
  String _store = ShopStores.presets.first;
  final _otherController = TextEditingController();
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {
      for (final item in widget.needItems)
        if (!item.bought) item.id,
    };
  }

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final open = widget.needItems.where((item) => !item.bought).toList();
    final storeName =
        _store == 'Other' ? _otherController.text.trim() : _store;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: open.isEmpty ? 0.42 : 0.72,
      maxChildSize: 0.92,
      builder: (context, controller) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: ListView(
            controller: controller,
            children: [
              Text(
                'Start a trip',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final store in ShopStores.presets)
                    ChoiceChip(
                      label: Text(store),
                      selected: _store == store,
                      selectedColor: AppColors.accentWarm.withValues(alpha: 0.2),
                      onSelected: (_) => setState(() => _store = store),
                    ),
                ],
              ),
              if (_store == 'Other') ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _otherController,
                  decoration: const InputDecoration(hintText: 'Store name'),
                  onChanged: (_) => setState(() {}),
                ),
              ],
              if (open.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  'PULL FROM NEED',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceMuted,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                for (final item in open)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: _selected.contains(item.id),
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selected.add(item.id);
                        } else {
                          _selected.remove(item.id);
                        }
                      });
                    },
                  ),
              ],
              const SizedBox(height: 12),
              FilledButton(
                onPressed: storeName.isEmpty
                    ? null
                    : () => Navigator.pop(
                          context,
                          StartTripResult(
                            storeName: storeName,
                            selectedIds: _selected,
                          ),
                        ),
                child: Text('Create trip · ${_selected.length} items'),
              ),
            ],
          ),
        );
      },
    );
  }
}
