import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

typedef TaskNotificationTapCallback = void Function(String taskId);

class TaskNotificationService {
  TaskNotificationService();

  static const _reminderChannelId = 'family_tasks_reminders';
  static const _reminderChannelName = 'Task reminders';
  static const _reminderChannelDescription = 'Local reminders for your tasks';

  static const _newTaskChannelId = 'family_tasks_new_assignments';
  static const _newTaskChannelName = 'New tasks';
  static const _newTaskChannelDescription =
      'Alerts when a new task is assigned to you';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _pendingLaunchTaskId;

  /// Set by the app to navigate when the user taps a notification.
  TaskNotificationTapCallback? onNotificationTap;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    const reminderChannel = AndroidNotificationChannel(
      _reminderChannelId,
      _reminderChannelName,
      description: _reminderChannelDescription,
      importance: Importance.high,
    );
    const newTaskChannel = AndroidNotificationChannel(
      _newTaskChannelId,
      _newTaskChannelName,
      description: _newTaskChannelDescription,
      importance: Importance.high,
    );

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(reminderChannel);
    await androidPlugin?.createNotificationChannel(newTaskChannel);

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final payload = launchDetails?.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        _pendingLaunchTaskId = payload;
      }
    }

    _initialized = true;
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    final callback = onNotificationTap;
    if (callback != null) {
      callback(payload);
    } else {
      _pendingLaunchTaskId = payload;
    }
  }

  /// Returns a task id that launched the app via notification, if any.
  String? consumePendingLaunchTaskId() {
    final taskId = _pendingLaunchTaskId;
    _pendingLaunchTaskId = null;
    return taskId;
  }

  void queuePendingTaskId(String taskId) {
    if (taskId.isEmpty) return;
    _pendingLaunchTaskId = taskId;
  }

  Future<bool> requestPermission() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final granted =
        await androidPlugin?.requestNotificationsPermission() ?? false;
    return granted;
  }

  int notificationIdForTask(String taskId) => taskId.hashCode & 0x7FFFFFFF;

  int notificationIdForNewTaskAlert(String taskId) =>
      (taskId.hashCode ^ 0x6E657774) & 0x7FFFFFFF;

  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    required DateTime reminderAt,
  }) async {
    await initialize();

    final now = DateTime.now();
    if (!reminderAt.isAfter(now)) return;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _reminderChannelId,
        _reminderChannelName,
        channelDescription: _reminderChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    await _plugin.zonedSchedule(
      notificationIdForTask(taskId),
      'Task reminder',
      title,
      tz.TZDateTime.from(reminderAt, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: taskId,
    );
  }

  Future<void> cancelTaskReminder(String taskId) async {
    await _plugin.cancel(notificationIdForTask(taskId));
  }

  Future<void> showNewTaskAssignment({
    required String taskId,
    required String title,
    required bool isGroupTask,
  }) async {
    await initialize();

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _newTaskChannelId,
        _newTaskChannelName,
        channelDescription: _newTaskChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    await _plugin.show(
      notificationIdForNewTaskAlert(taskId),
      isGroupTask ? 'New family task' : 'New task for you',
      title,
      details,
      payload: taskId,
    );
  }
}
