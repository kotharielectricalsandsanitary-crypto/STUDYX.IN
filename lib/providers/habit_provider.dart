import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit_model.dart';

class HabitProvider extends ChangeNotifier {
  static const String _storageKey = 'studyx_habits_v1';

  List<HabitModel> _habits = [];

  HabitProvider() {
    _loadHabits();
  }

  // ============================================================
  // GETTERS
  // ============================================================

  List<HabitModel> get habits => List.unmodifiable(_habits);

  List<HabitModel> get activeHabits {
    return _habits.where((habit) => habit.isActive).toList();
  }

  List<HabitModel> get inactiveHabits {
    return _habits.where((habit) => !habit.isActive).toList();
  }

  List<HabitModel> get todaysHabits {
    final today = DateTime.now();

    return activeHabits
        .where((habit) => habit.isScheduledOn(today))
        .toList();
  }

  List<HabitModel> get habitsForToday => todaysHabits;

  int get totalHabits => _habits.length;

  int get activeHabitCount => activeHabits.length;

  int get completedTodayCount {
    final today = DateTime.now();

    return todaysHabits
        .where((habit) => habit.isCompletedOn(today))
        .length;
  }

  int get remainingTodayCount {
    final today = DateTime.now();

    return todaysHabits
        .where((habit) => !habit.isCompletedOn(today))
        .length;
  }

  double get todayProgress {
    final total = todaysHabits.length;

    if (total == 0) return 0.0;

    return (completedTodayCount / total).clamp(0.0, 1.0);
  }

  int get totalCompletions {
    return _habits.fold<int>(
      0,
      (total, habit) => total + habit.completedCount,
    );
  }

  int get longestStreak {
    if (_habits.isEmpty) return 0;

    return _habits
        .map((habit) => habit.longestStreak)
        .fold<int>(
          0,
          (max, value) => value > max ? value : max,
        );
  }

  double get overallCompletionRate {
    if (_habits.isEmpty) return 0.0;

    final total = _habits.fold<double>(
      0.0,
      (sum, habit) => sum + habit.overallCompletionRate,
    );

    return (total / _habits.length).clamp(0.0, 1.0);
  }

  // ============================================================
  // FIND
  // ============================================================

  HabitModel? getHabitById(String id) {
    for (final habit in _habits) {
      if (habit.id == id) {
        return habit;
      }
    }

    return null;
  }

  HabitModel? findById(String id) {
    return getHabitById(id);
  }

  // ============================================================
  // ADD
  // ============================================================

  Future<void> addHabit({
    required String name,
    String description = '',
    String icon = 'check_circle',
    int colorValue = 0xff6C5CE7,
    List<int>? weekdays,
  }) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) return;

    final selectedWeekdays = weekdays == null
        ? [1, 2, 3, 4, 5, 6, 7]
        : List<int>.from(weekdays);

    selectedWeekdays.sort();

    final habit = HabitModel(
      id: _generateId(),
      name: cleanName,
      description: description.trim(),
      icon: icon,
      colorValue: colorValue,
      weekdays: selectedWeekdays,
      completedDates: const [],
      createdAt: DateTime.now(),
      isActive: true,
    );

    _habits.add(habit);

    await _saveHabits();

    notifyListeners();
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<void> updateHabit({
    required String habitId,
    String? name,
    String? description,
    String? icon,
    int? colorValue,
    List<int>? weekdays,
    bool? isActive,
  }) async {
    final index = _habits.indexWhere(
      (habit) => habit.id == habitId,
    );

    if (index == -1) return;

    final oldHabit = _habits[index];

    List<int>? updatedWeekdays;

    if (weekdays != null) {
      updatedWeekdays = List<int>.from(weekdays);
      updatedWeekdays.sort();
    }

    _habits[index] = oldHabit.copyWith(
      name: name == null || name.trim().isEmpty
          ? oldHabit.name
          : name.trim(),
      description:
          description?.trim() ?? oldHabit.description,
      icon: icon ?? oldHabit.icon,
      colorValue: colorValue ?? oldHabit.colorValue,
      weekdays: updatedWeekdays ?? oldHabit.weekdays,
      isActive: isActive ?? oldHabit.isActive,
    );

    await _saveHabits();

    notifyListeners();
  }

  // ============================================================
  // EDIT
  // ============================================================

  Future<void> editHabit(HabitModel updatedHabit) async {
    final index = _habits.indexWhere(
      (habit) => habit.id == updatedHabit.id,
    );

    if (index == -1) return;

    _habits[index] = updatedHabit;

    await _saveHabits();

    notifyListeners();
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteHabit(String habitId) async {
    _habits.removeWhere(
      (habit) => habit.id == habitId,
    );

    await _saveHabits();

    notifyListeners();
  }

  // ============================================================
  // ACTIVE / INACTIVE
  // ============================================================

  Future<void> toggleHabitActive(String habitId) async {
    final index = _habits.indexWhere(
      (habit) => habit.id == habitId,
    );

    if (index == -1) return;

    final habit = _habits[index];

    _habits[index] = habit.copyWith(
      isActive: !habit.isActive,
    );

    await _saveHabits();

    notifyListeners();
  }

  Future<void> setHabitActive(
    String habitId,
    bool active,
  ) async {
    final index = _habits.indexWhere(
      (habit) => habit.id == habitId,
    );

    if (index == -1) return;

    _habits[index] = _habits[index].copyWith(
      isActive: active,
    );

    await _saveHabits();

    notifyListeners();
  }

  // ============================================================
  // COMPLETION
  // ============================================================

  Future<void> completeHabit(
    String habitId, {
    DateTime? date,
  }) async {
    final index = _habits.indexWhere(
      (habit) => habit.id == habitId,
    );

    if (index == -1) return;

    final targetDate = date ?? DateTime.now();

    _habits[index] = _habits[index].markCompleted(
      targetDate,
    );

    await _saveHabits();

    notifyListeners();
  }

  Future<void> uncompleteHabit(
    String habitId, {
    DateTime? date,
  }) async {
    final index = _habits.indexWhere(
      (habit) => habit.id == habitId,
    );

    if (index == -1) return;

    final targetDate = date ?? DateTime.now();

    _habits[index] = _habits[index].markIncomplete(
      targetDate,
    );

    await _saveHabits();

    notifyListeners();
  }

  Future<void> toggleHabit(
    String habitId, {
    DateTime? date,
  }) async {
    final index = _habits.indexWhere(
      (habit) => habit.id == habitId,
    );

    if (index == -1) return;

    final targetDate = date ?? DateTime.now();

    _habits[index] = _habits[index].toggleDate(
      targetDate,
    );

    await _saveHabits();

    notifyListeners();
  }

  // Compatibility aliases.
  Future<void> toggleCompletion(
    String habitId, {
    DateTime? date,
  }) async {
    await toggleHabit(
      habitId,
      date: date,
    );
  }

  Future<void> markHabitComplete(
    String habitId, {
    DateTime? date,
  }) async {
    await completeHabit(
      habitId,
      date: date,
    );
  }

  // ============================================================
  // DATE CHECKS
  // ============================================================

  bool isHabitCompleted(
    String habitId, {
    DateTime? date,
  }) {
    final habit = getHabitById(habitId);

    if (habit == null) return false;

    return habit.isCompletedOn(
      date ?? DateTime.now(),
    );
  }

  bool isHabitScheduled(
    String habitId, {
    DateTime? date,
  }) {
    final habit = getHabitById(habitId);

    if (habit == null) return false;

    return habit.isScheduledOn(
      date ?? DateTime.now(),
    );
  }

  // ============================================================
  // DAILY SUMMARY
  // ============================================================

  int completedCountForDate(DateTime date) {
    return activeHabits.where((habit) {
      return habit.isScheduledOn(date) &&
          habit.isCompletedOn(date);
    }).length;
  }

  int scheduledCountForDate(DateTime date) {
    return activeHabits.where((habit) {
      return habit.isScheduledOn(date);
    }).length;
  }

  double progressForDate(DateTime date) {
    final total = scheduledCountForDate(date);

    if (total == 0) return 0.0;

    return (completedCountForDate(date) / total)
        .clamp(0.0, 1.0);
  }

  // ============================================================
  // WEEK
  // ============================================================

  List<DateTime> getCurrentWeekDates() {
    final today = DateTime.now();

    final todayOnly = DateTime(
      today.year,
      today.month,
      today.day,
    );

    final monday = todayOnly.subtract(
      Duration(
        days: todayOnly.weekday - DateTime.monday,
      ),
    );

    return List.generate(
      7,
      (index) => monday.add(
        Duration(days: index),
      ),
    );
  }

  int completedDaysForHabitThisWeek(
    String habitId,
  ) {
    final habit = getHabitById(habitId);

    if (habit == null) return 0;

    int count = 0;

    for (final date in getCurrentWeekDates()) {
      if (habit.isScheduledOn(date) &&
          habit.isCompletedOn(date)) {
        count++;
      }
    }

    return count;
  }

  int scheduledDaysForHabitThisWeek(
    String habitId,
  ) {
    final habit = getHabitById(habitId);

    if (habit == null) return 0;

    int count = 0;

    for (final date in getCurrentWeekDates()) {
      if (habit.isScheduledOn(date)) {
        count++;
      }
    }

    return count;
  }

  double weeklyProgressForHabit(
    String habitId,
  ) {
    final scheduled =
        scheduledDaysForHabitThisWeek(habitId);

    if (scheduled == 0) return 0.0;

    return (completedDaysForHabitThisWeek(habitId) /
            scheduled)
        .clamp(0.0, 1.0);
  }

  // ============================================================
  // WEEKLY DATA
  // ============================================================
  //
  // Used by HabitScreen's "Consistency" section.
  //
  // Returns the previous 7 days including today.
  //
  // Each item contains:
  // date       -> DateTime
  // completed  -> number of completed scheduled habits
  // scheduled  -> number of scheduled habits
  // rate       -> completion rate from 0.0 to 1.0
  //
  // ============================================================

  List<Map<String, dynamic>> getWeeklyData() {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    return List.generate(
      7,
      (index) {
        final date = today.subtract(
          Duration(days: 6 - index),
        );

        int completed = 0;
        int scheduled = 0;

        for (final habit in _habits) {
          if (!habit.isActive) continue;

          if (habit.isScheduledOn(date)) {
            scheduled++;

            if (habit.isCompletedOn(date)) {
              completed++;
            }
          }
        }

        final rate = scheduled == 0
            ? 0.0
            : (completed / scheduled).clamp(
                0.0,
                1.0,
              );

        return {
          'date': date,
          'completed': completed,
          'scheduled': scheduled,
          'rate': rate,
        };
      },
    );
  }

  // ============================================================
  // RESET
  // ============================================================

  Future<void> resetHabitForDate(
    String habitId,
    DateTime date,
  ) async {
    await uncompleteHabit(
      habitId,
      date: date,
    );
  }

  // ============================================================
  // CLEAR
  // ============================================================

  Future<void> clearAllHabits() async {
    _habits.clear();

    await _saveHabits();

    notifyListeners();
  }

  // ============================================================
  // STORAGE
  // ============================================================

  Future<void> _loadHabits() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final rawData =
          prefs.getString(_storageKey);

      if (rawData == null || rawData.isEmpty) {
        _habits = [];
        notifyListeners();
        return;
      }

      final decoded = jsonDecode(rawData);

      if (decoded is! List) {
        _habits = [];
        notifyListeners();
        return;
      }

      final loadedHabits =
          <HabitModel>[];

      for (final item in decoded) {
        if (item is! Map) continue;

        try {
          loadedHabits.add(
            HabitModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        } catch (_) {
          // Ignore only the corrupted habit.
        }
      }

      _habits = loadedHabits;

      notifyListeners();
    } catch (_) {
      _habits = [];
      notifyListeners();
    }
  }

  Future<void> _saveHabits() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final data = _habits
          .map(
            (habit) => habit.toJson(),
          )
          .toList();

      await prefs.setString(
        _storageKey,
        jsonEncode(data),
      );
    } catch (_) {
      // Prevent storage failures from crashing the app.
    }
  }

  // ============================================================
  // ID
  // ============================================================

  String _generateId() {
    return '${DateTime.now().microsecondsSinceEpoch}_${_habits.length}';
  }
}