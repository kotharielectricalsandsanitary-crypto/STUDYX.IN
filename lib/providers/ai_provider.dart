import 'package:flutter/foundation.dart';

import '../models/ai_plan_model.dart';
import '../models/chapter_model.dart';
import '../models/task_model.dart';
import '../services/ai/ai_action_service.dart';
import '../services/ai/ai_service.dart';
import '../models/ai/ai_command_model.dart';
import '../models/ai/ai_context.dart';
import 'study_session_provider.dart';
import 'syllabus_provider.dart';
import 'task_provider.dart';
import 'user_provider.dart';

// ============================================================
// AI CHAT MESSAGE MODEL
// ============================================================

class AiChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime createdAt;

  const AiChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.createdAt,
  });
}

// ============================================================
// AI PROVIDER
// ============================================================

class AiProvider extends ChangeNotifier {
  // ============================================================
  // BACKEND AI SERVICE
  // ============================================================

  final AiService _aiService = AiService(
    // Flutter Web / Chrome on the same PC:
    baseUrl: 'http://localhost:3000',

    // If using Android phone later, replace localhost with
    // your PC's local IP address.
  );

  bool _isLoading = false;
  String? _error;
  AiPlan? _currentPlan;

  final List<AiChatMessage> _messages = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  AiPlan? get currentPlan => _currentPlan;

  List<AiChatMessage> get messages =>
      List.unmodifiable(_messages);

  // ============================================================
  // CLEAR PLAN
  // ============================================================

  void clearPlan() {
    _currentPlan = null;
    _error = null;
    notifyListeners();
  }

  // ============================================================
  // CLEAR CHAT
  // ============================================================

  void clearChat() {
    _messages.clear();
    _error = null;
    notifyListeners();
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<String> sendMessage({
    required String userMessage,
    required UserProvider userProvider,
    required TaskProvider taskProvider,
    required SyllabusProvider syllabusProvider,
    required StudySessionProvider studySessionProvider,
  }) async {
    final message = userMessage.trim();

    if (message.isEmpty) {
      return '';
    }

    _error = null;

    // ----------------------------------------------------------
    // ADD USER MESSAGE
    // ----------------------------------------------------------

    _messages.add(
      AiChatMessage(
        id: 'user_${DateTime.now().microsecondsSinceEpoch}',
        text: message,
        isUser: true,
        createdAt: DateTime.now(),
      ),
    );

    _isLoading = true;
    notifyListeners();

    try {
      // --------------------------------------------------------
      // FIRST: CHECK REAL STUDYX APP ACTIONS
      // --------------------------------------------------------

      final actionResponse = await _tryAppAction(
        userMessage: message,
        userProvider: userProvider,
        taskProvider: taskProvider,
        syllabusProvider: syllabusProvider,
        studySessionProvider: studySessionProvider,
      );

      String response;

      // --------------------------------------------------------
      // IF IT IS AN APP COMMAND, HANDLE LOCALLY
      // --------------------------------------------------------

      if (actionResponse != null) {
        response = actionResponse;
      } else {
        // ------------------------------------------------------
        // OTHERWISE ASK BACKEND AI
        // ------------------------------------------------------

        response = await _askBackendAI(
          message: message,
          userProvider: userProvider,
          taskProvider: taskProvider,
          syllabusProvider: syllabusProvider,
          studySessionProvider: studySessionProvider,
        );
      }

      // --------------------------------------------------------
      // ADD AI RESPONSE
      // --------------------------------------------------------

      _messages.add(
        AiChatMessage(
          id: 'ai_${DateTime.now().microsecondsSinceEpoch}',
          text: response,
          isUser: false,
          createdAt: DateTime.now(),
        ),
      );

      return response;
    } catch (e) {
      debugPrint('AI chat error: $e');

      _error = 'Could not process that request.';

      const response =
          'I could not connect to StudyX AI right now. '
          'Make sure the StudyX AI backend is running on port 3000.';

      _messages.add(
        AiChatMessage(
          id: 'ai_error_${DateTime.now().microsecondsSinceEpoch}',
          text: response,
          isUser: false,
          createdAt: DateTime.now(),
        ),
      );

      return response;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // ASK BACKEND AI
  // ============================================================

  Future<String> _askBackendAI({
    required String message,
    required UserProvider userProvider,
    required TaskProvider taskProvider,
    required SyllabusProvider syllabusProvider,
    required StudySessionProvider studySessionProvider,
  }) async {
    final userContext = <String, dynamic>{
      'name': userProvider.name,
      'dailyHours': userProvider.dailyHours,
    };

    final syllabusContext =
        _buildSyllabusContext(syllabusProvider);

    final taskContext =
        _buildTasksContext(taskProvider);

    final studySessionContext =
        _buildStudySessionsContext(studySessionProvider);

    final messageContext = _messages
        .map(
          (item) => <String, dynamic>{
            'id': item.id,
            'text': item.text,
            'isUser': item.isUser,
            'createdAt':
                item.createdAt.toIso8601String(),
          },
        )
        .toList();

    return await _aiService.chat(
      message: message,
      user: userContext,
      syllabus: syllabusContext,
      tasks: taskContext,
      studySessions: studySessionContext,
      messages: messageContext,
    );
  }

  // ============================================================
  // SYLLABUS CONTEXT FOR AI
  // ============================================================

  List<Map<String, dynamic>> _buildSyllabusContext(
    SyllabusProvider provider,
  ) {
    return provider.subjects.map((subject) {
      return <String, dynamic>{
        'id': subject.id,
        'name': subject.name,
        'chapters': subject.chapters.map((chapter) {
          return <String, dynamic>{
            'id': chapter.id,
            'name': chapter.name,
            'isCompleted': chapter.isCompleted,
            'estimatedMinutes':
                chapter.estimatedMinutes,
          };
        }).toList(),
      };
    }).toList();
  }

  // ============================================================
  // TASK CONTEXT FOR AI
  // ============================================================

  List<Map<String, dynamic>> _buildTasksContext(
    TaskProvider provider,
  ) {
    final tasks = provider.pendingTasks;

    return tasks.map((task) {
      return <String, dynamic>{
        'id': task.id,
        'title': task.title,
        'description': task.description,
        'type': task.type.name,
        'priority': task.priority,
        'estimatedMinutes':
            task.estimatedMinutes,
        'deadline':
            task.deadline.toIso8601String(),
        'subjectId': task.subjectId,
        'chapterId': task.chapterId,
        'isCompleted': false,
      };
    }).toList();
  }

  // ============================================================
  // STUDY SESSION CONTEXT
  // ============================================================
  //
  // Kept intentionally safe because the exact internal
  // StudySession model can vary. We still send today's
  // calculated study time to the AI.
  // ============================================================

  List<Map<String, dynamic>> _buildStudySessionsContext(
    StudySessionProvider provider,
  ) {
    final todayHours =
        provider.hoursForDate(DateTime.now());

    return [
      <String, dynamic>{
        'date': DateTime.now()
            .toIso8601String(),
        'hours': todayHours,
      },
    ];
  }

  // ============================================================
  // REAL APP ACTION ENGINE
  // ============================================================

  Future<String?> _tryAppAction({
    required String userMessage,
    required UserProvider userProvider,
    required TaskProvider taskProvider,
    required SyllabusProvider syllabusProvider,
    required StudySessionProvider studySessionProvider,
  }) async {
    final query = userMessage.trim();

    if (query.isEmpty) return null;

    final lower = query.toLowerCase();

    if (_looksLikeCreateSubjectCommand(lower)) {
      return await _handleCreateSubject(
        message: query,
        syllabusProvider: syllabusProvider,
      );
    }

    if (_looksLikeAddSyllabusCommand(lower)) {
      return await _handleAddSyllabus(
        message: query,
        syllabusProvider: syllabusProvider,
      );
    }

    if (_looksLikeRevisionDoneCommand(lower)) {
      return await _handleRevisionDone(
        message: query,
        syllabusProvider: syllabusProvider,
      );
    }

    if (_looksLikeStudyDoneCommand(lower)) {
      return await _handleStudyDone(
        message: query,
        syllabusProvider: syllabusProvider,
      );
    }

    if (_looksLikeCompleteTaskCommand(lower)) {
      return await _handleCompleteTask(
        message: query,
        taskProvider: taskProvider,
      );
    }

    if (_looksLikeCreateTaskCommand(lower)) {
      return await _handleCreateTask(
        message: query,
        taskProvider: taskProvider,
        syllabusProvider: syllabusProvider,
      );
    }

    return null;
  }

  // ============================================================
  // CREATE SUBJECT COMMAND DETECTION
  // ============================================================

  bool _looksLikeCreateSubjectCommand(
    String query,
  ) {
    return _containsAny(
      query,
      [
        'create subject',
        'add subject',
        'make subject',
        'new subject',
        'create a subject',
        'add a subject',
        'make a subject',
      ],
    );
  }

  // ============================================================
  // CREATE SUBJECT
  // ============================================================

  Future<String> _handleCreateSubject({
    required String message,
    required SyllabusProvider syllabusProvider,
  }) async {
    var text = message.trim();

    text = text.replaceFirst(
      RegExp(
        r'^(ai|hey ai|okay ai|ok ai|please ai)[,\s]*',
        caseSensitive: false,
      ),
      '',
    );

    text = text.replaceFirst(
      RegExp(
        r'^(create|add|make|new)\s+(a\s+)?subject\s*',
        caseSensitive: false,
      ),
      '',
    );

    text = text
        .replaceAll(
          RegExp(
            r'\b(please|now|today)\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (text.isEmpty) {
      return 'Tell me the subject name.\n\n'
          'Example:\n'
          '"Create Biology"';
    }

    String subjectName = text;
    String? chapterPart;

    final chapterMatch = RegExp(
      r'^(.+?)\s+(?:with|and)\s+(?:chapters?|chapter)\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(text);

    if (chapterMatch != null) {
      subjectName =
          chapterMatch.group(1)?.trim() ?? text;

      chapterPart =
          chapterMatch.group(2)?.trim();
    }

    subjectName = subjectName
        .replaceFirst(
          RegExp(
            r'\s+subject$',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    if (subjectName.isEmpty) {
      return 'Tell me the subject name.\n\n'
          'Example:\n'
          '"Create Biology"';
    }

    final subject =
        await syllabusProvider.getOrCreateSubject(
      subjectName,
    );

    final addedChapters = <String>[];
    final existingChapters = <String>[];

    if (chapterPart != null &&
        chapterPart.isNotEmpty) {
      final chapters =
          _splitChapterNames(chapterPart);

      for (final rawChapter in chapters) {
        final chapterName =
            _cleanChapterName(rawChapter);

        if (chapterName.isEmpty) continue;

        final existing =
            syllabusProvider.findChapterByName(
          subjectId: subject.id,
          chapterName: chapterName,
        );

        if (existing != null) {
          existingChapters.add(chapterName);
          continue;
        }

        await syllabusProvider.addChapter(
          subjectId: subject.id,
          name: chapterName,
        );

        addedChapters.add(chapterName);
      }
    }

    if (chapterPart == null ||
        chapterPart.isEmpty) {
      return 'Subject "${subject.name}" is ready. ✅\n\n'
          'You can now add chapters to it.\n'
          'Example: "Add Cell to ${subject.name}".';
    }

    final buffer = StringBuffer();

    buffer.writeln(
      'Subject "${subject.name}" is ready. ✅',
    );

    if (addedChapters.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(
        'Added ${addedChapters.length} chapter'
        '${addedChapters.length == 1 ? '' : 's'}:',
      );

      for (final chapter in addedChapters) {
        buffer.writeln('• $chapter');
      }
    }

    if (existingChapters.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Already present:');

      for (final chapter in existingChapters) {
        buffer.writeln('• $chapter');
      }
    }

    return buffer.toString().trim();
  }

  // ============================================================
  // ADD SYLLABUS COMMAND DETECTION
  // ============================================================

  bool _looksLikeAddSyllabusCommand(
    String query,
  ) {
    return _containsAny(
      query,
      [
        'add chapter',
        'add chapters',
        'add this chapter',
        'add these chapters',
        'add a chapter',
        'add chapter to',
        'add chapters to',
        'add chapter in',
        'add chapters in',
        'put chapter',
        'put chapters',
        'put this chapter',
        'add to syllabus',
        'add in syllabus',
        'add it to syllabus',
        'create chapter',
        'create chapters',
        'create a chapter',
        'create multiple chapters',
        'make chapter',
        'make chapters',
        'make a chapter',
        'make multiple chapters',
        'add cell to',
        'add laws of motion to',
        'add kinematics to',
        'add thermodynamics to',
        'add structure of atom to',
        'add animal kingdom to',
      ],
    );
  }

  // ============================================================
  // HANDLE ADD CHAPTER
  // ============================================================

  Future<String> _handleAddSyllabus({
    required String message,
    required SyllabusProvider syllabusProvider,
  }) async {
    final lower = message.toLowerCase();

    String? subjectName;

    for (final subject in syllabusProvider.subjects) {
      final subjectLower =
          subject.name.trim().toLowerCase();

      if (subjectLower.isNotEmpty &&
          lower.contains(subjectLower)) {
        subjectName = subject.name.trim();
        break;
      }
    }

    subjectName ??=
        _detectCommonSubject(lower);

    if (subjectName == null) {
      final subjectMatch = RegExp(
        r'(?:in|to|for)\s+([a-zA-Z][a-zA-Z0-9 &_-]{1,40})',
        caseSensitive: false,
      ).firstMatch(message);

      if (subjectMatch != null) {
        subjectName =
            subjectMatch.group(1)?.trim();

        if (subjectName != null) {
          subjectName = subjectName
              .replaceAll(
                RegExp(
                  r'\b(syllabus|today|please|now|chapter|chapters|multiple)\b',
                  caseSensitive: false,
                ),
                '',
              )
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
        }
      }
    }

    if (subjectName == null ||
        subjectName.isEmpty) {
      return 'Tell me the subject too. 📚\n\n'
          'Example:\n'
          '"Add Cell and Biomolecules to Biology."';
    }

    var chapterText = message;

    chapterText = chapterText.replaceFirst(
      RegExp(
        r'^(ai|hey ai|okay ai|ok ai|please ai)[,\s]*',
        caseSensitive: false,
      ),
      '',
    );

    chapterText = chapterText.replaceFirst(
      RegExp(
        r'^(add|create|make|put)\s+'
        r'(?:(?:a|multiple|several|these|those|the)\s+)?'
        r'chapters?\s*',
        caseSensitive: false,
      ),
      '',
    );

    chapterText = chapterText.replaceFirst(
      RegExp(
        r'^(chapter|chapters)\s+',
        caseSensitive: false,
      ),
      '',
    );

    chapterText = chapterText.replaceFirst(
      RegExp(
        r'\s+(?:to|in|for)\s+'
        r'${RegExp.escape(subjectName)}'
        r'\s*$',
        caseSensitive: false,
      ),
      '',
    );

    chapterText = chapterText.replaceFirst(
      RegExp(
        r'^(?:to|in|for)\s+'
        r'${RegExp.escape(subjectName)}\s+',
        caseSensitive: false,
      ),
      '',
    );

    chapterText = chapterText.replaceFirst(
      RegExp(
        r'\s+(?:to|in|for)\s+'
        r'${RegExp.escape(subjectName)}'
        r'\s*[.!?]?\s*$',
        caseSensitive: false,
      ),
      '',
    );

    chapterText = chapterText
        .replaceAll(
          RegExp(
            r'\b(syllabus|please|now|today|these|those|multiple|several)\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (chapterText.isEmpty) {
      return 'Tell me which chapters you want to add. 📚\n\n'
          'Example:\n'
          '"Add Kinematics, Laws of Motion and Work to Physics."';
    }

    final chapters =
        _splitChapterNames(chapterText);

    if (chapters.isEmpty) {
      return 'I could not find any chapter names. 📚\n\n'
          'Example:\n'
          '"Add Kinematics, Laws of Motion and Work to Physics."';
    }

    final added = <String>[];
    final existing = <String>[];

    final subject =
        await syllabusProvider.getOrCreateSubject(
      subjectName,
    );

    for (final rawChapter in chapters) {
      final cleanChapter =
          _cleanChapterName(rawChapter);

      if (cleanChapter.isEmpty) continue;

      final alreadyExists =
          syllabusProvider.findChapterByName(
        subjectId: subject.id,
        chapterName: cleanChapter,
      );

      if (alreadyExists != null) {
        existing.add(cleanChapter);
        continue;
      }

      await syllabusProvider.addChapter(
        subjectId: subject.id,
        name: cleanChapter,
      );

      added.add(cleanChapter);
    }

    if (added.isEmpty &&
        existing.isNotEmpty) {
      return 'Those chapters are already in your '
          '${subject.name} syllabus. 📚';
    }

    if (added.isEmpty) {
      return 'I could not find a valid chapter name. 📚\n\n'
          'Example:\n'
          '"Add Kinematics, Laws of Motion and Work to Physics."';
    }

    final buffer = StringBuffer();

    buffer.writeln(
      'Added ${added.length} chapter'
      '${added.length == 1 ? '' : 's'} to ${subject.name}. ✅',
    );

    for (final chapter in added) {
      buffer.writeln('• $chapter');
    }

    if (existing.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Already present:');

      for (final chapter in existing) {
        buffer.writeln('• $chapter');
      }
    }

    return buffer.toString().trim();
  }

  // ============================================================
  // COMMON SUBJECT DETECTOR
  // ============================================================

  String? _detectCommonSubject(
    String lower,
  ) {
    if (RegExp(
      r'\bphysics\b',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return 'Physics';
    }

    if (RegExp(
      r'\bchemistry\b',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return 'Chemistry';
    }

    if (RegExp(
      r'\bbiology\b',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return 'Biology';
    }

    if (RegExp(
      r'\bbio\b',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return 'Biology';
    }

    if (RegExp(
      r'\benglish\b',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return 'English';
    }

    if (RegExp(
      r'\bhindi\b',
      caseSensitive: false,
    ).hasMatch(lower)) {
      return 'Hindi';
    }

    return null;
  }

  // ============================================================
  // SPLIT CHAPTER NAMES
  // ============================================================

  List<String> _splitChapterNames(
    String text,
  ) {
    var value = text.trim();

    if (value.isEmpty) return [];

    value = value
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('•', '\n')
        .replaceAll('▪', '\n')
        .replaceAll('●', '\n')
        .replaceAll('–', '-');

    value = value.replaceAll(
      RegExp(
        r'(?m)^\s*(?:\d+\s*[\.\)]|[-*])\s*',
      ),
      '\n',
    );

    value = value.replaceAll(
      RegExp(
        r'(?i)\bchapter\s+\d+\s*[:.\-]\s*',
      ),
      '\n',
    );

    value = value.replaceAll(
      RegExp(r'\s*(?:;|\|)\s*'),
      ',',
    );

    value = value.replaceAll('\n', ',');

    value = value.replaceAll(
      RegExp(
        r'\s+(?:and|&)\s+',
        caseSensitive: false,
      ),
      ',',
    );

    value = value.replaceAll(
      RegExp(
        r'\s+then\s+',
        caseSensitive: false,
      ),
      ',',
    );

    return value
        .split(',')
        .map((item) => item.trim())
        .map(
          (item) => item
              .replaceAll(
                RegExp(r'^[\s,.:;\-]+'),
                '',
              )
              .replaceAll(
                RegExp(r'[\s,;]+$'),
                '',
              )
              .trim(),
        )
        .where(
          (item) => item.isNotEmpty,
        )
        .toList();
  }

  // ============================================================
  // STUDY DONE
  // ============================================================

  bool _looksLikeStudyDoneCommand(
    String query,
  ) {
    return _containsAny(
      query,
      [
        'i studied',
        'i study',
        'i completed',
        'i complete',
        'i finished',
        'finished studying',
        'completed studying',
        'done studying',
        'studied today',
        'completed today',
        'finished today',
        'i did',
      ],
    );
  }

  Future<String> _handleStudyDone({
    required String message,
    required SyllabusProvider syllabusProvider,
  }) async {
    final chapterInfo =
        _findChapterFromMessage(
      message,
      syllabusProvider,
    );

    if (chapterInfo == null) {
      return 'I could not find that chapter in your syllabus. 📚\n\n'
          'Try:\n'
          '"I completed Cell: The Unit of Life today."\n\n'
          'The chapter must already exist in your syllabus.';
    }

    final subject = chapterInfo.subject;
    final chapter = chapterInfo.chapter;

    await syllabusProvider.markChapterStudied(
      subjectId: subject.id,
      chapterId: chapter.id,
    );

    return 'Marked "${chapter.name}" as studied today. ✅\n\n'
        'Subject: ${subject.name}\n'
        'Revision has been scheduled automatically. 🔄';
  }

  // ============================================================
  // REVISION DONE
  // ============================================================

  bool _looksLikeRevisionDoneCommand(
    String query,
  ) {
    final hasRevisionWord =
        _containsAny(
      query,
      [
        'revised',
        'revision done',
        'revision completed',
        'finished revision',
        'completed revision',
        'revise done',
      ],
    );

    final hasDoneWord =
        _containsAny(
      query,
      [
        'i revised',
        'i did revision',
        'i finished revision',
        'i completed revision',
      ],
    );

    return hasRevisionWord ||
        hasDoneWord;
  }

  Future<String> _handleRevisionDone({
    required String message,
    required SyllabusProvider syllabusProvider,
  }) async {
    final chapterInfo =
        _findChapterFromMessage(
      message,
      syllabusProvider,
    );

    if (chapterInfo == null) {
      return 'I could not find that chapter in your syllabus. 📚\n\n'
          'Example:\n'
          '"I revised Cell today."';
    }

    await syllabusProvider
        .markChapterRevisionDone(
      subjectId: chapterInfo.subject.id,
      chapterId: chapterInfo.chapter.id,
    );

    return 'Revision completed for '
        '"${chapterInfo.chapter.name}". ✅\n\n'
        'I have scheduled the next revision automatically. 🔄';
  }

  // ============================================================
  // CREATE TASK
  // ============================================================

  bool _looksLikeCreateTaskCommand(
    String query,
  ) {
    return _containsAny(
      query,
      [
        'make a task',
        'create a task',
        'add a task',
        'make task',
        'create task',
        'add task',
        'remind me to',
        'i need to',
        'task for',
      ],
    );
  }

  Future<String> _handleCreateTask({
    required String message,
    required TaskProvider taskProvider,
    required SyllabusProvider syllabusProvider,
  }) async {
    var title = message.trim();

    title = title.replaceFirst(
      RegExp(
        r'^(ai|hey ai|please ai)[,\s]*',
        caseSensitive: false,
      ),
      '',
    );

    title = title.replaceFirst(
      RegExp(
        r'^(make|create|add)\s+(a\s+)?task\s*',
        caseSensitive: false,
      ),
      '',
    );

    title = title.replaceFirst(
      RegExp(
        r'^remind\s+me\s+to\s*',
        caseSensitive: false,
      ),
      '',
    );

    title = title.trim();

    if (title.isEmpty) {
      return 'Tell me what task you want me to create.\n\n'
          'Example:\n'
          '"Make a task to revise Physics tomorrow."';
    }

    TaskType type = TaskType.study;

    if (_containsAny(
      title.toLowerCase(),
      [
        'revision',
        'revise',
      ],
    )) {
      type = TaskType.revision;
    }

    final deadline =
        _extractDeadline(title);

    final priority =
        _extractPriority(title);

    String? subjectId;
    String? chapterId;

    final chapterInfo =
        _findChapterFromMessage(
      title,
      syllabusProvider,
    );

    if (chapterInfo != null) {
      subjectId =
          chapterInfo.subject.id;

      chapterId =
          chapterInfo.chapter.id;
    }

    title = title
        .replaceAll(
          RegExp(
            r'\b(today|tomorrow|tonight|next week|next sunday)\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(
            r'\b(priority|urgent|high priority)\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        )
        .trim();

    if (title.isEmpty) {
      title = type == TaskType.revision
          ? 'Revision'
          : 'Study Task';
    }

    await taskProvider.createTask(
      title: _capitalizeFirst(title),
      description:
          'Created by StudyX AI.',
      type: type,
      deadline: deadline,
      priority: priority,
      estimatedMinutes:
          type == TaskType.revision
              ? 30
              : 45,
      subjectId: subjectId,
      chapterId: chapterId,
    );

    final dateText =
        _friendlyDate(deadline);

    return 'Task created successfully. ✅\n\n'
        '📝 ${_capitalizeFirst(title)}\n'
        '📅 $dateText\n'
        '🎯 Priority: $priority/10\n'
        '⏱️ ${type == TaskType.revision ? 30 : 45} minutes';
  }

  // ============================================================
  // COMPLETE TASK
  // ============================================================

  bool _looksLikeCompleteTaskCommand(
    String query,
  ) {
    return _containsAny(
      query,
      [
        'complete task',
        'completed task',
        'finish task',
        'finished task',
        'done task',
        'task is done',
        'i finished my task',
        'i completed my task',
        'mark task done',
      ],
    );
  }

  Future<String> _handleCompleteTask({
    required String message,
    required TaskProvider taskProvider,
  }) async {
    final pending =
        taskProvider.pendingTasks;

    if (pending.isEmpty) {
      return 'You have no pending tasks right now. ✅';
    }

    final clean = message
        .toLowerCase()
        .replaceAll(
          RegExp(
            r'\b(i|have|just|finished|finish|completed|complete|done|my|task|the|is|now|mark)\b',
          ),
          ' ',
        )
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        )
        .trim();

    TaskModel? matchedTask;

    if (clean.isNotEmpty) {
      for (final task in pending) {
        final taskTitle =
            task.title.toLowerCase();

        if (taskTitle.contains(clean) ||
            clean.contains(taskTitle)) {
          matchedTask = task;
          break;
        }
      }
    }

    if (matchedTask == null &&
        pending.length == 1) {
      matchedTask = pending.first;
    }

    matchedTask ??= pending.first;

    await taskProvider.completeTask(
      matchedTask.id,
    );

    return 'Task completed. ✅\n\n'
        '📝 ${matchedTask.title}\n'
        'Great — I updated your StudyX progress.';
  }

  // ============================================================
  // CHAPTER SEARCH
  // ============================================================

  _ChapterInfo? _findChapterFromMessage(
    String message,
    SyllabusProvider provider,
  ) {
    final lowerMessage =
        message.toLowerCase();

    _ChapterInfo? bestMatch;
    var bestScore = 0;

    for (final subject in provider.subjects) {
      for (final chapter
          in subject.chapters) {
        final chapterName =
            chapter.name.trim().toLowerCase();

        final subjectName =
            subject.name.trim().toLowerCase();

        var score = 0;

        if (chapterName.isNotEmpty &&
            lowerMessage.contains(
              chapterName,
            )) {
          score += 100;
        }

        if (subjectName.isNotEmpty &&
            lowerMessage.contains(
              subjectName,
            )) {
          score += 20;
        }

        final words = chapterName
            .split(RegExp(r'\s+'))
            .where(
              (word) => word.length >= 3,
            )
            .toList();

        for (final word in words) {
          if (lowerMessage.contains(word)) {
            score += 5;
          }
        }

        if (score > bestScore) {
          bestScore = score;

          bestMatch = _ChapterInfo(
            subject: subject,
            chapter: chapter,
          );
        }
      }
    }

    return bestMatch;
  }

  // ============================================================
  // DEADLINE PARSER
  // ============================================================

  DateTime _extractDeadline(
    String text,
  ) {
    final now = DateTime.now();
    final lower = text.toLowerCase();

    final cleanToday = DateTime(
      now.year,
      now.month,
      now.day,
    );

    if (lower.contains('tomorrow')) {
      return cleanToday.add(
        const Duration(days: 1),
      );
    }

    if (lower.contains('next week')) {
      return cleanToday.add(
        const Duration(days: 7),
      );
    }

    if (lower.contains('next sunday')) {
      var days =
          (DateTime.sunday -
                  cleanToday.weekday +
                  7) %
              7;

      if (days == 0) {
        days = 7;
      }

      return cleanToday.add(
        Duration(days: days),
      );
    }

    return cleanToday;
  }

  // ============================================================
  // PRIORITY PARSER
  // ============================================================

  int _extractPriority(
    String text,
  ) {
    final lower =
        text.toLowerCase();

    if (_containsAny(
      lower,
      [
        'urgent',
        'very important',
        'highest priority',
      ],
    )) {
      return 10;
    }

    if (_containsAny(
      lower,
      [
        'high priority',
        'important',
      ],
    )) {
      return 8;
    }

    if (_containsAny(
      lower,
      [
        'low priority',
        'not urgent',
      ],
    )) {
      return 3;
    }

    return 5;
  }

  // ============================================================
  // GENERATE STUDY PLAN
  // ============================================================

  Future<void> generatePlan({
    required String userMessage,
    required UserProvider userProvider,
    required TaskProvider taskProvider,
    required SyllabusProvider syllabusProvider,
    required StudySessionProvider studySessionProvider,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final plan = _buildSmartPlan(
        userMessage: userMessage,
        userProvider: userProvider,
        taskProvider: taskProvider,
        syllabusProvider: syllabusProvider,
        studySessionProvider:
            studySessionProvider,
      );

      _currentPlan = plan;
    } catch (e) {
      debugPrint('AI plan error: $e');
      _error =
          'Could not create a study plan.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // SMART PLAN
  // ============================================================

  AiPlan _buildSmartPlan({
    required String userMessage,
    required UserProvider userProvider,
    required TaskProvider taskProvider,
    required SyllabusProvider syllabusProvider,
    required StudySessionProvider studySessionProvider,
  }) {
    final query =
        userMessage.trim().toLowerCase();

    final items = <AiPlanItem>[];

    final dailyMinutes =
        (userProvider.dailyHours * 60)
            .round();

    final todayStudiedMinutes =
        (studySessionProvider
                    .hoursForDate(
                      DateTime.now(),
                    ) *
                60)
            .round();

    final rawRemainingMinutes =
        dailyMinutes -
            todayStudiedMinutes;

    final remainingMinutes =
        rawRemainingMinutes <= 0
            ? 30
            : rawRemainingMinutes;

    final revisionChapters =
        syllabusProvider
            .getChaptersForRevision();

    final wantsRevision =
        query.contains('revision') ||
            query.contains('revise') ||
            query.contains('sunday');

    if (wantsRevision ||
        DateTime.now().weekday ==
            DateTime.sunday) {
      for (final chapter
          in revisionChapters.take(3)) {
        final subjectId =
            _findSubjectId(
          syllabusProvider,
          chapter.id,
        );

        items.add(
          AiPlanItem(
            title:
                'Revise ${chapter.name}',
            description:
                'This chapter is due for revision.',
            type:
                TaskType.revision,
            estimatedMinutes: 30,
            priority: 9,
            subjectId: subjectId,
            chapterId: chapter.id,
          ),
        );
      }
    }

    final pendingTasks =
        taskProvider.pendingTasks;

    for (final task
        in pendingTasks.take(5)) {
      if (items.length >= 8) {
        break;
      }

      final alreadyAdded =
          items.any(
        (item) =>
            item.title ==
                task.title &&
            item.chapterId ==
                task.chapterId,
      );

      if (alreadyAdded) {
        continue;
      }

      items.add(
        AiPlanItem(
          title: task.title,
          description:
              task.description,
          type: task.type,
          estimatedMinutes:
              task.estimatedMinutes,
          priority: task.priority,
          subjectId: task.subjectId,
          chapterId: task.chapterId,
        ),
      );
    }

    final incompleteChapters =
        <_ChapterInfo>[];

    for (final subject
        in syllabusProvider.subjects) {
      for (final chapter
          in subject.chapters) {
        if (!chapter.isCompleted) {
          incompleteChapters.add(
            _ChapterInfo(
              subject: subject,
              chapter: chapter,
            ),
          );
        }
      }
    }

    var usedMinutes =
        items.fold<int>(
      0,
      (sum, item) =>
          sum + item.estimatedMinutes,
    );

    for (final info
        in incompleteChapters) {
      if (usedMinutes >=
          remainingMinutes) {
        break;
      }

      if (items.length >= 8) {
        break;
      }

      final alreadyAdded =
          items.any(
        (item) =>
            item.chapterId ==
            info.chapter.id,
      );

      if (alreadyAdded) {
        continue;
      }

      final minutes =
          info.chapter.estimatedMinutes
              .clamp(30, 90);

      items.add(
        AiPlanItem(
          title:
              '${info.subject.name}: ${info.chapter.name}',
          description:
              'Continue this incomplete chapter.',
          type:
              TaskType.study,
          estimatedMinutes:
              minutes,
          priority: 7,
          subjectId:
              info.subject.id,
          chapterId:
              info.chapter.id,
        ),
      );

      usedMinutes += minutes;
    }

    if (items.isEmpty) {
      items.add(
        const AiPlanItem(
          title:
              'Plan your syllabus',
          description:
              'Add subjects and chapters so StudyX AI can create a personalized plan.',
          type:
              TaskType.study,
          estimatedMinutes: 30,
          priority: 5,
        ),
      );
    }

    final finalItems =
        <AiPlanItem>[];

    var finalMinutes = 0;

    for (final item in items) {
      if (finalItems.isNotEmpty &&
          finalMinutes +
                  item.estimatedMinutes >
              remainingMinutes) {
        continue;
      }

      finalItems.add(item);

      finalMinutes +=
          item.estimatedMinutes;
    }

    if (finalItems.isEmpty &&
        items.isNotEmpty) {
      finalItems.add(
        items.first,
      );
    }

    final planMinutes =
        finalItems.fold<int>(
      0,
      (sum, item) =>
          sum + item.estimatedMinutes,
    );

    return AiPlan(
      message: _createMessage(
        userProvider: userProvider,
        query: query,
        todayStudiedMinutes:
            todayStudiedMinutes,
        planMinutes:
            planMinutes,
      ),
      items: finalItems,
    );
  }

  // ============================================================
  // APPLY PLAN
  // ============================================================

  Future<void> applyCurrentPlan(
    TaskProvider taskProvider,
  ) async {
    final plan = _currentPlan;

    if (plan == null) return;

    final deadline =
        DateTime.now();

    for (final item
        in plan.items) {
      final exists =
          item.subjectId != null &&
              item.chapterId != null &&
              taskProvider
                  .hasPendingChapterTask(
            subjectId:
                item.subjectId!,
            chapterId:
                item.chapterId!,
            type: item.type,
            deadline: deadline,
          );

      if (exists) continue;

      await taskProvider
          .createTask(
        title: item.title,
        description:
            item.description,
        type: item.type,
        deadline: deadline,
        priority: item.priority,
        estimatedMinutes:
            item.estimatedMinutes,
        subjectId:
            item.subjectId,
        chapterId:
            item.chapterId,
      );
    }

    notifyListeners();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  int _getIncompleteChapterCount(
    SyllabusProvider provider,
  ) {
    var count = 0;

    for (final subject
        in provider.subjects) {
      for (final chapter
          in subject.chapters) {
        if (!chapter.isCompleted) {
          count++;
        }
      }
    }

    return count;
  }

  String? _findSubjectId(
    SyllabusProvider provider,
    String chapterId,
  ) {
    for (final subject
        in provider.subjects) {
      for (final chapter
          in subject.chapters) {
        if (chapter.id ==
            chapterId) {
          return subject.id;
        }
      }
    }

    return null;
  }

  String _createMessage({
    required UserProvider userProvider,
    required String query,
    required int todayStudiedMinutes,
    required int planMinutes,
  }) {
    final name =
        userProvider.name.isEmpty
            ? 'Student'
            : userProvider.name;

    final studiedHours =
        (todayStudiedMinutes / 60)
            .toStringAsFixed(1);

    final planHours =
        (planMinutes / 60)
            .toStringAsFixed(1);

    if (query.contains('backlog')) {
      return '$name, I prioritized your pending work and incomplete chapters. '
          'Complete the highest-priority work first. '
          "Today's AI plan is about $planHours hours.";
    }

    if (query.contains('revision') ||
        query.contains('revise')) {
      return '$name, this plan focuses on chapters due for revision. '
          'Estimated revision time: $planHours hours.';
    }

    return '$name, you have studied $studiedHours hours today. '
        'Your next plan contains about $planHours hours of focused work.';
  }

  // ============================================================
  // MOTIVATION
  // ============================================================

  String _buildMotivationResponse({
    required String name,
    required int todayMinutes,
    required double goalHours,
  }) {
    final studiedHours =
        (todayMinutes / 60)
            .toStringAsFixed(1);

    if (todayMinutes == 0) {
      return '$name, do not worry about the entire '
          '${goalHours.toStringAsFixed(1)}-hour goal right now. 🎯\n\n'
          'Start one focused session and build from there.';
    }

    return '$name, you already studied '
        '$studiedHours hours today. 🔥\n\n'
        'Focus on the next session instead of the whole day.';
  }

  // ============================================================
  // GENERIC KEYWORD HELPER
  // ============================================================

  bool _containsAny(
    String text,
    List<String> keywords,
  ) {
    return keywords.any(
      (keyword) =>
          text.contains(keyword),
    );
  }

  // ============================================================
  // CHAPTER NAME CLEANER
  // ============================================================

  String _cleanChapterName(
    String value,
  ) {
    var result = value.trim();

    result = result.replaceFirst(
      RegExp(
        r'^(chapter\s*)',
        caseSensitive: false,
      ),
      '',
    );

    result = result.replaceFirst(
      RegExp(
        r'^(?:\d+\s*[\.\):\-]\s*)',
        caseSensitive: false,
      ),
      '',
    );

    result = result.replaceFirst(
      RegExp(
        r'^(?:[-*]\s*)',
        caseSensitive: false,
      ),
      '',
    );

    result = result
        .replaceAll(
          RegExp(
            r'\b(please|now|today)\b',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        )
        .trim();

    return result;
  }

  // ============================================================
  // CAPITALIZE
  // ============================================================

  String _capitalizeFirst(
    String value,
  ) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() +
        value.substring(1);
  }

  // ============================================================
  // FRIENDLY DATE
  // ============================================================

  String _friendlyDate(
    DateTime date,
  ) {
    final now =
        DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final target = DateTime(
      date.year,
      date.month,
      date.day,
    );

    if (target == today) {
      return 'Today';
    }

    if (target ==
        today.add(
          const Duration(days: 1),
        )) {
      return 'Tomorrow';
    }

    return '${date.day}/${date.month}/${date.year}';
  }
}

// ============================================================
// CHAPTER INFO
// ============================================================

class _ChapterInfo {
  final Subject subject;
  final ChapterModel chapter;

  const _ChapterInfo({
    required this.subject,
    required this.chapter,
  });
}