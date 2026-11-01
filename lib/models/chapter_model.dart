class ChapterStep {
  final String id;
  final String title;
  final bool completed;
  final DateTime? completedAt;

  const ChapterStep({
    required this.id,
    required this.title,
    this.completed = false,
    this.completedAt,
  });

  ChapterStep copyWith({
    String? id,
    String? title,
    bool? completed,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return ChapterStep(
      id: id ?? this.id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
      completedAt: clearCompletedAt
          ? null
          : completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory ChapterStep.fromJson(Map<String, dynamic> json) {
    final completedAtValue = json['completedAt'];

    return ChapterStep(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      completed: json['completed'] == true,
      completedAt: completedAtValue == null
          ? null
          : DateTime.tryParse(completedAtValue.toString()),
    );
  }
}

class ChapterModel {
  final String id;
  final String name;
  final List<ChapterStep> steps;

  final int estimatedMinutes;
  final DateTime createdAt;

  /// Date when the chapter's actual learning was completed.
  final DateTime? studiedAt;

  /// Date when the most recent revision was completed.
  final DateTime? lastRevisionAt;

  /// Date when the next revision is due.
  ///
  /// First revision:
  /// studiedAt + 7 days
  ///
  /// Later revisions:
  /// lastRevisionAt + 21 days
  final DateTime? nextRevisionAt;

  const ChapterModel({
    required this.id,
    required this.name,
    required this.steps,
    this.estimatedMinutes = 45,
    required this.createdAt,
    this.studiedAt,
    this.lastRevisionAt,
    this.nextRevisionAt,
  });

  // ============================================================
  // STEP HELPERS
  // ============================================================

  /// Returns true when the step is a revision step.
  static bool isRevisionStep(ChapterStep step) {
    final title = step.title.trim().toLowerCase();

    return title == 'revision' ||
        title.contains('revise') ||
        title.contains('revision');
  }

  /// Steps used for the initial study of the chapter.
  List<ChapterStep> get studySteps {
    return steps
        .where((step) => !isRevisionStep(step))
        .toList();
  }

  /// Revision steps of this chapter.
  List<ChapterStep> get revisionSteps {
    return steps
        .where((step) => isRevisionStep(step))
        .toList();
  }

  // ============================================================
  // COMPLETION
  // ============================================================

  /// True when all actual study/learning steps are completed.
  ///
  /// Revision is deliberately NOT required here.
  bool get isStudyCompleted {
    if (studySteps.isEmpty) return false;

    return studySteps.every(
      (step) => step.completed,
    );
  }

  /// True when all steps, including revision, are completed.
  bool get isCompleted {
    if (steps.isEmpty) return false;

    return steps.every(
      (step) => step.completed,
    );
  }

  /// True when this chapter has already been studied.
  bool get hasBeenStudied {
    return studiedAt != null;
  }

  /// True when the chapter currently has a revision scheduled.
  bool get hasRevisionScheduled {
    return nextRevisionAt != null;
  }

  /// True when today's date is at or after the scheduled revision date.
  bool get isRevisionDue {
    final next = nextRevisionAt;

    if (next == null) return false;

    final now = DateTime.now();

    return !next.isAfter(now);
  }

  /// True when the next revision is still in the future.
  bool get isRevisionPending {
    final next = nextRevisionAt;

    if (next == null) return false;

    return next.isAfter(DateTime.now());
  }

  // ============================================================
  // PROGRESS
  // ============================================================

  /// Progress of the actual study steps.
  ///
  /// Revision is excluded.
  double get studyProgress {
    if (studySteps.isEmpty) return 0.0;

    final completedCount =
        studySteps.where((step) => step.completed).length;

    return completedCount / studySteps.length;
  }

  /// Progress of revision steps.
  double get revisionProgress {
    if (revisionSteps.isEmpty) return 0.0;

    final completedCount =
        revisionSteps.where((step) => step.completed).length;

    return completedCount / revisionSteps.length;
  }

  /// Overall progress including every step.
  double get progress {
    if (steps.isEmpty) return 0.0;

    final completedCount =
        steps.where((step) => step.completed).length;

    return completedCount / steps.length;
  }

  // ============================================================
  // REVISION STATUS
  // ============================================================

  /// Number of days until the next revision.
  ///
  /// Returns null if no revision is scheduled.
  int? get daysUntilRevision {
    final next = nextRevisionAt;

    if (next == null) return null;

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final revisionDay = DateTime(
      next.year,
      next.month,
      next.day,
    );

    return revisionDay.difference(today).inDays;
  }

  /// Whether this is waiting for its first 7-day revision.
  bool get waitingForFirstRevision {
    return studiedAt != null &&
        lastRevisionAt == null &&
        nextRevisionAt != null;
  }

  /// Whether this chapter has already had at least one revision.
  bool get hasRevisionHistory {
    return lastRevisionAt != null;
  }

  // ============================================================
  // COPY
  // ============================================================

  ChapterModel copyWith({
    String? id,
    String? name,
    List<ChapterStep>? steps,
    int? estimatedMinutes,
    DateTime? createdAt,
    DateTime? studiedAt,
    DateTime? lastRevisionAt,
    DateTime? nextRevisionAt,
    bool clearStudiedAt = false,
    bool clearLastRevisionAt = false,
    bool clearNextRevisionAt = false,
  }) {
    return ChapterModel(
      id: id ?? this.id,
      name: name ?? this.name,
      steps: steps ?? this.steps,
      estimatedMinutes:
          estimatedMinutes ?? this.estimatedMinutes,
      createdAt: createdAt ?? this.createdAt,

      studiedAt: clearStudiedAt
          ? null
          : studiedAt ?? this.studiedAt,

      lastRevisionAt: clearLastRevisionAt
          ? null
          : lastRevisionAt ?? this.lastRevisionAt,

      nextRevisionAt: clearNextRevisionAt
          ? null
          : nextRevisionAt ?? this.nextRevisionAt,
    );
  }

  // ============================================================
  // JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'steps': steps
          .map((step) => step.toJson())
          .toList(),

      'estimatedMinutes': estimatedMinutes,

      'createdAt':
          createdAt.toIso8601String(),

      'studiedAt':
          studiedAt?.toIso8601String(),

      'lastRevisionAt':
          lastRevisionAt?.toIso8601String(),

      'nextRevisionAt':
          nextRevisionAt?.toIso8601String(),
    };
  }

  factory ChapterModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawSteps = json['steps'];

    final steps = rawSteps is List
        ? rawSteps
            .whereType<Map>()
            .map(
              (item) => ChapterStep.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : <ChapterStep>[];

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;

      return DateTime.tryParse(
        value.toString(),
      );
    }

    return ChapterModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      steps: steps,

      estimatedMinutes:
          (json['estimatedMinutes'] as num?)
                  ?.toInt() ??
              45,

      createdAt:
          parseDate(json['createdAt']) ??
              DateTime.now(),

      studiedAt:
          parseDate(json['studiedAt']),

      lastRevisionAt:
          parseDate(
            json['lastRevisionAt'],
          ),

      nextRevisionAt:
          parseDate(
            json['nextRevisionAt'],
          ),
    );
  }
}