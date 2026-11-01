enum TaskType {
  study,
  revision,
  practice,
  test,
  backlog,
  custom,
}

class TaskModel {
  final String id;
  final String title;
  final String description;
  final TaskType type;

  final DateTime deadline;
  final DateTime createdAt;

  final bool isCompleted;
  final DateTime? completedAt;

  final int priority;
  final int estimatedMinutes;

  final String? subjectId;
  final String? chapterId;

  const TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    this.type = TaskType.study,
    required this.deadline,
    required this.createdAt,
    this.isCompleted = false,
    this.completedAt,
    this.priority = 5,
    this.estimatedMinutes = 30,
    this.subjectId,
    this.chapterId,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    TaskType? type,
    DateTime? deadline,
    DateTime? createdAt,
    bool? isCompleted,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    int? priority,
    int? estimatedMinutes,
    String? subjectId,
    String? chapterId,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: clearCompletedAt
          ? null
          : completedAt ?? this.completedAt,
      priority: priority ?? this.priority,
      estimatedMinutes:
          estimatedMinutes ?? this.estimatedMinutes,
      subjectId: subjectId ?? this.subjectId,
      chapterId: chapterId ?? this.chapterId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'deadline': deadline.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'priority': priority,
      'estimatedMinutes': estimatedMinutes,
      'subjectId': subjectId,
      'chapterId': chapterId,
    };
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    TaskType parseTaskType(dynamic value) {
      final typeName = value?.toString() ?? '';

      return TaskType.values.firstWhere(
        (type) => type.name == typeName,
        orElse: () => TaskType.study,
      );
    }

    DateTime parseDate(
      dynamic value,
      DateTime fallback,
    ) {
      return DateTime.tryParse(
            value?.toString() ?? '',
          ) ??
          fallback;
    }

    int parseInt(
      dynamic value,
      int fallback,
    ) {
      if (value is int) return value;

      if (value is num) {
        return value.toInt();
      }

      return int.tryParse(
            value?.toString() ?? '',
          ) ??
          fallback;
    }

    bool parseBool(dynamic value) {
      if (value is bool) return value;

      return value?.toString().toLowerCase() == 'true';
    }

    final now = DateTime.now();

    return TaskModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      type: parseTaskType(json['type']),
      deadline: parseDate(
        json['deadline'],
        now,
      ),
      createdAt: parseDate(
        json['createdAt'],
        now,
      ),
      isCompleted: parseBool(json['isCompleted']),
      completedAt: DateTime.tryParse(
        json['completedAt']?.toString() ?? '',
      ),
      priority: parseInt(
        json['priority'],
        5,
      ).clamp(1, 10),
      estimatedMinutes: parseInt(
        json['estimatedMinutes'],
        30,
      ) < 1
          ? 1
          : parseInt(
              json['estimatedMinutes'],
              30,
            ),
      subjectId: json['subjectId']?.toString(),
      chapterId: json['chapterId']?.toString(),
    );
  }

  @override
  String toString() {
    return 'TaskModel('
        'id: $id, '
        'title: $title, '
        'type: ${type.name}, '
        'isCompleted: $isCompleted'
        ')';
  }
}