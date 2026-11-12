import 'dart:async';

import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/notes/data/note_repository.dart';
import 'package:family_tasks/features/notes/domain/note.dart';
import 'package:family_tasks/features/notes/domain/note_checklist_item.dart';
import 'package:family_tasks/features/notes/domain/note_type.dart';
import 'package:family_tasks/features/notes/presentation/providers/note_providers.dart';
import 'package:family_tasks/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, required this.noteId});

  final String noteId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _uuid = const Uuid();
  Timer? _saveTimer;
  Note? _draft;
  var _didHydrate = false;
  String? _userId;
  NoteRepository? _repo;

  @override
  void dispose() {
    _saveTimer?.cancel();
    final userId = _userId;
    final repo = _repo;
    final draft = _assembled();
    if (userId != null && repo != null && draft != null) {
      unawaited(() async {
        if (draft.isEmpty) {
          await repo.deleteNote(userId: userId, noteId: draft.id);
        } else {
          await repo.updateNote(userId: userId, note: draft);
        }
      }());
    }
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _hydrate(Note note) {
    if (_didHydrate) return;
    _didHydrate = true;
    _draft = note;
    _titleController.text = note.title;
    _bodyController.text = note.body;
  }

  Note? _assembled() {
    final draft = _draft;
    if (draft == null) return null;
    return draft.copyWith(
      title: _titleController.text,
      body: _bodyController.text,
    );
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 450), () {
      unawaited(_flush());
    });
  }

  Future<void> _flush({bool deleteIfEmpty = false}) async {
    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    final draft = _assembled();
    if (userId == null || draft == null) return;
    final repo = ref.read(noteRepositoryProvider);
    if (deleteIfEmpty && draft.isEmpty) {
      await repo.deleteNote(userId: userId, noteId: draft.id);
      return;
    }
    await repo.updateNote(userId: userId, note: draft);
  }

  @override
  Widget build(BuildContext context) {
    _userId = ref.watch(authStateProvider).valueOrNull?.uid;
    _repo = ref.read(noteRepositoryProvider);
    final userId = _userId;
    final fromStream = ref.watch(noteByIdProvider(widget.noteId));
    final fromCache = userId == null
        ? null
        : ref.read(noteRepositoryProvider).getCachedNote(
              userId: userId,
              noteId: widget.noteId,
            );
    final note = fromStream ?? fromCache;
    if (note != null) _hydrate(note);
    final draft = _draft;

    if (draft == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Note')),
        body: const EmptyState(
          icon: Icons.notes_rounded,
          title: 'Note not found',
          subtitle: 'It may have been removed.',
          compact: true,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(draft.type == NoteType.list ? 'List' : 'Note'),
        actions: [
          IconButton(
            tooltip: 'Delete',
            onPressed: () => _delete(draft),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: draft.type == NoteType.list
          ? _listBody(draft)
          : _textBody(),
    );
  }

  Widget _textBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        TextField(
          controller: _titleController,
          textCapitalization: TextCapitalization.sentences,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
          decoration: const InputDecoration(
            hintText: 'Title',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
          onChanged: (_) => _scheduleSave(),
        ),
        TextField(
          controller: _bodyController,
          maxLines: null,
          minLines: 12,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Write something…',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
          onChanged: (_) => _scheduleSave(),
        ),
      ],
    );
  }

  Widget _listBody(Note draft) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            decoration: const InputDecoration(
              hintText: 'List title',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
            ),
            onChanged: (_) => _scheduleSave(),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
            itemCount: draft.items.length + 1,
            itemBuilder: (context, index) {
              if (index == draft.items.length) {
                return ListTile(
                  leading: const Icon(Icons.add_rounded),
                  title: const Text('Add item'),
                  onTap: _addItem,
                );
              }
              final item = draft.items[index];
              return _ChecklistRow(
                key: ValueKey(item.id),
                item: item,
                onToggle: () => _toggleItem(item.id),
                onText: (value) => _setItemText(item.id, value),
                onRemove: () => _removeItem(item.id),
              );
            },
          ),
        ),
      ],
    );
  }

  void _addItem() {
    final draft = _draft;
    if (draft == null) return;
    setState(() {
      _draft = draft.copyWith(
        items: [
          ...draft.items,
          NoteChecklistItem(id: _uuid.v4(), text: '', done: false),
        ],
      );
    });
    _scheduleSave();
  }

  void _toggleItem(String id) {
    final draft = _draft;
    if (draft == null) return;
    setState(() {
      _draft = draft.copyWith(
        items: [
          for (final item in draft.items)
            if (item.id == id) item.copyWith(done: !item.done) else item,
        ],
      );
    });
    _scheduleSave();
  }

  void _setItemText(String id, String text) {
    final draft = _draft;
    if (draft == null) return;
    _draft = draft.copyWith(
      items: [
        for (final item in draft.items)
          if (item.id == id) item.copyWith(text: text) else item,
      ],
    );
    _scheduleSave();
  }

  void _removeItem(String id) {
    final draft = _draft;
    if (draft == null) return;
    setState(() {
      _draft = draft.copyWith(
        items: [for (final item in draft.items) if (item.id != id) item],
      );
    });
    _scheduleSave();
  }

  Future<void> _delete(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _draft = null;
    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    if (userId != null) {
      await ref.read(noteRepositoryProvider).deleteNote(
            userId: userId,
            noteId: note.id,
          );
    }
    if (mounted) Navigator.pop(context);
  }
}

class _ChecklistRow extends StatefulWidget {
  const _ChecklistRow({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onText,
    required this.onRemove,
  });

  final NoteChecklistItem item;
  final VoidCallback onToggle;
  final ValueChanged<String> onText;
  final VoidCallback onRemove;

  @override
  State<_ChecklistRow> createState() => _ChecklistRowState();
}

class _ChecklistRowState extends State<_ChecklistRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconButton(
        icon: Icon(
          widget.item.done
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: widget.item.done
              ? AppColors.success
              : AppColors.onSurfaceMuted,
        ),
        onPressed: widget.onToggle,
      ),
      title: TextField(
        controller: _controller,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          hintText: 'Item',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: widget.onText,
      ),
      trailing: IconButton(
        tooltip: 'Remove',
        onPressed: widget.onRemove,
        icon: const Icon(Icons.close_rounded, size: 18),
      ),
    );
  }
}
