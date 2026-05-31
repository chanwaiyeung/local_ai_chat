import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/models/book.dart';
import 'package:local_ai_chat/services/ai_router_service.dart';
import 'package:local_ai_chat/services/book_ai_service.dart';
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

  group('BookAiService Tests', () {
    late Directory tempDir;
    late _FakeOllamaService ollama;
    late _FakeCloudLLMService cloud;
    late RagService rag;
    late VectorStore store;
    late AiRouterService router;
    late BookAiService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('book_ai_');
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
      service = BookAiService(router);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('BookAiService summarizeChapter calls localLlm and returns summary', () async {
      ollama.responseText = 'fake summary';

      final result = await service.summarizeChapter('This is chapter text.');

      expect(result, 'fake summary');
      expect(ollama.lastPrompt, contains('請摘要以下內容：'));
      expect(ollama.lastPrompt, contains('This is chapter text.'));
    });

    test('BookAiService deepExplain calls cloudLlm and returns deep explanation', () async {
      cloud.reply = 'fake explanation';

      final result = await service.deepExplain('What is Flutter?', ['context 1', 'context 2']);

      expect(result, 'fake explanation');
      expect(cloud.lastPrompt, contains('問題：What is Flutter?'));
      expect(cloud.lastPrompt, contains('context 1'));
      expect(cloud.lastPrompt, contains('context 2'));
    });

    test('BookAiService generateAutoNotes calls cloudLlm and parses JSON list successfully', () async {
      cloud.reply = '''
Here is the JSON:
```json
[
  {"word": "日本語", "reading": "にほんご", "meaning": "日文", "explanation": "Language"}
]
```
Enjoy!
''';

      final result = await service.generateAutoNotes('日本語を話します。');

      expect(result, hasLength(1));
      expect(result.first['word'], '日本語');
      expect(result.first['reading'], 'にほんご');
      expect(result.first['meaning'], '日文');
      expect(result.first['explanation'], 'Language');
      expect(cloud.lastPrompt, contains('日本語を話します。'));
    });

    test('BookAiService classifyBook calls localLlmJson and returns map', () async {
      ollama.responseText = '''
```json
{
  "category": "Technology",
  "tags": ["Flutter", "Dart"]
}
```
''';
      final book = Book(
        id: 'book1',
        title: 'Learn Flutter',
        author: 'Jane Doe',
        notes: 'A great guide to mobile development.',
      );

      final result = await service.classifyBook(book);

      expect(result, equals({
        'category': 'Technology',
        'tags': ['Flutter', 'Dart'],
      }));
      expect(ollama.lastPrompt, contains('Learn Flutter'));
      expect(ollama.lastPrompt, contains('Jane Doe'));
      expect(ollama.lastPrompt, contains('A great guide to mobile development.'));
    });

    test('BookAiService askBookQuestion calls localRag and returns answer', () async {
      final book = Book(id: 'book1', title: 'Learn Flutter');
      
      // Ingest fake doc chunk
      final docChunk = DocChunk(
        id: 'chunk_1',
        docName: 'book1',
        chunkIndex: 0,
        text: 'Flutter is an open-source UI toolkit.',
        embedding: List.generate(384, (i) => i.toDouble()),
      );
      await store.replaceDoc('book1', [docChunk]);

      ollama.responseText = 'rag answer';

      final result = await service.askBookQuestion(book, 'What is Flutter?');

      expect(result, 'rag answer');
      expect(ollama.lastPrompt, contains('以下是參考資料：'));
      expect(ollama.lastPrompt, contains('Flutter is an open-source UI toolkit.'));
    });
  });
}


