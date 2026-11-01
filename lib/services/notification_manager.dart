import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';
import '../providers/task_provider.dart';
import '../providers/study_session_provider.dart';
import '../providers/user_provider.dart';
import '../providers/syllabus_provider.dart';

class NotificationManager {
  NotificationManager._();

  static final NotificationManager instance =
      NotificationManager._();

  Timer? _timer;

  bool _morningSent = false;
  bool _taskSent = false;
  bool _revisionSent = false;
  bool _streakSent = false;
  bool _goalSent = false;

  void start({
    required SharedPreferences prefs,
    required TaskProvider taskProvider,
    required StudySessionProvider studySessionProvider,
    required UserProvider userProvider,
    required SyllabusProvider syllabusProvider,
  }) {
    stop();

    // Check immediately.
    _check(
      prefs: prefs,
      taskProvider: taskProvider,
      studySessionProvider: studySessionProvider,
      userProvider: userProvider,
      syllabusProvider: syllabusProvider,
    );

    // Check every 60 seconds while StudyX is open.
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        _check(
          prefs: prefs,
          taskProvider: taskProvider,
          studySessionProvider: studySessionProvider,
          userProvider: userProvider,
          syllabusProvider: syllabusProvider,
        );
      },
    );
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _check({
    required SharedPreferences prefs,
    required TaskProvider taskProvider,
    required StudySessionProvider studySessionProvider,
    required UserProvider userProvider,
    required SyllabusProvider syllabusProvider,
  }) async {
    if (!NotificationService.instance.isGranted) {
      return;
    }

    final now = DateTime.now();

    await _morningNotification(
      prefs,
      now,
      userProvider,
    );

    await _taskNotification(
      prefs,
      now,
      taskProvider,
    );

    await _revisionNotification(
      prefs,
      now,
      syllabusProvider,
    );

    await _goalNotification(
      prefs,
      now,
      studySessionProvider,
      userProvider,
    );
  }

  Future<void> _morningNotification(
    SharedPreferences prefs,
    DateTime now,
    UserProvider userProvider,
  ) async {
    if (now.hour < 7 || now.hour >= 11) return;

    final key = _dateKey('morning', now);

    if (prefs.getBool(key) == true) return;

    final name =
        userProvider.name.isEmpty ? 'there' : userProvider.name;

    NotificationService.instance.show(
      title: '🌅 Good Morning, $name!',
      body:
          'Your StudyX plan is ready. Let\'s make today count. 🎯',
    );

    await prefs.setBool(key, true);
  }

  Future<void> _taskNotification(
    SharedPreferences prefs,
    DateTime now,
    TaskProvider taskProvider,
  ) async {
    final pending = taskProvider.pendingTasks;

    if (pending.isEmpty) return;

    final key = _dateKey('tasks', now);

    if (prefs.getBool(key) == true) return;

    final firstTask = pending.first;

    NotificationService.instance.show(
      title: '📚 Today\'s Tasks',
      body:
          'You have ${pending.length} tasks remaining today. '
          'Start with: ${firstTask.title}.',
    );

    await prefs.setBool(key, true);
  }

  Future<void> _revisionNotification(
    SharedPreferences prefs,
    DateTime now,
    SyllabusProvider syllabusProvider,
  ) async {
    final dueChapters = syllabusProvider.getChaptersForRevision();
    final revisionCount = dueChapters.length;

    if (revisionCount == 0) return;

    final key = _dateKey('revision', now);

    if (prefs.getBool(key) == true) return;

    NotificationService.instance.show(
      title: '🧠 Revision Due',
      body:
          'You have $revisionCount ${revisionCount == 1 ? 'chapter' : 'chapters'} scheduled for revision today.',
    );

    await prefs.setBool(key, true);
  }

  Future<void> _goalNotification(
    SharedPreferences prefs,
    DateTime now,
    StudySessionProvider studySessionProvider,
    UserProvider userProvider,
  ) async {
    final dailyTarget = userProvider.dailyHours;

    if (dailyTarget <= 0) return;

    final todayHours =
        studySessionProvider.hoursForDate(now);

    final remaining = dailyTarget - todayHours;

    if (remaining <= 0) return;

    // Only notify later in the day.
    if (now.hour < 17) return;

    final key = _dateKey('goal', now);

    if (prefs.getBool(key) == true) return;

    NotificationService.instance.show(
      title: '🎯 Study Goal',
      body:
          'You have ${remaining.toStringAsFixed(1)} hours left '
          'to reach today\'s study target.',
    );

    await prefs.setBool(key, true);
  }

  String _dateKey(String type, DateTime date) {
    return 'studyx_notification_${type}_'
        '${date.year}_${date.month}_${date.day}';
  }
}