import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudLLMService {
  final String apiKey;
  final String model;

  CloudLLMService({
    required this.apiKey,
    this.model = 'gemini-2.5-flash',
  });

  /// 呼叫 Gemini 產生內容
  Future<String> generateContent({
    required String systemPrompt,
    required String userPrompt,
    String? mediaBase64,
    String? mediaMimeType,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('API Key is missing');
    }

    final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');

      final parts = <Map<String, dynamic>>[
        {"text": userPrompt}
      ];

      if (mediaBase64 != null && mediaBase64.isNotEmpty) {
        parts.add({
          "inlineData": {
            "mimeType": mediaMimeType ?? "image/jpeg",
            "data": mediaBase64,
          }
        });
      }

      final body = jsonEncode({
        "systemInstruction": {
          "parts": [
            {"text": systemPrompt}
          ]
        },
        "contents": [
          {
            "parts": parts
          }
        ],
        "generationConfig": {
          "temperature": 0.7,
        }
      });

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

    if (response.statusCode != 200) {
      throw Exception('Gemini API Error (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates != null && candidates.isNotEmpty) {
      final content = candidates.first['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts != null && parts.isNotEmpty) {
        return parts.first['text'] as String? ?? '';
      }
    }

    return '';
  }
}
