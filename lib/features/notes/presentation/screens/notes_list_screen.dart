import 'package:family_tasks/core/router/routes.dart';
import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/family/domain/group_member.dart';
import 'package:family_tasks/features/family/presentation/providers/family_providers.dart';
import 'package:family_tasks/features/notes/domain/note.dart';
import 'package:family_tasks/features/notes/domain/note_type.dart';
import 'package:family_tasks/features/notes/presentation/providers/note_providers.dart';
import 'package:family_tasks/features/notes/presentation/widgets/note_card.dart';
import 'package:family_tasks/shared/widgets/root_app_bar.dart';
import 'package:family_tasks/features/notes/presentation/widgets/note_share_sheet.dart';
import 'package:family_tasks/shared/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NotesListScreen extends ConsumerStatefulWidget {
  const NotesListScreen({super.key});

  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen> {
  final _searchController = TextEditingController();
  bool _searchOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);
    final members = ref.watch(groupMembersProvider).valueOrNull ?? const [];
    final query = ref.watch(notesSearchQueryProvider).trim().toLowerCase();

    return Scaffold(
      appBar: RootAppBar(
        title: 'Notes',
        actions: [
          IconButton(
            tooltip: _searchOpen ? 'Close search' : 'Search',
            onPressed: () {
              if (_searchOpen) {
                _searchController.clear();
                ref.read(notesSearchQueryProvider.notifier).state = '';
              }
              setState(() => _searchOpen = !_searchOpen);
            },
            icon: Icon(
              _searchOpen ? Icons.close_rounded : Icons.search_rounded,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New note',
        onPressed: () => _onFab(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Could not load notes',
          subtitle: error.toString(),
          compact: true,
        ),
        data: (notes) {
          final filtered = query.isEmpty
              ? notes
              : notes.where((note) {
                  return note.title.toLowerCase().contains(query) ||
                      note.body.toLowerCase().contains(query) ||
                      note.items.any(
                        (item) => item.text.toLowerCase().contains(query),
                      );
                }).toList();

          return Column(
            children: [
              if (_searchOpen)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (value) {
                      ref.read(notesSearchQueryProvider.notifier).state = value;
                    },
                    decoration: const InputDecoration(hintText: 'Search notes'),
                  ),
                ),
              Expanded(
                child: filtered.isEmpty
                    ? EmptyState(
                        icon: query.isNotEmpty
                            ? Icons.search_off_rounded
                            : Icons.notes_rounded,
                        title: query.isNotEmpty
                            ? 'No matches'
                            : 'Nothing here',
                        subtitle: query.isNotEmpty
                            ? 'Nothing matches “$query”.'
                            : 'Private notes — text or a checklist. Only you see them.',
                        compact: true,
                        action: query.isEmpty
                            ? FilledButton(
                                onPressed: () => _onFab(context),
                                child: const Text('New note'),
                              )
                            : null,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 96),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final note = filtered[index];
                          return NoteCard(
                            note: note,
                            onTap: () =>
                                context.push(AppRoutes.noteDetail(note.id)),
                            onLongPress: () => _onLongPress(note, members),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onFab(BuildContext context) async {
    final choice = await showModalBottomSheet<NoteType>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.notes_rounded),
                title: const Text('Text note'),
                subtitle: const Text('A title and some writing'),
                onTap: () => Navigator.pop(context, NoteType.text),
              ),
              ListTile(
                leading: const Icon(Icons.checklist_rounded),
                title: const Text('Checklist'),
                subtitle: const Text('A list you can tick off'),
                onTap: () => Navigator.pop(context, NoteType.list),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (choice == null || !context.mounted) return;
    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    if (userId == null) return;
    final note = await ref.read(noteRepositoryProvider).createNote(
          userId: userId,
          type: choice,
        );
    if (!context.mounted) return;
    context.push(AppRoutes.noteDetail(note.id));
  }

  Future<void> _onLongPress(Note note, List<GroupMember> members) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () => Navigator.pop(context, 'edit'),
              ),
              ListTile(
                leading: const Icon(Icons.ios_share_rounded),
                title: const Text('Share'),
                onTap: () => Navigator.pop(context, 'share'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.danger,
                ),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.danger),
                ),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (!mounted || action == null) return;
    if (action == 'edit') {
      context.push(AppRoutes.noteDetail(note.id));
      return;
    }
    if (action == 'share') {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      final user = ref.read(authStateProvider).valueOrNull;
      final profile = ref.read(userProfileProvider).valueOrNull;
      if (user == null) return;
      await showNoteShareSheet(
        context: context,
        note: note,
        repository: ref.read(noteRepositoryProvider),
        currentUserId: user.uid,
        currentUserName: (profile?.displayName.isNotEmpty ?? false)
            ? profile!.displayName
            : (user.displayName ?? 'Someone'),
        members: members,
      );
      return;
    }
    if (action == 'delete') {
      await _confirmDelete(note);
    }
  }

  Future<void> _confirmDelete(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text('Delete “${note.displayTitle}”. This cannot be undone.'),
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
    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    if (userId == null) return;
    await ref.read(noteRepositoryProvider).deleteNote(
          userId: userId,
          noteId: note.id,
        );
  }
}
