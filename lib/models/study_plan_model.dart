
enum StudyPlanTaskType {
  backlog,
  newChapter,
  revision,
  practice,
  test,
  custom,
}

class StudyPlanTask {
  final String id;
  final String title;
  final String description;
  final StudyPlanTaskType type;

  final String? subjectId;
  final String? chapterId;

  final int estimatedMinutes;
  final int priority;

  final DateTime date;
  final DateTime createdAt;

  final bool isCompleted;

  const StudyPlanTask({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.subjectId,
    this.chapterId,
    required this.estimatedMinutes,
    required this.priority,
    required this.date,
    required this.createdAt,
    this.isCompleted = false,
  });

  StudyPlanTask copyWith({
    bool? isCompleted,
  }) {
    return StudyPlanTask(
      id: id,
      title: title,
      description: description,
      type: type,
      subjectId: subjectId,
      chapterId: chapterId,
      estimatedMinutes: estimatedMinutes,
      priority: priority,
      date: date,
      createdAt: createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'subjectId': subjectId,
      'chapterId': chapterId,
      'estimatedMinutes': estimatedMinutes,
      'priority': priority,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory StudyPlanTask.fromJson(
    Map<String, dynamic> json,
  ) {
    final typeName =
        json['type']?.toString() ?? '';

    final type = StudyPlanTaskType.values.firstWhere(
      (item) => item.name == typeName,
      orElse: () => StudyPlanTaskType.custom,
    );

    return StudyPlanTask(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      type: type,
      subjectId: json['subjectId']?.toString(),
      chapterId: json['chapterId']?.toString(),
      estimatedMinutes:
          (json['estimatedMinutes'] as num?)
                  ?.toInt() ??
              30,
      priority:
          (json['priority'] as num?)?.toInt() ?? 5,
      date:
          DateTime.tryParse(
            json['date']?.toString() ?? '',
          ) ??
          DateTime.now(),
      createdAt:
          DateTime.tryParse(
            json['createdAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
      isCompleted: json['isCompleted'] == true,
    );
  }
}

class StudyPlanModel {
  final String id;
  final DateTime date;
  final int targetMinutes;
  final List<StudyPlanTask> tasks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudyPlanModel({
    required this.id,
    required this.date,
    required this.targetMinutes,
    required this.tasks,
    required this.createdAt,
    required this.updatedAt,
  });

  int get totalMinutes {
    return tasks.fold(
      0,
      (total, task) =>
          total + task.estimatedMinutes,
    );
  }

  int get completedMinutes {
    return tasks
        .where((task) => task.isCompleted)
        .fold(
          0,
          (total, task) =>
              total + task.estimatedMinutes,
        );
  }

  double get progress {
    if (targetMinutes <= 0) return 0;

    return completedMinutes / targetMinutes;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'targetMinutes': targetMinutes,
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

