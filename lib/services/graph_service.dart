import 'package:fl_chart/fl_chart.dart';

import '../models/study_session.dart';

class GraphService {
  /// Total Study Hours
  static double getTotalHours(List<StudySession> sessions) {
    return sessions.fold(
      0,
      (sum, session) => sum + session.studyHours,
    );
  }

  /// Total Study Minutes
  static int getTotalMinutes(List<StudySession> sessions) {
    return sessions.fold(
      0,
      (sum, session) => sum + session.studyMinutes,
    );
  }

  /// Average Daily Hours
  static double getAverageHours(List<StudySession> sessions) {
    if (sessions.isEmpty) return 0;

    return getTotalHours(sessions) / sessions.length;
  }

  /// Longest Streak
  static int getLongestStreak(List<StudySession> sessions) {
    if (sessions.isEmpty) return 0;

    final dates = sessions
        .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
        .toSet()
        .toList()
      ..sort();

    int longest = 1;
    int current = 1;

    for (int i = 1; i < dates.length; i++) {
      if (dates[i].difference(dates[i - 1]).inDays == 1) {
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

  /// Current Streak
  static int getCurrentStreak(List<StudySession> sessions) {
    if (sessions.isEmpty) return 0;

    final dates = sessions
        .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
        .toSet()
        .toList()
      ..sort();

    DateTime current = DateTime.now();
    current = DateTime(current.year, current.month, current.day);

    int streak = 0;

    while (dates.contains(current)) {
      streak++;
      current = current.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// Last 7 Days Graph
  static List<FlSpot> getWeeklyGraph(List<StudySession> sessions) {
    final List<FlSpot> spots = [];

    for (int i = 6; i >= 0; i--) {
      final day = DateTime.now().subtract(Duration(days: i));

      double hours = 0;

      for (final session in sessions) {
        if (session.date.year == day.year &&
            session.date.month == day.month &&
            session.date.day == day.day) {
          hours += session.studyHours;
        }
      }

      spots.add(
        FlSpot(
          (6 - i).toDouble(),
          hours,
        ),
      );
    }

    return spots;
  }

  /// Last 30 Days Bar Graph
  static List<BarChartGroupData> getMonthlyBars(
      List<StudySession> sessions) {
    final List<BarChartGroupData> bars = [];

    for (int i = 29; i >= 0; i--) {
      final day = DateTime.now().subtract(Duration(days: i));

      double hours = 0;

      for (final session in sessions) {
        if (session.date.year == day.year &&
            session.date.month == day.month &&
            session.date.day == day.day) {
          hours += session.studyHours;
        }
      }

      bars.add(
        BarChartGroupData(
          x: 29 - i,
          barRods: [
            BarChartRodData(
              toY: hours,
              width: 8,
            ),
          ],
        ),
      );
    }

    return bars;
  }

  /// Heatmap Data
  static Map<DateTime, double> getHeatmapData(
      List<StudySession> sessions) {
    final Map<DateTime, double> data = {};

    for (final session in sessions) {
      final date = DateTime(
        session.date.year,
        session.date.month,
        session.date.day,
      );

      data.update(
        date,
        (value) => value + session.studyHours,
        ifAbsent: () => session.studyHours,
      );
    }

    return data;
  }

  /// Today's Hours
  static double getTodayHours(List<StudySession> sessions) {
    final today = DateTime.now();

    double total = 0;

    for (final session in sessions) {
      if (session.date.year == today.year &&
          session.date.month == today.month &&
          session.date.day == today.day) {
        total += session.studyHours;
      }
    }

    return total;
  }

  /// Best Study Day
  static double getBestDayHours(List<StudySession> sessions) {
    final heatmap = getHeatmapData(sessions);

    if (heatmap.isEmpty) return 0;

    return heatmap.values.reduce(
      (a, b) => a > b ? a : b,
    );
  }
}