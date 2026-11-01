import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  final SharedPreferences prefs;

  UserProvider(this.prefs);

  // ============================================================
  // USER DATA
  // ============================================================

  String get name =>
      prefs.getString('name') ?? '';

  String get goal =>
      prefs.getString('goal') ?? '';

  double get dailyHours =>
      prefs.getDouble('daily_hours') ?? 0;

  bool get isUserDone =>
      prefs.getBool('onboarding_completed') ?? false;

  // ============================================================
  // SAVE USER
  // ============================================================

  Future<void> saveUser({
    required String userName,
    required String userGoal,
    required double studyHours,
  }) async {
    final cleanName = userName.trim();
    final cleanGoal = userGoal.trim();

    if (cleanName.isEmpty ||
        cleanGoal.isEmpty ||
        studyHours <= 0) {
      return;
    }

    await prefs.setString(
      'name',
      cleanName,
    );

    await prefs.setString(
      'goal',
      cleanGoal,
    );

    await prefs.setDouble(
      'daily_hours',
      studyHours,
    );

    await prefs.setBool(
      'onboarding_completed',
      true,
    );

    notifyListeners();
  }

  // ============================================================
  // UPDATE NAME
  // ============================================================

  Future<void> updateName(
    String newName,
  ) async {
    final cleanName = newName.trim();

    if (cleanName.isEmpty) return;

    await prefs.setString(
      'name',
      cleanName,
    );

    notifyListeners();
  }

  // ============================================================
  // UPDATE GOAL
  // ============================================================

  Future<void> updateGoal(
    String newGoal,
  ) async {
    final cleanGoal = newGoal.trim();

    if (cleanGoal.isEmpty) return;

    await prefs.setString(
      'goal',
      cleanGoal,
    );

    notifyListeners();
  }

  // ============================================================
  // UPDATE DAILY STUDY HOURS
  // ============================================================

  Future<void> updateDailyHours(
    double hours,
  ) async {
    if (hours <= 0) return;

    await prefs.setDouble(
      'daily_hours',
      hours,
    );

    notifyListeners();
  }

  // ============================================================
  // UPDATE EVERYTHING
  // ============================================================

  Future<void> updateUser({
    String? newName,
    String? newGoal,
    double? newDailyHours,
  }) async {
    if (newName != null &&
        newName.trim().isNotEmpty) {
      await prefs.setString(
        'name',
        newName.trim(),
      );
    }

    if (newGoal != null &&
        newGoal.trim().isNotEmpty) {
      await prefs.setString(
        'goal',
        newGoal.trim(),
      );
    }

    if (newDailyHours != null &&
        newDailyHours > 0) {
      await prefs.setDouble(
        'daily_hours',
        newDailyHours,
      );
    }

    notifyListeners();
  }

  // ============================================================
  // CLEAR USER
  // ============================================================

  Future<void> clearUser() async {
    await prefs.remove('name');
    await prefs.remove('goal');
    await prefs.remove('daily_hours');
    await prefs.remove(
      'onboarding_completed',
    );

    notifyListeners();
  }
}