import '../../models/task_model.dart';
import '../../models/chapter_model.dart';
import '../../models/subject_model.dart';
import '../../providers/study_session_provider.dart';

class AIContext {
  final DateTime generatedAt;

  final List<AITaskContext> tasks;
  final List<AISubjectContext> subjects;
  final List<AIStudySessionContext> studySessions;

  AIContext({
    required this.generatedAt,
    required this.tasks,
    required this.subjects,
    required this.studySessions,
  });

  Map<String, dynamic> toJson() {
    return {
      'generatedAt': generatedAt.toIso8601String(),
      'tasks': tasks.map((e) => e.toJson()).toList(),
      'subjects': subjects.map((e) => e.toJson()).toList(),
      'studySessions':
          studySessions.map((e) => e.toJson()).toList(),
    };
  }
}

class AITaskContext {
  final String id;
  final String title;
  final String description;
  final String type;
  final String deadline;
  final int priority;
  final int estimatedMinutes;
  final bool completed;
  final String? subjectId;
  final String? chapterId;
  final String? completedAt;

  AITaskContext({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.deadline,
    required this.priority,
    required this.estimatedMinutes,
    required this.completed,
    this.subjectId,
    this.chapterId,
    this.completedAt,
  });

  factory AITaskContext.fromTask(TaskModel task) {
    return AITaskContext(
      id: task.id,
      title: task.title,
      description: task.description,
      type: task.type.toString(),
      deadline: task.deadline.toIso8601String(),
      priority: task.priority,
      estimatedMinutes: task.estimatedMinutes,
      completed: task.isCompleted,
      subjectId: task.subjectId,
      chapterId: task.chapterId,
      completedAt: task.completedAt?.toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'deadline': deadline,
      'priority': priority,
      'estimatedMinutes': estimatedMinutes,
      'completed': completed,
      'subjectId': subjectId,
      'chapterId': chapterId,
      'completedAt': completedAt,
    };
  }
}

class AISubjectContext {
  final String id;
  final String name;
  final List<AIChapterContext> chapters;

  AISubjectContext({
    required this.id,
    required this.name,
    required this.chapters,
  });

  factory AISubjectContext.fromSubject(
    SubjectModel subject,
  ) {
    return AISubjectContext(
      id: subject.id,
      name: subject.name,
      chapters: subject.chapters
          .map(AIChapterContext.fromChapter)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'chapters':
          chapters.map((e) => e.toJson()).toList(),
    };
  }
}

class AIChapterContext {
  final String id;
  final String name;
  final int estimatedMinutes;
  final bool studied;
  final String? studiedAt;
  final String? lastRevisionAt;
  final String? nextRevisionAt;
  final List<AIStepContext> steps;

  AIChapterContext({
    required this.id,
    required this.name,
    required this.estimatedMinutes,
    required this.studied,
    this.studiedAt,
    this.lastRevisionAt,
    this.nextRevisionAt,
    required this.steps,
  });

  factory AIChapterContext.fromChapter(
    ChapterModel chapter,
  ) {
    return AIChapterContext(
      id: chapter.id,
      name: chapter.name,
      estimatedMinutes: chapter.estimatedMinutes,
      studied: chapter.studiedAt != null,
      studiedAt:
          chapter.studiedAt?.toIso8601String(),
      lastRevisionAt:
          chapter.lastRevisionAt?.toIso8601String(),
      nextRevisionAt:
          chapter.nextRevisionAt?.toIso8601String(),
      steps: chapter.steps
          .map(
            (step) => AIStepContext(
              id: step.id,
              title: step.title,
              completed: step.completed,
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'estimatedMinutes': estimatedMinutes,
      'studied': studied,
      'studiedAt': studiedAt,
      'lastRevisionAt': lastRevisionAt,
      'nextRevisionAt': nextRevisionAt,
      'steps':
          steps.map((e) => e.toJson()).toList(),
    };
  }
}

class AIStepContext {
  final String id;
  final String title;
  final bool completed;

  AIStepContext({
    required this.id,
    required this.title,
    required this.completed,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
    };
  }
}

class AIStudySessionContext {
  final DateTime date;
  final int seconds;

  AIStudySessionContext({
    required this.date,
    required this.seconds,
  });

  factory AIStudySessionContext.fromSession(
    StudySession session,
  ) {
    return AIStudySessionContext(
      date: session.date,
      seconds: session.seconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'seconds': seconds,
    };
  }
}