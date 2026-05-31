import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/services/ai_notes_service.dart';
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

  group('AiNotesService Tests', () {
    late Directory tempDir;
    late _FakeOllamaService ollama;
    late _FakeCloudLLMService cloud;
    late RagService rag;
    late VectorStore store;
    late AiRouterService router;
    late AiNotesService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('ai_notes_');
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
      service = AiNotesService(router);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('AiNotesService generateNotes calls localLlm and returns notes text', () async {
      ollama.responseText = 'This is paragraph explanation notes.';

      final result = await service.generateNotes('This is paragraph text.');

      expect(result, 'This is paragraph explanation notes.');
      expect(ollama.lastPrompt, contains('請為以下段落生成簡短註解（包含解釋、背景與例子）：'));
      expect(ollama.lastPrompt, contains('This is paragraph text.'));
    });
  });
}


