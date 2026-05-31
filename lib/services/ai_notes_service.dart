import 'ai_router_service.dart';

class AiNotesService {
  final AiRouterService aiRouter;

  AiNotesService(this.aiRouter);

  Future<String> generateNotes(String text) async {
    final prompt = """
請為以下段落生成簡短註解（包含解釋、背景與例子）：
$text
""";

    return await aiRouter.localLlm(prompt);
  }
}


