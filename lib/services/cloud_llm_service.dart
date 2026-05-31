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

  /// 透過雲端精煉分類標籤，並強制格式化輸出為與本地相同的 JSON 結構
  Future<String> refineClassification(String localSummary) async {
    final systemPrompt = 'You are a book classification assistant. Refine the classification for the given book summary. '
        'You must determine a single category (string) and 3 to 5 tags (list of strings). '
        'Your response must be a JSON object with keys "category" and "tags". '
        'Do not write any explanation, intro, or markdown code blocks. Just return the raw JSON object. '
        'Example: {"category": "technical", "tags": ["flutter", "dart", "mobile-dev"]}';

    return generateContent(
      systemPrompt: systemPrompt,
      userPrompt: localSummary,
    );
  }

  /// 深度解說（Cloud AI RAG）
  Future<String> queryCloudRAG(String prompt, List<String> context) async {
    return generateContent(
      systemPrompt: '你現在是一個圖書深度解說助理，請根據提供的書籍內容片段進行教學式的深入解說。若片段內無資訊，請明確告知。',
      userPrompt: prompt,
    );
  }
}


