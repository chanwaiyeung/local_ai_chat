import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final apiKey = 'AIzaSyByD3cMsY-5o4CnGyfxRDXyl9F4y5Dp8Bw';
  final model = 'gemini-2.5-flash';
  final topic = '如何做好長期投資組合管理';

  final prompt = '''
你是一個專業的 AI 導師。使用者想學習一個主題：「\$topic」。
請為這個主題提供一個簡明扼要的高品質回答，並且萃取出適用的「思考路徑 (Reasoning Path)」。
回覆請嚴格遵循以下 JSON 格式（不要加上任何 Markdown 標記，只要純 JSON）：
{
  "reasoningPath": "關鍵洞見...\\n適用情境...\\n解決策略...",
  "answer": "高品質回答..."
}
''';

  print('Calling Gemini...');

  try {
    final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "systemInstruction": {
          "parts": [
            {"text": '你是知識提煉助手，必須只回傳符合格式的 JSON 字串。'}
          ]
        },
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.7,
        }
      }),
    );

    if (response.statusCode != 200) {
      print('Error (${response.statusCode}): ${response.body}');
      return;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates != null && candidates.isNotEmpty) {
      final content = candidates.first['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts != null && parts.isNotEmpty) {
        final text = parts.first['text'] as String? ?? '';
        print('Success! Result:');
        print(text);
      }
    }
  } catch (e) {
    print('Exception: $e');
  }
}
