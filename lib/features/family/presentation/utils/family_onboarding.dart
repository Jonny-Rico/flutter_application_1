import 'package:family_tasks/core/router/routes.dart';
import 'package:family_tasks/features/family/presentation/providers/family_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// After create group: one-time invite prompt.
Future<void> showInviteAfterCreateIfNeeded({
  required BuildContext context,
  required WidgetRef ref,
  required String userId,
}) async {
  final storage = ref.read(onboardingFlagsStorageProvider);
  if (storage.hasSeenInviteAfterCreate(userId)) return;

  await storage.markInviteAfterCreateSeen(userId);
  if (!context.mounted) return;

  final goInvite = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Invite your family'),
      content: const Text(
        'Invite someone so you can assign personal tasks and share Family tasks.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Invite member'),
        ),
      ],
    ),
  );

  if (goInvite == true && context.mounted) {
    context.push(AppRoutes.familyInvite);
  }
}

/// After join: one-time welcome with next steps.
Future<void> showJoinWelcomeIfNeeded({
  required BuildContext context,
  required WidgetRef ref,
  required String userId,
}) async {
  final storage = ref.read(onboardingFlagsStorageProvider);
  if (storage.hasSeenJoinWelcome(userId)) return;

  await storage.markJoinWelcomeSeen(userId);
  if (!context.mounted) return;

  final action = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('You’re in!'),
      content: const Text(
        'Check For me for tasks assigned to you, or create a Family task everyone can see.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 'ok'),
          child: const Text('OK'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, 'tasks'),
          child: const Text('Go to Tasks'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, 'create'),
          child: const Text('Create task'),
        ),
      ],
    ),
  );

  if (!context.mounted) return;
  switch (action) {
    case 'tasks':
      context.go(AppRoutes.tasks);
    case 'create':
      context.push(AppRoutes.taskCreate);
    default:
      break;
  }
}

/// After first assign to another member: one-time tip.
Future<void> showFirstAssignTipIfNeeded({
  required BuildContext context,
  required WidgetRef ref,
  required String userId,
  required String? assigneeId,
  required bool isGroupTask,
}) async {
  if (isGroupTask) return;
  if (assigneeId == null || assigneeId == userId) return;

  final storage = ref.read(onboardingFlagsStorageProvider);
  if (storage.hasSeenFirstAssignTip(userId)) return;

  await storage.markFirstAssignTipSeen(userId);
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Task assigned'),
      content: const Text(
        'They’ll see it under For me on their Tasks screen.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}
