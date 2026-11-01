import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exam_model.dart';
import 'syllabus_provider.dart';

class ExamProvider extends ChangeNotifier {
  static const String _storageKey = 'studyx_exams_v1';

  final SharedPreferences prefs;
  final SyllabusProvider syllabusProvider;

  List<ExamModel> _exams = [];

  ExamProvider({
    required this.prefs,
    required this.syllabusProvider,
  }) {
    _load();
  }

  List<ExamModel> get exams =>
      List.unmodifiable(_exams);

  // ============================================================
  // LOAD
  // ============================================================

  void _load() {
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);

      if (decoded is List) {
        _exams = decoded
            .whereType<Map>()
            .map(
              (item) => ExamModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      }
    } catch (_) {
      _exams = [];
    }

    notifyListeners();
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _save() async {
    await prefs.setString(
      _storageKey,
      jsonEncode(
        _exams
            .map((exam) => exam.toJson())
            .toList(),
      ),
    );
  }

  // ============================================================
  // CREATE EXAM
  // ============================================================

  Future<ExamModel> createExam({
    required String name,
    required DateTime examDate,
    double targetPercentage = 80,
  }) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw Exception(
        'Exam name cannot be empty',
      );
    }

    final now = DateTime.now();

    final exam = ExamModel(
      id: 'exam_${now.microsecondsSinceEpoch}',
      name: cleanName,
      examDate: examDate,
      targetPercentage:
          targetPercentage.clamp(1, 100).toDouble(),
    );

    _exams = [
      ..._exams,
      exam,
    ];

    await _save();
    notifyListeners();

    return exam;
  }

  // ============================================================
  // COMPATIBILITY: addExam
  // ============================================================
  //
  // Your existing CreateExamScreen uses addExam().
  // Keep this so you don't have to rewrite that screen.

  Future<ExamModel> addExam({
    required String name,
    required DateTime examDate,
    double targetPercentage = 80,
  }) async {
    return createExam(
      name: name,
      examDate: examDate,
      targetPercentage: targetPercentage,
    );
  }

  // ============================================================
  // DELETE EXAM
  // ============================================================

  Future<void> deleteExam(
    String examId,
  ) async {
    _exams = _exams
        .where(
          (exam) => exam.id != examId,
        )
        .toList();

    await _save();
    notifyListeners();
  }

  // ============================================================
  // GET EXAM
  // ============================================================

  ExamModel? getExamById(
    String id,
  ) {
    for (final exam in _exams) {
      if (exam.id == id) {
        return exam;
      }
    }

    return null;
  }

  // ============================================================
  // SELECT CHAPTER
  // ============================================================

  Future<void> toggleChapter({
    required String examId,
    required String chapterId,
  }) async {
    final index = _exams.indexWhere(
      (exam) => exam.id == examId,
    );

    if (index == -1) return;

    final exam = _exams[index];

    final chapters = [
      ...exam.chapterIds,
    ];

    if (chapters.contains(chapterId)) {
      chapters.remove(chapterId);
    } else {
      chapters.add(chapterId);
    }

    _exams = [..._exams];

    _exams[index] = exam.copyWith(
      chapterIds: chapters,
    );

    await _save();
    notifyListeners();
  }

  // ============================================================
  // ADD TOPIC
  // ============================================================

  Future<void> addTopic({
    required String examId,
    required String topic,
  }) async {
    final index = _exams.indexWhere(
      (exam) => exam.id == examId,
    );

    if (index == -1) return;

    final cleanTopic = topic.trim();

    if (cleanTopic.isEmpty) return;

    final exam = _exams[index];

    if (exam.topics.contains(cleanTopic)) {
      return;
    }

    _exams = [..._exams];

    _exams[index] = exam.copyWith(
      topics: [
        ...exam.topics,
        cleanTopic,
      ],
    );

    await _save();
    notifyListeners();
  }

  // ============================================================
  // REMOVE TOPIC
  // ============================================================

  Future<void> removeTopic({
    required String examId,
    required String topic,
  }) async {
    final index = _exams.indexWhere(
      (exam) => exam.id == examId,
    );

    if (index == -1) return;

    final exam = _exams[index];

    _exams = [..._exams];

    _exams[index] = exam.copyWith(
      topics: exam.topics
          .where(
            (item) => item != topic,
          )
          .toList(),
    );

    await _save();
    notifyListeners();
  }

  // ============================================================
  // GET SELECTED CHAPTERS
  // ============================================================

  List<Chapter> getExamChapters(
    ExamModel exam,
  ) {
    final result = <Chapter>[];

    for (final subject
        in syllabusProvider.subjects) {
      for (final chapter
          in subject.chapters) {
        if (exam.chapterIds.contains(
          chapter.id,
        )) {
          result.add(chapter);
        }
      }
    }

    return result;
  }

  // ============================================================
  // PROGRESS
  // ============================================================

  double getExamProgress(
    ExamModel exam,
  ) {
    final chapters =
        getExamChapters(exam);

    if (chapters.isEmpty) {
      return 0;
    }

    int totalSteps = 0;
    int completedSteps = 0;

    for (final chapter in chapters) {
      final studySteps =
          chapter.steps.where(
        (step) => !step.title
            .toLowerCase()
            .contains('revision'),
      );

      totalSteps += studySteps.length;

      completedSteps += studySteps
          .where(
            (step) => step.completed,
          )
          .length;
    }

    if (totalSteps == 0) {
      return 0;
    }

    return completedSteps / totalSteps;
  }
}