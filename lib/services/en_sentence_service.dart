import 'ai_router_service.dart';

class EnSentenceService {
  final AiRouterService aiRouter;

  EnSentenceService(this.aiRouter);

  /// 生成英文單字或句型的多難度例句，並回傳結構化 JSON 資料。
  Future<Map<String, dynamic>> makeSentences(String wordOrPattern) async {
    final prompt = """
You are an expert English tutor.
Using the following word or grammar pattern, generate examples of different difficulty levels.
Respond strictly in JSON format with this structure, using Traditional Chinese (Cantonese phrasing preferred) for translations:
{
  "beginner": {"en": "初級例句", "zh": "中文翻譯"},
  "intermediate": {"en": "中級例句", "zh": "中文翻譯"},
  "advanced": {"en": "進階例句", "zh": "中文翻譯"},
  "slang_or_spoken": {"en": "口語用法例句", "zh": "中文翻譯"}
}
Respond ONLY with valid JSON. Do not include markdown code blocks.

Target: "$wordOrPattern"
""";

    return await aiRouter.localLlmJson(prompt);
  }

  /// 針對單字或句型設計 3 題四選一測驗，並回傳結構化 JSON 資料。
  Future<Map<String, dynamic>> makeQuiz(String wordOrPattern) async {
    final prompt = """
You are an expert English tutor designing a quiz.
Create 3 multiple-choice questions based on the following word or grammar pattern.
Respond strictly in JSON format with this structure, using Traditional Chinese (Cantonese phrasing preferred) for explanations:
{
  "questions": [
    {
      "question": "題目（留空部分可用 ___ 表示）",
      "options": ["選項A", "選項B", "選項C", "選項D"],
      "correct_answer_index": 0,
      "explanation": "中文解析為什麼選這個答案"
    }
  ]
}
Respond ONLY with valid JSON. Do not include markdown code blocks.

Target: "$wordOrPattern"
""";

    return await aiRouter.localLlmJson(prompt);
  }
}


