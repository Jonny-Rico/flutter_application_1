import 'package:family_tasks/features/notes/domain/note.dart';
import 'package:family_tasks/features/notes/domain/note_checklist_item.dart';
import 'package:family_tasks/features/notes/domain/note_type.dart';

final _now = DateTime(2026, 8, 19, 12);

Note buildNote({
  String id = 'note-1',
  String ownerId = 'user-a',
  NoteType type = NoteType.text,
  String title = 'Wi-Fi',
  String body = 'Kitchen: treehouse',
  List<NoteChecklistItem> items = const [],
  String? sharedBy,
  String? sharedByName,
}) {
  return Note(
    id: id,
    ownerId: ownerId,
    type: type,
    title: title,
    body: body,
    items: items,
    createdAt: _now,
    updatedAt: _now,
    sharedBy: sharedBy,
    sharedByName: sharedByName,
  );
}

Note buildListNote({
  String id = 'note-list',
  String ownerId = 'user-a',
  String title = 'Weekend guests',
}) {
  return buildNote(
    id: id,
    ownerId: ownerId,
    type: NoteType.list,
    title: title,
    body: '',
    items: const [
      NoteChecklistItem(id: 'i1', text: 'Wine', done: false),
      NoteChecklistItem(id: 'i2', text: 'Flowers', done: true),
    ],
  );
}
