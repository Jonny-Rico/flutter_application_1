import 'package:family_tasks/features/app_lock/data/app_lock_storage.dart';
import 'package:family_tasks/features/app_lock/data/biometric_auth_service.dart';
import 'package:family_tasks/features/auth/presentation/providers/auth_providers.dart';
import 'package:family_tasks/features/tasks/data/task_local_storage.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final appLockStorageProvider = Provider<AppLockStorage>((ref) {
  final box = Hive.box<dynamic>(TaskLocalStorage.boxName);
  return AppLockStorage(box);
});

final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) {
  return BiometricAuthService();
});

/// Current user's app-lock configuration (enabled + PIN hash).
final appLockConfigProvider =
    StateNotifierProvider<AppLockConfigController, AppLockConfig>((ref) {
  return AppLockConfigController(
    storage: ref.watch(appLockStorageProvider),
    ref: ref,
  );
});

class AppLockConfigController extends StateNotifier<AppLockConfig> {
  AppLockConfigController({
    required this._storage,
    required this._ref,
  }) : super(AppLockConfig.disabled) {
    _bindAuth();
  }

  final AppLockStorage _storage;
  final Ref _ref;

  void _bindAuth() {
    _ref.listen(authStateProvider, (previous, next) {
      final userId = next.valueOrNull?.uid;
      if (userId == null) {
        state = AppLockConfig.disabled;
        return;
      }
      state = _storage.load(userId);
    }, fireImmediately: true);
  }

  String? get _userId => _ref.read(authStateProvider).valueOrNull?.uid;

  Future<void> save(AppLockConfig config) async {
    final userId = _userId;
    if (userId == null) return;
    state = config;
    await _storage.save(userId, config);
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    await save(state.copyWith(biometricsEnabled: enabled));
  }

  Future<void> setPinAndEnable(String pin) async {
    await save(state.withNewPin(pin));
  }

  Future<void> changePin(String pin) async {
    await save(state.withNewPin(pin).copyWith(enabled: true));
  }

  Future<void> disableAndClearPin() async {
    await save(
      AppLockConfig(
        enabled: false,
        biometricsEnabled: state.biometricsEnabled,
      ),
    );
  }

  bool verifyPin(String pin) => state.verifyPin(pin);
}

/// Whether the session is currently unlocked for this app run.
final appLockUnlockedProvider =
    StateNotifierProvider<AppLockSessionController, bool>((ref) {
  return AppLockSessionController(ref);
});

class AppLockSessionController extends StateNotifier<bool> {
  AppLockSessionController(this._ref) : super(true) {
    _ref.listen(authStateProvider, (previous, next) {
      final previousUid = previous?.valueOrNull?.uid;
      final nextUid = next.valueOrNull?.uid;
      if (nextUid == null) {
        state = true;
        return;
      }
      // Same account: ignore profile/token refreshes (verify, name, linking).
      if (previousUid == nextUid) return;

      // New uid or session restore — lock after prefs load for that user.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        final config = _ref.read(appLockConfigProvider);
        if (config.isActive) {
          state = false;
        }
      });
    }, fireImmediately: true);

    _ref.listen(appLockConfigProvider, (previous, next) {
      if (!next.isActive) {
        state = true;
        return;
      }
      // User just finished enabling lock in Settings — stay unlocked.
      if (previous != null && !previous.isActive && next.isActive) {
        state = true;
      }
    });
  }

  final Ref _ref;

  /// Skip re-lock while system biometric / credential UI is up.
  bool suppressLifecycleLock = false;

  void unlock() => state = true;

  void lockIfNeeded() {
    if (suppressLifecycleLock) return;
    final config = _ref.read(appLockConfigProvider);
    final loggedIn = _ref.read(authStateProvider).valueOrNull != null;
    if (loggedIn && config.isActive) {
      state = false;
    }
  }
}

/// True when lock UI must cover the app.
final appLockGateVisibleProvider = Provider<bool>((ref) {
  final loggedIn = ref.watch(authStateProvider).valueOrNull != null;
  final config = ref.watch(appLockConfigProvider);
  final unlocked = ref.watch(appLockUnlockedProvider);
  return loggedIn && config.isActive && !unlocked;
});
