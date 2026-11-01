import '../../models/exam_model.dart';
class ExamModel {
  final String id;
  final String name;
  final DateTime examDate;
  final int totalMarks;
  final double targetPercentage;
  final List<String> subjectIds;

  ExamModel({
    required this.id,
    required this.name,
    required this.examDate,
    required this.totalMarks,
    required this.targetPercentage,
    required this.subjectIds,
  });

  ExamModel copyWith({
    String? name,
    DateTime? examDate,
    int? totalMarks,
    double? targetPercentage,
    List<String>? subjectIds,
  }) {
    return ExamModel(
      id: id,
      name: name ?? this.name,
      examDate: examDate ?? this.examDate,
      totalMarks: totalMarks ?? this.totalMarks,
      targetPercentage:
          targetPercentage ?? this.targetPercentage,
      subjectIds:
          subjectIds ?? this.subjectIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'examDate': examDate.toIso8601String(),
      'totalMarks': totalMarks,
      'targetPercentage': targetPercentage,
      'subjectIds': subjectIds,
    };
  }

  factory ExamModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ExamModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      examDate: DateTime.parse(
        json['examDate'],
      ),
      totalMarks:
          json['totalMarks'] ?? 30,
      targetPercentage:
          (json['targetPercentage'] ?? 80).toDouble(),
      subjectIds:
          List<String>.from(
        json['subjectIds'] ?? [],
      ),
    );
  }
}