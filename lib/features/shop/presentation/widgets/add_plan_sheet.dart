import 'package:flutter/material.dart';

class AddPlanResult {
  const AddPlanResult({
    required this.title,
    required this.quantity,
    this.note,
  });

  final String title;
  final int quantity;
  final String? note;
}

Future<AddPlanResult?> showAddPlanSheet(
  BuildContext context, {
  String titleText = 'Add to Plans',
  String hintText = 'Sofa, TV, dining table…',
}) {
  return showModalBottomSheet<AddPlanResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _AddPlanSheet(
      titleText: titleText,
      hintText: hintText,
    ),
  );
}

class _AddPlanSheet extends StatefulWidget {
  const _AddPlanSheet({
    required this.titleText,
    required this.hintText,
  });

  final String titleText;
  final String hintText;

  @override
  State<_AddPlanSheet> createState() => _AddPlanSheetState();
}

class _AddPlanSheetState extends State<_AddPlanSheet> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  int _quantity = 1;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Enter a name');
      return;
    }
    final note = _noteController.text.trim();
    Navigator.pop(
      context,
      AddPlanResult(
        title: title,
        quantity: _quantity,
        note: note.isEmpty ? null : note,
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
            controller: _titleController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: widget.hintText,
              errorText: _error,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              hintText: 'Note (optional)',
            ),
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
