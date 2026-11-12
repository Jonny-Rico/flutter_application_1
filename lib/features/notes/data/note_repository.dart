import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_tasks/core/firebase/firestore_errors.dart';
import 'package:family_tasks/features/notes/data/note_local_storage.dart';
import 'package:family_tasks/features/notes/domain/note.dart';
import 'package:family_tasks/features/notes/domain/note_checklist_item.dart';
import 'package:family_tasks/features/notes/domain/note_type.dart';
import 'package:uuid/uuid.dart';

class NoteRepository {
  NoteRepository({
    FirebaseFirestore? firestore,
    this._localStorage,
    Uuid? uuid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _firestore;
  final NoteLocalStorage? _localStorage;
  final Uuid _uuid;
  final Map<String, List<Note>> _memory = {};

  CollectionReference<Map<String, dynamic>> _notesRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('notes');
  }

  List<Note> getCachedNotes(String userId) {
    return List<Note>.from(
      _memory[userId] ?? _localStorage?.loadNotes(userId) ?? const [],
    );
  }

  Stream<List<Note>> watchNotes(String userId) {
    return _notesRef(userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Note.fromFirestore).toList())
        .asyncMap((notes) async {
          _memory[userId] = List<Note>.from(notes);
          await _localStorage?.saveNotes(userId, notes);
          return notes;
        })
        .ignoreFirestoreAuthLoss();
  }

  Note? getCachedNote({required String userId, required String noteId}) {
    for (final note in getCachedNotes(userId)) {
      if (note.id == noteId) return note;
    }
    return null;
  }

  Future<Note> createNote({
    required String userId,
    required NoteType type,
  }) async {
    final now = DateTime.now();
    final note = Note(
      id: _uuid.v4(),
      ownerId: userId,
      type: type,
      title: '',
      body: '',
      items: type == NoteType.list
          ? [
              NoteChecklistItem(id: _uuid.v4(), text: '', done: false),
            ]
          : const [],
      createdAt: now,
      updatedAt: now,
    );
    await _notesRef(userId).doc(note.id).set(note.toFirestore());
    await _upsert(userId, note);
    return note;
  }

  Future<void> updateNote({
    required String userId,
    required Note note,
  }) async {
    final updated = note.copyWith(updatedAt: DateTime.now());
    await _notesRef(userId).doc(note.id).update(updated.toFirestore());
    await _upsert(userId, updated);
  }

  Future<void> deleteNote({
    required String userId,
    required String noteId,
  }) async {
    await _notesRef(userId).doc(noteId).delete();
    final next = getCachedNotes(userId).where((note) => note.id != noteId).toList();
    _memory[userId] = next;
    await _localStorage?.saveNotes(userId, next);
  }

  Future<Note> shareCopyToUser({
    required Note note,
    required String recipientId,
    required String sharedBy,
    required String sharedByName,
  }) async {
    final now = DateTime.now();
    final copy = note.copyForShare(
      id: _uuid.v4(),
      ownerId: recipientId,
      sharedBy: sharedBy,
      sharedByName: sharedByName,
      now: now,
    );
    await _notesRef(recipientId).doc(copy.id).set(copy.toFirestore());
    if (_memory.containsKey(recipientId)) {
      await _upsert(recipientId, copy);
    }
    return copy;
  }

  Future<void> _upsert(String userId, Note note) async {
    final next = getCachedNotes(userId);
    final index = next.indexWhere((entry) => entry.id == note.id);
    if (index >= 0) {
      next[index] = note;
    } else {
      next.insert(0, note);
    }
    _memory[userId] = next;
    await _localStorage?.saveNotes(userId, next);
  }
}
