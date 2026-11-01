import '../task_model.dart';

/// ============================================================
/// AI ACTION MODEL
/// ============================================================
///
/// Represents one structured action requested by StudyX AI.
///
/// This model is designed to work with AIActionService and supports
/// the action types currently used by the StudyX application.
///
/// The model also supports JSON conversion so actions can be passed
/// between the Flutter app and the AI backend.
/// ============================================================

class AIAction {
// ============================================================
// CORE
// ============================================================

final AIActionType type;

/// Optional unique ID for this action.
final String? actionId;

/// Optional subject ID.
final String? subjectId;

/// Optional subject name.
final String? subjectName;

/// Optional chapter ID.
final String? chapterId;

/// Optional chapter name.
final String? chapterName;

/// Optional step ID.
final String? stepId;

/// Optional step title.
final String? stepTitle;

/// Optional task ID.
final String? taskId;

/// Optional task title.
final String? taskTitle;

/// Optional task description.
final String? taskDescription;

/// Optional task type.
final TaskType? taskType;

/// Optional task priority.
final int? priority;

/// Optional estimated duration in minutes.
final int? estimatedMinutes;

/// Optional deadline.
final DateTime? deadline;

/// Optional arbitrary parameters.
final Map<String, dynamic> data;

/// Whether this action requires user confirmation.
final bool requiresConfirmation;

/// Optional warning attached to the action.
final String? warning;

// ============================================================
// CONSTRUCTOR
// ============================================================

const AIAction({
required this.type,
this.actionId,
this.subjectId,
this.subjectName,
this.chapterId,
this.chapterName,
this.stepId,
this.stepTitle,
this.taskId,
this.taskTitle,
this.taskDescription,
this.taskType,
this.priority,
this.estimatedMinutes,
this.deadline,
this.data = const {},
this.requiresConfirmation = false,
this.warning,
});

// ============================================================
// FROM JSON
// ============================================================

factory AIAction.fromJson(
Map<String, dynamic> json,
) {
return AIAction(
type: AIActionType.fromString(
_firstNonNull(
json['type'],
json['action'],
json['actionType'],
),
),


  actionId: _stringOrNull(
    _firstNonNull(
      json['actionId'],
      json['action_id'],
      json['id'],
    ),
  ),

  subjectId: _stringOrNull(
    _firstNonNull(
      json['subjectId'],
      json['subject_id'],
    ),
  ),

  subjectName: _stringOrNull(
    _firstNonNull(
      json['subjectName'],
      json['subject_name'],
      json['subject'],
    ),
  ),

  chapterId: _stringOrNull(
    _firstNonNull(
      json['chapterId'],
      json['chapter_id'],
    ),
  ),

  chapterName: _stringOrNull(
    _firstNonNull(
      json['chapterName'],
      json['chapter_name'],
      json['chapter'],
    ),
  ),

  stepId: _stringOrNull(
    _firstNonNull(
      json['stepId'],
      json['step_id'],
    ),
  ),

  stepTitle: _stringOrNull(
    _firstNonNull(
      json['stepTitle'],
      json['step_title'],
      json['step'],
    ),
  ),

  taskId: _stringOrNull(
    _firstNonNull(
      json['taskId'],
      json['task_id'],
    ),
  ),

  taskTitle: _stringOrNull(
    _firstNonNull(
      json['taskTitle'],
      json['task_title'],
      json['title'],
    ),
  ),

  taskDescription: _stringOrNull(
    _firstNonNull(
      json['taskDescription'],
      json['task_description'],
      json['description'],
    ),
  ),

  taskType: TaskTypeParser.fromJson(
    _firstNonNull(
      json['taskType'],
      json['task_type'],
    ),
  ),

  priority: _parseNullableInt(
    json['priority'],
  ),

  estimatedMinutes: _parseNullableInt(
    _firstNonNull(
      json['estimatedMinutes'],
      json['estimated_minutes'],
      json['duration'],
    ),
  ),

  deadline: _parseDateTime(
    _firstNonNull(
      json['deadline'],
      json['dueDate'],
      json['due_date'],
    ),
  ),

  data: _parseMap(
    _firstNonNull(
      json['data'],
      json['parameters'],
      json['payload'],
    ),
  ),

  requiresConfirmation: _parseBool(
    _firstNonNull(
      json['requiresConfirmation'],
      json['requires_confirmation'],
      json['confirm'],
    ),
    false,
  ),

  warning: _stringOrNull(
    json['warning'],
  ),
);


}

// ============================================================
// TO JSON
// ============================================================

Map<String, dynamic> toJson() {
return {
'type': type.value,


  if (actionId != null)
    'actionId': actionId,

  if (subjectId != null)
    'subjectId': subjectId,

  if (subjectName != null)
    'subjectName': subjectName,

  if (chapterId != null)
    'chapterId': chapterId,

  if (chapterName != null)
    'chapterName': chapterName,

  if (stepId != null)
    'stepId': stepId,

  if (stepTitle != null)
    'stepTitle': stepTitle,

  if (taskId != null)
    'taskId': taskId,

  if (taskTitle != null)
    'taskTitle': taskTitle,

  if (taskDescription != null)
    'taskDescription': taskDescription,

  if (taskType != null)
    'taskType': TaskTypeParser.toJson(taskType),

  if (priority != null)
    'priority': priority,

  if (estimatedMinutes != null)
    'estimatedMinutes': estimatedMinutes,

  if (deadline != null)
    'deadline': deadline!.toIso8601String(),

  if (data.isNotEmpty)
    'data': data,

  if (requiresConfirmation)
    'requiresConfirmation': true,

  if (warning != null)
    'warning': warning,
};


}

// ============================================================
// COPY WITH
// ============================================================

AIAction copyWith({
AIActionType? type,
String? actionId,
String? subjectId,
String? subjectName,
String? chapterId,
String? chapterName,
String? stepId,
String? stepTitle,
String? taskId,
String? taskTitle,
String? taskDescription,
TaskType? taskType,
int? priority,
int? estimatedMinutes,
DateTime? deadline,
Map<String, dynamic>? data,
bool? requiresConfirmation,
String? warning,
}) {
return AIAction(
type: type ?? this.type,
actionId: actionId ?? this.actionId,
subjectId: subjectId ?? this.subjectId,
subjectName: subjectName ?? this.subjectName,
chapterId: chapterId ?? this.chapterId,
chapterName: chapterName ?? this.chapterName,
stepId: stepId ?? this.stepId,
stepTitle: stepTitle ?? this.stepTitle,
taskId: taskId ?? this.taskId,
taskTitle: taskTitle ?? this.taskTitle,
taskDescription:
taskDescription ?? this.taskDescription,
taskType: taskType ?? this.taskType,
priority: priority ?? this.priority,
estimatedMinutes:
estimatedMinutes ?? this.estimatedMinutes,
deadline: deadline ?? this.deadline,
data: data ?? this.data,
requiresConfirmation:
requiresConfirmation ??
this.requiresConfirmation,
warning: warning ?? this.warning,
);
}

// ============================================================
// HELPERS
// ============================================================

dynamic operator [](String key) {
return toJson()[key];
}

bool get isUnknown =>
type == AIActionType.unknown;

bool get isStudyAction =>
type == AIActionType.completeStep ||
type == AIActionType.uncompleteStep ||
type == AIActionType.markChapterStudied ||
type == AIActionType.markRevisionDone;

bool get isTaskAction =>
type == AIActionType.createTask ||
type == AIActionType.completeTask ||
type == AIActionType.uncompleteTask ||
type == AIActionType.deleteTask;

bool get isSyllabusAction =>
type == AIActionType.createSubject ||
type == AIActionType.createChapter ||
type == AIActionType.addChapterStep ||
type == AIActionType.deleteChapter ||
type == AIActionType.deleteSubject;

@override
String toString() {
return 'AIAction('
'type: ${type.value}, '
'subjectName: $subjectName, '
'chapterName: $chapterName, '
'stepTitle: $stepTitle, '
'taskTitle: $taskTitle'
')';
}

// ============================================================
// GENERIC HELPERS
// ============================================================

static dynamic _firstNonNull(
dynamic first,
dynamic second, [
dynamic third,
]) {
if (first != null) {
return first;
}


if (second != null) {
  return second;
}

if (third != null) {
  return third;
}

return null;


}

static String? _stringOrNull(
dynamic value,
) {
if (value == null) {
return null;
}


final text =
    value.toString().trim();

if (text.isEmpty ||
    text.toLowerCase() == 'null') {
  return null;
}

return text;


}

static int? _parseNullableInt(
dynamic value,
) {
if (value == null) {
return null;
}


if (value is int) {
  return value;
}

if (value is num) {
  return value.toInt();
}

return int.tryParse(
  value.toString().trim(),
);


}

static DateTime? _parseDateTime(
dynamic value,
) {
if (value == null) {
return null;
}


if (value is DateTime) {
  return value;
}

return DateTime.tryParse(
  value.toString().trim(),
);


}

static bool _parseBool(
dynamic value,
bool fallback,
) {
if (value == null) {
return fallback;
}


if (value is bool) {
  return value;
}

if (value is num) {
  return value != 0;
}

final text =
    value.toString().trim().toLowerCase();

switch (text) {
  case 'true':
  case 'yes':
  case '1':
  case 'on':
    return true;

  case 'false':
  case 'no':
  case '0':
  case 'off':
    return false;

  default:
    return fallback;
}


}

static Map<String, dynamic> _parseMap(
dynamic value,
) {
if (value is Map) {
return Map<String, dynamic>.from(value);
}


return const {};


}
}

/// ============================================================
/// AI ACTION TYPES
/// ============================================================

enum AIActionType {
createSubject,
createChapter,
addChapterStep,
completeStep,
uncompleteStep,
markChapterStudied,
markRevisionDone,
createTask,
completeTask,
uncompleteTask,
deleteTask,
deleteChapter,
deleteSubject,
unknown;

// ============================================================
// STRING VALUE
// ============================================================

String get value {
switch (this) {
case AIActionType.createSubject:
return 'createSubject';


  case AIActionType.createChapter:
    return 'createChapter';

  case AIActionType.addChapterStep:
    return 'addChapterStep';

  case AIActionType.completeStep:
    return 'completeStep';

  case AIActionType.uncompleteStep:
    return 'uncompleteStep';

  case AIActionType.markChapterStudied:
    return 'markChapterStudied';

  case AIActionType.markRevisionDone:
    return 'markRevisionDone';

  case AIActionType.createTask:
    return 'createTask';

  case AIActionType.completeTask:
    return 'completeTask';

  case AIActionType.uncompleteTask:
    return 'uncompleteTask';

  case AIActionType.deleteTask:
    return 'deleteTask';

  case AIActionType.deleteChapter:
    return 'deleteChapter';

  case AIActionType.deleteSubject:
    return 'deleteSubject';

  case AIActionType.unknown:
    return 'unknown';
}


}

// ============================================================
// FROM STRING
// ============================================================

static AIActionType fromString(
dynamic value,
) {
if (value == null) {
return AIActionType.unknown;
}


final normalized =
    value
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(
          '_',
          '',
        )
        .replaceAll(
          '-',
          '',
        )
        .replaceAll(
          ' ',
          '',
        );

switch (normalized) {
  case 'createsubject':
  case 'addsubject':
    return AIActionType.createSubject;

  case 'createchapter':
  case 'addchapter':
    return AIActionType.createChapter;

  case 'addchapterstep':
  case 'createstep':
  case 'addstep':
    return AIActionType.addChapterStep;

  case 'completestep':
  case 'finishstep':
  case 'markstepcomplete':
    return AIActionType.completeStep;

  case 'uncompletestep':
  case 'undoStep':
  case 'markstepincomplete':
    return AIActionType.uncompleteStep;

  case 'markchapterstudied':
  case 'chapterstudied':
  case 'studychapter':
    return AIActionType.markChapterStudied;

  case 'markrevisiondone':
  case 'revisiondone':
  case 'completerevision':
    return AIActionType.markRevisionDone;

  case 'createtask':
  case 'addtask':
    return AIActionType.createTask;

  case 'completetask':
  case 'finishtask':
  case 'marktaskcomplete':
    return AIActionType.completeTask;

  case 'uncompletetask':
  case 'marktaskincomplete':
    return AIActionType.uncompleteTask;

  case 'deletetask':
  case 'removetask':
    return AIActionType.deleteTask;

  case 'deletechapter':
  case 'removechapter':
    return AIActionType.deleteChapter;

  case 'deletesubject':
  case 'removesubject':
    return AIActionType.deleteSubject;

  default:
    return AIActionType.unknown;
}


}
}

/// ============================================================
/// TASK TYPE PARSER
/// ============================================================
///
/// Keeps this file independent from the exact enum implementation
/// inside task_model.dart as much as possible.
/// ============================================================

class TaskTypeParser {
static TaskType? fromJson(
dynamic value,
) {
if (value == null) {
return null;
}


if (value is TaskType) {
  return value;
}

final normalized =
    value
        .toString()
        .trim()
        .toLowerCase();

for (final type in TaskType.values) {
  final name =
      type
          .toString()
          .split('.')
          .last
          .toLowerCase();

  if (name == normalized) {
    return type;
  }
}

return null;


}

static String? toJson(
TaskType? value,
) {
if (value == null) {
return null;
}


return value
    .toString()
    .split('.')
    .last;


}
}
