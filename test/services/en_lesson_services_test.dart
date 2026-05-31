import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/services/ai_router_service.dart';
import 'package:local_ai_chat/services/cloud_llm_service.dart';
import 'package:local_ai_chat/services/en_grammar_lesson_service.dart';
import 'package:local_ai_chat/services/en_quiz_service.dart';
import 'package:local_ai_chat/services/en_vocab_lesson_service.dart';
import 'package:local_ai_chat/services/ollama_service.dart';
import 'package:local_ai_chat/services/rag_service.dart';

class _FakeOllamaService extends Fake implements OllamaService {
  String responseText = '';

  @override
  Future<String> generate(String prompt, {String? systemPrompt, String? format = 'json', Map<String, dynamic>? options}) async {
    return responseText;
  }
}

class _FakeCloudLLMService extends Fake implements CloudLLMService {
  String replyText = '';

  @override
  Future<String> generateContent({
    required String systemPrompt,
    required String userPrompt,
    String? mediaBase64,
    String? mediaMimeType,
  }) async {
    return replyText;
  }

  @override
  Future<String> queryCloudRAG(String prompt, List<String> context) async {
    return replyText;
  }
}

class _FakeRagService extends Fake implements RagService {}

void main() {
  group('English Lesson Services Tests', () {
    late _FakeOllamaService local;
    late _FakeCloudLLMService cloud;
    late AiRouterService aiRouter;

    setUp(() {
      local = _FakeOllamaService();
      cloud = _FakeCloudLLMService();
      aiRouter = AiRouterService(
        local: local,
        cloud: cloud,
        rag: _FakeRagService(),
      );
    });

    test('EnGrammarLessonService parses lesson JSON correctly', () async {
      final service = EnGrammarLessonService(aiRouter);
      cloud.replyText = '''
```json
{
  "explanation": "Test explanation",
  "examples": [
    {"en": "Test en", "zh": "Test zh"}
  ],
  "common_mistakes": "Test mistake",
  "quiz": [
    {
      "question": "Test question",
      "options": ["A", "B", "C", "D"],
      "correct_answer_index": 1,
      "explanation": "Test explanation"
    }
  ],
  "tts_sentences": ["Sent 1", "Sent 2"]
}
```
''';

      final result = await service.generateLesson('Test Topic');

      expect(result['explanation'], 'Test explanation');
      expect(result['examples'][0]['en'], 'Test en');
      expect(result['common_mistakes'], 'Test mistake');
      expect(result['quiz'][0]['question'], 'Test question');
      expect(result['tts_sentences'], equals(['Sent 1', 'Sent 2']));
    });

    test('EnVocabLessonService parses vocabulary JSON correctly', () async {
      final service = EnVocabLessonService(aiRouter);
      local.responseText = '''
{
  "vocabulary": [
    {
      "word": "abandon",
      "part_of_speech": "v.",
      "meaning": "放棄",
      "example": {"en": "abandon ship", "zh": "棄船"},
      "synonyms": ["desert"],
      "antonyms": ["keep"]
    }
  ]
}
''';

      final result = await service.generateVocabSet('Test Topic');

      expect(result['vocabulary'][0]['word'], 'abandon');
      expect(result['vocabulary'][0]['part_of_speech'], 'v.');
      expect(result['vocabulary'][0]['meaning'], '放棄');
      expect(result['vocabulary'][0]['example']['en'], 'abandon ship');
      expect(result['vocabulary'][0]['synonyms'], equals(['desert']));
      expect(result['vocabulary'][0]['antonyms'], equals(['keep']));
    });

    test('EnQuizService parses quiz JSON correctly', () async {
      final service = EnQuizService(aiRouter);
      local.responseText = '''
{
  "questions": [
    {
      "question": "Choose the correct word: ___ the ship.",
      "options": ["abandon", "bark", "sing", "run"],
      "correct_answer_index": 0,
      "explanation": "abandon means to leave."
    }
  ]
}
''';

      final result = await service.generateQuiz('Test Topic');

      expect(result['questions'][0]['question'], 'Choose the correct word: ___ the ship.');
      expect(result['questions'][0]['options'], equals(['abandon', 'bark', 'sing', 'run']));
      expect(result['questions'][0]['correct_answer_index'], 0);
      expect(result['questions'][0]['explanation'], 'abandon means to leave.');
    });
  });
}


