import 'package:family_tasks/core/constants/app_constants.dart';
import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/family/domain/group_member.dart';
import 'package:family_tasks/features/notes/data/note_repository.dart';
import 'package:family_tasks/features/notes/domain/note.dart';
import 'package:family_tasks/features/notes/domain/note_share_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

Future<void> showNoteShareSheet({
  required BuildContext context,
  required Note note,
  required NoteRepository repository,
  required String currentUserId,
  required String currentUserName,
  required List<GroupMember> members,
}) async {
  if (note.isEmpty) {
    AppConstants.scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('Nothing to share'),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final others = [
    for (final member in members)
      if (member.userId != currentUserId) member,
  ];

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Share “${note.displayTitle}”',
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            if (others.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  'FAMILY',
                  style: Theme.of(sheetContext).textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceMuted,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                ),
              ),
              for (final member in others)
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: Text(
                    member.displayName.trim().isEmpty
                        ? 'Member'
                        : member.displayName.trim(),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _shareToMember(
                      repository: repository,
                      note: note,
                      recipientId: member.userId,
                      recipientName: member.displayName,
                      sharedBy: currentUserId,
                      sharedByName: currentUserName,
                    );
                  },
                ),
              if (others.length > 1)
                ListTile(
                  leading: const Icon(Icons.groups_outlined),
                  title: const Text('Share with all members'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _shareToAll(
                      repository: repository,
                      note: note,
                      members: others,
                      sharedBy: currentUserId,
                      sharedByName: currentUserName,
                    );
                  },
                ),
              const Divider(),
            ],
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy text'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await Clipboard.setData(ClipboardData(text: noteShareText(note)));
                AppConstants.scaffoldMessengerKey.currentState?.showSnackBar(
                  const SnackBar(
                    content: Text('Copied'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.ios_share_rounded),
              title: const Text('More apps…'),
              subtitle: const Text('Telegram, WhatsApp, Viber, SMS…'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await SharePlus.instance.share(
                  ShareParams(text: noteShareText(note)),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _shareToMember({
  required NoteRepository repository,
  required Note note,
  required String recipientId,
  required String recipientName,
  required String sharedBy,
  required String sharedByName,
}) async {
  try {
    await repository.shareCopyToUser(
      note: note,
      recipientId: recipientId,
      sharedBy: sharedBy,
      sharedByName: sharedByName,
    );
    final name = recipientName.trim().isEmpty ? 'them' : recipientName.trim();
    AppConstants.scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('Copied to $name’s notes'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (error) {
    AppConstants.scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('$error'),
        backgroundColor: AppColors.danger,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

Future<void> _shareToAll({
  required NoteRepository repository,
  required Note note,
  required List<GroupMember> members,
  required String sharedBy,
  required String sharedByName,
}) async {
  try {
    for (final member in members) {
      await repository.shareCopyToUser(
        note: note,
        recipientId: member.userId,
        sharedBy: sharedBy,
        sharedByName: sharedByName,
      );
    }
    AppConstants.scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('Copied to ${members.length} members'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (error) {
    AppConstants.scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('$error'),
        backgroundColor: AppColors.danger,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
