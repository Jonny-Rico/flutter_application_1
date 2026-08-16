import 'package:family_tasks/core/notifications/task_notification_service.dart';
import 'package:family_tasks/features/tasks/data/task_local_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

TaskNotificationService? _taskNotificationService;
bool _bootstrapped = false;

TaskNotificationService get taskNotificationService {
  final service = _taskNotificationService;
  if (service == null) {
    throw StateError('bootstrap() must run before using notifications.');
  }
  return service;
}

Future<void> bootstrap() async {
  if (_bootstrapped) return;
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  await Hive.initFlutter();
  if (!Hive.isBoxOpen(TaskLocalStorage.boxName)) {
    await Hive.openBox<dynamic>(TaskLocalStorage.boxName);
  }

  _taskNotificationService = TaskNotificationService();
  await _taskNotificationService!.initialize();
  _bootstrapped = true;
}
