import 'dart:math' as math;

class BacklogLecture {
  final int number;
  final bool completed;
  final DateTime? completedAt;

  const BacklogLecture({
    required this.number,
    this.completed = false,
    this.completedAt,
  });

  BacklogLecture copyWith({
    int? number,
    bool? completed,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return BacklogLecture(
      number: number ?? this.number,
      completed: completed ?? this.completed,
      completedAt: clearCompletedAt
          ? null
          : completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'completed': completed,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory BacklogLecture.fromJson(
    Map<String, dynamic> json,
  ) {
    final completedAtValue = json['completedAt'];

    return BacklogLecture(
      number: (json['number'] as num?)?.toInt() ?? 1,
      completed: json['completed'] == true,
      completedAt: completedAtValue == null
          ? null
          : DateTime.tryParse(
              completedAtValue.toString(),
            ),
    );
  }
}

class BacklogItem {
  final String id;
  final String topic;
  final int totalLectures;
  final int minutesPerLecture;
  final List<BacklogLecture> lectures;
  final DateTime createdAt;

  const BacklogItem({
    required this.id,
    required this.topic,
    required this.totalLectures,
    required this.minutesPerLecture,
    required this.lectures,
    required this.createdAt,
  });

  int get completedLectures {
    return lectures.where((lecture) => lecture.completed).length;
  }

  int get remainingLectures {
    return math.max(
      0,
      totalLectures - completedLectures,
    );
  }

  double get progress {
    if (totalLectures <= 0) return 0;

    return completedLectures / totalLectures;
  }

  int get remainingMinutes {
    return remainingLectures * minutesPerLecture;
  }

  int get completedMinutes {
    return completedLectures * minutesPerLecture;
  }

  bool get isCompleted {
    return totalLectures > 0 &&
        completedLectures >= totalLectures;
  }

  BacklogItem copyWith({
    String? id,
    String? topic,
    int? totalLectures,
    int? minutesPerLecture,
    List<BacklogLecture>? lectures,
    DateTime? createdAt,
  }) {
    return BacklogItem(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      totalLectures: totalLectures ?? this.totalLectures,
      minutesPerLecture:
          minutesPerLecture ?? this.minutesPerLecture,
      lectures: lectures ?? this.lectures,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topic': topic,
      'totalLectures': totalLectures,
      'minutesPerLecture': minutesPerLecture,
      'lectures':
          lectures.map((lecture) => lecture.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BacklogItem.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawLectures = json['lectures'];

    final lectures = rawLectures is List
        ? rawLectures
            .whereType<Map>()
            .map(
              (item) => BacklogLecture.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : <BacklogLecture>[];

    final totalLectures =
        (json['totalLectures'] as num?)?.toInt() ?? 1;

    final finalLectures = lectures.isEmpty
        ? List.generate(
            totalLectures,
            (index) => BacklogLecture(
              number: index + 1,
            ),
          )
        : lectures;

    return BacklogItem(
      id: json['id']?.toString() ?? '',
      topic: json['topic']?.toString() ?? '',
      totalLectures: totalLectures,
      minutesPerLecture:
          (json['minutesPerLecture'] as num?)?.toInt() ?? 60,
      lectures: finalLectures,
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }
}