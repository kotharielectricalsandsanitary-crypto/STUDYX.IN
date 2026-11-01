
export 'notification_service_stub.dart'
    if (dart.library.html) 'notification_service_web.dart'
    if (dart.library.io) 'notification_service_mobile.dart';

import 'notification_service_stub.dart'
    if (dart.library.html) 'notification_service_web.dart'
    if (dart.library.io) 'notification_service_mobile.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  bool _initialized = false;
  bool _granted = false;

  bool get isGranted => _granted;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _granted = await platformInitialize();
    } catch (_) {
      _granted = false;
    }

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    if (!_initialized) await initialize();

    try {
      _granted = await platformRequestPermission();
    } catch (_) {
      _granted = false;
    }

    return _granted;
  }

  Future<void> show({
    required String title,
    required String body,
  }) async {
    if (!_initialized) await initialize();

    if (!_granted) {
      _granted = await requestPermission();
    }

    if (!_granted) return;

    try {
      await platformShow(title: title, body: body);
    } catch (_) {}
  }

  /// Shows or updates the single active-study notification.
  Future<void> showStudySessionNotification({
    required String body,
  }) async {
    if (!_initialized) await initialize();

    if (!_granted) {
      _granted = await requestPermission();
    }

    if (!_granted) return;

    try {
      await platformShowStudySessionNotification(body: body);
    } catch (_) {}
  }

  /// Dismisses only the study-session notification.
  Future<void> cancelStudySessionNotification() async {
    try {
      await platformCancelStudySessionNotification();
    } catch (_) {}
  }

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (!_initialized) await initialize();

    if (!_granted) {
      _granted = await requestPermission();
    }

    if (!_granted) return;

    try {
      await platformSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
      );
    } catch (_) {}
  }

  Future<void> cancelAllScheduled() async {
    try {
      await platformCancelAllScheduled();
    } catch (_) {}
  }

  Future<void> showTestNotification() async {
    await show(
      title: 'StudyX Test',
      body: 'Notifications are working correctly.',
    );
  }
}
