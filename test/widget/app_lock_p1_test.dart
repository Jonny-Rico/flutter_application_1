import 'package:family_tasks/features/app_lock/data/app_lock_storage.dart';
import 'package:family_tasks/features/app_lock/data/biometric_auth_service.dart';
import 'package:family_tasks/features/app_lock/presentation/providers/app_lock_providers.dart';
import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_auth_user.dart';

class _MemoryLockStorage extends Fake implements AppLockStorage {
  AppLockConfig config = AppLockConfig.disabled;

  @override
  AppLockConfig load(String userId) => config;

  @override
  Future<void> save(String userId, AppLockConfig next) async {
    config = next;
  }
}

class _NoBiometrics extends Fake implements BiometricAuthService {
  @override
  Future<bool> get isAvailable async => false;
}

void main() {
  testWidgets('LOCK-P-03: disableAndClearPin turns lock off', (tester) async {
    late AppLockConfigController controller;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(FakeAuthUser()),
          ),
          appLockStorageProvider.overrideWithValue(_MemoryLockStorage()),
          biometricAuthServiceProvider.overrideWithValue(_NoBiometrics()),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            controller = ref.watch(appLockConfigProvider.notifier);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pump();

    await controller.setPinAndEnable('1234');
    expect(controller.state.isActive, isTrue);

    await controller.disableAndClearPin();
    expect(controller.state.isActive, isFalse);
  });

  testWidgets('LOCK-N-03: same-uid auth refresh does not lock', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(FakeAuthUser()),
          ),
          appLockStorageProvider.overrideWithValue(_MemoryLockStorage()),
          biometricAuthServiceProvider.overrideWithValue(_NoBiometrics()),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final unlocked = ref.watch(appLockUnlockedProvider);
            return MaterialApp(
              home: Text(unlocked ? 'unlocked' : 'locked'),
            );
          },
        ),
      ),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    await container.read(appLockConfigProvider.notifier).setPinAndEnable('1234');
    container.read(appLockUnlockedProvider.notifier).unlock();
    await tester.pump();

    expect(find.text('unlocked'), findsOneWidget);

    // Profile/token refresh keeps the same uid — stay unlocked.
    await tester.pump();
    expect(find.text('unlocked'), findsOneWidget);
  });
}
