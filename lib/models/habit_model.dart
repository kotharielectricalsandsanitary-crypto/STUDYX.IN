class HabitModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int colorValue;

  /// Days on which the habit should be completed.
  /// 1 = Monday, 7 = Sunday.
  final List<int> weekdays;

  /// Dates on which the habit was completed.
  /// Stored as yyyy-MM-dd strings.
  final List<String> completedDates;

  final DateTime createdAt;
  final bool isActive;

  HabitModel({
    required this.id,
    required this.name,
    this.description = '',
    this.icon = 'check_circle',
    this.colorValue = 0xff6C5CE7,
    this.weekdays = const [],
    this.completedDates = const [],
    required this.createdAt,
    this.isActive = true,
  });

  /// Number of completed days.
  int get completedCount => completedDates.length;

  /// Check whether the habit was completed on a specific date.
  bool isCompletedOn(DateTime date) {
    final key = _dateKey(date);
    return completedDates.contains(key);
  }

  /// Returns the current consecutive streak.
  int get currentStreak {
    if (completedDates.isEmpty) return 0;

    final completed = completedDates.toSet();
    DateTime day = _dateOnly(DateTime.now());

    int streak = 0;

    // If today isn't completed, allow the streak to continue from yesterday.
    if (!completed.contains(_dateKey(day))) {
      day = day.subtract(const Duration(days: 1));
    }

    while (completed.contains(_dateKey(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// Best consecutive streak ever achieved.
  int get longestStreak {
    if (completedDates.isEmpty) return 0;

    final dates = completedDates
        .map(_parseDate)
        .whereType<DateTime>()
        .map(_dateOnly)
        .toSet()
        .toList()
      ..sort();

    if (dates.isEmpty) return 0;

    int longest = 1;
    int current = 1;

    for (int i = 1; i < dates.length; i++) {
      final difference = dates[i].difference(dates[i - 1]).inDays;

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

  /// Completion percentage for the last 7 days.
  double get weeklyCompletionRate {
    if (completedDates.isEmpty) return 0;

    final today = _dateOnly(DateTime.now());
    int completed = 0;

    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));

      if (isCompletedOn(date)) {
        completed++;
      }
    }

    return completed / 7;
  }

  /// Completion percentage for the current calendar month.
  double get monthlyCompletionRate {
    final today = _dateOnly(DateTime.now());

    int totalDays = today.day;
    if (totalDays <= 0) return 0;

    int completed = 0;

    for (int i = 1; i <= totalDays; i++) {
      final date = DateTime(today.year, today.month, i);

      if (isCompletedOn(date)) {
        completed++;
      }
    }

    return completed / totalDays;
  }

  /// Creates a new model with selected fields changed.
  HabitModel copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    int? colorValue,
    List<int>? weekdays,
    List<String>? completedDates,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return HabitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      colorValue: colorValue ?? this.colorValue,
      weekdays: weekdays ?? this.weekdays,
      completedDates: completedDates ?? this.completedDates,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Convert model to JSON for SharedPreferences.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'colorValue': colorValue,
      'weekdays': weekdays,
      'completedDates': completedDates,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// Create model from JSON.
  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'check_circle',
      colorValue: _parseInt(json['colorValue'], 0xff6C5CE7),
      weekdays: _parseIntList(json['weekdays']),
      completedDates: _parseStringList(json['completedDates']),
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      isActive: json['isActive'] != false,
    );
  }

  /// Adds a completion date.
  HabitModel markCompleted(DateTime date) {
    final key = _dateKey(date);

    if (completedDates.contains(key)) {
      return this;
    }

    final updatedDates = List<String>.from(completedDates)
      ..add(key);

    updatedDates.sort();

    return copyWith(
      completedDates: updatedDates,
    );
  }

  /// Removes a completion date.
  HabitModel markIncomplete(DateTime date) {
    final key = _dateKey(date);

    final updatedDates = List<String>.from(completedDates)
      ..remove(key);

    return copyWith(
      completedDates: updatedDates,
    );
  }

  /// Toggle completion for a date.
  HabitModel toggleDate(DateTime date) {
    if (isCompletedOn(date)) {
      return markIncomplete(date);
    }

    return markCompleted(date);
  }

  /// Whether this habit is scheduled for a particular weekday.
  bool isScheduledOn(DateTime date) {
    if (weekdays.isEmpty) {
      return true;
    }

    return weekdays.contains(date.weekday);
  }

  /// Whether the habit is due today.
  bool get isDueToday {
    return isActive && isScheduledOn(DateTime.now());
  }

  /// Number of days the habit has existed.
  int get ageInDays {
    final today = _dateOnly(DateTime.now());
    final created = _dateOnly(createdAt);

    final difference = today.difference(created).inDays;

    return difference < 0 ? 0 : difference + 1;
  }

  /// Overall completion rate since the habit was created.
  double get overallCompletionRate {
    if (ageInDays <= 0) return 0;

    final scheduledDays = _scheduledDaysSinceCreation();

    if (scheduledDays <= 0) return 0;

    final completedScheduledDays = completedDates
        .map(_parseDate)
        .whereType<DateTime>()
        .where((date) => date.isAfter(
              _dateOnly(createdAt).subtract(const Duration(days: 1)),
            ))
        .where((date) => date.isBefore(
              _dateOnly(DateTime.now()).add(const Duration(days: 1)),
            ))
        .where(isScheduledOn)
        .length;

    return (completedScheduledDays / scheduledDays).clamp(0.0, 1.0);
  }

  int _scheduledDaysSinceCreation() {
    final start = _dateOnly(createdAt);
    final today = _dateOnly(DateTime.now());

    if (start.isAfter(today)) return 0;

    int count = 0;
    DateTime current = start;

    while (!current.isAfter(today)) {
      if (isScheduledOn(current)) {
        count++;
      }

      current = current.add(const Duration(days: 1));
    }

    return count;
  }

  static String _dateKey(DateTime date) {
    final normalized = _dateOnly(date);

    final year = normalized.year.toString().padLeft(4, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  static DateTime? _parseDate(String value) {
    return DateTime.tryParse(value);
  }

  static int _parseInt(dynamic value, int fallback) {
    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static List<int> _parseIntList(dynamic value) {
    if (value is! List) return [];

    return value
        .map((item) {
          if (item is int) return item;
          if (item is num) return item.toInt();

          return int.tryParse(item.toString());
        })
        .whereType<int>()
        .toList();
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) return [];

    return value
        .map((item) => item.toString())
        .toList();
  }
}