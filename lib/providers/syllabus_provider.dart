import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chapter_model.dart';
import '../models/subject_model.dart';

// Compatibility aliases for existing screens.
typedef Subject = SubjectModel;
typedef Chapter = ChapterModel;

class SyllabusProvider extends ChangeNotifier {
  static const String _storageKey = 'studyx_syllabus_data_v2';

  final SharedPreferences _prefs;

  List<SubjectModel> _subjects = [];

  List<SubjectModel> get subjects => List.unmodifiable(_subjects);

  SyllabusProvider(this._prefs) {
    _load();
  }

  // ============================================================
  // LOAD
  // ============================================================

  void _load() {
    final raw = _prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);

      if (decoded is List) {
        _subjects = decoded
            .whereType<Map>()
            .map(
              (item) => SubjectModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }
    } catch (_) {
      _subjects = [];
    }
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    final data = _subjects
        .map((subject) => subject.toJson())
        .toList();

    await _prefs.setString(
      _storageKey,
      jsonEncode(data),
    );
  }

  // ============================================================
  // FIND SUBJECT / CHAPTER
  // ============================================================

  SubjectModel? findSubjectByName(String name) {
    final normalized = name.trim().toLowerCase();

    for (final subject in _subjects) {
      if (subject.name.trim().toLowerCase() == normalized) {
        return subject;
      }
    }

    return null;
  }

  SubjectModel? findSubjectById(String subjectId) {
    for (final subject in _subjects) {
      if (subject.id == subjectId) {
        return subject;
      }
    }

    return null;
  }

  ChapterModel? findChapterByName({
    required String subjectId,
    required String chapterName,
  }) {
    final normalized = chapterName.trim().toLowerCase();

    final subject = findSubjectById(subjectId);

    if (subject == null) return null;

    for (final chapter in subject.chapters) {
      if (chapter.name.trim().toLowerCase() == normalized) {
        return chapter;
      }
    }

    return null;
  }

  ChapterModel? findChapterById({
    required String subjectId,
    required String chapterId,
  }) {
    final subject = findSubjectById(subjectId);

    if (subject == null) return null;

    for (final chapter in subject.chapters) {
      if (chapter.id == chapterId) {
        return chapter;
      }
    }

    return null;
  }

  // ============================================================
  // SUBJECTS
  // ============================================================

  Future<SubjectModel> addSubject(String name) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw Exception('Subject name cannot be empty');
    }

    final existing = findSubjectByName(cleanName);

    if (existing != null) {
      return existing;
    }

    final now = DateTime.now();

    final subject = SubjectModel(
      id: 'subject_${now.microsecondsSinceEpoch}',
      name: cleanName,
      chapters: const [],
      createdAt: now,
    );

    _subjects = [
      ..._subjects,
      subject,
    ];

    await _save();
    notifyListeners();

    return subject;
  }

  Future<SubjectModel> getOrCreateSubject(
    String name,
  ) async {
    final existing = findSubjectByName(name);

    if (existing != null) {
      return existing;
    }

    return addSubject(name);
  }

  Future<void> deleteSubject(String subjectId) async {
    _subjects = _subjects
        .where((subject) => subject.id != subjectId)
        .toList();

    await _save();
    notifyListeners();
  }

  // ============================================================
  // CHAPTERS
  // ============================================================

  Future<ChapterModel> addChapter({
    required String subjectId,
    required String name,
    List<ChapterStep>? steps,
    int estimatedMinutes = 45,
  }) async {
    final subjectIndex = _subjects.indexWhere(
      (subject) => subject.id == subjectId,
    );

    if (subjectIndex == -1) {
      throw Exception('Subject not found');
    }

    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw Exception('Chapter name cannot be empty');
    }

    final existing = findChapterByName(
      subjectId: subjectId,
      chapterName: cleanName,
    );

    if (existing != null) {
      return existing;
    }

    final now = DateTime.now();

    final chapter = ChapterModel(
      id: 'chapter_${now.microsecondsSinceEpoch}',
      name: cleanName,
      steps: steps ?? _defaultSteps(now),
      estimatedMinutes: estimatedMinutes,
      createdAt: now,
    );

    final subject = _subjects[subjectIndex];

    final updatedSubject = subject.copyWith(
      chapters: [
        ...subject.chapters,
        chapter,
      ],
    );

    _subjects = [..._subjects];
    _subjects[subjectIndex] = updatedSubject;

    await _save();
    notifyListeners();

    return chapter;
  }

  Future<ChapterModel> getOrCreateChapter({
    required String subjectName,
    required String chapterName,
    List<ChapterStep>? steps,
    int estimatedMinutes = 45,
  }) async {
    final subject = await getOrCreateSubject(
      subjectName,
    );

    final existing = findChapterByName(
      subjectId: subject.id,
      chapterName: chapterName,
    );

    if (existing != null) {
      return existing;
    }

    return addChapter(
      subjectId: subject.id,
      name: chapterName,
      steps: steps,
      estimatedMinutes: estimatedMinutes,
    );
  }

  Future<void> deleteChapter(
    String subjectId,
    String chapterId,
  ) async {
    final subjectIndex = _subjects.indexWhere(
      (subject) => subject.id == subjectId,
    );

    if (subjectIndex == -1) return;

    final subject = _subjects[subjectIndex];

    final updatedChapters = subject.chapters
        .where((chapter) => chapter.id != chapterId)
        .toList();

    _subjects = [..._subjects];

    _subjects[subjectIndex] = subject.copyWith(
      chapters: updatedChapters,
    );

    await _save();
    notifyListeners();
  }

  // ============================================================
  // CHAPTER STEPS
  // ============================================================

  Future<void> updateChapterSteps({
    required String subjectId,
    required String chapterId,
    required List<ChapterStep> steps,
  }) async {
    await _updateChapter(
      subjectId: subjectId,
      chapterId: chapterId,
      update: (chapter) => chapter.copyWith(
        steps: steps,
      ),
    );
  }

  // ============================================================
  // TOGGLE STEP
  //
  // THIS IS THE MAIN STUDY TRACKING SYSTEM.
  //
  // Learning steps:
  //   Learn Chapter
  //   Make Notes
  //   Practice Questions
  //
  // Revision is kept separate.
  //
  // When ALL learning steps become complete:
  //
  //   completedAt = NOW
  //   first revision = NOW + 7 days
  //
  // After a revision:
  //
  //   next revision = revision completion + 21 days
  //
  // Every later revision also uses +21 days.
  // ============================================================

  Future<void> toggleStep({
    required String subjectId,
    required String chapterId,
    required String stepId,
    required bool completed,
  }) async {
    final chapter = findChapterById(
      subjectId: subjectId,
      chapterId: chapterId,
    );

    if (chapter == null) return;

    final selectedStep = chapter.steps
        .where((step) => step.id == stepId)
        .firstOrNull;

    if (selectedStep == null) return;

    final now = DateTime.now();

    final isRevisionStep = _isRevisionStep(selectedStep);

    // ------------------------------------------------------------
    // CHECK STATUS BEFORE THIS CHANGE
    // ------------------------------------------------------------

    final oldStudySteps = chapter.steps
        .where((step) => !_isRevisionStep(step))
        .toList();

    final wasLearningCompleted =
        oldStudySteps.isNotEmpty &&
        oldStudySteps.every((step) => step.completed);

    // ------------------------------------------------------------
    // UPDATE SELECTED STEP
    // ------------------------------------------------------------

    final updatedSteps = chapter.steps.map((step) {
      if (step.id != stepId) {
        return step;
      }

      return step.copyWith(
        completed: completed,
        completedAt: completed ? now : null,
        clearCompletedAt: !completed,
      );
    }).toList();

    // ------------------------------------------------------------
    // CHECK STATUS AFTER THIS CHANGE
    // ------------------------------------------------------------

    final studySteps = updatedSteps
        .where((step) => !_isRevisionStep(step))
        .toList();

    final learningCompleted =
        studySteps.isNotEmpty &&
        studySteps.every((step) => step.completed);

    // ------------------------------------------------------------
    // UPDATE CHAPTER
    // ------------------------------------------------------------

    await _updateChapter(
      subjectId: subjectId,
      chapterId: chapterId,
      update: (current) {
        DateTime? studiedAt = current.studiedAt;
        DateTime? nextRevisionAt = current.nextRevisionAt;
        DateTime? lastRevisionAt = current.lastRevisionAt;

        // ========================================================
        // 1. CHAPTER JUST BECAME FULLY STUDIED
        //
        // This is the important transition:
        //
        // BEFORE:
        //   not all learning steps completed
        //
        // AFTER:
        //   all learning steps completed
        //
        // Therefore NOW is the actual study completion time.
        // ========================================================

        if (learningCompleted && !wasLearningCompleted) {
          studiedAt = now;

          // First revision exactly 7 days after completion.
          nextRevisionAt = now.add(
            const Duration(days: 7),
          );
        }

        // ========================================================
        // 2. LEARNING STEP WAS UNCHECKED
        //
        // If the chapter is no longer fully studied, remove the
        // active study completion schedule.
        //
        // This prevents an incomplete chapter from appearing in
        // Revision simply because it had old scheduling data.
        // ========================================================

        if (!learningCompleted &&
            wasLearningCompleted &&
            !isRevisionStep) {
          studiedAt = null;
          nextRevisionAt = null;
          lastRevisionAt = null;
        }

        // ========================================================
        // 3. REVISION COMPLETED
        //
        // Revision itself does NOT affect learningCompleted.
        //
        // Every completed revision schedules another revision
        // exactly 21 days later.
        // ========================================================

        if (isRevisionStep && completed) {
          // A revision is only meaningful for a chapter that has
          // already completed its learning phase.
          if (current.studiedAt != null) {
            lastRevisionAt = now;

            nextRevisionAt = now.add(
              const Duration(days: 21),
            );
          }
        }

        // ========================================================
        // 4. REVISION UNCHECKED
        //
        // Do not destroy the existing revision schedule.
        //
        // Example:
        //
        // Revision was completed yesterday.
        // User accidentally unchecks the Revision checkbox today.
        //
        // The next scheduled revision remains based on the
        // previously completed revision.
        // ========================================================

        return current.copyWith(
          steps: updatedSteps,
          studiedAt: studiedAt,
          lastRevisionAt: lastRevisionAt,
          nextRevisionAt: nextRevisionAt,
        );
      },
    );
  }

  // ============================================================
  // MANUAL STUDY COMPLETION
  //
  // Useful for existing screens or future features that want to
  // directly mark a chapter as studied.
  // ============================================================

  Future<void> markChapterStudied({
    required String subjectId,
    required String chapterId,
    DateTime? studiedAt,
  }) async {
    final date = studiedAt ?? DateTime.now();

    await _updateChapter(
      subjectId: subjectId,
      chapterId: chapterId,
      update: (chapter) {
        // Do not overwrite an existing genuine completion time.
        final actualStudiedAt = chapter.studiedAt ?? date;

        return chapter.copyWith(
          studiedAt: actualStudiedAt,

          // First revision is 7 days after actual study completion.
          nextRevisionAt: chapter.nextRevisionAt ??
              actualStudiedAt.add(
                const Duration(days: 7),
              ),
        );
      },
    );
  }

  // ============================================================
  // COMPLETE REVISION
  //
  // Revision 1 -> +21 days
  // Revision 2 -> +21 days
  // Revision 3 -> +21 days
  // etc.
  // ============================================================

  Future<void> markChapterRevisionDone({
    required String subjectId,
    required String chapterId,
    DateTime? revisionDate,
  }) async {
    final now = revisionDate ?? DateTime.now();

    await _updateChapter(
      subjectId: subjectId,
      chapterId: chapterId,
      update: (chapter) {
        // A chapter must have been studied before it can have
        // a genuine revision.
        if (chapter.studiedAt == null) {
          return chapter;
        }

        return chapter.copyWith(
          lastRevisionAt: now,
          nextRevisionAt: now.add(
            const Duration(days: 21),
          ),
        );
      },
    );
  }

  // ============================================================
  // GET DUE REVISION CHAPTERS
  //
  // ONLY chapters with an actual scheduled revision are returned.
  //
  // No random chapters.
  // ============================================================

  List<ChapterModel> getChaptersForRevision() {
    final now = DateTime.now();

    final dueChapters = <ChapterModel>[];

    for (final subject in _subjects) {
      for (final chapter in subject.chapters) {
        final revisionDate = chapter.nextRevisionAt;

        if (revisionDate != null &&
            !revisionDate.isAfter(now)) {
          dueChapters.add(chapter);
        }
      }
    }

    // Earliest scheduled revision first.
    dueChapters.sort((a, b) {
      final aDate = a.nextRevisionAt;
      final bDate = b.nextRevisionAt;

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return aDate.compareTo(bDate);
    });

    return dueChapters;
  }

  // ============================================================
  // GET ALL SCHEDULED REVISION CHAPTERS
  //
  // Useful for future calendar / progress screens.
  // ============================================================

  List<ChapterModel> getScheduledRevisionChapters() {
    final chapters = <ChapterModel>[];

    for (final subject in _subjects) {
      for (final chapter in subject.chapters) {
        if (chapter.nextRevisionAt != null) {
          chapters.add(chapter);
        }
      }
    }

    chapters.sort((a, b) {
      final aDate = a.nextRevisionAt;
      final bDate = b.nextRevisionAt;

      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;

      return aDate.compareTo(bDate);
    });

    return chapters;
  }

  // ============================================================
  // GET SUBJECT NAME FOR A CHAPTER
  // ============================================================

  String? getSubjectNameForChapter(
    String chapterId,
  ) {
    for (final subject in _subjects) {
      for (final chapter in subject.chapters) {
        if (chapter.id == chapterId) {
          return subject.name;
        }
      }
    }

    return null;
  }

  // ============================================================
  // CHECK IF STEP IS REVISION
  // ============================================================

  bool _isRevisionStep(ChapterStep step) {
    final title = step.title.trim().toLowerCase();

    return title == 'revision' ||
        title.contains('revise') ||
        title.contains('revision');
  }

  // ============================================================
  // DEFAULT STEPS
  // ============================================================

  List<ChapterStep> _defaultSteps(
    DateTime now,
  ) {
    final base = now.microsecondsSinceEpoch.toString();

    return [
      ChapterStep(
        id: '${base}_learn',
        title: 'Learn Chapter',
      ),
      ChapterStep(
        id: '${base}_notes',
        title: 'Make Notes',
      ),
      ChapterStep(
        id: '${base}_practice',
        title: 'Practice Questions',
      ),
      ChapterStep(
        id: '${base}_revision',
        title: 'Revision',
      ),
    ];
  }

  // ============================================================
  // INTERNAL UPDATE
  // ============================================================

  Future<void> _updateChapter({
    required String subjectId,
    required String chapterId,
    required ChapterModel Function(
      ChapterModel chapter,
    ) update,
  }) async {
    final subjectIndex = _subjects.indexWhere(
      (subject) => subject.id == subjectId,
    );

    if (subjectIndex == -1) return;

    final subject = _subjects[subjectIndex];

    final updatedChapters = subject.chapters.map((chapter) {
      if (chapter.id != chapterId) {
        return chapter;
      }

      return update(chapter);
    }).toList();

    _subjects = [..._subjects];

    _subjects[subjectIndex] = subject.copyWith(
      chapters: updatedChapters,
    );

    await _save();
    notifyListeners();
  }
}