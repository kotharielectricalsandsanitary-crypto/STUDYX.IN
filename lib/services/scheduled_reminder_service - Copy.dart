import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Android scheduled local notifications for StudyX.
class ScheduledReminderService {
  ScheduledReminderService._();
  static final ScheduledReminderService instance = ScheduledReminderService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    final localZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localZone.name));
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings);
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    _initialized = true;
  }

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required bool repeatDaily,
  }) async {
    await initialize();
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) scheduled = scheduled.add(const Duration(days: 1));

    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    var mode = AndroidScheduleMode.inexactAllowWhileIdle;
    try {
      if (await android?.requestExactAlarmsPermission() == true) {
        mode = AndroidScheduleMode.exactAllowWhileIdle;
      }
    } catch (_) {
      mode = AndroidScheduleMode.inexactAllowWhileIdle;
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'studyx_study_reminders', 'Study reminders',
        channelDescription: 'Reminders scheduled by StudyX',
        importance: Importance.max, priority: Priority.high, enableVibration: true,
      ),
    );
    await _plugin.zonedSchedule(
      id, title, body, scheduled, details,
      androidScheduleMode: mode,
      matchDateTimeComponents: repeatDaily ? DateTimeComponents.time : null,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);

  Future<void> showTestNotification() async {
    await initialize();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'studyx_study_reminders', 'Study reminders',
        channelDescription: 'Reminders scheduled by StudyX',
        importance: Importance.max, priority: Priority.high,
      ),
    );
    await _plugin.show(987654, 'StudyX notifications are working',
        'Your phone can display StudyX reminders.', details);
  }
}
