import 'ai_router_service.dart';

class EnVocabService {
  final AiRouterService aiRouter;

  EnVocabService(this.aiRouter);

  /// 查詢英文單字資訊，並回傳結構化 JSON 資料。
  Future<Map<String, dynamic>> lookup(String word) async {
    final prompt = """
You are an expert English vocabulary tutor.
Analyze the word below and respond strictly in JSON format with the following keys. Output values in Traditional Chinese (Cantonese phrasing preferred):
{
  "word": "單字本身",
  "part_of_speech": "詞性 (例如 n., v., adj.)",
  "meaning": "中文意思",
  "collocations": ["搭配詞1", "搭配詞2"],
  "examples": [
    {"en": "英文例句1", "zh": "中文翻譯1"},
    {"en": "英文例句2", "zh": "中文翻譯2"}
  ],
  "synonyms_antonyms": "同義詞 / 反義詞",
  "cefr_level": "難度等級 (例如 A2, B1, B2)"
}
Respond ONLY with valid JSON. Do not include markdown code blocks.

Word: "$word"
""";

    return await aiRouter.localLlmJson(prompt);
  }
}


