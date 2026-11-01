import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyllabusStep {
  final String title;
  bool completed;

  SyllabusStep({
    required this.title,
    this.completed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'completed': completed,
    };
  }

  factory SyllabusStep.fromJson(Map<String, dynamic> json) {
    return SyllabusStep(
      title: json['title'] as String,
      completed: json['completed'] as bool? ?? false,
    );
  }
}

class Chapter {
  final String id;
  String name;
  List<SyllabusStep> steps;

  Chapter({
    required this.id,
    required this.name,
    List<SyllabusStep>? steps,
  }) : steps = steps ??
            [
              SyllabusStep(title: 'Watch all lectures'),
              SyllabusStep(title: 'Make notes'),
              SyllabusStep(title: 'Understand & learn notes'),
              SyllabusStep(title: 'Solve DPPs & tests'),
              SyllabusStep(title: 'Revision'),
            ];

  double get progress {
    if (steps.isEmpty) return 0;

    final completed =
        steps.where((step) => step.completed).length;

    return completed / steps.length;
  }

  bool get isCompleted => progress == 1.0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'steps': steps.map((step) => step.toJson()).toList(),
    };
  }

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] as String,
      name: json['name'] as String,
      steps: (json['steps'] as List<dynamic>? ?? [])
          .map(
            (item) => SyllabusStep.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class Subject {
  final String id;
  String name;
  List<Chapter> chapters;

  Subject({
    required this.id,
    required this.name,
    List<Chapter>? chapters,
  }) : chapters = chapters ?? [];

  double get progress {
    if (chapters.isEmpty) return 0;

    final total =
        chapters.fold<double>(0, (sum, chapter) {
      return sum + chapter.progress;
    });

    return total / chapters.length;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'chapters':
          chapters.map((chapter) => chapter.toJson()).toList(),
    };
  }

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as String,
      name: json['name'] as String,
      chapters: (json['chapters'] as List<dynamic>? ?? [])
          .map(
            (item) => Chapter.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class SyllabusProvider extends ChangeNotifier {
  final SharedPreferences prefs;

  SyllabusProvider(this.prefs);

  static const String _key = 'studyx_syllabus';

  List<Subject> _subjects = [];

  List<Subject> get subjects =>
      List.unmodifiable(_subjects);

  Future<void> loadSyllabus() async {
    final saved = prefs.getString(_key);

    if (saved == null) {
      _subjects = [];
      notifyListeners();
      return;
    }

    try {
      final decoded = jsonDecode(saved) as List<dynamic>;

      _subjects = decoded
          .map(
            (item) => Subject.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();

      notifyListeners();
    } catch (_) {
      _subjects = [];
      notifyListeners();
    }
  }

  Future<void> addSubject(String name) async {
    final cleanName = name.trim();

    if (cleanName.isEmpty) return;

    final subject = Subject(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: cleanName,
    );

    _subjects.add(subject);

    await _save();
    notifyListeners();
  }

  Future<void> deleteSubject(String subjectId) async {
    _subjects.removeWhere(
      (subject) => subject.id == subjectId,
    );

    await _save();
    notifyListeners();
  }

  Future<void> addChapter(
    String subjectId,
    String chapterName,
  ) async {
    final cleanName = chapterName.trim();

    if (cleanName.isEmpty) return;

    final subject = _findSubject(subjectId);

    if (subject == null) return;

    subject.chapters.add(
      Chapter(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: cleanName,
      ),
    );

    await _save();
    notifyListeners();
  }

  Future<void> deleteChapter(
    String subjectId,
    String chapterId,
  ) async {
    final subject = _findSubject(subjectId);

    if (subject == null) return;

    subject.chapters.removeWhere(
      (chapter) => chapter.id == chapterId,
    );

    await _save();
    notifyListeners();
  }

  Future<void> toggleStep(
    String subjectId,
    String chapterId,
    int stepIndex,
  ) async {
    final subject = _findSubject(subjectId);

    if (subject == null) return;

    final chapter = _findChapter(
      subject,
      chapterId,
    );

    if (chapter == null) return;

    if (stepIndex < 0 ||
        stepIndex >= chapter.steps.length) {
      return;
    }

    chapter.steps[stepIndex].completed =
        !chapter.steps[stepIndex].completed;

    await _save();
    notifyListeners();
  }

  Subject? _findSubject(String id) {
    for (final subject in _subjects) {
      if (subject.id == id) {
        return subject;
      }
    }

    return null;
  }

  Chapter? _findChapter(
    Subject subject,
    String chapterId,
  ) {
    for (final chapter in subject.chapters) {
      if (chapter.id == chapterId) {
        return chapter;
      }
    }

    return null;
  }

  Future<void> _save() async {
    final data = _subjects
        .map((subject) => subject.toJson())
        .toList();

    await prefs.setString(
      _key,
      jsonEncode(data),
    );
  }
}