import '../../models/ai/ai_context.dart';
import '../../providers/task_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../providers/study_session_provider.dart';

/// ============================================================
/// ADVANCED AI CONTEXT BUILDER
/// ============================================================
///
/// Builds the most useful current StudyX state for the AI.
///
/// Design goals:
/// - Keep compatibility with the existing AIContext model.
/// - Give the AI the most important information first.
/// - Put urgent tasks before less important tasks.
/// - Put recent study sessions first.
/// - Remove accidental duplicate records.
/// - Avoid sending unnecessarily huge context when limits are used.
/// - Never modify provider data.
///
/// Existing usage remains compatible:
///
/// final context = AIContextBuilder(
///   taskProvider: taskProvider,
///   syllabusProvider: syllabusProvider,
///   studySessionProvider: studySessionProvider,
/// ).build();
///
/// ============================================================

class AIContextBuilder {
  final TaskProvider taskProvider;
  final SyllabusProvider syllabusProvider;
  final StudySessionProvider studySessionProvider;

  /// Maximum number of tasks included in AI context.
  ///
  /// Null = include all tasks.
  final int? maxTasks;

  /// Maximum number of study sessions included in AI context.
  ///
  /// Null = include all sessions.
  final int? maxStudySessions;

  /// Whether completed tasks should be included.
  ///
  /// Keeping completed tasks enabled gives the AI historical context.
  final bool includeCompletedTasks;

  /// Whether completed study sessions should be included.
  ///
  /// Study sessions are historical records, so normally this stays true.
  final bool includeStudySessions;

  AIContextBuilder({
    required this.taskProvider,
    required this.syllabusProvider,
    required this.studySessionProvider,
    this.maxTasks,
    this.maxStudySessions,
    this.includeCompletedTasks = true,
    this.includeStudySessions = true,
  });

  // ============================================================
  // BUILD FULL CONTEXT
  // ============================================================

  AIContext build() {
    final now = DateTime.now();

    return AIContext(
      generatedAt: now,

      tasks: _buildTasks(
        now,
      ),

      subjects: _buildSubjects(),

      studySessions: _buildStudySessions(),
    );
  }

  // ============================================================
  // TASK CONTEXT
  // ============================================================

  List<AITaskContext> _buildTasks(
    DateTime now,
  ) {
    final sourceTasks = List.of(
      taskProvider.tasks,
    );

    // ----------------------------------------------------------
    // Remove completed tasks if requested.
    // ----------------------------------------------------------

    final filteredTasks = sourceTasks.where(
      (task) {
        if (includeCompletedTasks) {
          return true;
        }

        return !task.isCompleted;
      },
    ).toList();

    // ----------------------------------------------------------
    // Remove duplicate task IDs.
    //
    // This protects the AI from receiving the same task twice.
    // ----------------------------------------------------------

    final seenIds = <String>{};

    final uniqueTasks = filteredTasks.where(
      (task) {
        final id = task.id.trim();

        if (id.isEmpty) {
          return true;
        }

        if (seenIds.contains(id)) {
          return false;
        }

        seenIds.add(id);
        return true;
      },
    ).toList();

    // ----------------------------------------------------------
    // Intelligent AI ordering.
    //
    // 1. Pending tasks first.
    // 2. Overdue tasks before future tasks.
    // 3. Earlier deadline first.
    // 4. Higher priority first.
    // 5. Larger estimated task first.
    //
    // This means the AI sees urgent information first.
    // ----------------------------------------------------------

    uniqueTasks.sort(
      (a, b) {
        // Pending before completed.
        final completedCompare =
            _boolCompare(
          a.isCompleted,
          b.isCompleted,
        );

        if (completedCompare != 0) {
          return completedCompare;
        }

        // Overdue pending tasks first.
        final aOverdue =
            !a.isCompleted &&
            a.deadline.isBefore(now);

        final bOverdue =
            !b.isCompleted &&
            b.deadline.isBefore(now);

        if (aOverdue != bOverdue) {
          return aOverdue ? -1 : 1;
        }

        // Earlier deadline first.
        final deadlineCompare =
            a.deadline.compareTo(
          b.deadline,
        );

        if (deadlineCompare != 0) {
          return deadlineCompare;
        }

        // Higher priority first.
        final priorityCompare =
            b.priority.compareTo(
          a.priority,
        );

        if (priorityCompare != 0) {
          return priorityCompare;
        }

        // Longer tasks first.
        final durationCompare =
            b.estimatedMinutes.compareTo(
          a.estimatedMinutes,
        );

        if (durationCompare != 0) {
          return durationCompare;
        }

        // Stable alphabetical fallback.
        return a.title
            .trim()
            .toLowerCase()
            .compareTo(
              b.title
                  .trim()
                  .toLowerCase(),
            );
      },
    );

    final contexts = uniqueTasks
        .map(
          AITaskContext.fromTask,
        )
        .toList();

    // ----------------------------------------------------------
    // Optional context size limit.
    // ----------------------------------------------------------

    if (maxTasks == null) {
      return contexts;
    }

    final limit = _safeLimit(
      maxTasks,
      contexts.length,
    );

    return contexts.take(limit).toList();
  }

  // ============================================================
  // SUBJECT / CHAPTER CONTEXT
  // ============================================================

  List<AISubjectContext> _buildSubjects() {
    final sourceSubjects = List.of(
      syllabusProvider.subjects,
    );

    // ----------------------------------------------------------
    // Remove duplicate subject IDs.
    // ----------------------------------------------------------

    final seenIds = <String>{};

    final uniqueSubjects = sourceSubjects.where(
      (subject) {
        final id = subject.id.trim();

        if (id.isEmpty) {
          return true;
        }

        if (seenIds.contains(id)) {
          return false;
        }

        seenIds.add(id);
        return true;
      },
    ).toList();

    // ----------------------------------------------------------
    // Keep subject order deterministic.
    // ----------------------------------------------------------

    uniqueSubjects.sort(
      (a, b) {
        return a.name
            .trim()
            .toLowerCase()
            .compareTo(
              b.name
                  .trim()
                  .toLowerCase(),
            );
      },
    );

    return uniqueSubjects
        .map(
          AISubjectContext.fromSubject,
        )
        .toList();
  }

  // ============================================================
  // STUDY SESSION CONTEXT
  // ============================================================

  List<AIStudySessionContext> _buildStudySessions() {
    if (!includeStudySessions) {
      return const [];
    }

    final sourceSessions = List.of(
      studySessionProvider.sessions,
    );

    // ----------------------------------------------------------
    // Remove accidental duplicate sessions.
    //
    // Study sessions don't expose an ID in the current
    // AIStudySessionContext, so we deduplicate using date + seconds.
    // ----------------------------------------------------------

    final seen = <String>{};

    final uniqueSessions =
        sourceSessions.where(
      (session) {
        final key =
            '${session.date.toIso8601String()}_${session.seconds}';

        if (seen.contains(key)) {
          return false;
        }

        seen.add(key);
        return true;
      },
    ).toList();

    // ----------------------------------------------------------
    // Newest sessions first.
    //
    // Recent activity is generally more useful to AI planning
    // and progress reasoning.
    // ----------------------------------------------------------

    uniqueSessions.sort(
      (a, b) {
        return b.date.compareTo(
          a.date,
        );
      },
    );

    final contexts = uniqueSessions
        .map(
          AIStudySessionContext.fromSession,
        )
        .toList();

    // ----------------------------------------------------------
    // Optional history limit.
    // ----------------------------------------------------------

    if (maxStudySessions == null) {
      return contexts;
    }

    final limit = _safeLimit(
      maxStudySessions,
      contexts.length,
    );

    return contexts.take(limit).toList();
  }

  // ============================================================
  // BOOLEAN SORT HELPER
  // ============================================================

  int _boolCompare(
    bool a,
    bool b,
  ) {
    if (a == b) {
      return 0;
    }

    // false before true.
    return a ? 1 : -1;
  }

  // ============================================================
  // SAFE LIMIT
  // ============================================================

  int _safeLimit(
    int? requested,
    int length,
  ) {
    if (requested == null) {
      return length;
    }

    if (requested <= 0) {
      return 0;
    }

    if (requested >= length) {
      return length;
    }

    return requested;
  }

  // ============================================================
  // DEBUG / SUMMARY
  // ============================================================

  /// Useful when debugging AI context size.
  ///
  /// Does not expose the actual user data.
  String debugSummary() {
    final context = build();

    return 'AIContext('
        'tasks=${context.tasks.length}, '
        'subjects=${context.subjects.length}, '
        'studySessions=${context.studySessions.length}'
        ')';
  }
}