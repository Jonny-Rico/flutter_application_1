import 'package:flutter/services.dart';

/// Light Android/iOS feedback for primary destructive / completion actions.
///
/// Controlled by Settings → Haptic feedback (persisted per user).
abstract final class AppHaptics {
  /// When false, [light] / [medium] are no-ops. Default on.
  static bool enabled = true;

  static Future<void> light() async {
    if (!enabled) return;
    await HapticFeedback.lightImpact();
  }

  static Future<void> medium() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
  }
}
