import 'ai_router_service.dart';

class JpSentenceService {
  final AiRouterService aiRouter;

  JpSentenceService(this.aiRouter);

  Future<String> makeSentences(String word) async {
    final prompt = """
請用以下單字造句，提供：
1. 初級句子
2. 中級句子
3. 高級句子
4. 敬語句子
5. 中文翻譯

單字：$word
""";

    return await aiRouter.localLlm(prompt);
  }
}


