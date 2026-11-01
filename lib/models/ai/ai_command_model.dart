import '../task_model.dart';

/// ============================================================
/// AI ACTION TYPES
/// ============================================================

enum AIActionType {
  createSubject,
  createChapter,
  addChapterStep,

  completeStep,
  uncompleteStep,

  markChapterStudied,
  markRevisionDone,

  createTask,
  completeTask,
  uncompleteTask,
  deleteTask,

  deleteChapter,
  deleteSubject,

  unknown,
}

/// ============================================================
/// AI ACTION
/// ============================================================

class AIAction {
  final AIActionType type;
  final String description;

  // Subject
  final String? subjectId;
  final String? subjectName;

  // Chapter
  final String? chapterId;
  final String? chapterName;

  // Chapter step
  final String? stepId;
  final String? stepTitle;

  // Task
  final String? taskId;
  final String? taskTitle;
  final String? taskDescription;
  final TaskType? taskType;

  // Dates / task settings
  final DateTime? deadline;
  final int priority;
  final int estimatedMinutes;

  const AIAction({
    required this.type,
    this.description = '',
    this.subjectId,
    this.subjectName,
    this.chapterId,
    this.chapterName,
    this.stepId,
    this.stepTitle,
    this.taskId,
    this.taskTitle,
    this.taskDescription,
    this.taskType,
    this.deadline,
    this.priority = 5,
    this.estimatedMinutes = 30,
  });

  // ============================================================
  // FROM JSON
  // ============================================================

  factory AIAction.fromJson(
    Map<String, dynamic> json,
  ) {
    return AIAction(
      type: _parseActionType(
        json['type'] ??
            json['action'] ??
            json['actionType'],
      ),

      description:
          _stringOrNull(
            json['description'],
          ) ??
          '',

      subjectId: _stringOrNull(
        json['subjectId'] ??
            json['subject_id'],
      ),

      subjectName: _stringOrNull(
        json['subjectName'] ??
            json['subject_name'] ??
            json['subject'],
      ),

      chapterId: _stringOrNull(
        json['chapterId'] ??
            json['chapter_id'],
      ),

      chapterName: _stringOrNull(
        json['chapterName'] ??
            json['chapter_name'] ??
            json['chapter'],
      ),

      stepId: _stringOrNull(
        json['stepId'] ??
            json['step_id'],
      ),

      stepTitle: _stringOrNull(
        json['stepTitle'] ??
            json['step_title'] ??
            json['step'],
      ),

      taskId: _stringOrNull(
        json['taskId'] ??
            json['task_id'],
      ),

      taskTitle: _stringOrNull(
        json['taskTitle'] ??
            json['task_title'] ??
            json['task'],
      ),

      taskDescription: _stringOrNull(
        json['taskDescription'] ??
            json['task_description'],
      ),

      taskType: _parseTaskType(
        json['taskType'] ??
            json['task_type'],
      ),

      deadline: _parseDate(
        json['deadline'] ??
            json['dueDate'] ??
            json['due_date'],
      ),

      priority: _parseInt(
        json['priority'],
        5,
      ).clamp(1, 10),

      estimatedMinutes: _parseInt(
        json['estimatedMinutes'] ??
            json['estimated_minutes'],
        30,
      ).clamp(1, 1440),
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'description': description,

      'subjectId': subjectId,
      'subjectName': subjectName,

      'chapterId': chapterId,
      'chapterName': chapterName,

      'stepId': stepId,
      'stepTitle': stepTitle,

      'taskId': taskId,
      'taskTitle': taskTitle,
      'taskDescription': taskDescription,
      'taskType': taskType?.name,

      'deadline': deadline?.toIso8601String(),

      'priority': priority,
      'estimatedMinutes': estimatedMinutes,
    };
  }

  // ============================================================
  // ACTION TYPE PARSER
  // ============================================================

  static AIActionType _parseActionType(
    dynamic value,
  ) {
    if (value == null) {
      return AIActionType.unknown;
    }

    final normalized = value
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    switch (normalized) {
      // SUBJECT
      case 'createsubject':
      case 'create_subject':
      case 'addsubject':
      case 'add_subject':
        return AIActionType.createSubject;

      // CHAPTER
      case 'createchapter':
      case 'create_chapter':
      case 'addchapter':
      case 'add_chapter':
        return AIActionType.createChapter;

      // STEP
      case 'addchapterstep':
      case 'add_chapter_step':
      case 'createstep':
      case 'create_step':
      case 'addstep':
      case 'add_step':
        return AIActionType.addChapterStep;

      // COMPLETE STEP
      case 'completestep':
      case 'complete_step':
      case 'tickstep':
      case 'tick_step':
        return AIActionType.completeStep;

      // UNCOMPLETE STEP
      case 'uncompletestep':
      case 'uncomplete_step':
      case 'un_tick_step':
      case 'untickstep':
      case 'untick_step':
        return AIActionType.uncompleteStep;

      // STUDIED
      case 'markchapterstudied':
      case 'mark_chapter_studied':
      case 'completechapter':
      case 'complete_chapter':
      case 'studychapter':
      case 'study_chapter':
        return AIActionType.markChapterStudied;

      // REVISION
      case 'markrevisiondone':
      case 'mark_revision_done':
      case 'completerevision':
      case 'complete_revision':
      case 'revisiondone':
      case 'revision_done':
        return AIActionType.markRevisionDone;

      // CREATE TASK
      case 'createtask':
      case 'create_task':
      case 'addtask':
      case 'add_task':
        return AIActionType.createTask;

      // COMPLETE TASK
      case 'completetask':
      case 'complete_task':
      case 'finishtask':
      case 'finish_task':
        return AIActionType.completeTask;

      // UNCOMPLETE TASK
      case 'uncompletetask':
      case 'uncomplete_task':
      case 'undotask':
      case 'undo_task':
        return AIActionType.uncompleteTask;

      // DELETE TASK
      case 'deletetask':
      case 'delete_task':
      case 'removetask':
      case 'remove_task':
        return AIActionType.deleteTask;

      // DELETE CHAPTER
      case 'deletechapter':
      case 'delete_chapter':
      case 'removechapter':
      case 'remove_chapter':
        return AIActionType.deleteChapter;

      // DELETE SUBJECT
      case 'deletesubject':
      case 'delete_subject':
      case 'removesubject':
      case 'remove_subject':
        return AIActionType.deleteSubject;

      default:
        return AIActionType.unknown;
    }
  }

  // ============================================================
  // TASK TYPE
  // ============================================================

  static TaskType? _parseTaskType(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final normalized = value
        .toString()
        .trim()
        .toLowerCase();

    for (final type in TaskType.values) {
      if (type.name.toLowerCase() == normalized) {
        return type;
      }
    }

    return TaskType.study;
  }

  // ============================================================
  // STRING
  // ============================================================

  static String? _stringOrNull(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final text = value
        .toString()
        .trim();

    if (text.isEmpty ||
        text.toLowerCase() == 'null') {
      return null;
    }

    return text;
  }

  // ============================================================
  // DATE
  // ============================================================

  static DateTime? _parseDate(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  // ============================================================
  // INTEGER
  // ============================================================

  static int _parseInt(
    dynamic value,
    int fallback,
  ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  // ============================================================
  // DEBUG
  // ============================================================

  @override
  String toString() {
    return 'AIAction('
        'type: ${type.name}, '
        'subject: $subjectName, '
        'chapter: $chapterName, '
        'step: $stepTitle, '
        'task: $taskTitle'
        ')';
  }
}