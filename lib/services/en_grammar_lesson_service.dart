import 'dart:convert';
import 'ai_router_service.dart';

class EnGrammarLessonService {
  final AiRouterService aiRouter;

  EnGrammarLessonService(this.aiRouter);

  Future<Map<String, dynamic>> generateLesson(String topic) async {
    final prompt = """
You are an expert English grammar teacher.
Create a comprehensive lesson for the topic below.
Respond strictly in JSON format with this structure, using Traditional Chinese (Cantonese phrasing preferred) for explanations and translations:
{
  "explanation": "文法解說（詳細中文說明）",
  "examples": [
    {"en": "英文例句1", "zh": "中文翻譯1"}
  ],
  "common_mistakes": "常見錯誤或容易混淆的地方",
  "quiz": [
    {
      "question": "小測驗題目",
      "options": ["選項A", "選項B", "選項C", "選項D"],
      "correct_answer_index": 0,
      "explanation": "中文解析"
    }
  ],
  "tts_sentences": ["適合用來練習朗讀的英文句子1", "適合用來練習朗讀的英文句子2"]
}
Respond ONLY with valid JSON.
Topic: "$topic"
""";

    // 文法課堂需要深度推論，直接 call cloudLlm
    final raw = await aiRouter.cloudLlm(prompt);
    return _parseJson(raw);
  }

  Map<String, dynamic> _parseJson(String raw) {
    String cleaned = raw.trim();
    if (cleaned.contains('```json')) {
      cleaned = cleaned.split('```json')[1].split('```')[0].trim();
    } else if (cleaned.contains('```')) {
      cleaned = cleaned.split('```')[1].split('```')[0].trim();
    }
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start != -1 && end != -1 && end >= start) {
      cleaned = cleaned.substring(start, end + 1);
    }
    return jsonDecode(cleaned) as Map<String, dynamic>;
  }
}


