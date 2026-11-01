import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/planner_session_model.dart';

class PlannerProvider extends ChangeNotifier {
  static const String _storageKey = 'studyx_manual_planner_v1';

  List<PlannerSessionModel> _sessions = [];

  bool _isLoading = true;
  bool _disposed = false;

  Future<void>? _loadFuture;

  PlannerProvider() {
    unawaited(loadSessions());
  }

  // --------------------------------------------------
  // GETTERS
  // --------------------------------------------------

  bool get isLoading => _isLoading;

  List<PlannerSessionModel> get sessions {
    return List.unmodifiable(_sortedSessions(_sessions));
  }

  List<PlannerSessionModel> get pendingSessions {
    return List.unmodifiable(
      _sortedSessions(
        _sessions.where((session) => !session.isCompleted).toList(),
      ),
    );
  }

  List<PlannerSessionModel> get completedSessions {
    return List.unmodifiable(
      _sortedSessions(
        _sessions.where((session) => session.isCompleted).toList(),
      ),
    );
  }

  int get totalSessions => _sessions.length;

  int get completedCount =>
      _sessions.where((session) => session.isCompleted).length;

  int get pendingCount =>
      _sessions.where((session) => !session.isCompleted).length;

  double get completionRate {
    if (_sessions.isEmpty) return 0;

    return completedCount / totalSessions;
  }

  // --------------------------------------------------
  // DATE HELPERS
  // --------------------------------------------------

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  List<PlannerSessionModel> _sortedSessions(
    List<PlannerSessionModel> input,
  ) {
    final result = List<PlannerSessionModel>.from(input);

    result.sort((a, b) {
      final dateComparison =
          a.plannedDate.compareTo(b.plannedDate);

      if (dateComparison != 0) {
        return dateComparison;
      }

      final timeComparison =
          a.startMinutes.compareTo(b.startMinutes);

      if (timeComparison != 0) {
        return timeComparison;
      }

      return a.createdAt.compareTo(b.createdAt);
    });

    return result;
  }

  // --------------------------------------------------
  // LOAD AND SAVE
  // --------------------------------------------------

  Future<void> loadSessions() {
    if (_loadFuture != null) {
      return _loadFuture!;
    }

    _loadFuture = _loadSessionsInternal();
    return _loadFuture!;
  }

  Future<void> _loadSessionsInternal() async {
    _isLoading = true;
    _notifySafely();

    try {
      final preferences = await SharedPreferences.getInstance();
      final savedData = preferences.getString(_storageKey);

      if (savedData != null && savedData.isNotEmpty) {
        final decoded = jsonDecode(savedData);

        if (decoded is List) {
          _sessions = decoded
              .whereType<Map>()
              .map(
                (item) => PlannerSessionModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList();
        }
      }

      // Move unfinished sessions from past dates to today.
      await _carryForwardOverdueSessions(notify: false);
    } catch (error, stackTrace) {
      debugPrint('StudyX Planner load error: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isLoading = false;
      _loadFuture = null;
      _notifySafely();
    }
  }

  Future<void> _saveSessions() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      final encoded = jsonEncode(
        _sessions.map((session) => session.toJson()).toList(),
      );

      final saved = await preferences.setString(
        _storageKey,
        encoded,
      );

      if (!saved) {
        throw Exception('Could not save planner sessions.');
      }
    } catch (error, stackTrace) {
      debugPrint('StudyX Planner save error: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  void _notifySafely() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  // --------------------------------------------------
  // QUERY SESSIONS
  // --------------------------------------------------

  List<PlannerSessionModel> sessionsForDate(DateTime date) {
    return List.unmodifiable(
      _sortedSessions(
        _sessions
            .where(
              (session) => _isSameDate(session.plannedDate, date),
            )
            .toList(),
      ),
    );
  }

  List<PlannerSessionModel> pendingSessionsForDate(
    DateTime date,
  ) {
    return List.unmodifiable(
      _sortedSessions(
        _sessions
            .where(
              (session) =>
                  _isSameDate(session.plannedDate, date) &&
                  !session.isCompleted,
            )
            .toList(),
      ),
    );
  }

  List<PlannerSessionModel> completedSessionsForDate(
    DateTime date,
  ) {
    return List.unmodifiable(
      _sortedSessions(
        _sessions
            .where(
              (session) =>
                  _isSameDate(session.plannedDate, date) &&
                  session.isCompleted,
            )
            .toList(),
      ),
    );
  }

  PlannerSessionModel? getSessionById(String id) {
    for (final session in _sessions) {
      if (session.id == id) {
        return session;
      }
    }

    return null;
  }

  int plannedMinutesForDate(DateTime date) {
    return _sessions
        .where(
          (session) => _isSameDate(session.plannedDate, date),
        )
        .fold<int>(
          0,
          (total, session) => total + session.durationMinutes,
        );
  }

  int completedMinutesForDate(DateTime date) {
    return _sessions
        .where(
          (session) =>
              _isSameDate(session.plannedDate, date) &&
              session.isCompleted,
        )
        .fold<int>(
          0,
          (total, session) => total + session.durationMinutes,
        );
  }

  double dailyCompletionRate(DateTime date) {
    final daily = sessionsForDate(date);

    if (daily.isEmpty) return 0;

    final completed =
        daily.where((session) => session.isCompleted).length;

    return completed / daily.length;
  }

  // --------------------------------------------------
  // ADD SESSION
  // --------------------------------------------------

  Future<void> addSession(
    PlannerSessionModel session,
  ) async {
    await loadSessions();

    if (session.title.trim().isEmpty) {
      throw ArgumentError('Session title cannot be empty.');
    }

    if (session.durationMinutes <= 0) {
      throw ArgumentError('Duration must be greater than zero.');
    }

    if (session.startMinutes < 0 ||
        session.startMinutes >= 24 * 60) {
      throw ArgumentError(
        'Start time must be within the selected day.',
      );
    }

    if (getSessionById(session.id) != null) {
      throw ArgumentError(
        'A session with this ID already exists.',
      );
    }

    _sessions = [..._sessions, session];

    try {
      await _saveSessions();
    } catch (_) {
      _sessions.removeWhere((item) => item.id == session.id);
      rethrow;
    }

    _notifySafely();
  }

  // --------------------------------------------------
  // UPDATE SESSION
  // --------------------------------------------------

  Future<void> updateSession(
    PlannerSessionModel updatedSession,
  ) async {
    await loadSessions();

    final index = _sessions.indexWhere(
      (session) => session.id == updatedSession.id,
    );

    if (index == -1) {
      throw ArgumentError('Planner session not found.');
    }

    if (updatedSession.title.trim().isEmpty) {
      throw ArgumentError('Session title cannot be empty.');
    }

    if (updatedSession.durationMinutes <= 0) {
      throw ArgumentError('Duration must be greater than zero.');
    }

    final previous = _sessions[index];
    _sessions = List<PlannerSessionModel>.from(_sessions);
    _sessions[index] = updatedSession;

    try {
      await _saveSessions();
    } catch (_) {
      _sessions[index] = previous;
      rethrow;
    }

    _notifySafely();
  }

  // --------------------------------------------------
  // DELETE SESSION
  // --------------------------------------------------

  Future<void> deleteSession(String sessionId) async {
    await loadSessions();

    final previous = List<PlannerSessionModel>.from(_sessions);

    _sessions = _sessions
        .where((session) => session.id != sessionId)
        .toList();

    if (_sessions.length == previous.length) {
      return;
    }

    try {
      await _saveSessions();
    } catch (_) {
      _sessions = previous;
      rethrow;
    }

    _notifySafely();
  }

  // --------------------------------------------------
  // COMPLETE OR REOPEN SESSION
  // --------------------------------------------------

  Future<void> completeSession(String sessionId) async {
    await _setCompletion(sessionId, true);
  }

  Future<void> markIncomplete(String sessionId) async {
    await _setCompletion(sessionId, false);
  }

  Future<void> toggleCompletion(String sessionId) async {
    await loadSessions();

    final session = getSessionById(sessionId);

    if (session == null) {
      throw ArgumentError('Planner session not found.');
    }

    await _setCompletion(sessionId, !session.isCompleted);
  }

  Future<void> _setCompletion(
    String sessionId,
    bool completed,
  ) async {
    await loadSessions();

    final index = _sessions.indexWhere(
      (session) => session.id == sessionId,
    );

    if (index == -1) {
      throw ArgumentError('Planner session not found.');
    }

    final previous = _sessions[index];

    _sessions = List<PlannerSessionModel>.from(_sessions);

    _sessions[index] = previous.copyWith(
      isCompleted: completed,
      completedAt: completed ? DateTime.now() : null,
      clearCompletedAt: !completed,
    );

    try {
      await _saveSessions();
    } catch (_) {
      _sessions[index] = previous;
      rethrow;
    }

    _notifySafely();
  }

  // --------------------------------------------------
  // AUTOMATIC CARRY-FORWARD
  // --------------------------------------------------

  /// Moves unfinished sessions dated before today to today.
  ///
  /// Completed sessions are never moved.
  /// Running this more than once on the same day does not
  /// repeatedly increment rescheduledCount.
  Future<int> carryForwardOverdueSessions() async {
    await loadSessions();

    return _carryForwardOverdueSessions();
  }

  Future<int> _carryForwardOverdueSessions({
    bool notify = true,
  }) async {
    final today = _dateOnly(DateTime.now());

    final previous = List<PlannerSessionModel>.from(_sessions);
    int movedCount = 0;

    _sessions = _sessions.map((session) {
      if (session.isCompleted ||
          !_dateOnly(session.plannedDate).isBefore(today)) {
        return session;
      }

      movedCount++;

      return session.copyWith(
        plannedDate: today,
        rescheduledCount: session.rescheduledCount + 1,
      );
    }).toList();

    if (movedCount == 0) {
      return 0;
    }

    try {
      await _saveSessions();
    } catch (_) {
      _sessions = previous;
      rethrow;
    }

    if (notify) {
      _notifySafely();
    }

    return movedCount;
  }

  // --------------------------------------------------
  // MANUAL RESCHEDULING
  // --------------------------------------------------

  Future<void> rescheduleSession({
    required String sessionId,
    required DateTime newDate,
    int? newStartMinutes,
  }) async {
    await loadSessions();

    final session = getSessionById(sessionId);

    if (session == null) {
      throw ArgumentError('Planner session not found.');
    }

    await updateSession(
      session.copyWith(
        plannedDate: _dateOnly(newDate),
        startMinutes: newStartMinutes ?? session.startMinutes,
        rescheduledCount: session.rescheduledCount + 1,
      ),
    );
  }

  // --------------------------------------------------
  // CLEANUP
  // --------------------------------------------------

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
