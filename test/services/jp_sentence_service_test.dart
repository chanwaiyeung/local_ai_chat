import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/services/ai_router_service.dart';
import 'package:local_ai_chat/services/cloud_llm_service.dart';
import 'package:local_ai_chat/services/embedding_service.dart';
import 'package:local_ai_chat/services/jp_sentence_service.dart';
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

  group('JpSentenceService Tests', () {
    late Directory tempDir;
    late _FakeOllamaService ollama;
    late _FakeCloudLLMService cloud;
    late RagService rag;
    late VectorStore store;
    late AiRouterService router;
    late JpSentenceService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('jp_sentence_');
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
      service = JpSentenceService(router);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('JpSentenceService makeSentences calls local LLM generate and returns sentences text', () async {
      ollama.reply = '1. 初級句子\n  - Sentence 1\n2. 中級句子';

      final result = await service.makeSentences('練習');

      expect(result, '1. 初級句子\n  - Sentence 1\n2. 中級句子');
      expect(ollama.lastPrompt, contains('請用以下單字造句，提供：'));
      expect(ollama.lastPrompt, contains('練習'));
    });
  });
}


