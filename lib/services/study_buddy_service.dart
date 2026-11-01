import 'dart:convert';

import 'package:http/http.dart' as http;

/// Study Buddy networking layer.
///
/// To enable AI replies, configure STUDYX_AI_ENDPOINT at build/run time. The
/// endpoint must be your own server; never place a provider API key in the APK.
/// Expected request JSON: {"message": "...", "history": [{"role":"user",
/// "content":"..."}], "context": {"app":"StudyX", "exam":"NEET"}}
/// Expected response JSON: {"reply":"..."} or {"answer":"..."}. OpenAI-style
/// choices[0].message.content responses are also accepted.
class StudyBuddyService {
  StudyBuddyService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _endpoint = String.fromEnvironment(
    'STUDYX_AI_ENDPOINT',
    defaultValue: '',
  );

  bool get isAiConnected => _endpoint.trim().isNotEmpty;

  Future<String> sendMessage({
    required String message,
    required List<Map<String, String>> history,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty)
      return 'Type a question or choose one of the study prompts.';

    if (_endpoint.trim().isEmpty) {
      return _offlineReply(trimmed);
    }

    try {
      final response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': trimmed,
              'history': history,
              'context': {
                'app': 'StudyX',
                'exam': 'NEET',
                'subjects': ['Physics', 'Chemistry', 'Biology'],
                'instructions':
                    'Be a supportive study tutor. Explain clearly at Class 11/NEET level. Use steps for numericals and encourage independent learning.',
              },
            }),
          )
          .timeout(const Duration(seconds: 35));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return 'I could not reach the AI tutor (HTTP ${response.statusCode}). Check your Study Buddy server and try again.';
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final reply = decoded['reply'] ?? decoded['answer'] ?? decoded['text'];
        if (reply is String && reply.trim().isNotEmpty) return reply.trim();

        final choices = decoded['choices'];
        if (choices is List && choices.isNotEmpty && choices.first is Map) {
          final first = choices.first as Map;
          final messageData = first['message'];
          if (messageData is Map && messageData['content'] is String) {
            return (messageData['content'] as String).trim();
          }
        }
      }
      return 'The AI server replied, but I could not read its answer. Return JSON with a "reply" field.';
    } catch (_) {
      return 'I could not connect to the AI tutor. Check your internet connection and Study Buddy server, then try again.';
    }
  }

  String _offlineReply(String message) {
    final text = message.toLowerCase();

    if (text.contains('motivat') ||
        text.contains('demotiv') ||
        text.contains('lazy')) {
      return 'You do not need to feel motivated to begin. Pick one small task, set a 25-minute timer, and start. After that, take a 5-minute break. Consistency matters more than one perfect day. 💜\n\nNote: AI tutor connection is not configured yet; this is StudyX’s built-in offline response.';
    }

    if (text.contains('quiz') || text.contains('test me')) {
      return 'Quick NEET Biology warm-up 🧬\n\nQuestion: Which organelle is the main site of ATP production in most eukaryotic cells?\n\nA) Ribosome\nB) Mitochondrion\nC) Golgi apparatus\nD) Lysosome\n\nReply with A, B, C, or D. This is a sample offline question; connect an AI endpoint for interactive explanations and more questions.';
    }

    if (text.contains('plan') ||
        text.contains('timetable') ||
        text.contains('schedule')) {
      return 'Here is a simple 45-minute study block:\n\n• 5 min — recall what you already know\n• 25 min — study one small topic from NCERT/class notes\n• 10 min — solve 5–10 questions\n• 5 min — check mistakes and write one takeaway\n\nTell me the subject and chapter to tailor it. AI connection is not configured, so this is a built-in offline plan.';
    }

    if (text.contains('physics') ||
        text.contains('newton') ||
        text.contains('motion')) {
      return 'Study tip for Physics: first write the known quantities, then choose the relevant law or equation, substitute values with units, and check whether the final unit makes sense. For a specific explanation, connect your AI tutor endpoint.\n\nOffline mode is active; this message is a study hint, not a full AI-generated solution.';
    }

    if (text.contains('biology') ||
        text.contains('cell') ||
        text.contains('botany') ||
        text.contains('zoology')) {
      return 'Biology study method 🧬\n\n1. Read one short NCERT section carefully.\n2. Close the book and recall key terms.\n3. Reopen it to correct missing points.\n4. Practise MCQs and note why each wrong option is wrong.\n\nFor chapter-specific answers, connect an AI tutor endpoint. Offline mode is active.';
    }

    if (text.contains('chemistry') ||
        text.contains('chemical') ||
        text.contains('organic')) {
      return 'Chemistry study method ⚗️\n\n• Learn the meaning of each term before memorising it.\n• Keep a small formula/reaction notebook.\n• Solve examples yourself before reading the solution.\n• Revisit mistakes the next day.\n\nFor a specific concept, connect an AI tutor endpoint. Offline mode is active.';
    }

    return 'I’m your Study Buddy! I can help you build a routine and keep you motivated. Choose a quick prompt below, or ask a question about Physics, Chemistry, or Biology.\n\nTo get real AI answers and chapter-specific explanations, configure your own Study Buddy server with STUDYX_AI_ENDPOINT. The API key should stay on the server, never inside the APK.';
  }

  void dispose() => _client.close();
}
