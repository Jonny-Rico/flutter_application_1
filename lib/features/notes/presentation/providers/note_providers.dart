import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/notes/data/note_local_storage.dart';
import 'package:family_tasks/features/notes/data/note_repository.dart';
import 'package:family_tasks/features/notes/domain/note.dart';
import 'package:family_tasks/features/tasks/data/task_local_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final noteLocalStorageProvider = Provider<NoteLocalStorage>((ref) {
  final box = Hive.box<dynamic>(TaskLocalStorage.boxName);
  return NoteLocalStorage(box);
});

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository(localStorage: ref.watch(noteLocalStorageProvider));
});

final notesProvider = StreamProvider<List<Note>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(const []);
  return ref.watch(noteRepositoryProvider).watchNotes(user.uid);
});

final noteByIdProvider = Provider.family<Note?, String>((ref, id) {
  final notes = ref.watch(notesProvider).valueOrNull ?? const [];
  for (final note in notes) {
    if (note.id == id) return note;
  }
  return null;
});

final notesSearchQueryProvider = StateProvider<String>((ref) => '');
