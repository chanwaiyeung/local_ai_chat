import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/services/ai_router_service.dart';
import 'package:local_ai_chat/services/cloud_llm_service.dart';
import 'package:local_ai_chat/services/embedding_service.dart';
import 'package:local_ai_chat/services/en_grammar_service.dart';
import 'package:local_ai_chat/services/ollama_service.dart';
import 'package:local_ai_chat/services/rag_service.dart';
import 'package:local_ai_chat/services/vector_store.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FakePathProviderPlatform(this.tempDir);

  final Directory tempDir;

  @override
  Future<String?> getApplicationSupportPath() async => tempDir.path;

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir.path;

  @override
  Future<String?> getTemporaryPath() async => tempDir.path;
}

class _FakeOllamaService extends Fake implements OllamaService {
  String? lastPrompt;
  String reply = '';

  @override
  Future<String> generate(
    String prompt, {
    String? systemPrompt,
    String? format = 'json',
    Map<String, dynamic>? options,
  }) async {
    lastPrompt = prompt;
    return reply;
  }
}

class _FakeCloudLLMService extends Fake implements CloudLLMService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EnGrammarService Tests', () {
    late Directory tempDir;
    late _FakeOllamaService ollama;
    late _FakeCloudLLMService cloud;
    late RagService rag;
    late VectorStore store;
    late AiRouterService router;
    late EnGrammarService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('en_grammar_');
      PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir);
      ollama = _FakeOllamaService();
      cloud = _FakeCloudLLMService();
      store = VectorStore(
        storagePath: '${tempDir.path}${Platform.pathSeparator}vstore.json',
      );
      final embedder = EmbeddingService(embedFn: (text) async => List.filled(384, 0.1));
      rag = RagService(embedder: embedder, store: store);
      router = AiRouterService(
        local: ollama,
        cloud: cloud,
        rag: rag,
      );
      service = EnGrammarService(router);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('EnGrammarService analyze calls local LLM generate and returns structured JSON map', () async {
      ollama.reply = '''
```json
{
  "structure": "SVO",
  "pos_tags": "The/det quick/adj brown/adj fox/noun jumps/verb over/prep the/det lazy/adj dog/noun",
  "grammar_focus": "Present Simple Tense",
  "translation": "中文翻譯",
  "common_mistakes": "無"
}
```
''';

      final result = await service.analyze('The quick brown fox jumps over the lazy dog.');

      expect(result['structure'], 'SVO');
      expect(result['pos_tags'], contains('The/det'));
      expect(result['grammar_focus'], 'Present Simple Tense');
      expect(result['translation'], '中文翻譯');
      expect(result['common_mistakes'], '無');

      expect(ollama.lastPrompt, contains('You are an expert English grammar tutor.'));
      expect(ollama.lastPrompt, contains('The quick brown fox jumps over the lazy dog.'));
    });
  });
}


