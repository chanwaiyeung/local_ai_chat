import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/services/ai_mindmap_service.dart';
import 'package:local_ai_chat/services/ai_router_service.dart';
import 'package:local_ai_chat/services/cloud_llm_service.dart';
import 'package:local_ai_chat/services/embedding_service.dart';
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

class _FakeOllamaService extends Fake implements OllamaService {}

class _FakeCloudLLMService extends Fake implements CloudLLMService {
  String? lastPrompt;
  String reply = '';

  @override
  Future<String> queryCloudRAG(String prompt, List<String> context) async {
    lastPrompt = prompt;
    return reply;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiMindMapService Tests', () {
    late Directory tempDir;
    late _FakeOllamaService ollama;
    late _FakeCloudLLMService cloud;
    late RagService rag;
    late VectorStore store;
    late AiRouterService router;
    late AiMindMapService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('ai_mindmap_');
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
      service = AiMindMapService(router);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('AiMindMapService generateMindMap calls cloudLlm and returns mind map tree text', () async {
      cloud.reply = 'Introduction\n  - Concept 1\n  - Concept 2';

      final result = await service.generateMindMap('Chapter text about concept 1 and 2.');

      expect(result, 'Introduction\n  - Concept 1\n  - Concept 2');
      expect(cloud.lastPrompt, contains('請將以下章節內容轉成思維導圖（文字樹狀結構）：'));
      expect(cloud.lastPrompt, contains('Chapter text about concept 1 and 2.'));
    });
  });
}


