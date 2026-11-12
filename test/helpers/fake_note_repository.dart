import 'dart:async';

import 'package:family_tasks/features/notes/data/note_repository.dart';
import 'package:family_tasks/features/notes/domain/note.dart';
import 'package:family_tasks/features/notes/domain/note_checklist_item.dart';
import 'package:family_tasks/features/notes/domain/note_type.dart';

class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository([List<Note> seed = const []]) {
    notes.addAll(seed);
  }

  final List<Note> notes = [];
  final List<Note> sharedCopies = [];
  final _controller = StreamController<List<Note>>.broadcast();
  var _nextId = 1;

  void _emit() => _controller.add(List<Note>.from(notes));

  @override
  List<Note> getCachedNotes(String userId) => List<Note>.from(notes);

  @override
  Note? getCachedNote({required String userId, required String noteId}) {
    for (final note in notes) {
      if (note.id == noteId) return note;
    }
    return null;
  }

  @override
  Stream<List<Note>> watchNotes(String userId) {
    return Stream<List<Note>>.multi((listener) {
      listener.add(List<Note>.from(notes));
      final sub = _controller.stream.listen(
        listener.add,
        onError: listener.addError,
        onDone: listener.close,
      );
      listener
        ..onPause = sub.pause
        ..onResume = sub.resume
        ..onCancel = sub.cancel;
    });
  }

  @override
  Future<Note> createNote({
    required String userId,
    required NoteType type,
  }) async {
    final now = DateTime.now();
    final note = Note(
      id: 'note-${_nextId++}',
      ownerId: userId,
      type: type,
      title: '',
      body: '',
      items: type == NoteType.list
          ? [NoteChecklistItem(id: 'new', text: '', done: false)]
          : const [],
      createdAt: now,
      updatedAt: now,
    );
    notes.insert(0, note);
    _emit();
    return note;
  }

  @override
  Future<void> updateNote({
    required String userId,
    required Note note,
  }) async {
    final index = notes.indexWhere((entry) => entry.id == note.id);
    if (index < 0) return;
    notes[index] = note.copyWith(updatedAt: DateTime.now());
    _emit();
  }

  @override
  Future<void> deleteNote({
    required String userId,
    required String noteId,
  }) async {
    notes.removeWhere((note) => note.id == noteId);
    _emit();
  }

  @override
  Future<Note> shareCopyToUser({
    required Note note,
    required String recipientId,
    required String sharedBy,
    required String sharedByName,
  }) async {
    final copy = note.copyForShare(
      id: 'copy-${_nextId++}',
      ownerId: recipientId,
      sharedBy: sharedBy,
      sharedByName: sharedByName,
      now: DateTime.now(),
    );
    sharedCopies.add(copy);
    return copy;
  }
}
