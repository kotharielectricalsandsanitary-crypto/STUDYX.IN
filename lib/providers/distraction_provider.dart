import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/distraction_model.dart';

class DistractionProvider extends ChangeNotifier {
  static const String _appsKey = 'studyx_distraction_apps_v1';
  static const String _limitKey = 'studyx_distraction_limit_v1';
  static const String _dateKey = 'studyx_distraction_date_v1';
  static const String _enabledKey = 'studyx_distraction_blocker_v1';

  final SharedPreferences prefs;

  List<DistractionApp> _apps = [];

  int _dailyLimit = 30;

  bool _blockerEnabled = true;

  DistractionProvider(this.prefs) {
    _load();
  }

  List<DistractionApp> get apps =>
      List.unmodifiable(_apps);

  int get dailyLimit => _dailyLimit;

  bool get blockerEnabled => _blockerEnabled;

  int get totalUsed {
    return _apps.fold(
      0,
      (total, app) => total + app.minutesUsed,
    );
  }

  int get remainingMinutes {
    final remaining = _dailyLimit - totalUsed;
    return remaining < 0 ? 0 : remaining;
  }

  double get progress {
    if (_dailyLimit <= 0) return 0;

    final value = totalUsed / _dailyLimit;

    if (value > 1) return 1;

    return value;
  }

  bool get limitReached =>
      totalUsed >= _dailyLimit;

  void _load() {
    _resetIfNewDay();

    final raw = prefs.getString(_appsKey);

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);

        if (decoded is List) {
          _apps = decoded
              .whereType<Map>()
              .map(
                (item) => DistractionApp.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList();
        }
      } catch (_) {
        _apps = [];
      }
    }

    if (_apps.isEmpty) {
      _apps = const [
        DistractionApp(
          id: 'instagram',
          name: 'Instagram',
          emoji: '📸',
        ),
        DistractionApp(
          id: 'snapchat',
          name: 'Snapchat',
          emoji: '👻',
        ),
        DistractionApp(
          id: 'youtube',
          name: 'YouTube',
          emoji: '▶️',
        ),
      ];
    }

    _dailyLimit =
        prefs.getInt(_limitKey) ?? 30;

    _blockerEnabled =
        prefs.getBool(_enabledKey) ?? true;

    notifyListeners();
  }

  void _resetIfNewDay() {
    final today = _dateOnly(DateTime.now());

    final savedDate =
        prefs.getString(_dateKey);

    if (savedDate == today) return;

    prefs.setString(
      _dateKey,
      today,
    );

    final raw = prefs.getString(_appsKey);

    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);

      if (decoded is List) {
        _apps = decoded
            .whereType<Map>()
            .map(
              (item) => DistractionApp.fromJson(
                Map<String, dynamic>.from(item),
              ).copyWith(
                minutesUsed: 0,
              ),
            )
            .toList();

        _save();
      }
    } catch (_) {}
  }

  String _dateOnly(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    await prefs.setString(
      _appsKey,
      jsonEncode(
        _apps.map((app) => app.toJson()).toList(),
      ),
    );

    await prefs.setInt(
      _limitKey,
      _dailyLimit,
    );

    await prefs.setBool(
      _enabledKey,
      _blockerEnabled,
    );

    await prefs.setString(
      _dateKey,
      _dateOnly(DateTime.now()),
    );
  }

  Future<void> setDailyLimit(int minutes) async {
    if (minutes < 1) return;

    _dailyLimit = minutes;

    await _save();

    notifyListeners();
  }

  Future<void> setBlockerEnabled(bool value) async {
    _blockerEnabled = value;

    await _save();

    notifyListeners();
  }

  Future<void> addUsage({
    required String appId,
    required int minutes,
  }) async {
    if (minutes <= 0) return;

    if (limitReached) return;

    final index = _apps.indexWhere(
      (app) => app.id == appId,
    );

    if (index == -1) return;

    final app = _apps[index];

    final allowed =
        _dailyLimit - totalUsed;

    final actualMinutes =
        minutes > allowed ? allowed : minutes;

    if (actualMinutes <= 0) return;

    _apps = [..._apps];

    _apps[index] = app.copyWith(
      minutesUsed:
          app.minutesUsed + actualMinutes,
    );

    await _save();

    notifyListeners();
  }

  Future<void> toggleApp(String appId) async {
    final index = _apps.indexWhere(
      (app) => app.id == appId,
    );

    if (index == -1) return;

    final app = _apps[index];

    _apps = [..._apps];

    _apps[index] = app.copyWith(
      enabled: !app.enabled,
    );

    await _save();

    notifyListeners();
  }

  Future<void> resetToday() async {
    _apps = _apps
        .map(
          (app) => app.copyWith(
            minutesUsed: 0,
          ),
        )
        .toList();

    await _save();

    notifyListeners();
  }
}
