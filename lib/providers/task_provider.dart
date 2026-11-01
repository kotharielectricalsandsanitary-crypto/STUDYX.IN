import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task_model.dart';

class TaskProvider extends ChangeNotifier {
  static const String _storageKey = 'studyx_tasks_data_v2';

  final SharedPreferences _prefs;

  List<TaskModel> _tasks = [];

  TaskProvider(this._prefs) {
    _load();
  }

  /// All tasks.
  List<TaskModel> get tasks => List.unmodifiable(_tasks);

  /// Tasks that are not completed, sorted by priority and deadline.
  List<TaskModel> get pendingTasks {
    final result = _tasks
        .where((task) => !task.isCompleted)
        .toList();

    result.sort((a, b) {
      final priorityCompare = b.priority.compareTo(a.priority);

      if (priorityCompare != 0) {
        return priorityCompare;
      }

      return a.deadline.compareTo(b.deadline);
    });

    return List.unmodifiable(result);
  }

  /// Completed tasks.
  List<TaskModel> get completedTasks {
    return List.unmodifiable(
      _tasks.where((task) => task.isCompleted).toList(),
    );
  }

  /// Number of all tasks.
  int get totalTaskCount => _tasks.length;

  /// Number of pending tasks.
  int get pendingTaskCount => pendingTasks.length;

  /// Number of completed tasks.
  int get completedTaskCount => completedTasks.length;

  /// Tasks due today.
  List<TaskModel> get todayTasks {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    return List.unmodifiable(
      _tasks.where((task) {
        final deadline = DateTime(
          task.deadline.year,
          task.deadline.month,
          task.deadline.day,
        );

        return deadline == today;
      }).toList(),
    );
  }

  /// Pending tasks due today.
  List<TaskModel> get pendingTodayTasks {
    return List.unmodifiable(
      todayTasks.where((task) => !task.isCompleted).toList(),
    );
  }

  /// Load tasks from local storage.
  void _load() {
    final raw = _prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      _tasks = [];
      return;
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is List) {
        _tasks = decoded
            .whereType<Map>()
            .map(
              (item) => TaskModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();

        _sortTasks();
      } else {
        _tasks = [];
      }
    } catch (_) {
      _tasks = [];
    }
  }

  /// Save tasks to local storage.
  Future<void> _save() async {
    await _prefs.setString(
      _storageKey,
      jsonEncode(
        _tasks.map((task) => task.toJson()).toList(),
      ),
    );
  }

  void _sortTasks() {
    _tasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }

      final priorityCompare = b.priority.compareTo(a.priority);

      if (priorityCompare != 0) {
        return priorityCompare;
      }

      return a.deadline.compareTo(b.deadline);
    });
  }

  /// Add an existing TaskModel.
  Future<void> addTask(TaskModel task) async {
    final exists = _tasks.any(
      (item) => item.id == task.id,
    );

    if (exists) return;

    _tasks = [
      ..._tasks,
      task,
    ];

    _sortTasks();

    await _save();
    notifyListeners();
  }

  /// Create and add a new task.
  Future<TaskModel> createTask({
    required String title,
    String description = '',
    TaskType type = TaskType.study,
    required DateTime deadline,
    int priority = 5,
    int estimatedMinutes = 30,
    String? subjectId,
    String? chapterId,
  }) async {
    final now = DateTime.now();

    final task = TaskModel(
      id: 'task_${now.microsecondsSinceEpoch}',
      title: title.trim(),
      description: description.trim(),
      type: type,
      deadline: deadline,
      createdAt: now,
      priority: priority.clamp(1, 10),
      estimatedMinutes: estimatedMinutes < 1
          ? 1
          : estimatedMinutes,
      subjectId: subjectId,
      chapterId: chapterId,
    );

    await addTask(task);

    return task;
  }

  /// Update an existing task.
  Future<void> updateTask(TaskModel task) async {
    final index = _tasks.indexWhere(
      (item) => item.id == task.id,
    );

    if (index == -1) return;

    _tasks[index] = task;

    _sortTasks();

    await _save();
    notifyListeners();
  }

  /// Mark a task as completed or pending.
  Future<void> toggleTask(
    String taskId,
    bool completed,
  ) async {
    final index = _tasks.indexWhere(
      (task) => task.id == taskId,
    );

    if (index == -1) return;

    final task = _tasks[index];

    _tasks[index] = task.copyWith(
      isCompleted: completed,
      completedAt: completed ? DateTime.now() : null,
      clearCompletedAt: !completed,
    );

    _sortTasks();

    await _save();
    notifyListeners();
  }

  /// Toggle a task without needing to manually provide true/false.
  Future<void> toggleTaskStatus(String taskId) async {
    final task = _tasks.cast<TaskModel?>().firstWhere(
          (item) => item?.id == taskId,
          orElse: () => null,
        );

    if (task == null) return;

    await toggleTask(
      taskId,
      !task.isCompleted,
    );
  }

  /// Complete a task.
  Future<void> completeTask(String taskId) async {
    await toggleTask(taskId, true);
  }

  /// Mark a task as pending again.
  Future<void> uncompleteTask(String taskId) async {
    await toggleTask(taskId, false);
  }

  /// Delete one task.
  Future<void> deleteTask(String taskId) async {
    final oldLength = _tasks.length;

    _tasks = _tasks
        .where((task) => task.id != taskId)
        .toList();

    if (_tasks.length == oldLength) return;

    await _save();
    notifyListeners();
  }

  /// Delete all completed tasks.
  Future<void> deleteCompletedTasks() async {
    _tasks = _tasks
        .where((task) => !task.isCompleted)
        .toList();

    await _save();
    notifyListeners();
  }

  /// Find a task by ID.
  TaskModel? getTaskById(String taskId) {
    for (final task in _tasks) {
      if (task.id == taskId) {
        return task;
      }
    }

    return null;
  }

  /// Returns true if a matching pending chapter task already exists.
  bool hasPendingChapterTask({
    required String subjectId,
    required String chapterId,
    required TaskType type,
    DateTime? deadline,
  }) {
    final targetDate = deadline == null
        ? null
        : DateTime(
            deadline.year,
            deadline.month,
            deadline.day,
          );

    return _tasks.any((task) {
      if (task.isCompleted) return false;

      if (task.subjectId != subjectId ||
          task.chapterId != chapterId ||
          task.type != type) {
        return false;
      }

      if (targetDate == null) return true;

      final taskDate = DateTime(
        task.deadline.year,
        task.deadline.month,
        task.deadline.day,
      );

      return taskDate == targetDate;
    });
  }
}