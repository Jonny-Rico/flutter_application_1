import 'dart:async';

import 'package:family_tasks/core/constants/app_constants.dart';
import 'package:family_tasks/core/haptics/app_haptics.dart';
import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/family/presentation/providers/family_providers.dart';
import 'package:family_tasks/features/shop/domain/need_item.dart';
import 'package:family_tasks/features/shop/domain/plan_item.dart';
import 'package:family_tasks/features/shop/presentation/providers/shop_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> toggleNeedBoughtWithUndo({
  required WidgetRef ref,
  required NeedItem item,
}) async {
  final scope = ref.read(taskScopeProvider);
  if (scope == null) return;
  final repository = ref.read(shopRepositoryProvider);
  final nextBought = !item.bought;

  try {
    await AppHaptics.light();
    await repository.toggleNeedBought(
      userId: scope.userId,
      groupId: scope.groupId,
      itemId: item.id,
      bought: nextBought,
    );
    if (!nextBought) return;

    _showBoughtUndoSnackBar(
      title: item.title,
      onUndo: () => repository.toggleNeedBought(
        userId: scope.userId,
        groupId: scope.groupId,
        itemId: item.id,
        bought: false,
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

Future<void> togglePlanBoughtWithUndo({
  required WidgetRef ref,
  required PlanItem item,
}) async {
  final scope = ref.read(taskScopeProvider);
  if (scope == null) return;
  final repository = ref.read(shopRepositoryProvider);
  final nextBought = !item.bought;

  try {
    await AppHaptics.light();
    await repository.togglePlanBought(
      userId: scope.userId,
      groupId: scope.groupId,
      itemId: item.id,
      bought: nextBought,
    );
    if (!nextBought) return;

    _showBoughtUndoSnackBar(
      title: item.title,
      onUndo: () => repository.togglePlanBought(
        userId: scope.userId,
        groupId: scope.groupId,
        itemId: item.id,
        bought: false,
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

Future<void> togglePersonalBoughtWithUndo({
  required WidgetRef ref,
  required PlanItem item,
}) async {
  final userId = ref.read(authStateProvider).valueOrNull?.uid;
  if (userId == null) return;
  final repository = ref.read(shopRepositoryProvider);
  final nextBought = !item.bought;

  try {
    await AppHaptics.light();
    await repository.togglePersonalBought(
      userId: userId,
      itemId: item.id,
      bought: nextBought,
    );
    if (!nextBought) return;

    _showBoughtUndoSnackBar(
      title: item.title,
      onUndo: () => repository.togglePersonalBought(
        userId: userId,
        itemId: item.id,
        bought: false,
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

void _showBoughtUndoSnackBar({
  required String title,
  required Future<void> Function() onUndo,
}) {
  final messenger = AppConstants.scaffoldMessengerKey.currentState;
  if (messenger == null) return;

  messenger.clearSnackBars();

  const displayDuration = Duration(seconds: 4);
  final controller = messenger.showSnackBar(
    SnackBar(
      content: Text('$title bought'),
      duration: displayDuration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 88),
      dismissDirection: DismissDirection.down,
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          messenger.hideCurrentSnackBar();
          unawaited(onUndo());
        },
      ),
    ),
  );

  // Backup close: action snackbars can linger on Android / a11y.
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
