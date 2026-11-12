import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/notes/domain/note.dart';
import 'package:family_tasks/features/notes/domain/note_type.dart';
import 'package:flutter/material.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onLongPress,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = _preview(note);
    final from = note.sharedByName?.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    note.type == NoteType.list
                        ? Icons.checklist_rounded
                        : Icons.notes_rounded,
                    size: 18,
                    color: AppColors.onSurfaceMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (note.type == NoteType.list)
                    Text(
                      '${note.listOpenCount} left',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurfaceMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceMuted,
                  ),
                ),
              ],
              if (from != null && from.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'From $from',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.seed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _preview(Note note) {
    if (note.type == NoteType.text) {
      final title = note.title.trim();
      final body = note.body.trim().replaceAll('\n', ' ');
      if (title.isEmpty) return body;
      return body;
    }
    final open = note.items
        .where((item) => !item.done && item.text.trim().isNotEmpty)
        .map((item) => item.text.trim())
        .take(3)
        .join(', ');
    return open;
  }
}
