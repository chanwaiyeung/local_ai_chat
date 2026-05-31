import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/services/ai_router_service.dart';
import 'package:local_ai_chat/services/cloud_llm_service.dart';
import 'package:local_ai_chat/services/embedding_service.dart';
import 'package:local_ai_chat/services/en_sentence_service.dart';
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

  group('EnSentenceService Tests', () {
    late Directory tempDir;
    late _FakeOllamaService ollama;
    late _FakeCloudLLMService cloud;
    late RagService rag;
    late VectorStore store;
    late AiRouterService router;
    late EnSentenceService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('en_sentence_');
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
      service = EnSentenceService(router);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('EnSentenceService makeSentences calls local LLM generate and returns multi-difficulty sentences JSON', () async {
      ollama.reply = '''
{
  "beginner": {"en": "This is a simple sentence.", "zh": "這是一個簡單的句子。"},
  "intermediate": {"en": "This is an intermediate sentence.", "zh": "這是一個中級的句子。"},
  "advanced": {"en": "This is an advanced sentence.", "zh": "這是一個高級的句子。"},
  "slang_or_spoken": {"en": "This is a spoken sentence.", "zh": "這是一個口語句子。"}
}
''';

      final result = await service.makeSentences('evaluate');

      expect(result['beginner']['en'], 'This is a simple sentence.');
      expect(result['beginner']['zh'], '這是一個簡單的句子。');
      expect(result['intermediate']['en'], 'This is an intermediate sentence.');
      expect(result['advanced']['en'], 'This is an advanced sentence.');
      expect(result['slang_or_spoken']['en'], 'This is a spoken sentence.');

      expect(ollama.lastPrompt, contains('You are an expert English tutor.'));
      expect(ollama.lastPrompt, contains('evaluate'));
    });

    test('EnSentenceService makeQuiz calls local LLM generate and returns 3 questions quiz JSON', () async {
      ollama.reply = '''
{
  "questions": [
    {
      "question": "Question 1 ___",
      "options": ["optA", "optB", "optC", "optD"],
      "correct_answer_index": 1,
      "explanation": "Exp 1"
    },
    {
      "question": "Question 2 ___",
      "options": ["optA", "optB", "optC", "optD"],
      "correct_answer_index": 2,
      "explanation": "Exp 2"
    },
    {
      "question": "Question 3 ___",
      "options": ["optA", "optB", "optC", "optD"],
      "correct_answer_index": 3,
      "explanation": "Exp 3"
    }
  ]
}
''';

      final result = await service.makeQuiz('evaluate');

      expect(result['questions'], hasLength(3));
      expect(result['questions'][0]['question'], 'Question 1 ___');
      expect(result['questions'][0]['options'], contains('optA'));
      expect(result['questions'][0]['correct_answer_index'], 1);
      expect(result['questions'][0]['explanation'], 'Exp 1');

      expect(ollama.lastPrompt, contains('You are an expert English tutor designing a quiz.'));
      expect(ollama.lastPrompt, contains('evaluate'));
    });
  });
}


