class ExamModel {
  final String id;
  final String name;
  final DateTime examDate;

  /// Total marks for the exam.
  final int totalMarks;

  /// Target percentage for the exam.
  final double targetPercentage;

  /// IDs of chapters selected for this exam.
  final List<String> chapterIds;

  /// Topics specifically added for this exam.
  final List<String> topics;

  ExamModel({
    required this.id,
    required this.name,
    required this.examDate,
    this.totalMarks = 100,
    this.targetPercentage = 80,
    this.chapterIds = const [],
    this.topics = const [],
  });

  ExamModel copyWith({
    String? id,
    String? name,
    DateTime? examDate,
    int? totalMarks,
    double? targetPercentage,
    List<String>? chapterIds,
    List<String>? topics,
  }) {
    return ExamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      examDate: examDate ?? this.examDate,
      totalMarks: totalMarks ?? this.totalMarks,
      targetPercentage:
          targetPercentage ?? this.targetPercentage,
      chapterIds:
          chapterIds ?? this.chapterIds,
      topics:
          topics ?? this.topics,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'examDate': examDate.toIso8601String(),
      'totalMarks': totalMarks,
      'targetPercentage': targetPercentage,
      'chapterIds': chapterIds,
      'topics': topics,
    };
  }

  factory ExamModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ExamModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      examDate:
          DateTime.tryParse(
                json['examDate'] ?? '',
              ) ??
              DateTime.now(),

      // Supports old saved exams.
      totalMarks:
          (json['totalMarks'] ?? 100) is int
              ? json['totalMarks'] ?? 100
              : (json['totalMarks'] ?? 100)
                  .toInt(),

      targetPercentage:
          (json['targetPercentage'] ?? 80)
              .toDouble(),

      chapterIds:
          List<String>.from(
        json['chapterIds'] ?? [],
      ),

      topics:
          List<String>.from(
        json['topics'] ?? [],
      ),
    );
  }
}