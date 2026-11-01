import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DistractionBlockerProvider extends ChangeNotifier {
  static const String _enabledKey = 'distraction_blocker_enabled';
  static const String _limitKey = 'distraction_daily_limit';
  static const String _usedKey = 'distraction_used_seconds';
  static const String _dateKey = 'distraction_last_date';

  final SharedPreferences prefs;

  Timer? _timer;

  bool _enabled = false;
  int _dailyLimitMinutes = 30;
  int _usedSeconds = 0;

  DistractionBlockerProvider(this.prefs) {
    _load();
  }

  bool get enabled => _enabled;

  int get dailyLimitMinutes => _dailyLimitMinutes;

  int get usedSeconds => _usedSeconds;

  int get limitSeconds => _dailyLimitMinutes * 60;

  int get remainingSeconds {
    final remaining = limitSeconds - _usedSeconds;
    return remaining < 0 ? 0 : remaining;
  }

  double get progress {
    if (limitSeconds <= 0) return 0;

    final value = _usedSeconds / limitSeconds;

    if (value > 1) return 1;

    return value;
  }

  bool get isBlocked => _enabled && remainingSeconds <= 0;

  String get remainingText {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String get usedText {
    final minutes = _usedSeconds ~/ 60;
    final seconds = _usedSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // ------------------------------------------------------------
  // LOAD
  // ------------------------------------------------------------

  void _load() {
    _resetIfNewDay();

    _enabled =
        prefs.getBool(_enabledKey) ?? false;

    _dailyLimitMinutes =
        prefs.getInt(_limitKey) ?? 30;

    _usedSeconds =
        prefs.getInt(_usedKey) ?? 0;

    notifyListeners();
  }

  // ------------------------------------------------------------
  // NEW DAY RESET
  // ------------------------------------------------------------

  void _resetIfNewDay() {
    final today = _dateString(DateTime.now());

    final savedDate =
        prefs.getString(_dateKey);

    if (savedDate != today) {
      prefs.setInt(_usedKey, 0);
      prefs.setString(_dateKey, today);
    }
  }

  String _dateString(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // ------------------------------------------------------------
  // ENABLE / DISABLE
  // ------------------------------------------------------------

  Future<void> setEnabled(bool value) async {
    _enabled = value;

    await prefs.setBool(
      _enabledKey,
      value,
    );

    if (value) {
      startTracking();
    } else {
      stopTracking();
    }

    notifyListeners();
  }

  // ------------------------------------------------------------
  // DAILY LIMIT
  // ------------------------------------------------------------

  Future<void> setDailyLimit(int minutes) async {
    if (minutes < 20) {
      minutes = 20;
    }

    if (minutes > 40) {
      minutes = 40;
    }

    _dailyLimitMinutes = minutes;

    await prefs.setInt(
      _limitKey,
      minutes,
    );

    notifyListeners();
  }

  // ------------------------------------------------------------
  // START TRACKING
  // ------------------------------------------------------------

  void startTracking() {
    if (!_enabled) return;

    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (isBlocked) {
          stopTracking();
          return;
        }

        _usedSeconds++;

        prefs.setInt(
          _usedKey,
          _usedSeconds,
        );

        notifyListeners();

        if (isBlocked) {
          stopTracking();
        }
      },
    );
  }

  // ------------------------------------------------------------
  // STOP TRACKING
  // ------------------------------------------------------------

  void stopTracking() {
    _timer?.cancel();
    _timer = null;
  }

  // ------------------------------------------------------------
  // MANUAL RESET
  // ------------------------------------------------------------

  Future<void> resetToday() async {
    _usedSeconds = 0;

    await prefs.setInt(
      _usedKey,
      0,
    );

    await prefs.setString(
      _dateKey,
      _dateString(DateTime.now()),
    );

    notifyListeners();
  }

  // ------------------------------------------------------------
  // CLEANUP
  // ------------------------------------------------------------

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}