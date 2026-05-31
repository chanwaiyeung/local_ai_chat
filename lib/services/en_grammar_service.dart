import 'ai_router_service.dart';

class EnGrammarService {
  final AiRouterService aiRouter;

  EnGrammarService(this.aiRouter);

  /// 分析英文句子文法，並回傳結構化 JSON 資料。
  Future<Map<String, dynamic>> analyze(String sentence) async {
    final prompt = """
You are an expert English grammar tutor.
Analyze the following sentence and respond strictly in JSON format with the following keys, outputting the values in Traditional Chinese (Cantonese phrasing preferred):
{
  "structure": "句型結構（例如 SVO, SVC）",
  "pos_tags": "詞性標註（逐字標註）",
  "grammar_focus": "文法重點（時態、語態、子句等）",
  "translation": "中文意思",
  "common_mistakes": "常見錯誤或容易混淆的地方"
}
Respond ONLY with valid JSON. Do not include markdown code blocks.

Sentence: "$sentence"
""";

    return await aiRouter.localLlmJson(prompt);
  }
}


