import 'ai_router_service.dart';

class EnQuizService {
  final AiRouterService aiRouter;

  EnQuizService(this.aiRouter);

  Future<Map<String, dynamic>> generateQuiz(String topic) async {
    final prompt = """
You are an English tutor designing a quiz.
Create 5 English grammar multiple-choice questions for the topic below.
Respond strictly in JSON format with this structure, using Traditional Chinese for explanations:
{
  "questions": [
    {
      "question": "題目內容（留空部分用 ___ 表示）",
      "options": ["選項A", "選項B", "選項C", "選項D"],
      "correct_answer_index": 0,
      "explanation": "為什麼選這個答案的中文解析"
    }
  ]
}
Respond ONLY with valid JSON.
Topic: "$topic"
""";

    // 測驗題生成，適合交給 localLlmJson 處理
    return await aiRouter.localLlmJson(prompt);
  }
}


