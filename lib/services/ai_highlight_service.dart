import 'ai_router_service.dart';

class AiHighlightService {
  final AiRouterService aiRouter;

  AiHighlightService(this.aiRouter);

  /// 分析段落，抓出最重要、包含關鍵概念或主題句的句子。
  Future<List<String>> getHighlights(String paragraph) async {
    try {
      final prompt = '''
你是一位專業的閱讀助理。請分析以下段落，抓出最重要、包含關鍵概念、作者論點或主題句的句子。
請嚴格以 JSON 格式回傳，不要包含任何額外的說明文字。格式如下：
{
  "highlights": ["抓出的重要句子 1", "抓出的重要句子 2"]
}

段落內容：
$paragraph
''';

      final result = await aiRouter.localLlmJson(prompt);
      final highlights = result['highlights'];
      if (highlights is List) {
        return highlights.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      // 發生錯誤時，回傳空清單，不中斷使用者閱讀體驗
      return [];
    }
  }
}


