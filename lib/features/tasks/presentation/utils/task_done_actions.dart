import 'dart:async';

import 'package:family_tasks/core/constants/app_constants.dart';
import 'package:family_tasks/core/haptics/app_haptics.dart';
import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/family/presentation/providers/family_providers.dart';
import 'package:family_tasks/features/tasks/data/task_repository.dart';
import 'package:family_tasks/features/tasks/domain/task.dart';
import 'package:family_tasks/features/tasks/domain/task_status.dart';
import 'package:family_tasks/features/tasks/presentation/providers/task_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Marks task as Done and offers Undo (restores previous status, not reminder).
Future<void> markTaskDoneWithUndo({
  required BuildContext context,
  required WidgetRef ref,
  required Task task,
}) async {
  if (task.status == TaskStatus.done) return;

  final scope = ref.read(taskScopeProvider);
  final userId = ref.read(authStateProvider).valueOrNull?.uid;
  if (scope == null || userId == null) return;

  final previousStatus = task.status;
  final repository = ref.read(taskRepositoryProvider);
  final scheduler = ref.read(taskNotificationSchedulerProvider);

  // Capture values for Undo — do not use WidgetRef after list rebuilds.
  final undoUserId = scope.userId;
  final undoGroupId = scope.groupId;
  final undoTaskId = task.id;
  final undoCurrentUserId = userId;

  try {
    await AppHaptics.light();
    await repository.updateTaskStatus(
      userId: scope.userId,
      groupId: scope.groupId,
      taskId: task.id,
      newStatus: TaskStatus.done,
      currentUserId: userId,
      task: task,
    );
    await scheduler.cancelTask(task.id);

    _showDoneUndoSnackBar(
      repository: repository,
      previousStatus: previousStatus,
      userId: undoUserId,
      groupId: undoGroupId,
      taskId: undoTaskId,
      currentUserId: undoCurrentUserId,
    );
  } catch (error) {
    final messenger = AppConstants.scaffoldMessengerKey.currentState;
    messenger?.clearSnackBars();
    messenger?.showSnackBar(
      SnackBar(
        content: Text('$error'),
        backgroundColor: AppColors.danger,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Toggles Done ↔ To Do with Undo only when marking Done.
Future<void> toggleTaskDoneWithUndo({
  required BuildContext context,
  required WidgetRef ref,
  required Task task,
}) async {
  if (task.status == TaskStatus.done) {
    final scope = ref.read(taskScopeProvider);
    final userId = ref.read(authStateProvider).valueOrNull?.uid;
    if (scope == null || userId == null) return;

    try {
      await ref.read(taskRepositoryProvider).updateTaskStatus(
            userId: scope.userId,
            groupId: scope.groupId,
            taskId: task.id,
            newStatus: TaskStatus.todo,
            currentUserId: userId,
            // Always re-fetch: list row may hold a stale snapshot.
            task: null,
          );
    } catch (error) {
      final messenger = AppConstants.scaffoldMessengerKey.currentState;
      messenger?.clearSnackBars();
      messenger?.showSnackBar(
        SnackBar(
          content: Text('$error'),
          backgroundColor: AppColors.danger,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return;
  }

  await markTaskDoneWithUndo(context: context, ref: ref, task: task);
}

void _showDoneUndoSnackBar({
  required TaskRepository repository,
  required TaskStatus previousStatus,
  required String userId,
  required String? groupId,
  required String taskId,
  required String currentUserId,
}) {
  final messenger = AppConstants.scaffoldMessengerKey.currentState;
  if (messenger == null) return;

  messenger.clearSnackBars();

  const displayDuration = Duration(seconds: 4);

  final controller = messenger.showSnackBar(
    SnackBar(
      content: const Text('Task marked as done'),
      duration: displayDuration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 88),
      dismissDirection: DismissDirection.down,
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          // Close immediately; undo with captured repository (no WidgetRef).
          messenger.hideCurrentSnackBar();
          unawaited(
            _undoDone(
              repository: repository,
              previousStatus: previousStatus,
              userId: userId,
              groupId: groupId,
              taskId: taskId,
              currentUserId: currentUserId,
            ),
          );
        },
      ),
    ),
  );

  // Backup close: some platforms keep action snackbars visible too long.
  unawaited(
    Future<void>.delayed(displayDuration + const Duration(milliseconds: 200), () {
      try {
        controller.close();
      } catch (_) {
        // Already closed.
      }
    }),
  );
}

Future<void> _undoDone({
  required TaskRepository repository,
  required TaskStatus previousStatus,
  required String userId,
  required String? groupId,
  required String taskId,
  required String currentUserId,
}) async {
  final messenger = AppConstants.scaffoldMessengerKey.currentState;

  try {
    // task: null → load current doc from server/cache (status should be done).
    await repository.updateTaskStatus(
      userId: userId,
      groupId: groupId,
      taskId: taskId,
      newStatus: previousStatus,
      currentUserId: currentUserId,
      task: null,
    );
    await repository.deleteUneditedSpawnedSuccessor(
      userId: userId,
      groupId: groupId,
      parentTaskId: taskId,
      currentUserId: currentUserId,
    );
  } catch (error) {
    messenger?.clearSnackBars();
    messenger?.showSnackBar(
      SnackBar(
        content: Text('Undo failed: $error'),
        backgroundColor: AppColors.danger,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
