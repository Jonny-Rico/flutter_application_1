import 'package:family_tasks/features/app_lock/presentation/providers/app_lock_providers.dart';
import 'package:family_tasks/features/app_lock/presentation/screens/app_lock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Covers [child] with the lock UI when the session is locked.
/// Also re-locks when the app returns from background.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Lock when leaving the app (not while picking biometrics / sharing).
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      ref.read(appLockUnlockedProvider.notifier).lockIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final showLock = ref.watch(appLockGateVisibleProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (showLock) const Positioned.fill(child: AppLockScreen()),
      ],
    );
  }
}
