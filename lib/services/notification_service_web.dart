import 'dart:html' as html;

bool _initialized = false;
bool _granted = false;

Future<bool> platformInitialize() async {
  if (_initialized) {
    return _granted;
  }

  _initialized = true;

  final permission = html.Notification.permission;

  _granted =
      permission == 'granted';

  return _granted;
}

Future<bool> platformRequestPermission() async {
  if (!_initialized) {
    await platformInitialize();
  }

  if (html.Notification.permission == 'granted') {
    _granted = true;
    return true;
  }

  final result =
      await html.Notification.requestPermission();

  _granted = result == 'granted';

  return _granted;
}

Future<void> platformShow({
  required String title,
  required String body,
}) async {
  if (!_initialized) {
    await platformInitialize();
  }

  if (!_granted) {
    final granted =
        await platformRequestPermission();

    if (!granted) return;
  }

  html.Notification(
    title,
    body: body,
    icon: 'icons/Icon-192.png',
  );
}

Future<void> platformSchedule({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledDate,
}) async {
  // Browser notifications cannot reliably run after the
  // browser/web app is completely closed without Web Push.
  //
  // StudyXNotificationManager handles open-web-app timing.
}

Future<void> platformCancelAllScheduled() async {
  // Nothing persistent to cancel on the basic web implementation.
}
Future<void> platformShowStudySessionNotification({
  required String body,
}) async {
  await platformShow(
    title: 'StudyX — Study session running',
    body: body,
  );
}

Future<void> platformCancelStudySessionNotification() async {}