import 'ai_router_service.dart';

class JpGrammarService {
  final AiRouterService aiRouter;

  JpGrammarService(this.aiRouter);

  Future<String> analyze(String sentence) async {
    final prompt = """
請解析以下日文句子，格式如下：
1. 文法結構
2. 詞性分解
3. 中文意思
4. 常見錯誤
5. 類似句型

句子：$sentence
""";

    return await aiRouter.localLlm(prompt);
  }
}


