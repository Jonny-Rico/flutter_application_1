import 'package:family_tasks/features/app_lock/data/pin_hasher.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppLockConfig {
  const AppLockConfig({
    required this.enabled,
    required this.biometricsEnabled,
    this.pinHash,
    this.pinSalt,
  });

  static const disabled = AppLockConfig(
    enabled: false,
    biometricsEnabled: true,
  );

  final bool enabled;
  final bool biometricsEnabled;
  final String? pinHash;
  final String? pinSalt;

  bool get hasPin =>
      pinHash != null &&
      pinHash!.isNotEmpty &&
      pinSalt != null &&
      pinSalt!.isNotEmpty;

  bool get isActive => enabled && hasPin;

  AppLockConfig copyWith({
    bool? enabled,
    bool? biometricsEnabled,
    String? pinHash,
    String? pinSalt,
    bool clearPin = false,
  }) {
    return AppLockConfig(
      enabled: enabled ?? this.enabled,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      pinHash: clearPin ? null : (pinHash ?? this.pinHash),
      pinSalt: clearPin ? null : (pinSalt ?? this.pinSalt),
    );
  }

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'biometricsEnabled': biometricsEnabled,
        'pinHash': pinHash,
        'pinSalt': pinSalt,
      };

  factory AppLockConfig.fromMap(Map<dynamic, dynamic>? raw) {
    if (raw == null) return AppLockConfig.disabled;
    final map = Map<String, dynamic>.from(raw);
    return AppLockConfig(
      enabled: map['enabled'] as bool? ?? false,
      biometricsEnabled: map['biometricsEnabled'] as bool? ?? true,
      pinHash: map['pinHash'] as String?,
      pinSalt: map['pinSalt'] as String?,
    );
  }

  bool verifyPin(String pin) {
    if (!hasPin) return false;
    return PinHasher.verify(
      pin: pin,
      salt: pinSalt!,
      expectedHash: pinHash!,
    );
  }

  AppLockConfig withNewPin(String pin) {
    final salt = PinHasher.generateSalt();
    return copyWith(
      enabled: true,
      pinSalt: salt,
      pinHash: PinHasher.hash(pin, salt),
    );
  }
}

class AppLockStorage {
  AppLockStorage(this._box);

  static const _keyPrefix = 'app_lock_';

  final Box<dynamic> _box;

  String _keyFor(String userId) => '$_keyPrefix$userId';

  AppLockConfig load(String userId) {
    final raw = _box.get(_keyFor(userId));
    if (raw is! Map) return AppLockConfig.disabled;
    return AppLockConfig.fromMap(raw);
  }

  Future<void> save(String userId, AppLockConfig config) async {
    await _box.put(_keyFor(userId), config.toMap());
  }

  Future<void> clear(String userId) async {
    await _box.delete(_keyFor(userId));
  }
}
