import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/services/ai_highlight_service.dart';
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

  @override
  Future<String> generate(String prompt, {String? systemPrompt, String? format = 'json', Map<String, dynamic>? options}) async {
    lastPrompt = prompt;
    return responseText;
  }
}

class _FakeCloudLLMService extends Fake implements CloudLLMService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiHighlightService Tests', () {
    late Directory tempDir;
    late _FakeOllamaService ollama;
    late _FakeCloudLLMService cloud;
    late RagService rag;
    late VectorStore store;
    late AiRouterService router;
    late AiHighlightService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('ai_highlight_');
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
      service = AiHighlightService(router);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('AiHighlightService getHighlights calls localLlmJson and returns list of highlights', () async {
      ollama.responseText = '''
```json
{
  "highlights": ["Flutter is awesome.", "We love Dart."]
}
```
''';

      final result = await service.getHighlights('Flutter is awesome. We love Dart. Both are great.');

      expect(result, equals(['Flutter is awesome.', 'We love Dart.']));
      expect(ollama.lastPrompt, contains('你是一位專業的閱讀助理。'));
      expect(ollama.lastPrompt, contains('Flutter is awesome. We love Dart. Both are great.'));
    });

    test('AiHighlightService getHighlights returns empty list on invalid JSON response', () async {
      ollama.responseText = 'invalid text';

      final result = await service.getHighlights('Some text.');

      expect(result, isEmpty);
    });
  });
}


