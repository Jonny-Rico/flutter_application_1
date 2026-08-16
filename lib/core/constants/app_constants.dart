import 'package:flutter/material.dart';

abstract final class AppConstants {
  static const appName = 'FamilyTasks';
  static const maxGroupMembers = 10;
  static const splashDuration = Duration(milliseconds: 2200);
  static const inviteTtl = Duration(days: 7);

  /// Root messenger so SnackBars outlive nested Scaffold rebuilds (Tasks list).
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
}