import 'package:family_tasks/features/notes/domain/note_share_text.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_note_repository.dart';
import '../helpers/note_fixtures.dart';

void main() {
  test('text note exports title and body', () {
    expect(noteShareText(buildNote()), 'Wi-Fi\nKitchen: treehouse');
  });

  test('list note exports checked and open items', () {
    expect(
      noteShareText(buildListNote()),
      'Weekend guests\n[ ] Wine\n[x] Flowers',
    );
  });

  test('empty note has no share text', () {
    final note = buildNote(title: '', body: '');
    expect(note.isEmpty, isTrue);
    expect(noteShareText(note), isEmpty);
  });

  test('in-app share writes a copy for the recipient', () async {
    final repo = FakeNoteRepository([buildNote()]);
    final copy = await repo.shareCopyToUser(
      note: repo.notes.single,
      recipientId: 'user-b',
      sharedBy: 'user-a',
      sharedByName: 'QA User A',
    );
    expect(copy.ownerId, 'user-b');
    expect(copy.sharedBy, 'user-a');
    expect(copy.title, 'Wi-Fi');
    expect(copy.body, 'Kitchen: treehouse');
    expect(repo.sharedCopies, hasLength(1));
  });
}
