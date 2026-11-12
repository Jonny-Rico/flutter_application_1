import 'package:family_tasks/core/haptics/app_haptics.dart';
import 'package:family_tasks/core/router/routes.dart';
import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/family/domain/group_member.dart';
import 'package:family_tasks/features/family/domain/group_role.dart';
import 'package:family_tasks/features/family/presentation/providers/family_providers.dart';
import 'package:family_tasks/features/notes/presentation/providers/note_providers.dart';
import 'package:family_tasks/features/notes/presentation/screens/note_editor_screen.dart';
import 'package:family_tasks/features/notes/presentation/screens/notes_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/fake_auth_user.dart';
import '../helpers/fake_note_repository.dart';
import '../helpers/note_fixtures.dart';
import '../helpers/test_overrides.dart';

final _memberB = GroupMember(
  userId: 'user-b',
  role: GroupRole.member,
  joinedAt: DateTime(2026, 1, 1),
  displayName: 'QA User B',
  email: 'qa.b.familytasks@example.com',
);

List<Override> _noteOverrides(FakeNoteRepository repo) {
  return [
    authStateProvider.overrideWith(
      (ref) => Stream.value(FakeAuthUser(uid: testProfile.userId)),
    ),
    userProfileProvider.overrideWith((ref) => Stream.value(testProfile)),
    groupMembersProvider.overrideWith((ref) => Stream.value([_memberB])),
    noteRepositoryProvider.overrideWithValue(repo),
    notesProvider.overrideWith((ref) => repo.watchNotes(testProfile.userId)),
  ];
}

Widget _notesApp({
  required List<Override> overrides,
  String location = '/notes',
}) {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: AppRoutes.notes,
        builder: (context, state) => const NotesListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => NoteEditorScreen(
              noteId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  setUp(() => AppHaptics.enabled = false);
  tearDown(() => AppHaptics.enabled = true);

  testWidgets('empty notes copy is visible', (tester) async {
    await tester.pumpWidget(
      _notesApp(overrides: _noteOverrides(FakeNoteRepository())),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('account-menu')), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('New note'), findsOneWidget);
  });

  testWidgets('list shows personal note and From chip', (tester) async {
    final repo = FakeNoteRepository([
      buildNote(),
      buildNote(
        id: 'shared',
        title: 'Sofa ideas',
        body: 'Grey fabric',
        sharedBy: 'user-b',
        sharedByName: 'QA User B',
      ),
    ]);
    await tester.pumpWidget(_notesApp(overrides: _noteOverrides(repo)));
    await tester.pump();
    await tester.pump();

    expect(find.text('Wi-Fi'), findsOneWidget);
    expect(find.text('From QA User B'), findsOneWidget);
  });

  testWidgets('long press opens edit share delete', (tester) async {
    final repo = FakeNoteRepository([buildNote()]);
    await tester.pumpWidget(_notesApp(overrides: _noteOverrides(repo)));
    await tester.pump();
    await tester.pump();

    await tester.longPress(find.text('Wi-Fi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });
}
