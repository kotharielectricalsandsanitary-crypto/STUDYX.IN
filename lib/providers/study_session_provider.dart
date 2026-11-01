import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudySession {
  final String id;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final int durationInSeconds;

  const StudySession({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.durationInSeconds,
  });

  // Compatibility getter
  int get seconds => durationInSeconds;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationInSeconds': durationInSeconds,
    };
  }

  factory StudySession.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();

    final date =
        DateTime.tryParse(json['date']?.toString() ?? '') ?? now;

    final startTime =
        DateTime.tryParse(json['startTime']?.toString() ?? '') ?? date;

    final endTime =
        DateTime.tryParse(json['endTime']?.toString() ?? '') ?? date;

    int parseSeconds() {
      final value = json['durationInSeconds'];

      if (value is int) return value;

      if (value is num) return value.toInt();

      // Compatibility with the old format.
      final oldValue = json['seconds'];

      if (oldValue is int) return oldValue;

      if (oldValue is num) return oldValue.toInt();

      return int.tryParse(oldValue?.toString() ?? '') ?? 0;
    }

    return StudySession(
      id: json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      date: date,
      startTime: startTime,
      endTime: endTime,
      durationInSeconds: parseSeconds(),
    );
  }
}

class StudySessionProvider extends ChangeNotifier {
  final SharedPreferences prefs;

  StudySessionProvider(this.prefs);

  static const String _key = 'study_sessions';

  final List<StudySession> _sessions = [];

  Timer? _timer;

  int _elapsedSeconds = 0;

  DateTime? _sessionStartTime;

  bool _isRunning = false;

  bool _isPaused = false;

  // ============================================================
  // SESSION HISTORY
  // ============================================================

  List<StudySession> get sessions => List.unmodifiable(_sessions);

  List<StudySession> get recentSessions {
    final result = [..._sessions];

    result.sort(
      (a, b) => b.date.compareTo(a.date),
    );

    return List.unmodifiable(result);
  }

  // ============================================================
  // TIMER STATE
  // ============================================================

  bool get isRunning => _isRunning;

  bool get isPaused => _isPaused;

  int get elapsedSeconds => _elapsedSeconds;

  DateTime? get sessionStartTime => _sessionStartTime;

  String get formattedTime {
    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;
    final seconds = _elapsedSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // START TIMER
  // ============================================================

  void startTimer() {
    if (_isRunning) return;

    if (_sessionStartTime == null) {
      _sessionStartTime = DateTime.now().subtract(
        Duration(seconds: _elapsedSeconds),
      );
    }

    _isRunning = true;
    _isPaused = false;

    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        _elapsedSeconds++;
        notifyListeners();
      },
    );

    notifyListeners();
  }

  // ============================================================
  // PAUSE TIMER
  // ============================================================

  void pauseTimer() {
    if (!_isRunning) return;

    _timer?.cancel();
    _timer = null;

    _isRunning = false;
    _isPaused = true;

    notifyListeners();
  }

  // ============================================================
  // RESET TIMER
  // ============================================================

  void resetTimer() {
    _timer?.cancel();
    _timer = null;

    _elapsedSeconds = 0;
    _sessionStartTime = null;

    _isRunning = false;
    _isPaused = false;

    notifyListeners();
  }

  // ============================================================
  // SAVE CURRENT TIMER SESSION
  // ============================================================

  Future<void> saveCurrentSession() async {
    if (_elapsedSeconds <= 0) return;

    final now = DateTime.now();

    final startTime = _sessionStartTime ??
        now.subtract(
          Duration(seconds: _elapsedSeconds),
        );

    final session = StudySession(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      date: now,
      startTime: startTime,
      endTime: now,
      durationInSeconds: _elapsedSeconds,
    );

    // IMPORTANT:
    // Always ADD the new session.
    // Never replace an existing session from today.
    await addSessionObject(session);

    resetTimer();
  }

  // ============================================================
  // ADD SESSION
  // ============================================================

  Future<void> addSession(int seconds) async {
    if (seconds <= 0) return;

    final now = DateTime.now();

    final session = StudySession(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      date: now,
      startTime: now.subtract(
        Duration(seconds: seconds),
      ),
      endTime: now,
      durationInSeconds: seconds,
    );

    await addSessionObject(session);
  }

  // ============================================================
  // ADD SESSION OBJECT
  //
  // IMPORTANT:
  // MULTIPLE SAVED SESSIONS ARE ALLOWED PER DAY.
  //
  // Example:
  // Session 1 = 30 minutes
  // Session 2 = 20 minutes
  // Session 3 = 15 minutes
  //
  // Today's total = 65 minutes.
  // ============================================================

  Future<void> addSessionObject(
    StudySession session,
  ) async {
    if (session.durationInSeconds <= 0) return;

    // ALWAYS add a new session.
    //
    // DO NOT search for today's existing session.
    // DO NOT replace an old session.
    _sessions.add(session);

    // Keep sessions ordered from oldest to newest.
    _sessions.sort(
      (a, b) => a.date.compareTo(b.date),
    );

    await _save();

    notifyListeners();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> loadSessions() async {
    final saved = prefs.getStringList(_key);

    _sessions.clear();

    if (saved == null || saved.isEmpty) {
      notifyListeners();
      return;
    }

    for (final item in saved) {
      try {
        final decoded = jsonDecode(item);

        if (decoded is Map) {
          final session = StudySession.fromJson(
            Map<String, dynamic>.from(decoded),
          );

          if (session.durationInSeconds > 0) {
            _sessions.add(session);
          }
        }
      } catch (e) {
        debugPrint(
          'StudySession load error: $e',
        );
      }
    }

    // ==========================================================
    // IMPORTANT:
    // DO NOT REMOVE SAME-DAY SESSIONS.
    //
    // Older version of the provider kept only one session per day.
    // That would destroy cumulative study history.
    //
    // Every valid saved session is preserved.
    // ==========================================================

    _sessions.sort(
      (a, b) => a.date.compareTo(b.date),
    );

    // Save normalized data.
    await _save();

    notifyListeners();
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    final data = _sessions
        .map(
          (session) => jsonEncode(
            session.toJson(),
          ),
        )
        .toList();

    await prefs.setStringList(
      _key,
      data,
    );
  }

  // ============================================================
  // TOTAL STUDY TIME
  // ============================================================

  int get totalSeconds {
    return _sessions.fold<int>(
      0,
      (sum, session) =>
          sum + session.durationInSeconds,
    );
  }

  double get totalHours {
    return totalSeconds / 3600;
  }

  // ============================================================
  // TODAY
  // ============================================================

  int get todayStudySeconds {
    return secondsForDate(DateTime.now());
  }

  double get todayStudyHours {
    return todayStudySeconds / 3600;
  }

  int secondsForDate(DateTime date) {
    return _sessions
        .where(
          (session) => _isSameDay(
            session.date,
            date,
          ),
        )
        .fold<int>(
          0,
          (sum, session) =>
              sum + session.durationInSeconds,
        );
  }

  double hoursForDate(DateTime date) {
    return secondsForDate(date) / 3600;
  }

  // ============================================================
  // WEEK
  // ============================================================

  int get weeklyStudySeconds {
    final now = DateTime.now();

    final start = _startOfWeek(now);

    final end = start.add(
      const Duration(days: 7),
    );

    return _sessions
        .where(
          (session) =>
              !session.date.isBefore(start) &&
              session.date.isBefore(end),
        )
        .fold<int>(
          0,
          (sum, session) =>
              sum + session.durationInSeconds,
        );
  }

  double get weeklyStudyHours {
    return weeklyStudySeconds / 3600;
  }

  // ============================================================
  // MONTH
  // ============================================================

  int get monthlyStudySeconds {
    final now = DateTime.now();

    return _sessions
        .where(
          (session) =>
              session.date.year == now.year &&
              session.date.month == now.month,
        )
        .fold<int>(
          0,
          (sum, session) =>
              sum + session.durationInSeconds,
        );
  }

  double get monthlyStudyHours {
    return monthlyStudySeconds / 3600;
  }

  // ============================================================
  // STREAK
  // ============================================================

  int get currentStreak {
    if (_sessions.isEmpty) return 0;

    final studiedDays = _uniqueStudyDays();

    if (studiedDays.isEmpty) return 0;

    final today = _dateOnly(
      DateTime.now(),
    );

    // If today hasn't been studied,
    // allow yesterday to be the latest day.
    DateTime checkDay;

    if (studiedDays.contains(today)) {
      checkDay = today;
    } else {
      final yesterday = today.subtract(
        const Duration(days: 1),
      );

      if (!studiedDays.contains(yesterday)) {
        return 0;
      }

      checkDay = yesterday;
    }

    int streak = 0;

    while (studiedDays.contains(checkDay)) {
      streak++;

      checkDay = checkDay.subtract(
        const Duration(days: 1),
      );
    }

    return streak;
  }

  int get longestStreak {
    final studiedDays = _uniqueStudyDays();

    if (studiedDays.isEmpty) return 0;

    final sortedDays = studiedDays.toList()
      ..sort();

    int longest = 1;
    int current = 1;

    for (int i = 1; i < sortedDays.length; i++) {
      final difference = sortedDays[i].difference(
        sortedDays[i - 1],
      );

      if (difference.inDays == 1) {
        current++;
      } else {
        if (current > longest) {
          longest = current;
        }

        current = 1;
      }
    }

    if (current > longest) {
      longest = current;
    }

    return longest;
  }

  Set<DateTime> _uniqueStudyDays() {
    return _sessions
        .where(
          (session) =>
              session.durationInSeconds > 0,
        )
        .map(
          (session) => _dateOnly(
            session.date,
          ),
        )
        .toSet();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool _isSameDay(
    DateTime a,
    DateTime b,
  ) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  DateTime _dateOnly(
    DateTime date,
  ) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  DateTime _startOfWeek(
    DateTime date,
  ) {
    final clean = _dateOnly(date);

    return clean.subtract(
      Duration(
        days: clean.weekday - DateTime.monday,
      ),
    );
  }

  // ============================================================
  // DELETE SESSION
  // ============================================================

  Future<void> deleteSession(
    String sessionId,
  ) async {
    _sessions.removeWhere(
      (session) => session.id == sessionId,
    );

    await _save();

    notifyListeners();
  }

  // ============================================================
  // CLEAR ALL
  // ============================================================

  Future<void> clearSessions() async {
    _sessions.clear();

    await prefs.remove(_key);

    notifyListeners();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}