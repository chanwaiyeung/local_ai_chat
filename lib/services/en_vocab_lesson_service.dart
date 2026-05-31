import 'ai_router_service.dart';

class EnVocabLessonService {
  final AiRouterService aiRouter;

  EnVocabLessonService(this.aiRouter);

  Future<Map<String, dynamic>> generateVocabSet(String topic) async {
    final prompt = """
You are an English vocabulary tutor.
Generate 10 vocabulary words related to the topic below.
Respond strictly in JSON format with this structure, using Traditional Chinese for meanings and translations:
{
  "vocabulary": [
    {
      "word": "英文單字",
      "part_of_speech": "詞性 (例如 n., v., adj.)",
      "meaning": "中文意思",
      "example": {"en": "英文例句", "zh": "中文翻譯"},
      "synonyms": ["同義詞1", "同義詞2"],
      "antonyms": ["反義詞1", "反義詞2"]
    }
  ]
}
Respond ONLY with valid JSON.
Topic: "$topic"
""";

    // 結構化單字生成，適合交給 localLlmJson 處理
    return await aiRouter.localLlmJson(prompt);
  }
}


