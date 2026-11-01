import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/task_provider.dart';
import '../providers/study_session_provider.dart';
import '../providers/user_provider.dart';
import '../providers/syllabus_provider.dart';
import 'notification_service.dart';

class NotificationChecker {
  NotificationChecker._();

  static final NotificationChecker instance =
      NotificationChecker._();

  Timer? _timer;

  bool _running = false;

  TaskProvider? _taskProvider;
  StudySessionProvider? _studySessionProvider;
  UserProvider? _userProvider;
  SyllabusProvider? _syllabusProvider;

  /// Start automatic notification checking.
  ///
  /// This runs only while StudyX is open.
  void start({
    required TaskProvider taskProvider,
    required StudySessionProvider studySessionProvider,
    required UserProvider userProvider,
    required SyllabusProvider syllabusProvider,
  }) {
    if (_running) return;

    _running = true;

    _taskProvider = taskProvider;
    _studySessionProvider = studySessionProvider;
    _userProvider = userProvider;
    _syllabusProvider = syllabusProvider;

    // Check immediately when started.
    checkNow();

    // Then check every 1 minute while StudyX is open.
    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        checkNow();
      },
    );

    debugPrint('StudyX Notification Checker started.');
  }

  /// Stop notification checking.
  void stop() {
    _timer?.cancel();
    _timer = null;

    _running = false;

    debugPrint('StudyX Notification Checker stopped.');
  }

  /// Manually run all notification checks.
  Future<void> checkNow() async {
    if (!_running) return;

    final notificationService =
        NotificationService.instance;

    if (!notificationService.isGranted) {
      return;
    }

    final taskProvider = _taskProvider;
    final studySessionProvider =
        _studySessionProvider;
    final userProvider = _userProvider;
    final syllabusProvider = _syllabusProvider;

    if (taskProvider == null ||
        studySessionProvider == null ||
        userProvider == null ||
        syllabusProvider == null) {
      return;
    }

    final prefs =
        await SharedPreferences.getInstance();

    final now = DateTime.now();

    await _checkMorning(
      prefs: prefs,
      now: now,
      userProvider: userProvider,
    );

    await _checkTasks(
      prefs: prefs,
      now: now,
      taskProvider: taskProvider,
    );

    await _checkUpcomingTasks(
      prefs: prefs,
      now: now,
      taskProvider: taskProvider,
    );

    await _checkRevision(
      prefs: prefs,
      now: now,
      syllabusProvider: syllabusProvider,
    );

    await _checkDailyGoal(
      prefs: prefs,
      now: now,
      studySessionProvider: studySessionProvider,
      userProvider: userProvider,
    );

    await _checkStreak(
      prefs: prefs,
      now: now,
      studySessionProvider: studySessionProvider,
    );

    await _checkAchievement(
      prefs: prefs,
      now: now,
      studySessionProvider: studySessionProvider,
    );

    await _checkWeeklyReport(
      prefs: prefs,
      now: now,
      taskProvider: taskProvider,
      studySessionProvider: studySessionProvider,
    );
  }

  // ─────────────────────────────────────────────
  // 🌅 MORNING
  // ─────────────────────────────────────────────

  Future<void> _checkMorning({
    required SharedPreferences prefs,
    required DateTime now,
    required UserProvider userProvider,
  }) async {
    // Only send between 7:00 AM and 11:00 AM.
    if (now.hour < 7 || now.hour >= 11) {
      return;
    }

    final todayKey = _dateKey(now);

    final alreadySent =
        prefs.getString('morning_notification_date');

    if (alreadySent == todayKey) {
      return;
    }

    final name = userProvider.name.trim();

    final displayName =
        name.isEmpty ? 'there' : name;

    NotificationService.instance.show(
      title: '🌅 Good Morning, $displayName!',
      body:
          'Your StudyX plan is ready. Let’s make today count. 🎯',
    );

    await prefs.setString(
      'morning_notification_date',
      todayKey,
    );
  }

  // ─────────────────────────────────────────────
  // 📚 TASKS
  // ─────────────────────────────────────────────

  Future<void> _checkTasks({
    required SharedPreferences prefs,
    required DateTime now,
    required TaskProvider taskProvider,
  }) async {
    final todayTasks = taskProvider.tasks
        .where(
          (task) =>
              _isSameDate(task.deadline, now),
        )
        .toList();

    final pending = todayTasks
        .where((task) => !task.isCompleted)
        .toList();

    if (pending.isEmpty) {
      return;
    }

    final todayKey = _dateKey(now);

    final lastNotification =
        prefs.getString('task_notification_date');

    if (lastNotification == todayKey) {
      return;
    }

    final firstTask = pending.first;

    NotificationService.instance.show(
      title: '📚 Today’s Tasks',
      body:
          'You have ${pending.length} task${pending.length == 1 ? '' : 's'} remaining today. '
          'Start with: ${firstTask.title}.',
    );

    await prefs.setString(
      'task_notification_date',
      todayKey,
    );
  }

  // ─────────────────────────────────────────────
  // ⏰ UPCOMING TASK
  // ─────────────────────────────────────────────

  Future<void> _checkUpcomingTasks({
    required SharedPreferences prefs,
    required DateTime now,
    required TaskProvider taskProvider,
  }) async {
    final pending =
        taskProvider.pendingTasks;

    for (final task in pending) {
      final difference =
          task.deadline.difference(now);

      // Notify approximately 15 minutes before task.
      if (difference.inMinutes >= 14 &&
          difference.inMinutes <= 15) {
        final key =
            'upcoming_${task.id}_${_dateKey(now)}';

        if (prefs.getBool(key) == true) {
          continue;
        }

        NotificationService.instance.show(
          title: '⏰ Upcoming Task',
          body:
              '${task.title} is due in about 15 minutes.',
        );

        await prefs.setBool(key, true);
      }
    }
  }

  // ─────────────────────────────────────────────
  // 🧠 REVISION
  // ─────────────────────────────────────────────

  Future<void> _checkRevision({
    required SharedPreferences prefs,
    required DateTime now,
    required SyllabusProvider syllabusProvider,
  }) async {
    final dueChapters = syllabusProvider.getChaptersForRevision();
    final revisionDue = dueChapters.length;

    if (revisionDue <= 0) {
      return;
    }

    final todayKey = _dateKey(now);

    final lastNotification =
        prefs.getString(
      'revision_notification_date',
    );

    if (lastNotification == todayKey) {
      return;
    }

    NotificationService.instance.show(
      title: '🧠 Revision Due',
      body:
          'You have $revisionDue chapter${revisionDue == 1 ? '' : 's'} scheduled for revision today.',
    );

    await prefs.setString(
      'revision_notification_date',
      todayKey,
    );
  }

  // ─────────────────────────────────────────────
  // 🎯 DAILY GOAL
  // ─────────────────────────────────────────────

  Future<void> _checkDailyGoal({
    required SharedPreferences prefs,
    required DateTime now,
    required StudySessionProvider studySessionProvider,
    required UserProvider userProvider,
  }) async {
    final target = userProvider.dailyHours;

    if (target <= 0) {
      return;
    }

    final studied =
        studySessionProvider.hoursForDate(now);

    final remaining = target - studied;

    if (remaining <= 0) {
      return;
    }

    // Only remind after 5 PM.
    if (now.hour < 17) {
      return;
    }

    final todayKey = _dateKey(now);

    final lastNotification =
        prefs.getString(
      'daily_goal_notification_date',
    );

    if (lastNotification == todayKey) {
      return;
    }

    final roundedRemaining =
        remaining < 0.1 ? 0.1 : remaining;

    NotificationService.instance.show(
      title: '🎯 Daily Study Goal',
      body:
          'You have ${roundedRemaining.toStringAsFixed(1)} hours left to reach today’s study target.',
    );

    await prefs.setString(
      'daily_goal_notification_date',
      todayKey,
    );
  }

  // ─────────────────────────────────────────────
  // 🔥 STREAK
  // ─────────────────────────────────────────────

  Future<void> _checkStreak({
    required SharedPreferences prefs,
    required DateTime now,
    required StudySessionProvider studySessionProvider,
  }) async {
    final streak =
        _calculateStreak(
      studySessionProvider,
      now,
    );

    if (streak <= 0) {
      return;
    }

    final todayKey = _dateKey(now);

    final lastNotification =
        prefs.getString(
      'streak_notification_date',
    );

    if (lastNotification == todayKey) {
      return;
    }

    NotificationService.instance.show(
      title: '🔥 You’re on a $streak-day streak!',
      body:
          'Keep it going today. Open StudyX and study.',
    );

    await prefs.setString(
      'streak_notification_date',
      todayKey,
    );
  }

  // ─────────────────────────────────────────────
  // 🏆 ACHIEVEMENT
  // ─────────────────────────────────────────────

  Future<void> _checkAchievement({
    required SharedPreferences prefs,
    required DateTime now,
    required StudySessionProvider studySessionProvider,
  }) async {
    final sessions =
        studySessionProvider.sessions.length;

    if (sessions <= 0) {
      return;
    }

    final achievements = <int>[
      10,
      25,
      50,
      100,
    ];

    for (final achievement in achievements) {
      if (sessions < achievement) {
        continue;
      }

      final key =
          'achievement_$achievement';

      final alreadyShown =
          prefs.getBool(key) ?? false;

      if (alreadyShown) {
        continue;
      }

      NotificationService.instance.show(
        title: '🏆 Achievement Unlocked!',
        body:
            'You’ve completed $achievement study sessions.',
      );

      await prefs.setBool(key, true);

      break;
    }
  }

  // ─────────────────────────────────────────────
  // 📈 WEEKLY REPORT
  // ─────────────────────────────────────────────

  Future<void> _checkWeeklyReport({
    required SharedPreferences prefs,
    required DateTime now,
    required TaskProvider taskProvider,
    required StudySessionProvider studySessionProvider,
  }) async {
    // Sunday evening.
    if (now.weekday != DateTime.sunday ||
        now.hour < 18) {
      return;
    }

    final weekKey = _dateKey(now);

    final alreadySent =
        prefs.getString(
      'weekly_report_notification_date',
    );

    if (alreadySent == weekKey) {
      return;
    }

    final weekStart =
        now.subtract(
      Duration(days: now.weekday - 1),
    );

    final weeklySessions =
        studySessionProvider.sessions.where(
      (session) {
        return session.date.isAfter(
              weekStart.subtract(
                const Duration(seconds: 1),
              ),
            ) &&
            session.date.isBefore(
              now.add(
                const Duration(days: 1),
              ),
            );
      },
    ).toList();

    final weeklySeconds =
        weeklySessions.fold<int>(
      0,
      (sum, session) =>
          sum + session.seconds,
    );

    final weeklyHours =
        weeklySeconds / 3600;

    final completedTasks =
        taskProvider.tasks.where(
      (task) {
        return task.isCompleted &&
            task.deadline.isAfter(
              weekStart.subtract(
                const Duration(seconds: 1),
              ),
            );
      },
    ).length;

    NotificationService.instance.show(
      title: '📈 Your Weekly Report',
      body:
          'Study time: ${_formatHours(weeklyHours)} • '
          'Tasks completed: $completedTasks',
    );

    await prefs.setString(
      'weekly_report_notification_date',
      weekKey,
    );
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  String _dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  bool _isSameDate(
    DateTime a,
    DateTime b,
  ) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  int _calculateStreak(
    StudySessionProvider provider,
    DateTime now,
  ) {
    final studyDays = <String>{};

    for (final session in provider.sessions) {
      if (session.seconds <= 0) {
        continue;
      }

      studyDays.add(
        _dateKey(session.date),
      );
    }

    int streak = 0;

    DateTime day = DateTime(
      now.year,
      now.month,
      now.day,
    );

    // If the user hasn't studied today,
    // start checking from yesterday.
    if (!studyDays.contains(
      _dateKey(day),
    )) {
      day = day.subtract(
        const Duration(days: 1),
      );
    }

    while (studyDays.contains(
      _dateKey(day),
    )) {
      streak++;

      day = day.subtract(
        const Duration(days: 1),
      );
    }

    return streak;
  }

  String _formatHours(double hours) {
    final totalMinutes =
        (hours * 60).round();

    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;

    if (h == 0) {
      return '${m}m';
    }

    if (m == 0) {
      return '${h}h';
    }

    return '${h}h ${m}m';
  }
}