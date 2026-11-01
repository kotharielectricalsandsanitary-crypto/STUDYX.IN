import 'package:flutter/material.dart';

class GraphProvider extends ChangeNotifier {
  // ----------------------------
  // Statistics
  // ----------------------------

  double todayHours = 4.5;
  double weekHours = 28.0;
  double monthHours = 112.0;

  int streak = 18;

  String bestDay = "Wednesday";

  double averageHours = 4.0;

  double targetCompletion = 82;

  // ----------------------------
  // Weekly Graph
  // ----------------------------

  List<double> weeklyStudy = [
    3,
    5,
    4,
    6,
    8,
    2,
    7,
  ];

  // ----------------------------
  // Monthly Graph
  // ----------------------------

  List<double> monthlyStudy = [
    3,
    5,
    4,
    6,
    5,
    7,
    8,
    4,
    5,
    6,
    7,
    8,
    4,
    3,
    6,
    7,
    5,
    4,
    6,
    8,
    5,
    7,
    4,
    6,
    8,
    7,
    5,
    4,
    6,
    8,
  ];

  // ----------------------------
  // Yearly Graph
  // ----------------------------

  List<double> yearlyStudy = [
    90,
    110,
    120,
    135,
    140,
    128,
    145,
    150,
    160,
    155,
    170,
    180,
  ];

  // ----------------------------
  // Subject Wise Hours
  // ----------------------------

  final Map<String, double> subjectHours = {
    "Biology": 42,
    "Physics": 30,
    "Chemistry": 40,
    "Revision": 18,
  };

  // ----------------------------
  // Pie Chart Data
  // ----------------------------

  final Map<String, double> studyDistribution = {
    "Study": 70,
    "Revision": 20,
    "Tests": 10,
  };

  // ----------------------------
  // Return Graph Data
  // ----------------------------

  List<double> getGraphData(String range) {
    switch (range) {
      case "Week":
        return weeklyStudy;

      case "Month":
        return monthlyStudy;

      case "Year":
        return yearlyStudy;

      default:
        return weeklyStudy;
    }
  }

  // ----------------------------
  // Update Statistics
  // ----------------------------

  void updateTodayHours(double value) {
    todayHours = value;
    notifyListeners();
  }

  void updateWeekHours(double value) {
    weekHours = value;
    notifyListeners();
  }

  void updateMonthHours(double value) {
    monthHours = value;
    notifyListeners();
  }

  void updateStreak(int value) {
    streak = value;
    notifyListeners();
  }

  void updateAverage(double value) {
    averageHours = value;
    notifyListeners();
  }

  void updateTarget(double value) {
    targetCompletion = value;
    notifyListeners();
  }

  // ----------------------------
  // Add Study Session
  // ----------------------------

  void addStudyHours(double hours) {
    todayHours += hours;
    weekHours += hours;
    monthHours += hours;

    weeklyStudy[DateTime.now().weekday - 1] += hours;

    notifyListeners();
  }

  // ----------------------------
  // Reset
  // ----------------------------

  void resetAnalytics() {
    todayHours = 0;
    weekHours = 0;
    monthHours = 0;
    streak = 0;
    averageHours = 0;
    targetCompletion = 0;

    notifyListeners();
  }
}