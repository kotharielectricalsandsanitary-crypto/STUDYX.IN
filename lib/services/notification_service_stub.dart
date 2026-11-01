Future<bool> platformInitialize() async {
  return false;
}

Future<bool> platformRequestPermission() async {
  return false;
}

Future<void> platformShow({
  required String title,
  required String body,
}) async {}

Future<void> platformSchedule({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledDate,
}) async {}

Future<void> platformCancelAllScheduled() async {}
Future<void> platformShowStudySessionNotification({
  required String body,
}) async {}

Future<void> platformCancelStudySessionNotification() async {}