
import '../models/chapter_model.dart';
import '../models/task_model.dart';
import '../providers/syllabus_provider.dart';
import '../providers/task_provider.dart';

class StudyMemoryResult {
  final String subjectName;
  final String chapterName;
  final String subjectId;
  final String chapterId;
  final bool subjectCreated;
  final bool chapterCreated;
  final bool studyTaskCreated;
  final bool revisionTaskCreated;
  final DateTime nextRevisionDate;

  const StudyMemoryResult({
    required this.subjectName,
    required this.chapterName,
    required this.subjectId,
    required this.chapterId,
    required this.subjectCreated,
    required this.chapterCreated,
    required this.studyTaskCreated,
    required this.revisionTaskCreated,
    required this.nextRevisionDate,
  });
}

class StudyMemoryService {
  StudyMemoryService._();

  static Future<StudyMemoryResult> rememberChapter({
    required String subjectName,
    required String chapterName,
    required SyllabusProvider syllabusProvider,
    required TaskProvider taskProvider,
    List<String>? stepTitles,
    int estimatedMinutes = 60,
    DateTime? studiedAt,
  }) async {
    final cleanSubject = subjectName.trim();
    final cleanChapter = chapterName.trim();

    if (cleanSubject.isEmpty) {
      throw ArgumentError('Subject name cannot be empty.');
    }

    if (cleanChapter.isEmpty) {
      throw ArgumentError('Chapter name cannot be empty.');
    }

    final now = studiedAt ?? DateTime.now();

    final existingSubject =
        syllabusProvider.findSubjectByName(cleanSubject);

    final subject =
        await syllabusProvider.getOrCreateSubject(
      cleanSubject,
    );

    final existingChapter =
        syllabusProvider.findChapterByName(
      subjectId: subject.id,
      chapterName: cleanChapter,
    );

    final steps = _createSteps(
      stepTitles,
      now,
    );

    final chapter =
        await syllabusProvider.getOrCreateChapter(
      subjectName: cleanSubject,
      chapterName: cleanChapter,
      steps: steps,
      estimatedMinutes: estimatedMinutes,
    );

    await syllabusProvider.markChapterStudied(
      subjectId: subject.id,
      chapterId: chapter.id,
      studiedAt: now,
    );

    var studyTaskCreated = false;

    if (!taskProvider.hasPendingChapterTask(
      subjectId: subject.id,
      chapterId: chapter.id,
      type: TaskType.study,
    )) {
      await taskProvider.createTask(
        title: '$cleanSubject: $cleanChapter',
        description:
            'Study this chapter and complete its steps.',
        type: TaskType.study,
        deadline: DateTime(
          now.year,
          now.month,
          now.day,
          23,
          59,
        ),
        priority: 9,
        estimatedMinutes: estimatedMinutes,
        subjectId: subject.id,
        chapterId: chapter.id,
      );

      studyTaskCreated = true;
    }

    final sunday = _nextSunday(now);

    var revisionTaskCreated = false;

    if (!taskProvider.hasPendingChapterTask(
      subjectId: subject.id,
      chapterId: chapter.id,
      type: TaskType.revision,
      deadline: sunday,
    )) {
      await taskProvider.createTask(
        title: 'Revise $cleanChapter',
        description:
            'Weekly Sunday revision for $cleanSubject.',
        type: TaskType.revision,
        deadline: DateTime(
          sunday.year,
          sunday.month,
          sunday.day,
          9,
        ),
        priority: 10,
        estimatedMinutes: 30,
        subjectId: subject.id,
        chapterId: chapter.id,
      );

      revisionTaskCreated = true;
    }

    return StudyMemoryResult(
      subjectName: subject.name,
      chapterName: chapter.name,
      subjectId: subject.id,
      chapterId: chapter.id,
      subjectCreated: existingSubject == null,
      chapterCreated: existingChapter == null,
      studyTaskCreated: studyTaskCreated,
      revisionTaskCreated: revisionTaskCreated,
      nextRevisionDate: sunday,
    );
  }

  static Future<int> generateSundayRevisions({
    required SyllabusProvider syllabusProvider,
    required TaskProvider taskProvider,
    DateTime? date,
  }) async {
    final now = date ?? DateTime.now();

    final sunday = _nextSunday(now);

    int created = 0;

    for (final subject in syllabusProvider.subjects) {
      for (final chapter in subject.chapters) {
        if (chapter.studiedAt == null) {
          continue;
        }

        final alreadyExists =
            taskProvider.hasPendingChapterTask(
          subjectId: subject.id,
          chapterId: chapter.id,
          type: TaskType.revision,
          deadline: sunday,
        );

        if (alreadyExists) {
          continue;
        }

        await taskProvider.createTask(
          title: 'Revise ${chapter.name}',
          description:
              'Weekly revision: ${subject.name}.',
          type: TaskType.revision,
          deadline: DateTime(
            sunday.year,
            sunday.month,
            sunday.day,
            9,
          ),
          priority: 10,
          estimatedMinutes: 30,
          subjectId: subject.id,
          chapterId: chapter.id,
        );

        created++;
      }
    }

    return created;
  }

  static List<ChapterStep> _createSteps(
    List<String>? titles,
    DateTime now,
  ) {
    final items =
        titles == null || titles.isEmpty
            ? const [
                'Learn Chapter',
                'Make Notes',
                'Practice Questions',
                'Revision',
              ]
            : titles;

    return List.generate(
      items.length,
      (index) => ChapterStep(
        id:
            'step_${now.microsecondsSinceEpoch}_$index',
        title: items[index].trim(),
      ),
    );
  }

  static DateTime _nextSunday(DateTime date) {
    final clean = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final difference =
        DateTime.sunday - clean.weekday;

    return clean.add(
      Duration(
        days: difference < 0
            ? difference + 7
            : difference,
      ),
    );
  }
}

