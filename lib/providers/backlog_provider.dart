import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/backlog_model.dart';

class BacklogProvider extends ChangeNotifier {
  static const String _storageKey = 'studyx_backlog_data_v1';

  static const String _dailyTargetKey = 'studyx_backlog_daily_target';

  // Stores unfinished lectures that must be carried into the next day.
  static const String _carryOverKey = 'studyx_backlog_carry_over';

  // Stores the date on which the carry-over value was last calculated.
  static const String _carryOverDateKey =
      'studyx_backlog_carry_over_date';

  final SharedPreferences _prefs;

  List<BacklogItem> _items = [];

  // Normal daily target selected by the user.
  int _dailyTarget = 3;

  // Unfinished lectures from previous days.
  int _carryOverLectures = 0;

  // Date for which the current carry-over value belongs.
  DateTime? _carryOverDate;

  List<BacklogItem> get items => List.unmodifiable(_items);

  /// Normal target selected by the user.
  ///
  /// Example:
  /// If the user selected 6, this remains 6 even when
  /// today's actual target becomes 8 because of carry-over.
  int get dailyTarget => _dailyTarget;

  /// Unfinished lectures brought from previous days.
  int get carryOverLectures => _carryOverLectures;

  /// Today's actual target.
  ///
  /// Example:
  /// Normal target = 6
  /// Carry-over = 2
  /// Today's target = 8
  int get todayTarget {
    final totalRemaining = remainingLectures;

    if (totalRemaining <= 0) {
      return 0;
    }

    final target = _dailyTarget + _carryOverLectures;

    return target > totalRemaining ? totalRemaining : target;
  }

  BacklogProvider(this._prefs) {
    _load();
  }

  // ============================================================
  // LOAD
  // ============================================================

  void _load() {
    final raw = _prefs.getString(_storageKey);

    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);

        if (decoded is List) {
          _items = decoded
              .whereType<Map>()
              .map(
                (item) => BacklogItem.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList();
        }
      } catch (_) {
        _items = [];
      }
    }

    _dailyTarget = _prefs.getInt(_dailyTargetKey) ?? 3;

    if (_dailyTarget < 1) {
      _dailyTarget = 3;
    }

    if (_dailyTarget > 10) {
      _dailyTarget = 10;
    }

    _carryOverLectures =
        _prefs.getInt(_carryOverKey) ?? 0;

    if (_carryOverLectures < 0) {
      _carryOverLectures = 0;
    }

    final storedDate =
        _prefs.getString(_carryOverDateKey);

    if (storedDate != null && storedDate.isNotEmpty) {
      _carryOverDate = DateTime.tryParse(storedDate);
    }

    _handleNewDay();
  }

  // ============================================================
  // NEW DAY / CARRY FORWARD
  // ============================================================

  void _handleNewDay() {
    final today = _dateOnly(DateTime.now());

    // First time using the carry-forward system.
    if (_carryOverDate == null) {
      _carryOverDate = today;

      _saveCarryOverState();
      return;
    }

    final storedDay = _dateOnly(_carryOverDate!);

    // Still the same day.
    if (_sameDate(storedDay, today)) {
      return;
    }

    /*
     * A new calendar day has started.
     *
     * The previous day's actual target was:
     *
     * normal target + previous carry-over
     *
     * Whatever was not completed becomes today's carry-over.
     *
     * Example:
     *
     * Normal target = 6
     * Previous carry-over = 0
     * Previous target = 6
     * Previous completed = 4
     *
     * New carry-over = 6 - 4 = 2
     *
     * Today:
     * 6 + 2 = 8
     */

    final daysPassed = today.difference(storedDay).inDays;

    if (daysPassed <= 0) {
      _carryOverDate = today;
      _saveCarryOverState();
      return;
    }

    int carryOver = _carryOverLectures;

    DateTime calculationDate = storedDay;

    /*
     * Calculate each missed calendar day.
     *
     * If the app was not opened for several days, each missed day
     * is treated as having zero completed lectures, so its normal
     * target is also carried forward.
     */
    for (int i = 0; i < daysPassed; i++) {
      final targetForDay =
          _dailyTarget + carryOver;

      final completedThatDay =
          completedLecturesForDate(calculationDate);

      carryOver =
          targetForDay - completedThatDay;

      if (carryOver < 0) {
        carryOver = 0;
      }

      // Never carry more lectures than actually remain.
      final remaining = remainingLectures;

      if (carryOver > remaining) {
        carryOver = remaining;
      }

      calculationDate =
          calculationDate.add(
        const Duration(days: 1),
      );
    }

    _carryOverLectures = carryOver;
    _carryOverDate = today;

    _saveCarryOverState();
  }

  Future<void> _saveCarryOverState() async {
    await _prefs.setInt(
      _carryOverKey,
      _carryOverLectures,
    );

    if (_carryOverDate != null) {
      await _prefs.setString(
        _carryOverDateKey,
        _carryOverDate!.toIso8601String(),
      );
    }
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    final data =
        _items.map((item) => item.toJson()).toList();

    await _prefs.setString(
      _storageKey,
      jsonEncode(data),
    );

    await _prefs.setInt(
      _dailyTargetKey,
      _dailyTarget,
    );

    await _prefs.setInt(
      _carryOverKey,
      _carryOverLectures,
    );

    if (_carryOverDate != null) {
      await _prefs.setString(
        _carryOverDateKey,
        _carryOverDate!.toIso8601String(),
      );
    }
  }

  // ============================================================
  // DAILY TARGET
  // ============================================================

  Future<void> setDailyTarget(int target) async {
    if (target < 1) {
      target = 1;
    }

    if (target > 10) {
      target = 10;
    }

    _dailyTarget = target;

    await _save();
    notifyListeners();
  }

  // ============================================================
  // ADD BACKLOG
  // ============================================================

  Future<BacklogItem> addBacklog({
    required String topic,
    required int totalLectures,
    int minutesPerLecture = 60,
  }) async {
    final cleanTopic = topic.trim();

    if (cleanTopic.isEmpty) {
      throw Exception('Topic cannot be empty');
    }

    if (totalLectures < 1) {
      throw Exception(
        'Lecture count must be at least 1',
      );
    }

    if (minutesPerLecture < 1) {
      minutesPerLecture = 60;
    }

    final now = DateTime.now();

    final lectures = List.generate(
      totalLectures,
      (index) => BacklogLecture(
        number: index + 1,
      ),
    );

    final item = BacklogItem(
      id: 'backlog_${now.microsecondsSinceEpoch}',
      topic: cleanTopic,
      totalLectures: totalLectures,
      minutesPerLecture: minutesPerLecture,
      lectures: lectures,
      createdAt: now,
    );

    _items = [
      ..._items,
      item,
    ];

    await _save();
    notifyListeners();

    return item;
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteBacklog(
    String backlogId,
  ) async {
    _items = _items
        .where((item) => item.id != backlogId)
        .toList();

    await _save();
    notifyListeners();
  }

  // ============================================================
  // TOGGLE LECTURE
  // ============================================================

  Future<void> toggleLecture({
    required String backlogId,
    required int lectureNumber,
    required bool completed,
  }) async {
    final itemIndex = _items.indexWhere(
      (item) => item.id == backlogId,
    );

    if (itemIndex == -1) return;

    final item = _items[itemIndex];

    final now = DateTime.now();

    final updatedLectures =
        item.lectures.map((lecture) {
      if (lecture.number != lectureNumber) {
        return lecture;
      }

      return lecture.copyWith(
        completed: completed,
        completedAt:
            completed ? now : null,
        clearCompletedAt: !completed,
      );
    }).toList();

    final updatedItem = item.copyWith(
      lectures: updatedLectures,
    );

    _items = [..._items];

    _items[itemIndex] = updatedItem;

    await _save();
    notifyListeners();
  }

  // ============================================================
  // FIND
  // ============================================================

  BacklogItem? findById(String id) {
    for (final item in _items) {
      if (item.id == id) {
        return item;
      }
    }

    return null;
  }

  // ============================================================
  // TOTALS
  // ============================================================

  int get totalLectures {
    return _items.fold(
      0,
      (sum, item) => sum + item.totalLectures,
    );
  }

  int get completedLectures {
    return _items.fold(
      0,
      (sum, item) => sum + item.completedLectures,
    );
  }

  int get remainingLectures {
    return _items.fold(
      0,
      (sum, item) => sum + item.remainingLectures,
    );
  }

  int get remainingMinutes {
    return _items.fold(
      0,
      (sum, item) => sum + item.remainingMinutes,
    );
  }

  int get completedMinutes {
    return _items.fold(
      0,
      (sum, item) => sum + item.completedMinutes,
    );
  }

  double get overallProgress {
    if (totalLectures == 0) {
      return 0;
    }

    return completedLectures / totalLectures;
  }

  // ============================================================
  // TODAY
  // ============================================================

  int get todayCompletedLectures {
    return completedLecturesForDate(
      DateTime.now(),
    );
  }

  int get todayCompletedMinutes {
    return completedMinutesForDate(
      DateTime.now(),
    );
  }

  // ============================================================
  // YESTERDAY
  // ============================================================

  int get yesterdayCompletedLectures {
    final yesterday = DateTime.now().subtract(
      const Duration(days: 1),
    );

    return completedLecturesForDate(
      yesterday,
    );
  }

  int get yesterdayCompletedMinutes {
    final yesterday = DateTime.now().subtract(
      const Duration(days: 1),
    );

    return completedMinutesForDate(
      yesterday,
    );
  }

  // ============================================================
  // DAILY INCREASE
  // ============================================================

  int get dailyLectureIncrease {
    return todayCompletedLectures -
        yesterdayCompletedLectures;
  }

  // ============================================================
  // DAILY INCREASE PERCENTAGE
  // ============================================================

  double get dailyLectureIncreasePercent {
    final yesterday =
        yesterdayCompletedLectures;

    final today =
        todayCompletedLectures;

    if (yesterday == 0) {
      if (today > 0) {
        return 100;
      }

      return 0;
    }

    return ((today - yesterday) /
            yesterday) *
        100;
  }

  // ============================================================
  // DAILY RATE
  // ============================================================

  double get dailyLectureRate {
    return averageLecturesPerDay;
  }

  // ============================================================
  // TODAY VS TARGET
  // ============================================================

  int get todayRemainingTarget {
    final remaining =
        todayTarget -
            todayCompletedLectures;

    return remaining < 0
        ? 0
        : remaining;
  }

  bool get todayTargetCompleted {
    return todayCompletedLectures >=
        todayTarget;
  }

  double get todayTargetProgress {
    if (todayTarget <= 0) {
      return 0;
    }

    final progress =
        todayCompletedLectures /
            todayTarget;

    return progress > 1
        ? 1
        : progress;
  }

  // ============================================================
  // COMPLETION RATE AGAINST TARGET
  // ============================================================

  double get todayTargetPercentage {
    if (todayTarget <= 0) {
      return 0;
    }

    return (todayCompletedLectures /
            todayTarget) *
        100;
  }

  // ============================================================
  // AVERAGE LECTURES PER DAY
  // ============================================================

  double get averageLecturesPerDay {
    final dates = <String>{};

    for (final item in _items) {
      for (final lecture in item.lectures) {
        final date =
            lecture.completedAt;

        if (!lecture.completed ||
            date == null) {
          continue;
        }

        dates.add(
          _dateKeyFromDate(date),
        );
      }
    }

    if (dates.isEmpty) {
      return 0;
    }

    return completedLectures /
        dates.length;
  }

  // ============================================================
  // AVERAGE LECTURES PER DAY - LAST 7 DAYS
  // ============================================================

  double get averageLecturesLast7Days {
    int total = 0;

    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(
        Duration(days: i),
      );

      total += completedLecturesForDate(
        date,
      );
    }

    return total / 7;
  }

  // ============================================================
  // LAST 7 DAYS TOTAL
  // ============================================================

  int get lecturesCompletedLast7Days {
    int total = 0;

    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(
        Duration(days: i),
      );

      total += completedLecturesForDate(
        date,
      );
    }

    return total;
  }

  // ============================================================
  // LAST 7 DAYS DAILY DATA
  // ============================================================

  List<Map<String, dynamic>>
      get last7DaysLectureData {
    final result =
        <Map<String, dynamic>>[];

    for (int i = 6; i >= 0; i--) {
      final date =
          DateTime.now().subtract(
        Duration(days: i),
      );

      result.add({
        'date': date,
        'lectures':
            completedLecturesForDate(
          date,
        ),
      });
    }

    return result;
  }

  // ============================================================
  // LAST 7 DAYS INCREASE
  // ============================================================

  double get todayVs7DayAverageIncrease {
    final average =
        averageLecturesLast7Days;

    if (average == 0) {
      if (todayCompletedLectures > 0) {
        return 100;
      }

      return 0;
    }

    return ((todayCompletedLectures -
                average) /
            average) *
        100;
  }

  // ============================================================
  // BEST DAY
  // ============================================================

  int get bestDayLectures {
    int best = 0;

    for (int i = 0; i < 30; i++) {
      final date =
          DateTime.now().subtract(
        Duration(days: i),
      );

      final count =
          completedLecturesForDate(
        date,
      );

      if (count > best) {
        best = count;
      }
    }

    return best;
  }

  // ============================================================
  // ESTIMATED DAYS
  // ============================================================

  int get estimatedDaysRemaining {
    if (remainingLectures == 0) {
      return 0;
    }

    if (_dailyTarget <= 0) {
      return 0;
    }

    return (remainingLectures /
            _dailyTarget)
        .ceil();
  }

  // ============================================================
  // ESTIMATED DAYS USING ACTUAL RATE
  // ============================================================

  int get estimatedDaysUsingActualRate {
    if (remainingLectures == 0) {
      return 0;
    }

    final rate =
        averageLecturesPerDay;

    if (rate <= 0) {
      return estimatedDaysRemaining;
    }

    return (remainingLectures / rate)
        .ceil();
  }

  // ============================================================
  // ESTIMATED COMPLETION TIME
  // ============================================================

  int get estimatedRemainingHours {
    return remainingMinutes ~/ 60;
  }

  int get estimatedRemainingMinutesOnly {
    return remainingMinutes % 60;
  }

  // ============================================================
  // COMPLETED LECTURES FOR ANY DATE
  // ============================================================

  int completedLecturesForDate(
    DateTime date,
  ) {
    int count = 0;

    for (final item in _items) {
      for (final lecture in item.lectures) {
        final completedAt =
            lecture.completedAt;

        if (!lecture.completed ||
            completedAt == null) {
          continue;
        }

        if (_sameDate(
          completedAt,
          date,
        )) {
          count++;
        }
      }
    }

    return count;
  }

  // ============================================================
  // COMPLETED MINUTES FOR ANY DATE
  // ============================================================

  int completedMinutesForDate(
    DateTime date,
  ) {
    int minutes = 0;

    for (final item in _items) {
      for (final lecture in item.lectures) {
        final completedAt =
            lecture.completedAt;

        if (!lecture.completed ||
            completedAt == null) {
          continue;
        }

        if (_sameDate(
          completedAt,
          date,
        )) {
          minutes +=
              item.minutesPerLecture;
        }
      }
    }

    return minutes;
  }

  // ============================================================
  // DAILY HISTORY
  // ============================================================

  List<Map<String, dynamic>>
      get dailyHistory {
    final dates = <String, int>{};

    for (final item in _items) {
      for (final lecture in item.lectures) {
        final date =
            lecture.completedAt;

        if (!lecture.completed ||
            date == null) {
          continue;
        }

        final key =
            _dateKeyFromDate(date);

        dates[key] =
            (dates[key] ?? 0) + 1;
      }
    }

    final result =
        <Map<String, dynamic>>[];

    final sortedKeys =
        dates.keys.toList()..sort();

    for (final key in sortedKeys) {
      result.add({
        'date': key,
        'lectures': dates[key] ?? 0,
      });
    }

    return result;
  }

  // ============================================================
  // CURRENT STREAK
  // ============================================================

  int get currentStreak {
    int streak = 0;

    DateTime date =
        DateTime.now();

    while (true) {
      final count =
          completedLecturesForDate(
        date,
      );

      if (count <= 0) {
        break;
      }

      streak++;

      date = date.subtract(
        const Duration(days: 1),
      );
    }

    return streak;
  }

  // ============================================================
  // LONGEST STREAK
  // ============================================================

  int get longestStreak {
    if (_items.isEmpty) {
      return 0;
    }

    final dates = <String>{};

    for (final item in _items) {
      for (final lecture in item.lectures) {
        final date =
            lecture.completedAt;

        if (!lecture.completed ||
            date == null) {
          continue;
        }

        dates.add(
          _dateKeyFromDate(date),
        );
      }
    }

    if (dates.isEmpty) {
      return 0;
    }

    final sortedDates =
        dates.map((value) {
      final parts =
          value.split('-');

      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    }).toList()
          ..sort();

    int longest = 1;
    int current = 1;

    for (int i = 1;
        i < sortedDates.length;
        i++) {
      final difference =
          sortedDates[i]
              .difference(
                sortedDates[i - 1],
              )
              .inDays;

      if (difference == 1) {
        current++;

        if (current > longest) {
          longest = current;
        }
      } else {
        current = 1;
      }
    }

    return longest;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  DateTime _dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  bool _sameDate(
    DateTime first,
    DateTime second,
  ) {
    return first.year ==
            second.year &&
        first.month ==
            second.month &&
        first.day ==
            second.day;
  }

  String _dateKeyFromDate(
    DateTime date,
  ) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}