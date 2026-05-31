import 'ai_router_service.dart';

class JpVocabService {
  final AiRouterService aiRouter;

  JpVocabService(this.aiRouter);

  Future<String> lookup(String word) async {
    final prompt = """
請提供以下日文單字的詳細資訊：
1. 詞性
2. 中文意思
3. 例句（附中文）
4. 同義詞
5. 反義詞
6. JLPT 等級

單字：$word
""";

    return await aiRouter.localLlm(prompt);
  }
}


