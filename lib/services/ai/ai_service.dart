import 'dart:convert';

import 'package:http/http.dart' as http;

class AiService {
  AiService({
    String? baseUrl,
  }) : baseUrl = baseUrl ?? 'http://localhost:3000';

  final String baseUrl;

  Future<String> chat({
    required String message,
    required Map<String, dynamic> user,
    required List<Map<String, dynamic>> syllabus,
    required List<Map<String, dynamic>> tasks,
    required List<Map<String, dynamic>> studySessions,
    required List<Map<String, dynamic>> messages,
  }) async {
    final cleanMessage = message.trim();

    if (cleanMessage.isEmpty) {
      throw Exception('Message cannot be empty.');
    }

    final uri = Uri.parse('$baseUrl/api/ai/chat');

    print('========================================');
    print('STUDYX AI FLUTTER REQUEST');
    print('URL: $uri');
    print('========================================');

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'message': cleanMessage,
              'user': user,
              'syllabus': syllabus,
              'tasks': tasks,
              'studySessions': studySessions,
              'messages': messages,
            }),
          )
          .timeout(const Duration(seconds: 60));

      print('STUDYX AI STATUS: ${response.statusCode}');
      print('STUDYX AI RESPONSE: ${response.body}');

      if (response.statusCode != 200) {
        String errorMessage =
            'AI server error: ${response.statusCode}';

        try {
          final decoded = jsonDecode(response.body);

          if (decoded is Map<String, dynamic>) {
            final serverError = decoded['error'];

            if (serverError != null &&
                serverError.toString().trim().isNotEmpty) {
              errorMessage = serverError.toString();
            }
          }
        } catch (_) {}

        throw Exception(errorMessage);
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'Invalid response from StudyX AI server.',
        );
      }

      if (decoded['success'] != true) {
        throw Exception(
          decoded['error']?.toString() ??
              'StudyX AI request failed.',
        );
      }

      final answer = decoded['answer']?.toString();

      if (answer == null || answer.trim().isEmpty) {
        throw Exception(
          'StudyX AI returned an empty response.',
        );
      }

      print('STUDYX AI SUCCESS');

      return answer.trim();
    } on http.ClientException catch (e) {
      print('STUDYX AI CLIENT ERROR: $e');

      throw Exception(
        'Connection error: ${e.message}',
      );
    } on FormatException catch (e) {
      print('STUDYX AI JSON ERROR: $e');

      throw Exception(
        'Invalid response from StudyX AI.',
      );
    } catch (e) {
      print('STUDYX AI ERROR: $e');
      rethrow;
    }
  }

  Future<bool> checkHealth() async {
    final uri = Uri.parse('$baseUrl/health');

    try {
      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      print(
        'STUDYX AI HEALTH: ${response.statusCode} ${response.body}',
      );

      if (response.statusCode != 200) {
        return false;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        return false;
      }

      return decoded['ok'] == true;
    } catch (e) {
      print('STUDYX AI HEALTH ERROR: $e');
      return false;
    }
  }
}

