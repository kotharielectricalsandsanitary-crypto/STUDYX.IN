
// lib/models/planner_session_model.dart

class PlannerSessionModel {
  final String id;
  final String title;

  final String subject;
  final String chapter;
  final String topic;

  /// The calendar date on which this session is planned.
  /// The time portion is normalized to midnight.
  final DateTime plannedDate;

  /// Minutes after midnight. Example: 9:30 AM = 570.
  final int startMinutes;

  /// Planned study duration in minutes.
  final int durationMinutes;

  final String notes;

  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;

  /// Number of times this unfinished session has been
  /// automatically moved to another day.
  final int rescheduledCount;

  PlannerSessionModel({
    required this.id,
    required this.title,
    required DateTime plannedDate,
    required this.startMinutes,
    required this.durationMinutes,
    this.subject = '',
    this.chapter = '',
    this.topic = '',
    this.notes = '',
    this.isCompleted = false,
    DateTime? createdAt,
    this.completedAt,
    this.rescheduledCount = 0,
  })  : plannedDate = DateTime(
          plannedDate.year,
          plannedDate.month,
          plannedDate.day,
        ),
        createdAt = createdAt ?? DateTime.now();

  // --------------------------------------------------
  // DATE AND TIME HELPERS
  // --------------------------------------------------

  DateTime get scheduledStart {
    return DateTime(
      plannedDate.year,
      plannedDate.month,
      plannedDate.day,
    ).add(
      Duration(minutes: startMinutes),
    );
  }

  DateTime get scheduledEnd {
    return scheduledStart.add(
      Duration(minutes: durationMinutes),
    );
  }

  bool get isOverdue {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    return !isCompleted && plannedDate.isBefore(today);
  }

  bool get isScheduledForToday {
    final now = DateTime.now();

    return plannedDate.year == now.year &&
        plannedDate.month == now.month &&
        plannedDate.day == now.day;
  }

  String get formattedStartTime {
    final hour = startMinutes ~/ 60;
    final minute = startMinutes % 60;

    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final displayMinute = minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';

    return '$displayHour:$displayMinute $period';
  }

  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;

    if (hours == 0) {
      return '${minutes}m';
    }

    if (minutes == 0) {
      return '${hours}h';
    }

    return '${hours}h ${minutes}m';
  }

  // --------------------------------------------------
  // COPY WITH
  // --------------------------------------------------

  PlannerSessionModel copyWith({
    String? id,
    String? title,
    String? subject,
    String? chapter,
    String? topic,
    DateTime? plannedDate,
    int? startMinutes,
    int? durationMinutes,
    String? notes,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    int? rescheduledCount,
  }) {
    return PlannerSessionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      chapter: chapter ?? this.chapter,
      topic: topic ?? this.topic,
      plannedDate: plannedDate ?? this.plannedDate,
      startMinutes: startMinutes ?? this.startMinutes,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: clearCompletedAt
          ? null
          : completedAt ?? this.completedAt,
      rescheduledCount:
          rescheduledCount ?? this.rescheduledCount,
    );
  }

  // --------------------------------------------------
  // LOCAL STORAGE SERIALIZATION
  // --------------------------------------------------

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'chapter': chapter,
      'topic': topic,
      'plannedDate': plannedDate.toIso8601String(),
      'startMinutes': startMinutes,
      'durationMinutes': durationMinutes,
      'notes': notes,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'rescheduledCount': rescheduledCount,
    };
  }

  factory PlannerSessionModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawDate = json['plannedDate']?.toString();

    final parsedDate = rawDate == null
        ? DateTime.now()
        : DateTime.tryParse(rawDate) ?? DateTime.now();

    final rawCreatedAt = json['createdAt']?.toString();

    final parsedCreatedAt = rawCreatedAt == null
        ? DateTime.now()
        : DateTime.tryParse(rawCreatedAt) ?? DateTime.now();

    final rawCompletedAt = json['completedAt']?.toString();

    return PlannerSessionModel(
      id: json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      chapter: json['chapter']?.toString() ?? '',
      topic: json['topic']?.toString() ?? '',
      plannedDate: parsedDate,
      startMinutes: _readInt(json['startMinutes'], 540),
      durationMinutes: _readInt(json['durationMinutes'], 60),
      notes: json['notes']?.toString() ?? '',
      isCompleted: json['isCompleted'] == true,
      createdAt: parsedCreatedAt,
      completedAt: rawCompletedAt == null
          ? null
          : DateTime.tryParse(rawCompletedAt),
      rescheduledCount: _readInt(json['rescheduledCount'], 0),
    );
  }

  static int _readInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
