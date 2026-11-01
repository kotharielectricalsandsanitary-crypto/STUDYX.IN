import 'dart:convert';

class GoalModel {
  final String id;
  final String title;
  final String description;
  final String target;
  final DateTime? targetDate;
  final double progress;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GoalModel({
    required this.id,
    required this.title,
    this.description = '',
    this.target = '',
    this.targetDate,
    this.progress = 0.0,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  GoalModel copyWith({
    String? id,
    String? title,
    String? description,
    String? target,
    DateTime? targetDate,
    double? progress,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GoalModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      target: target ?? this.target,
      targetDate: targetDate ?? this.targetDate,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'target': target,
      'targetDate': targetDate?.toIso8601String(),
      'progress': progress,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory GoalModel.fromMap(Map<String, dynamic> map) {
    return GoalModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      target: map['target']?.toString() ?? '',
      targetDate: map['targetDate'] != null &&
              map['targetDate'].toString().isNotEmpty
          ? DateTime.tryParse(
              map['targetDate'].toString(),
            )
          : null,
      progress: _parseDouble(map['progress']),
      isCompleted: map['isCompleted'] == true,
      createdAt: DateTime.tryParse(
            map['createdAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(
            map['updatedAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }

  String toJson() {
    return jsonEncode(toMap());
  }

  factory GoalModel.fromJson(String source) {
    return GoalModel.fromMap(
      Map<String, dynamic>.from(
        jsonDecode(source) as Map,
      ),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }
}