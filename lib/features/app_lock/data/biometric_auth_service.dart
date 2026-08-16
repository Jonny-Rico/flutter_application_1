import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  BiometricAuthService({LocalAuthentication? localAuth})
      : _auth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> get isDeviceSupported async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> get canCheckBiometrics async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> get isAvailable async {
    final supported = await isDeviceSupported;
    if (!supported) return false;
    try {
      final types = await _auth.getAvailableBiometrics();
      return types.isNotEmpty || await canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// Authenticate with biometrics or device credentials when available.
  Future<bool> authenticate({
    String reason = 'Unlock FamilyTasks',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
