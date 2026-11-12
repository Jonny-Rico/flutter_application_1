import 'package:family_tasks/features/notes/domain/note.dart';
import 'package:hive_flutter/hive_flutter.dart';

class NoteLocalStorage {
  NoteLocalStorage(this._box);

  final Box<dynamic> _box;

  String _key(String userId) => 'notes_$userId';

  Future<void> saveNotes(String userId, List<Note> notes) async {
    await _box.put(_key(userId), notes.map((note) => note.toMap()).toList());
  }

  List<Note> loadNotes(String userId) {
    final raw = _box.get(_key(userId));
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((entry) => Note.fromMap(Map<String, dynamic>.from(entry)))
        .toList();
  }
}
