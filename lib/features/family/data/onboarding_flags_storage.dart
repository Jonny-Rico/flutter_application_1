import 'package:hive_flutter/hive_flutter.dart';

/// One-time onboarding flags per user (Hive).
class OnboardingFlagsStorage {
  OnboardingFlagsStorage(this._box);

  static const _prefix = 'onboarding_flags_';

  final Box<dynamic> _box;

  String _key(String userId) => '$_prefix$userId';

  Map<String, dynamic> _loadMap(String userId) {
    final raw = _box.get(_key(userId));
    if (raw is! Map) return {};
    return Map<String, dynamic>.from(raw);
  }

  Future<void> _saveMap(String userId, Map<String, dynamic> map) async {
    await _box.put(_key(userId), map);
  }

  bool hasSeenInviteAfterCreate(String userId) =>
      _loadMap(userId)['inviteAfterCreate'] as bool? ?? false;

  Future<void> markInviteAfterCreateSeen(String userId) async {
    final map = _loadMap(userId);
    map['inviteAfterCreate'] = true;
    await _saveMap(userId, map);
  }

  bool hasSeenJoinWelcome(String userId) =>
      _loadMap(userId)['joinWelcome'] as bool? ?? false;

  Future<void> markJoinWelcomeSeen(String userId) async {
    final map = _loadMap(userId);
    map['joinWelcome'] = true;
    await _saveMap(userId, map);
  }

  bool hasSeenFirstAssignTip(String userId) =>
      _loadMap(userId)['firstAssignTip'] as bool? ?? false;

  Future<void> markFirstAssignTipSeen(String userId) async {
    final map = _loadMap(userId);
    map['firstAssignTip'] = true;
    await _saveMap(userId, map);
  }
}
