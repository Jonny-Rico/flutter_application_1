import 'package:family_tasks/features/notes/domain/note.dart';
import 'package:family_tasks/features/notes/domain/note_type.dart';

String noteShareText(Note note) {
  final lines = <String>[];
  final title = note.title.trim();
  if (title.isNotEmpty) lines.add(title);

  if (note.type == NoteType.text) {
    final body = note.body.trim();
    if (body.isNotEmpty) lines.add(body);
  } else {
    for (final item in note.items) {
      final text = item.text.trim();
      if (text.isEmpty) continue;
      lines.add('${item.done ? '[x]' : '[ ]'} $text');
    }
  }

  return lines.join('\n');
}
