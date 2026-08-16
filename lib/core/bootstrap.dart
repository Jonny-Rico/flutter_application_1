import 'package:family_tasks/core/notifications/task_notification_service.dart';
import 'package:family_tasks/features/tasks/data/task_local_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';

late final TaskNotificationService taskNotificationService;

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();
  await Hive.openBox<dynamic>(TaskLocalStorage.boxName);

  taskNotificationService = TaskNotificationService();
  await taskNotificationService.initialize();
}