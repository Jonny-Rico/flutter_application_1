import 'package:family_tasks/core/constants/app_constants.dart';
import 'package:family_tasks/core/theme/app_colors.dart';
import 'package:family_tasks/features/app_lock/presentation/providers/app_lock_providers.dart';
import 'package:family_tasks/features/app_lock/presentation/widgets/pin_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _pinLength = 4;

/// Full-screen gate shown when app lock is active and session is locked.
class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  String _pin = '';
  String? _error;
  bool _biometricsAvailable = false;
  bool _bioAttempted = false;
  var _failedAttempts = 0;
  DateTime? _lockUntil;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initBiometrics());
  }

  Future<void> _initBiometrics() async {
    final config = ref.read(appLockConfigProvider);
    if (!config.biometricsEnabled) return;

    final available =
        await ref.read(biometricAuthServiceProvider).isAvailable;
    if (!mounted) return;
    setState(() => _biometricsAvailable = available);

    if (available && !_bioAttempted) {
      _bioAttempted = true;
      await _tryBiometrics();
    }
  }

  Future<void> _tryBiometrics() async {
    final session = ref.read(appLockUnlockedProvider.notifier);
    session.suppressLifecycleLock = true;
    try {
      final ok = await ref.read(biometricAuthServiceProvider).authenticate(
            reason: 'Unlock ${AppConstants.appName}',
          );
      if (!mounted) return;
      if (ok) {
        session.unlock();
      }
    } finally {
      // Delay so lifecycle "resume" after the sheet does not re-lock.
      Future<void>.delayed(const Duration(milliseconds: 600), () {
        session.suppressLifecycleLock = false;
      });
    }
  }

  bool get _isThrottled {
    final until = _lockUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  Duration get _throttleDuration {
    if (_failedAttempts < 10) return const Duration(seconds: 30);
    if (_failedAttempts < 15) return const Duration(seconds: 60);
    return const Duration(seconds: 120);
  }

  void _onDigit(String digit) {
    if (_isThrottled) {
      setState(() {
        final seconds = _lockUntil!.difference(DateTime.now()).inSeconds;
        _error = 'Too many attempts. Try again in ${seconds}s';
      });
      return;
    }
    if (_pin.length >= _pinLength) return;
    setState(() {
      _error = null;
      _pin += digit;
    });
    if (_pin.length == _pinLength) {
      _submitPin();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _error = null;
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  void _submitPin() {
    final ok = ref.read(appLockConfigProvider.notifier).verifyPin(_pin);
    if (ok) {
      _failedAttempts = 0;
      _lockUntil = null;
      ref.read(appLockUnlockedProvider.notifier).unlock();
      return;
    }
    HapticFeedback.heavyImpact();
    _failedAttempts++;
    if (_failedAttempts >= 5) {
      _lockUntil = DateTime.now().add(_throttleDuration);
      final seconds = _throttleDuration.inSeconds;
      setState(() {
        _error = 'Too many attempts. Try again in ${seconds}s';
        _pin = '';
      });
      return;
    }
    setState(() {
      _error = 'Wrong PIN';
      _pin = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showBio = _biometricsAvailable &&
        ref.watch(appLockConfigProvider).biometricsEnabled;

    return Material(
      color: AppColors.surfaceDark,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Icon(
                Icons.lock_rounded,
                size: 40,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'App locked',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                showBio
                    ? 'Use biometrics or enter your PIN'
                    : 'Enter your PIN',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: 28),
              PinDots(
                length: _pinLength,
                filled: _pin.length,
                error: _error != null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const Spacer(),
              PinPad(
                onDigit: _onDigit,
                onBackspace: _onBackspace,
                showBiometrics: showBio,
                onBiometrics: _tryBiometrics,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
