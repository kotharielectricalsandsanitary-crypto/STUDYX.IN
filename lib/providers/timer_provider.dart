import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudyTask {
  final String id;
  final String title;
  final DateTime deadline;
  bool completed;

  StudyTask({
    required this.id,
    required this.title,
    required this.deadline,
    this.completed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'deadline': deadline.toIso8601String(),
      'completed': completed,
    };
  }

  factory StudyTask.fromJson(Map<String, dynamic> json) {
    return StudyTask(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      deadline: DateTime.tryParse(
            json['deadline'] as String? ?? '',
          ) ??
          DateTime.now(),
      completed: json['completed'] as bool? ?? false,
    );
  }
}

class TaskProvider extends ChangeNotifier {
  final SharedPreferences prefs;

  TaskProvider(this.prefs) {
    _loadTasks();
  }

  static const String _key = 'studyx_tasks';

  List<StudyTask> _tasks = [];

  List<StudyTask> get tasks => List.unmodifiable(_tasks);

  List<StudyTask> get pendingTasks {
    final result = _tasks
        .where((task) => !task.completed)
        .toList();

    result.sort(
      (a, b) => a.deadline.compareTo(b.deadline),
    );

    return result;
  }

  List<StudyTask> get completedTasks {
    final result = _tasks
        .where((task) => task.completed)
        .toList();

    result.sort(
      (a, b) => b.deadline.compareTo(a.deadline),
    );

    return result;
  }

  int get totalTasks => _tasks.length;

  int get completedTaskCount =>
      _tasks.where((task) => task.completed).length;

  int get pendingTaskCount =>
      _tasks.where((task) => !task.completed).length;

  double get completionRate {
    if (_tasks.isEmpty) return 0;

    return completedTaskCount / totalTasks;
  }

  Future<void> _loadTasks() async {
    final saved = prefs.getStringList(_key);

    if (saved == null) {
      _tasks = [];
      notifyListeners();
      return;
    }

    try {
      _tasks = saved.map((item) {
        final json =
            jsonDecode(item) as Map<String, dynamic>;

        return StudyTask.fromJson(json);
      }).toList();
    } catch (e) {
      debugPrint('Task load error: $e');
      _tasks = [];
    }

    notifyListeners();
  }

  Future<void> _saveTasks() async {
    final data = _tasks.map(
      (task) => jsonEncode(task.toJson()),
    ).toList();

    await prefs.setStringList(_key, data);
  }

  Future<void> addTask({
    required String title,
    required DateTime deadline,
  }) async {
    final cleanTitle = title.trim();

    if (cleanTitle.isEmpty) return;

    final task = StudyTask(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      title: cleanTitle,
      deadline: deadline,
    );

    _tasks.add(task);

    await _saveTasks();
    notifyListeners();
  }

  Future<void> toggleTask(String taskId) async {
    final index = _tasks.indexWhere(
      (task) => task.id == taskId,
    );

    if (index == -1) return;

    _tasks[index].completed =
        !_tasks[index].completed;

    await _saveTasks();
    notifyListeners();
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere(
      (task) => task.id == taskId,
    );

    await _saveTasks();
    notifyListeners();
  }

  Future<void> clearCompleted() async {
    _tasks.removeWhere(
      (task) => task.completed,
    );

    await _saveTasks();
    notifyListeners();
  }
}