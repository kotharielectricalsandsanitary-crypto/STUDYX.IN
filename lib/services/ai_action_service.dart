
import '../../models/ai/ai_action_result.dart';
import '../../models/ai/ai_command_model.dart';
import '../../models/chapter_model.dart';
import '../../models/task_model.dart';

import '../../providers/syllabus_provider.dart';
import '../../providers/task_provider.dart';

class AIActionService {
  final SyllabusProvider syllabusProvider;
  final TaskProvider taskProvider;

  AIActionService({
    required this.syllabusProvider,
    required this.taskProvider,
  });

  // ============================================================
  // EXECUTE MULTIPLE ACTIONS
  // ============================================================

  Future<List<AIActionResult>> executeActions(
    List<AIAction> actions,
  ) async {
    final results = <AIActionResult>[];

    for (final action in actions) {
      final result = await executeAction(action);
      results.add(result);
    }

    return results;
  }

  // ============================================================
  // EXECUTE ONE ACTION
  // ============================================================

  Future<AIActionResult> executeAction(
    AIAction action,
  ) async {
    try {
      switch (action.type) {
        case AIActionType.createSubject:
          return await _createSubject(action);

        case AIActionType.createChapter:
          return await _createChapter(action);

        case AIActionType.addChapterStep:
          return await _addChapterStep(action);

        case AIActionType.completeStep:
          return await _toggleStep(
            action,
            completed: true,
          );

        case AIActionType.uncompleteStep:
          return await _toggleStep(
            action,
            completed: false,
          );

        case AIActionType.markChapterStudied:
          return await _markChapterStudied(action);

        case AIActionType.markRevisionDone:
          return await _markRevisionDone(action);

        case AIActionType.createTask:
          return await _createTask(action);

        case AIActionType.completeTask:
          return await _completeTask(action);

        case AIActionType.uncompleteTask:
          return await _uncompleteTask(action);

        case AIActionType.deleteTask:
          return await _deleteTask(action);

        case AIActionType.deleteChapter:
          return await _deleteChapter(action);

        case AIActionType.deleteSubject:
          return await _deleteSubject(action);

        case AIActionType.unknown:
          return const AIActionResult(
            success: false,
            message: 'I could not understand that AI action.',
          );
      }
    } catch (e) {
      return AIActionResult(
        success: false,
        message: 'Action failed: $e',
        error: e.toString(),
      );
    }
  }

  // ============================================================
  // CREATE SUBJECT
  // ============================================================

  Future<AIActionResult> _createSubject(
    AIAction action,
  ) async {
    final name = _clean(action.subjectName);

    if (name == null) {
      return const AIActionResult(
        success: false,
        message: 'Subject name is missing.',
      );
    }

    final existing =
        syllabusProvider.findSubjectByName(name);

    if (existing != null) {
      return AIActionResult(
        success: true,
        skipped: true,
        message: 'Subject "$name" already exists.',
        subjectId: existing.id,
        subjectName: existing.name,
      );
    }

    final subject =
        await syllabusProvider.addSubject(name);

    return AIActionResult(
      success: true,
      message: 'Added subject "${subject.name}".',
      subjectId: subject.id,
      subjectName: subject.name,
    );
  }

  // ============================================================
  // CREATE CHAPTER
  // ============================================================

  Future<AIActionResult> _createChapter(
    AIAction action,
  ) async {
    final subjectName =
        _clean(action.subjectName);

    final chapterName =
        _clean(action.chapterName);

    if (subjectName == null) {
      return const AIActionResult(
        success: false,
        message: 'Subject name is missing.',
      );
    }

    if (chapterName == null) {
      return const AIActionResult(
        success: false,
        message: 'Chapter name is missing.',
      );
    }

    final chapter =
        await syllabusProvider.getOrCreateChapter(
      subjectName: subjectName,
      chapterName: chapterName,
      estimatedMinutes:
          _safeEstimatedMinutes(
        action.estimatedMinutes,
      ),
    );

    final subject =
        syllabusProvider.findSubjectByName(
      subjectName,
    );

    return AIActionResult(
      success: true,
      message:
          'Added chapter "${chapter.name}" to "$subjectName".',
      subjectId: subject?.id,
      subjectName: subject?.name ?? subjectName,
      chapterId: chapter.id,
      chapterName: chapter.name,
    );
  }

  // ============================================================
  // ADD CHAPTER STEP
  // ============================================================

  Future<AIActionResult> _addChapterStep(
    AIAction action,
  ) async {
    final subjectId =
        await _resolveSubjectId(action);

    if (subjectId == null) {
      return const AIActionResult(
        success: false,
        message: 'Could not find the subject.',
      );
    }

    final chapterId =
        await _resolveChapterId(
      action,
      subjectId,
    );

    if (chapterId == null) {
      return const AIActionResult(
        success: false,
        message: 'Could not find the chapter.',
      );
    }

    final stepTitle =
        _clean(action.stepTitle);

    if (stepTitle == null) {
      return const AIActionResult(
        success: false,
        message: 'Step title is missing.',
      );
    }

    final chapter =
        syllabusProvider.findChapterById(
      subjectId: subjectId,
      chapterId: chapterId,
    );

    if (chapter == null) {
      return const AIActionResult(
        success: false,
        message: 'Chapter not found.',
      );
    }

    final existingStep =
        _findStepByTitle(
      chapter,
      stepTitle,
    );

    if (existingStep != null) {
      return AIActionResult(
        success: true,
        skipped: true,
        message:
            'Step "$stepTitle" already exists in "${chapter.name}".',
        subjectId: subjectId,
        chapterId: chapterId,
        chapterName: chapter.name,
      );
    }

    final newStep = ChapterStep(
      id:
          'step_${DateTime.now().microsecondsSinceEpoch}',
      title: stepTitle,
    );

    final updatedSteps = [
      ...chapter.steps,
      newStep,
    ];

    await syllabusProvider.updateChapterSteps(
      subjectId: subjectId,
      chapterId: chapterId,
      steps: updatedSteps,
    );

    return AIActionResult(
      success: true,
      message:
          'Added step "$stepTitle" to "${chapter.name}".',
      subjectId: subjectId,
      chapterId: chapterId,
      chapterName: chapter.name,
      data: {
        'stepId': newStep.id,
        'stepTitle': newStep.title,
      },
    );
  }

  // ============================================================
  // COMPLETE / UNCOMPLETE STEP
  // ============================================================

  Future<AIActionResult> _toggleStep(
    AIAction action, {
    required bool completed,
  }) async {
    final subjectId =
        await _resolveSubjectId(action);

    if (subjectId == null) {
      return const AIActionResult(
        success: false,
        message: 'Subject not found.',
      );
    }

    final chapterId =
        await _resolveChapterId(
      action,
      subjectId,
    );

    if (chapterId == null) {
      return const AIActionResult(
        success: false,
        message: 'Chapter not found.',
      );
    }

    final chapter =
        syllabusProvider.findChapterById(
      subjectId: subjectId,
      chapterId: chapterId,
    );

    if (chapter == null) {
      return const AIActionResult(
        success: false,
        message: 'Chapter not found.',
      );
    }

    final step =
        _findStep(
      chapter,
      action,
    );

    if (step == null) {
      return AIActionResult(
        success: false,
        message:
            'Could not find the step in "${chapter.name}".',
      );
    }

    await syllabusProvider.toggleStep(
      subjectId: subjectId,
      chapterId: chapterId,
      stepId: step.id,
      completed: completed,
    );

    return AIActionResult(
      success: true,
      message: completed
          ? 'Marked "${step.title}" complete in "${chapter.name}".'
          : 'Marked "${step.title}" incomplete in "${chapter.name}".',
      subjectId: subjectId,
      chapterId: chapterId,
      chapterName: chapter.name,
      data: {
        'stepId': step.id,
        'stepTitle': step.title,
        'completed': completed,
      },
    );
  }

  // ============================================================
  // MARK CHAPTER STUDIED
  // ============================================================

  Future<AIActionResult> _markChapterStudied(
    AIAction action,
  ) async {
    final subjectId =
        await _resolveSubjectId(action);

    if (subjectId == null) {
      return const AIActionResult(
        success: false,
        message: 'Subject not found.',
      );
    }

    final chapterId =
        await _resolveChapterId(
      action,
      subjectId,
    );

    if (chapterId == null) {
      return const AIActionResult(
        success: false,
        message: 'Chapter not found.',
      );
    }

    await syllabusProvider.markChapterStudied(
      subjectId: subjectId,
      chapterId: chapterId,
    );

    final chapter =
        syllabusProvider.findChapterById(
      subjectId: subjectId,
      chapterId: chapterId,
    );

    return AIActionResult(
      success: true,
      message:
          'Marked "${chapter?.name ?? 'chapter'}" as studied.',
      subjectId: subjectId,
      chapterId: chapterId,
      chapterName: chapter?.name,
    );
  }

  // ============================================================
  // MARK REVISION DONE
  // ============================================================

  Future<AIActionResult> _markRevisionDone(
    AIAction action,
  ) async {
    final subjectId =
        await _resolveSubjectId(action);

    if (subjectId == null) {
      return const AIActionResult(
        success: false,
        message: 'Subject not found.',
      );
    }

    final chapterId =
        await _resolveChapterId(
      action,
      subjectId,
    );

    if (chapterId == null) {
      return const AIActionResult(
        success: false,
        message: 'Chapter not found.',
      );
    }

    await syllabusProvider.markChapterRevisionDone(
      subjectId: subjectId,
      chapterId: chapterId,
    );

    final chapter =
        syllabusProvider.findChapterById(
      subjectId: subjectId,
      chapterId: chapterId,
    );

    return AIActionResult(
      success: true,
      message:
          'Revision completed for "${chapter?.name ?? 'chapter'}".',
      subjectId: subjectId,
      chapterId: chapterId,
      chapterName: chapter?.name,
    );
  }

  // ============================================================
  // CREATE TASK
  // ============================================================

  Future<AIActionResult> _createTask(
    AIAction action,
  ) async {
    final title =
        _clean(action.taskTitle);

    if (title == null) {
      return const AIActionResult(
        success: false,
        message: 'Task title is missing.',
      );
    }

    String? subjectId =
        _clean(action.subjectId);

    if (subjectId == null) {
      final subjectName =
          _clean(action.subjectName);

      if (subjectName != null) {
        subjectId =
            syllabusProvider
                .findSubjectByName(subjectName)
                ?.id;
      }
    }

    String? chapterId =
        _clean(action.chapterId);

    if (chapterId == null &&
        subjectId != null) {
      final chapterName =
          _clean(action.chapterName);

      if (chapterName != null) {
        chapterId =
            syllabusProvider.findChapterByName(
          subjectId: subjectId,
          chapterName: chapterName,
        )?.id;
      }
    }

    final deadline =
        action.deadline ?? DateTime.now();

    final existing =
        _findSimilarPendingTask(
      title: title,
      subjectId: subjectId,
      chapterId: chapterId,
    );

    if (existing != null) {
      return AIActionResult(
        success: true,
        skipped: true,
        message: 'Task "$title" already exists.',
        taskId: existing.id,
        taskTitle: existing.title,
      );
    }

    await taskProvider.createTask(
      title: title,
      description:
          action.taskDescription ?? '',
      type:
          action.taskType ?? TaskType.study,
      deadline: deadline,
      priority:
          action.priority.clamp(1, 10),
      estimatedMinutes:
          _safeEstimatedMinutes(
        action.estimatedMinutes,
      ),
      subjectId: subjectId,
      chapterId: chapterId,
    );

    return AIActionResult(
      success: true,
      message: 'Created task "$title".',
      subjectId: subjectId,
      chapterId: chapterId,
      taskTitle: title,
      data: {
        'deadline': deadline.toIso8601String(),
      },
    );
  }

  // ============================================================
  // COMPLETE TASK
  // ============================================================

  Future<AIActionResult> _completeTask(
    AIAction action,
  ) async {
    final task =
        _findTask(action);

    if (task == null) {
      return const AIActionResult(
        success: false,
        message: 'Task not found.',
      );
    }

    await taskProvider.completeTask(
      task.id,
    );

    return AIActionResult(
      success: true,
      message:
          'Completed task "${task.title}".',
      taskId: task.id,
      taskTitle: task.title,
    );
  }

  // ============================================================
  // UNCOMPLETE TASK
  // ============================================================

  Future<AIActionResult> _uncompleteTask(
    AIAction action,
  ) async {
    final task =
        _findTask(action);

    if (task == null) {
      return const AIActionResult(
        success: false,
        message: 'Task not found.',
      );
    }

    await taskProvider.uncompleteTask(
      task.id,
    );

    return AIActionResult(
      success: true,
      message:
          'Marked task "${task.title}" as pending.',
      taskId: task.id,
      taskTitle: task.title,
    );
  }

  // ============================================================
  // DELETE TASK
  // ============================================================

  Future<AIActionResult> _deleteTask(
    AIAction action,
  ) async {
    final task =
        _findTask(action);

    if (task == null) {
      return const AIActionResult(
        success: false,
        message: 'Task not found.',
      );
    }

    await taskProvider.deleteTask(
      task.id,
    );

    return AIActionResult(
      success: true,
      message:
          'Deleted task "${task.title}".',
      taskId: task.id,
      taskTitle: task.title,
    );
  }

  // ============================================================
  // DELETE CHAPTER
  // ============================================================

  Future<AIActionResult> _deleteChapter(
    AIAction action,
  ) async {
    final subjectId =
        await _resolveSubjectId(action);

    if (subjectId == null) {
      return const AIActionResult(
        success: false,
        message: 'Subject not found.',
      );
    }

    final chapterId =
        await _resolveChapterId(
      action,
      subjectId,
    );

    if (chapterId == null) {
      return const AIActionResult(
        success: false,
        message: 'Chapter not found.',
      );
    }

    final chapter =
        syllabusProvider.findChapterById(
      subjectId: subjectId,
      chapterId: chapterId,
    );

    await syllabusProvider.deleteChapter(
      subjectId,
      chapterId,
    );

    return AIActionResult(
      success: true,
      message:
          'Deleted chapter "${chapter?.name ?? 'chapter'}".',
      subjectId: subjectId,
      chapterId: chapterId,
      chapterName: chapter?.name,
    );
  }

  // ============================================================
  // DELETE SUBJECT
  // ============================================================

  Future<AIActionResult> _deleteSubject(
    AIAction action,
  ) async {
    String? subjectId =
        _clean(action.subjectId);

    if (subjectId == null) {
      final subjectName =
          _clean(action.subjectName);

      if (subjectName != null) {
        subjectId =
            syllabusProvider
                .findSubjectByName(subjectName)
                ?.id;
      }
    }

    if (subjectId == null) {
      return const AIActionResult(
        success: false,
        message: 'Subject not found.',
      );
    }

    final subject =
        syllabusProvider.findSubjectById(
      subjectId,
    );

    await syllabusProvider.deleteSubject(
      subjectId,
    );

    return AIActionResult(
      success: true,
      message:
          'Deleted subject "${subject?.name ?? 'subject'}".',
      subjectId: subjectId,
      subjectName: subject?.name,
    );
  }

  // ============================================================
  // RESOLVE SUBJECT
  // ============================================================

  Future<String?> _resolveSubjectId(
    AIAction action,
  ) async {
    final subjectId =
        _clean(action.subjectId);

    if (subjectId != null) {
      final subject =
          syllabusProvider.findSubjectById(
        subjectId,
      );

      if (subject != null) {
        return subject.id;
      }
    }

    final subjectName =
        _clean(action.subjectName);

    if (subjectName != null) {
      final subject =
          syllabusProvider.findSubjectByName(
        subjectName,
      );

      if (subject != null) {
        return subject.id;
      }
    }

    return null;
  }

  // ============================================================
  // RESOLVE CHAPTER
  // ============================================================

  Future<String?> _resolveChapterId(
    AIAction action,
    String subjectId,
  ) async {
    final chapterId =
        _clean(action.chapterId);

    if (chapterId != null) {
      final chapter =
          syllabusProvider.findChapterById(
        subjectId: subjectId,
        chapterId: chapterId,
      );

      if (chapter != null) {
        return chapter.id;
      }
    }

    final chapterName =
        _clean(action.chapterName);

    if (chapterName != null) {
      final chapter =
          syllabusProvider.findChapterByName(
        subjectId: subjectId,
        chapterName: chapterName,
      );

      if (chapter != null) {
        return chapter.id;
      }
    }

    return null;
  }

  // ============================================================
  // FIND STEP
  // ============================================================

  ChapterStep? _findStep(
    ChapterModel chapter,
    AIAction action,
  ) {
    final stepId =
        _clean(action.stepId);

    if (stepId != null) {
      for (final step in chapter.steps) {
        if (step.id == stepId) {
          return step;
        }
      }
    }

    final stepTitle =
        _clean(action.stepTitle);

    if (stepTitle != null) {
      return _findStepByTitle(
        chapter,
        stepTitle,
      );
    }

    return null;
  }

  // ============================================================
  // FIND STEP BY TITLE
  // ============================================================

  ChapterStep? _findStepByTitle(
    ChapterModel chapter,
    String title,
  ) {
    final wanted =
        title.trim().toLowerCase();

    for (final step in chapter.steps) {
      if (step.title.trim().toLowerCase() ==
          wanted) {
        return step;
      }
    }

    return null;
  }

  // ============================================================
  // FIND TASK
  // ============================================================

  TaskModel? _findTask(
    AIAction action,
  ) {
    final taskId =
        _clean(action.taskId);

    if (taskId != null) {
      return taskProvider.getTaskById(
        taskId,
      );
    }

    final title =
        _clean(action.taskTitle);

    if (title != null) {
      final wanted =
          title.trim().toLowerCase();

      for (final task
          in taskProvider.tasks) {
        if (task.title.trim().toLowerCase() ==
            wanted) {
          return task;
        }
      }
    }

    return null;
  }

  // ============================================================
  // FIND SIMILAR TASK
  // ============================================================

  TaskModel? _findSimilarPendingTask({
    required String title,
    String? subjectId,
    String? chapterId,
  }) {
    final wanted =
        title.trim().toLowerCase();

    for (final task
        in taskProvider.pendingTasks) {
      if (task.title.trim().toLowerCase() !=
          wanted) {
        continue;
      }

      if (subjectId != null &&
          task.subjectId != subjectId) {
        continue;
      }

      if (chapterId != null &&
          task.chapterId != chapterId) {
        continue;
      }

      return task;
    }

    return null;
  }

  // ============================================================
  // CLEAN STRING
  // ============================================================

  String? _clean(
    String? value,
  ) {
    if (value == null) {
      return null;
    }

    final text = value.trim();

    if (text.isEmpty ||
        text.toLowerCase() == 'null') {
      return null;
    }

    return text;
  }

  // ============================================================
  // SAFE ESTIMATED MINUTES
  // ============================================================

  int _safeEstimatedMinutes(
    int value,
  ) {
    if (value < 1) {
      return 1;
    }

    if (value > 1440) {
      return 1440;
    }

    return value;
  }
}
