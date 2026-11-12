import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/shop/domain/shop_category.dart';
import 'package:flutter/material.dart';

class AddNeedResult {
  const AddNeedResult({
    required this.title,
    required this.quantity,
    required this.category,
    required this.isStaple,
  });

  final String title;
  final int quantity;
  final ShopCategory category;
  final bool isStaple;
}

Future<AddNeedResult?> showAddNeedSheet(
  BuildContext context, {
  String titleText = 'Add to Need',
}) {
  return showModalBottomSheet<AddNeedResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _AddNeedSheet(titleText: titleText),
  );
}

class _AddNeedSheet extends StatefulWidget {
  const _AddNeedSheet({required this.titleText});

  final String titleText;

  @override
  State<_AddNeedSheet> createState() => _AddNeedSheetState();
}

class _AddNeedSheetState extends State<_AddNeedSheet> {
  final _controller = TextEditingController();
  ShopCategory _category = ShopCategory.groceries;
  int _quantity = 1;
  bool _staple = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Enter a name');
      return;
    }
    Navigator.pop(
      context,
      AddNeedResult(
        title: title,
        quantity: _quantity,
        category: _category,
        isStaple: _staple,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.titleText,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'Milk, sponges, coffee…',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [
              for (final category in ShopCategory.values)
                ChoiceChip(
                  label: Text(category.label),
                  selected: _category == category,
                  onSelected: (_) => setState(() => _category = category),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Qty', style: theme.textTheme.labelLarge),
              IconButton(
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity -= 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(
                '$_quantity',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                onPressed: _quantity < 99
                    ? () => setState(() => _quantity += 1)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
              const Spacer(),
              FilterChip(
                selected: _staple,
                label: const Text('Regular'),
                selectedColor: AppColors.seed.withValues(alpha: 0.2),
                onSelected: (value) => setState(() => _staple = value),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: const Text('Add'),
            ),
          ),
        ],
      ),
    );
  }
}
