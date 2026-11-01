import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin _notifications =
    FlutterLocalNotificationsPlugin();

bool _initialized = false;

const String _channelId = 'studyx_general_channel';

const AndroidNotificationChannel _channel =
    AndroidNotificationChannel(
  _channelId,
  'StudyX Notifications',
  description: 'Study reminders and progress notifications',
  importance: Importance.max,
);

Future<bool> platformInitialize() async {
  if (_initialized) {
    return true;
  }

  tz_data.initializeTimeZones();

  tz.setLocalLocation(
    tz.getLocation('Asia/Kolkata'),
  );

  // Android settings
  const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // Windows settings
  const windowsSettings =
      WindowsInitializationSettings(
    appName: 'StudyX',
    appUserModelId: 'com.studyx.app',
    guid: '6f7b7e8e-4c7a-4b5f-9e3d-123456789abc',
  );

  const settings = InitializationSettings(
    android: androidSettings,
    windows: windowsSettings,
  );

  final result = await _notifications.initialize(
    settings,
  );

  // Android notification channel
  if (Platform.isAndroid) {
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      _channel,
    );

    await androidPlugin?.requestNotificationsPermission();
  }

  _initialized = result ?? false;

  return _initialized;
}

Future<bool> platformRequestPermission() async {
  if (!_initialized) {
    await platformInitialize();
  }

  if (!Platform.isAndroid) {
    return true;
  }

  final androidPlugin =
      _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  final granted =
      await androidPlugin?.requestNotificationsPermission();

  return granted ?? true;
}

Future<void> platformShow({
  required String title,
  required String body,
}) async {
  if (!_initialized) {
    await platformInitialize();
  }

  if (Platform.isWindows) {
    const windowsDetails = WindowsNotificationDetails();

    const details = NotificationDetails(
      windows: windowsDetails,
    );

    final id =
        DateTime.now().millisecondsSinceEpoch.remainder(2147483647);

    await _notifications.show(
      id,
      title,
      body,
      details,
    );

    return;
  }

  const androidDetails = AndroidNotificationDetails(
    _channelId,
    'StudyX Notifications',
    channelDescription:
        'Study reminders and progress notifications',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  const details = NotificationDetails(
    android: androidDetails,
  );

  final id =
      DateTime.now().millisecondsSinceEpoch.remainder(2147483647);

  await _notifications.show(
    id,
    title,
    body,
    details,
  );
}

Future<void> platformSchedule({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledDate,
}) async {
  if (!_initialized) {
    await platformInitialize();
  }

  if (!scheduledDate.isAfter(DateTime.now())) {
    return;
  }

  if (Platform.isWindows) {
    // Windows scheduling is handled differently by the plugin.
    // Skip here for now rather than crashing the application.
    return;
  }

  const androidDetails = AndroidNotificationDetails(
    _channelId,
    'StudyX Notifications',
    channelDescription:
        'Study reminders and progress notifications',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  const details = NotificationDetails(
    android: androidDetails,
  );

  final scheduledTzDate =
      tz.TZDateTime.from(
    scheduledDate,
    tz.local,
  );

  await _notifications.zonedSchedule(
    id,
    title,
    body,
    scheduledTzDate,
    details,
    androidScheduleMode:
        AndroidScheduleMode.inexactAllowWhileIdle,
  );
}

Future<void> platformCancelAllScheduled() async {
  if (!_initialized) {
    await platformInitialize();
  }

  await _notifications.cancelAll();
}
const int _studySessionNotificationId = 7301;

Future<void> platformShowStudySessionNotification({
  required String body,
}) async {
  if (!_initialized) {
    await platformInitialize();
  }

  if (!Platform.isAndroid) return;

  const androidDetails = AndroidNotificationDetails(
    'studyx_active_session',
    'Active study session',
    channelDescription:
        'Shows when a StudyX study session is running',
    importance: Importance.low,
    priority: Priority.low,
    ongoing: true,
    autoCancel: false,
    onlyAlertOnce: true,
    category: AndroidNotificationCategory.service,
  );

  const details = NotificationDetails(android: androidDetails);

  await _notifications.show(
    _studySessionNotificationId,
    'StudyX — Study session running',
    body,
    details,
  );
}

Future<void> platformCancelStudySessionNotification() async {
  if (!_initialized) {
    await platformInitialize();
  }

  await _notifications.cancel(_studySessionNotificationId);
}