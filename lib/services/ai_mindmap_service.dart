import 'ai_router_service.dart';

class AiMindMapService {
  final AiRouterService aiRouter;

  AiMindMapService(this.aiRouter);

  Future<String> generateMindMap(String chapterText) async {
    final prompt = """
請將以下章節內容轉成思維導圖（文字樹狀結構）：
$chapterText
""";

    return await aiRouter.cloudLlm(prompt);
  }
}


