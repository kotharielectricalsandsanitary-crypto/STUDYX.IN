
/// Result returned by StudyX AI after executing an action.
///
/// This model is intentionally backward-compatible with the existing
/// AIActionService. The original `success` and `message` fields remain
/// unchanged, while additional metadata makes AI workflows easier to
/// debug, summarize, and extend.
class AIActionResult {
  final bool success;
  final String message;

  /// Optional identifier for the action that produced this result.
  final String? actionId;

  /// Optional action type, for example `createChapter`, `createTask`, etc.
  final String? actionType;

  /// Optional subject associated with the action.
  final String? subjectId;
  final String? subjectName;

  /// Optional chapter associated with the action.
  final String? chapterId;
  final String? chapterName;

  /// Optional task associated with the action.
  final String? taskId;
  final String? taskTitle;

  /// Optional error/debug information.
  final String? error;

  /// Whether this result represents an action that was intentionally skipped.
  final bool skipped;

  /// Optional structured data for future AI features.
  final Map<String, dynamic>? data;

  const AIActionResult({
    required this.success,
    required this.message,
    this.actionId,
    this.actionType,
    this.subjectId,
    this.subjectName,
    this.chapterId,
    this.chapterName,
    this.taskId,
    this.taskTitle,
    this.error,
    this.skipped = false,
    this.data,
  });

  // ============================================================
  // STATUS
  // ============================================================

  bool get isFailure => !success && !skipped;

  bool get isSkipped => skipped;

  bool get isCompleted => success;

  bool get isSuccessfulOrSkipped => success || skipped;

  // ============================================================
  // SAFE DATA ACCESS
  // ============================================================

  dynamic getValue(String key) {
    return data?[key];
  }

  String? stringValue(String key) {
    final value = data?[key];

    if (value == null) {
      return null;
    }

    final result = value.toString().trim();

    return result.isEmpty ? null : result;
  }

  int? intValue(String key) {
    final value = data?[key];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    );
  }

  bool boolValue(
    String key, {
    bool fallback = false,
  }) {
    final value = data?[key];

    if (value is bool) {
      return value;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();

      if (normalized == 'true' ||
          normalized == 'yes' ||
          normalized == '1') {
        return true;
      }

      if (normalized == 'false' ||
          normalized == 'no' ||
          normalized == '0') {
        return false;
      }
    }

    if (value is num) {
      return value != 0;
    }

    return fallback;
  }

  // ============================================================
  // COPY
  // ============================================================

  AIActionResult copyWith({
    bool? success,
    String? message,
    String? actionId,
    String? actionType,
    String? subjectId,
    String? subjectName,
    String? chapterId,
    String? chapterName,
    String? taskId,
    String? taskTitle,
    String? error,
    bool? skipped,
    Map<String, dynamic>? data,
  }) {
    return AIActionResult(
      success: success ?? this.success,
      message: message ?? this.message,
      actionId: actionId ?? this.actionId,
      actionType: actionType ?? this.actionType,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      chapterId: chapterId ?? this.chapterId,
      chapterName: chapterName ?? this.chapterName,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      error: error ?? this.error,
      skipped: skipped ?? this.skipped,
      data: data ?? this.data,
    );
  }

  // ============================================================
  // JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      if (actionId != null) 'actionId': actionId,
      if (actionType != null) 'actionType': actionType,
      if (subjectId != null) 'subjectId': subjectId,
      if (subjectName != null) 'subjectName': subjectName,
      if (chapterId != null) 'chapterId': chapterId,
      if (chapterName != null) 'chapterName': chapterName,
      if (taskId != null) 'taskId': taskId,
      if (taskTitle != null) 'taskTitle': taskTitle,
      if (error != null) 'error': error,
      if (skipped) 'skipped': true,
      if (data != null) 'data': Map<String, dynamic>.from(data!),
    };
  }

  factory AIActionResult.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawData = json['data'];

    Map<String, dynamic>? parsedData;

    if (rawData is Map) {
      parsedData = Map<String, dynamic>.from(rawData);
    }

    return AIActionResult(
      success: _parseBool(
        json['success'],
        fallback: false,
      ),
      message: json['message']?.toString() ?? '',
      actionId: _cleanString(json['actionId']),
      actionType: _cleanString(json['actionType']),
      subjectId: _cleanString(json['subjectId']),
      subjectName: _cleanString(json['subjectName']),
      chapterId: _cleanString(json['chapterId']),
      chapterName: _cleanString(json['chapterName']),
      taskId: _cleanString(json['taskId']),
      taskTitle: _cleanString(json['taskTitle']),
      error: _cleanString(json['error']),
      skipped: _parseBool(
        json['skipped'],
        fallback: false,
      ),
      data: parsedData,
    );
  }

  // ============================================================
  // FACTORIES
  // ============================================================

  factory AIActionResult.successResult({
    required String message,
    String? actionId,
    String? actionType,
    String? subjectId,
    String? subjectName,
    String? chapterId,
    String? chapterName,
    String? taskId,
    String? taskTitle,
    Map<String, dynamic>? data,
  }) {
    return AIActionResult(
      success: true,
      message: message,
      actionId: actionId,
      actionType: actionType,
      subjectId: subjectId,
      subjectName: subjectName,
      chapterId: chapterId,
      chapterName: chapterName,
      taskId: taskId,
      taskTitle: taskTitle,
      data: data,
    );
  }

  factory AIActionResult.failureResult({
    required String message,
    String? error,
    String? actionId,
    String? actionType,
    Map<String, dynamic>? data,
  }) {
    return AIActionResult(
      success: false,
      message: message,
      error: error,
      actionId: actionId,
      actionType: actionType,
      data: data,
    );
  }

  factory AIActionResult.skippedResult({
    required String message,
    String? actionId,
    String? actionType,
    Map<String, dynamic>? data,
  }) {
    return AIActionResult(
      success: false,
      skipped: true,
      message: message,
      actionId: actionId,
      actionType: actionType,
      data: data,
    );
  }

  // ============================================================
  // MULTI-ACTION SUMMARY
  // ============================================================

  static AIActionResult combine(
    List<AIActionResult> results, {
    String? actionId,
    String? actionType,
  }) {
    if (results.isEmpty) {
      return const AIActionResult(
        success: false,
        skipped: true,
        message: 'No AI actions were executed.',
      );
    }

    final successful =
        results.where((result) => result.success).length;

    final skipped =
        results.where((result) => result.skipped).length;

    final failed =
        results.where((result) => result.isFailure).length;

    final messages = results
        .map((result) => result.message.trim())
        .where((message) => message.isNotEmpty)
        .toList();

    final buffer = StringBuffer();

    if (failed == 0) {
      if (successful > 0 && skipped > 0) {
        buffer.write(
          '$successful action'
          '${successful == 1 ? '' : 's'} completed, '
          '$skipped skipped.',
        );
      } else if (successful > 0) {
        buffer.write(
          '$successful action'
          '${successful == 1 ? '' : 's'} completed successfully.',
        );
      } else {
        buffer.write(
          '$skipped action'
          '${skipped == 1 ? '' : 's'} skipped.',
        );
      }
    } else {
      buffer.write(
        '$successful completed, '
        '$skipped skipped, '
        '$failed failed.',
      );
    }

    if (messages.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln();

      for (final message in messages) {
        buffer.writeln('• $message');
      }
    }

    return AIActionResult(
      success: failed == 0 && successful > 0,
      skipped: successful == 0 && failed == 0,
      message: buffer.toString().trim(),
      actionId: actionId,
      actionType: actionType,
      data: {
        'total': results.length,
        'successful': successful,
        'skipped': skipped,
        'failed': failed,
      },
    );
  }

  // ============================================================
  // STRING REPRESENTATION
  // ============================================================

  @override
  String toString() {
    return 'AIActionResult('
        'success: $success, '
        'message: $message, '
        'actionType: $actionType, '
        'subjectName: $subjectName, '
        'chapterName: $chapterName, '
        'taskTitle: $taskTitle, '
        'skipped: $skipped'
        ')';
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static String? _cleanString(dynamic value) {
    if (value == null) {
      return null;
    }

    final result = value.toString().trim();

    return result.isEmpty ? null : result;
  }

  static bool _parseBool(
    dynamic value, {
    required bool fallback,
  }) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();

      if (normalized == 'true' ||
          normalized == 'yes' ||
          normalized == '1') {
        return true;
      }

      if (normalized == 'false' ||
          normalized == 'no' ||
          normalized == '0') {
        return false;
      }
    }

    return fallback;
  }
}
