import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
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

class _FakeOllamaService extends Fake implements OllamaService {
  String? lastPrompt;
  String responseText = '';
  bool throwError = false;
  bool simulateTimeout = false;

  @override
  Future<String> generate(String prompt, {String? systemPrompt, String? format = 'json', Map<String, dynamic>? options}) async {
    lastPrompt = prompt;
    if (simulateTimeout) {
      await Future.delayed(const Duration(seconds: 15));
    }
    if (throwError) {
      throw Exception('Local Ollama unavailable');
    }
    return responseText;
  }
}

class _FakeCloudLLMService extends Fake implements CloudLLMService {
  String? lastPrompt;
  String? lastSystemPrompt;
  String replyText = 'cloud generateContent reply';

  @override
  Future<String> queryCloudRAG(String prompt, List<String> context) async {
    lastPrompt = prompt;
    return 'cloud reply';
  }

  @override
  Future<String> generateContent({
    required String systemPrompt,
    required String userPrompt,
    String? mediaBase64,
    String? mediaMimeType,
  }) async {
    lastPrompt = userPrompt;
    lastSystemPrompt = systemPrompt;
    return replyText;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiRouterService Tests', () {
    late Directory tempDir;
    late _FakeOllamaService ollama;
    late _FakeCloudLLMService cloud;
    late RagService rag;
    late VectorStore store;
    late AiRouterService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('ai_router_');
      PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir);
      ollama = _FakeOllamaService();
      cloud = _FakeCloudLLMService();
      store = VectorStore(
        storagePath: '${tempDir.path}${Platform.pathSeparator}vstore.json',
      );
      final embedder = EmbeddingService(embedFn: (text) async => List.filled(384, 0.1));
      rag = RagService(embedder: embedder, store: store);
      service = AiRouterService(
        local: ollama,
        cloud: cloud,
        rag: rag,
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('localLlm forwards prompt and returns raw response', () async {
      ollama.responseText = 'hello world';
      final result = await service.localLlm('say hello');
      expect(result, 'hello world');
      expect(ollama.lastPrompt, 'say hello');
    });

    test('localLlm falls back to Cloud LLM on local error', () async {
      ollama.throwError = true;
      cloud.replyText = 'cloud backup response';
      final result = await service.localLlm('say hello');
      expect(result, 'cloud backup response');
      expect(cloud.lastPrompt, 'say hello');
    });

    test('localLlmJson defensive parsing strips markdown and noise', () async {
      ollama.responseText = '''
Noise before JSON
```json
{
  "key": "value"
}
```
Noise after JSON
''';
      final result = await service.localLlmJson('get json');
      expect(result, equals({'key': 'value'}));
    });

    test('localLlmJson falls back to Cloud LLM on local error and cleans JSON', () async {
      ollama.throwError = true;
      cloud.replyText = '```json{"fallback_key": "fallback_val"}```';
      final result = await service.localLlmJson('get json');
      expect(result, equals({'fallback_key': 'fallback_val'}));
      expect(cloud.lastPrompt, 'get json');
      expect(cloud.lastSystemPrompt, contains('respond strictly in valid JSON format'));
    });

    test('cloudLlm forwards prompt to queryCloudRAG', () async {
      final result = await service.cloudLlm('hello cloud');
      expect(result, 'cloud reply');
      expect(cloud.lastPrompt, 'hello cloud');
    });

    test('localRag retrieves context chunks and formats local LLM prompt', () async {
      // Ingest fake document chunk
      final docName = 'book_1';
      final chunks = [
        DocChunk(
          id: 'chunk_1',
          docName: docName,
          chunkIndex: 0,
          text: 'This is the book content.',
          embedding: List.generate(384, (i) => i.toDouble()),
        )
      ];
      await store.replaceDoc(docName, chunks);

      ollama.responseText = 'rag answer';

      final result = await service.localRag(
        question: 'What content?',
        bookId: docName,
      );

      expect(result, 'rag answer');
      expect(ollama.lastPrompt, contains('以下是參考資料：'));
      expect(ollama.lastPrompt, contains('This is the book content.'));
      expect(ollama.lastPrompt, contains('請根據以上資料回答問題：What content?'));
    });

    test('smartRoute uses local LLM for short text', () async {
      ollama.responseText = 'local response';
      final result = await service.smartRoute('prompt', 'short input');
      expect(result, 'local response');
      expect(ollama.lastPrompt, 'prompt');
    });

    test('smartRoute uses cloud LLM for long text', () async {
      cloud.replyText = 'cloud response';
      final longText = 'a' * 250;
      final result = await service.smartRoute('prompt', longText);
      expect(result, 'cloud response');
      expect(cloud.lastPrompt, 'prompt');
    });

    test('smartRoute uses cloud LLM when forceCloud is true', () async {
      cloud.replyText = 'cloud response';
      final result = await service.smartRoute('prompt', 'short', forceCloud: true);
      expect(result, 'cloud response');
      expect(cloud.lastPrompt, 'prompt');
    });

    test('smartRoute falls back to cloud LLM on local error', () async {
      ollama.throwError = true;
      cloud.replyText = 'cloud response';
      final result = await service.smartRoute('prompt', 'short');
      expect(result, 'cloud response');
      expect(cloud.lastPrompt, 'prompt');
    });

    test('smartRoute falls back to cloud LLM on local timeout', () {
      fakeAsync((async) {
        ollama.simulateTimeout = true;
        cloud.replyText = 'cloud timeout fallback';
        
        String? result;
        service.smartRoute('prompt', 'short').then((val) {
          result = val;
        });
        
        async.elapse(const Duration(seconds: 15));
        
        expect(result, 'cloud timeout fallback');
      });
    });
  });
}



