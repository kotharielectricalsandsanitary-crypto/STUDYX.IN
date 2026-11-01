
import '../models/study_plan_model.dart';
import '../models/task_model.dart';
import '../providers/syllabus_provider.dart';
import '../providers/task_provider.dart';
import '../providers/user_provider.dart';

class AdaptivePlanService {
  AdaptivePlanService._();

  static StudyPlanModel generateTodayPlan({
    required UserProvider userProvider,
    required SyllabusProvider syllabusProvider,
    required TaskProvider taskProvider,
    int? availableMinutes,
  }) {
    final now = DateTime.now();

    final date = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final targetMinutes =
        availableMinutes ??
            _dailyTargetMinutes(userProvider);

    final tasks = <StudyPlanTask>[];

    var remainingMinutes = targetMinutes;

    // ============================================================
    // 1. BACKLOG
    // ============================================================

    final backlogTasks =
        taskProvider.pendingTasks.where((task) {
      return task.type == TaskType.backlog;
    }).toList();

    for (final backlog in backlogTasks) {
      if (remainingMinutes <= 0) break;

      final minutes = _allocateMinutes(
        preferred: backlog.estimatedMinutes,
        remaining: remainingMinutes,
        minimum: 20,
      );

      if (minutes <= 0) continue;

      tasks.add(
        StudyPlanTask(
          id: 'plan_backlog_${backlog.id}',
          title: backlog.title,
          description: backlog.description.isEmpty
              ? 'Clear an item from your backlog.'
              : backlog.description,
          type: StudyPlanTaskType.backlog,
          subjectId: backlog.subjectId,
          chapterId: backlog.chapterId,
          estimatedMinutes: minutes,
          priority: 10,
          date: date,
          createdAt: now,
        ),
      );

      remainingMinutes -= minutes;
    }

    // ============================================================
    // 2. REVISION DUE TODAY
    // ============================================================

    final todayRevisionTasks =
        taskProvider.pendingTasks.where((task) {
      if (task.type != TaskType.revision) {
        return false;
      }

      return _sameDate(
        task.deadline,
        date,
      );
    }).toList();

    for (final revision in todayRevisionTasks) {
      if (remainingMinutes <= 0) break;

      final minutes = _allocateMinutes(
        preferred: revision.estimatedMinutes,
        remaining: remainingMinutes,
        minimum: 20,
      );

      if (minutes <= 0) continue;

      tasks.add(
        StudyPlanTask(
          id: 'plan_revision_task_${revision.id}',
          title: revision.title,
          description: revision.description.isEmpty
              ? 'Strengthen retention through revision.'
              : revision.description,
          type: StudyPlanTaskType.revision,
          subjectId: revision.subjectId,
          chapterId: revision.chapterId,
          estimatedMinutes: minutes,
          priority: 9,
          date: date,
          createdAt: now,
        ),
      );

      remainingMinutes -= minutes;
    }

    // ============================================================
    // 3. UNFINISHED CHAPTERS
    // ============================================================

    final chapters = <_ChapterEntry>[];

    for (final subject in syllabusProvider.subjects) {
      for (final chapter in subject.chapters) {
        if (!chapter.isCompleted) {
          chapters.add(
            _ChapterEntry(
              subjectId: subject.id,
              subjectName: subject.name,
              chapterId: chapter.id,
              chapterName: chapter.name,
              progress: chapter.progress,
              estimatedMinutes:
                  chapter.estimatedMinutes,
            ),
          );
        }
      }
    }

    chapters.sort(
      (a, b) => a.progress.compareTo(b.progress),
    );

    for (final chapter in chapters) {
      if (remainingMinutes <= 0) break;

      final minutes = _allocateMinutes(
        preferred: chapter.estimatedMinutes,
        remaining: remainingMinutes,
        minimum: 30,
      );

      if (minutes <= 0) continue;

      tasks.add(
        StudyPlanTask(
          id:
              'plan_chapter_${chapter.subjectId}_${chapter.chapterId}',
          title:
              '${chapter.subjectName}: ${chapter.chapterName}',
          description:
              'Continue your syllabus progress.',
          type: StudyPlanTaskType.newChapter,
          subjectId: chapter.subjectId,
          chapterId: chapter.chapterId,
          estimatedMinutes: minutes,
          priority: 8,
          date: date,
          createdAt: now,
        ),
      );

      remainingMinutes -= minutes;
    }

    // ============================================================
    // 4. PENDING NORMAL STUDY TASKS
    // ============================================================

    final normalTasks =
        taskProvider.pendingTasks.where((task) {
      return task.type == TaskType.study ||
          task.type == TaskType.custom;
    }).toList();

    for (final task in normalTasks) {
      if (remainingMinutes <= 0) break;

      final alreadyAdded = tasks.any(
        (item) =>
            item.subjectId == task.subjectId &&
            item.chapterId == task.chapterId &&
            item.type ==
                StudyPlanTaskType.newChapter,
      );

      if (alreadyAdded) continue;

      final minutes = _allocateMinutes(
        preferred: task.estimatedMinutes,
        remaining: remainingMinutes,
        minimum: 20,
      );

      if (minutes <= 0) continue;

      tasks.add(
        StudyPlanTask(
          id: 'plan_task_${task.id}',
          title: task.title,
          description: task.description,
          type: StudyPlanTaskType.newChapter,
          subjectId: task.subjectId,
          chapterId: task.chapterId,
          estimatedMinutes: minutes,
          priority: task.priority,
          date: date,
          createdAt: now,
        ),
      );

      remainingMinutes -= minutes;
    }

    // ============================================================
    // 5. PRACTICE
    // ============================================================

    if (remainingMinutes > 0) {
      final minutes = _allocateMinutes(
        preferred: 30,
        remaining: remainingMinutes,
        minimum: 20,
      );

      if (minutes > 0) {
        tasks.add(
          StudyPlanTask(
            id: 'plan_practice_${_dateId(date)}',
            title: 'Practice Questions',
            description:
                'Solve questions from today’s completed work.',
            type: StudyPlanTaskType.practice,
            estimatedMinutes: minutes,
            priority: 6,
            date: date,
            createdAt: now,
          ),
        );

        remainingMinutes -= minutes;
      }
    }

    // ============================================================
    // 6. MINI TEST
    // ============================================================

    if (remainingMinutes >= 30) {
      tasks.add(
        StudyPlanTask(
          id: 'plan_test_${_dateId(date)}',
          title: 'Mini Test',
          description:
              'Test yourself on today’s preparation.',
          type: StudyPlanTaskType.test,
          estimatedMinutes: 30,
          priority: 5,
          date: date,
          createdAt: now,
        ),
      );

      remainingMinutes -= 30;
    }

    // ============================================================
    // 7. FINAL FOCUS BLOCK
    // ============================================================

    if (remainingMinutes > 0) {
      tasks.add(
        StudyPlanTask(
          id: 'plan_focus_${_dateId(date)}',
          title: 'Focused Study Session',
          description:
              'Use this time for your most important unfinished work.',
          type: StudyPlanTaskType.custom,
          estimatedMinutes: remainingMinutes,
          priority: 4,
          date: date,
          createdAt: now,
        ),
      );
    }

    return StudyPlanModel(
      id: 'plan_${_dateId(date)}',
      date: date,
      targetMinutes: targetMinutes,
      tasks: tasks,
      createdAt: now,
      updatedAt: now,
    );
  }

  static int _dailyTargetMinutes(
    UserProvider userProvider,
  ) {
    final hours = userProvider.dailyHours;

    if (hours <= 0) {
      return 60;
    }

    return (hours * 60).round();
  }

  static int _allocateMinutes({
    required int preferred,
    required int remaining,
    required int minimum,
  }) {
    if (remaining <= 0) return 0;

    if (remaining < minimum) {
      return remaining;
    }

    if (preferred <= 0) {
      return remaining;
    }

    return preferred > remaining
        ? remaining
        : preferred;
  }

  static bool _sameDate(
    DateTime first,
    DateTime second,
  ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  static String _dateId(DateTime date) {
    return '${date.year}_${date.month}_${date.day}';
  }
}

class _ChapterEntry {
  final String subjectId;
  final String subjectName;
  final String chapterId;
  final String chapterName;
  final double progress;
  final int estimatedMinutes;

  const _ChapterEntry({
    required this.subjectId,
    required this.subjectName,
    required this.chapterId,
    required this.chapterName,
    required this.progress,
    required this.estimatedMinutes,
  });
}

