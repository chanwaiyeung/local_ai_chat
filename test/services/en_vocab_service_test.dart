import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/services/ai_router_service.dart';
import 'package:local_ai_chat/services/cloud_llm_service.dart';
import 'package:local_ai_chat/services/embedding_service.dart';
import 'package:local_ai_chat/services/en_vocab_service.dart';
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

  group('EnVocabService Tests', () {
    late Directory tempDir;
    late _FakeOllamaService ollama;
    late _FakeCloudLLMService cloud;
    late RagService rag;
    late VectorStore store;
    late AiRouterService router;
    late EnVocabService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('en_vocab_');
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
      service = EnVocabService(router);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('EnVocabService lookup calls local LLM generate and returns vocabulary details JSON', () async {
      ollama.reply = '''
{
  "word": "abandon",
  "part_of_speech": "v.",
  "meaning": "放棄，遺棄",
  "collocations": ["abandon the project", "abandon the ship"],
  "examples": [
    {"en": "They had to abandon the ship.", "zh": "他們不得不棄船。"},
    {"en": "Never abandon your dreams.", "zh": "永遠不要放棄你的夢想。"}
  ],
  "synonyms_antonyms": "同義詞: desert, leave / 反義詞: keep, retain",
  "cefr_level": "B2"
}
''';

      final result = await service.lookup('abandon');

      expect(result['word'], 'abandon');
      expect(result['part_of_speech'], 'v.');
      expect(result['meaning'], '放棄，遺棄');
      expect(result['collocations'], contains('abandon the project'));
      expect(result['examples'], hasLength(2));
      expect(result['examples'][0]['en'], 'They had to abandon the ship.');
      expect(result['examples'][0]['zh'], '他們不得不棄船。');
      expect(result['synonyms_antonyms'], contains('desert, leave'));
      expect(result['cefr_level'], 'B2');

      expect(ollama.lastPrompt, contains('Analyze the word below and respond strictly in JSON format'));
      expect(ollama.lastPrompt, contains('abandon'));
    });
  });
}


