// test/services/classification_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/services/classification_service.dart';
import 'package:local_ai_chat/services/cloud_llm_service.dart';
import 'package:local_ai_chat/services/ollama_service.dart';

class _FakeOllamaService extends Fake implements OllamaService {
  final String response;
  String? lastPrompt;
  bool isGenerateCalled = false;

  _FakeOllamaService({required this.response});

  @override
  Future<String> generate(String prompt, {String? systemPrompt, String? format = 'json', Map<String, dynamic>? options}) async {
    isGenerateCalled = true;
    lastPrompt = prompt;
    return response;
  }
}

class _FakeCloudLLMService extends Fake implements CloudLLMService {
  final String response;
  String? lastSummary;
  bool isRefineCalled = false;

  _FakeCloudLLMService({required this.response});

  @override
  Future<String> refineClassification(String localSummary) async {
    isRefineCalled = true;
    lastSummary = localSummary;
    return response;
  }
}

void main() {
  group('ClassificationService Tests', () {
    test('Data Sanitization removes sensitive information before sending to Ollama', () async {
      final recordingOllama = _RecordingOllamaService(
        response: '{"category": "test", "tags": ["t1"], "score": 0.9}',
      );
      final service = ClassificationService(ollamaService: recordingOllama);

      final dirtyText = 'Contact me at albert@gmail.com or call +1 555 123 4567. '
          'I spent \$125.50 at the store and 500元 on taxi.';

      await service.classifyBook(dirtyText);

      expect(recordingOllama.lastPrompt, isNotNull);
      expect(recordingOllama.lastPrompt, isNot(contains('albert@gmail.com')));
      expect(recordingOllama.lastPrompt, isNot(contains('+1 555 123 4567')));
      expect(recordingOllama.lastPrompt, isNot(contains('\$125.50')));
      expect(recordingOllama.lastPrompt, isNot(contains('500元')));
      
      expect(recordingOllama.lastPrompt, contains('[EMAIL]'));
      expect(recordingOllama.lastPrompt, contains('[PHONE]'));
      expect(recordingOllama.lastPrompt, contains('[AMOUNT]'));
    });

    test('Local-only path when score is above threshold', () async {
      final localOllama = _FakeOllamaService(
        response: '{"category": "education", "tags": ["school", "learning"], "score": 0.85}',
      );
      final cloudLLM = _FakeCloudLLMService(
        response: '{"category": "refined", "tags": ["cloud"]}',
      );

      final service = ClassificationService(
        ollamaService: localOllama,
        cloudLLMService: cloudLLM,
      );

      final result = await service.classifyBook('A book about classroom teaching.');

      expect(localOllama.isGenerateCalled, isTrue);
      expect(cloudLLM.isRefineCalled, isFalse);
      expect(result.category, 'education');
      expect(result.tags, ['school', 'learning']);
      expect(result.isRefinedByCloud, isFalse);
      expect(result.score, 0.85);
      expect(result.source, 'local');
    });

    test('Cloud escalation path when score is below threshold', () async {
      final lowScoreOllama = _FakeOllamaService(
        // Low confidence score (0.45 < 0.7)
        response: '{"category": "other", "tags": ["misc"], "score": 0.45}',
      );
      final cloudLLM = _FakeCloudLLMService(
        response: '{"category": "poetry", "tags": ["verse", "art"]}',
      );

      final service = ClassificationService(
        ollamaService: lowScoreOllama,
        cloudLLMService: cloudLLM,
      );

      final result = await service.classifyBook('A beautiful collection of sonnets.');

      expect(lowScoreOllama.isGenerateCalled, isTrue);
      expect(cloudLLM.isRefineCalled, isTrue);
      expect(cloudLLM.lastSummary, contains('sonnets'));
      expect(result.category, 'poetry');
      expect(result.tags, ['verse', 'art']);
      expect(result.isRefinedByCloud, isTrue);
      expect(result.score, 0.45);
      expect(result.source, 'cloud');
    });

    test('Graceful fallback to local values when cloud fails or is unavailable', () async {
      final lowScoreOllama = _FakeOllamaService(
        response: '{"category": "history", "tags": ["war"], "score": 0.5}',
      );
      
      // Injecting a cloud service that throws exception (simulating network failure or empty api key)
      final failingCloud = _FailingCloudLLMService();

      final service = ClassificationService(
        ollamaService: lowScoreOllama,
        cloudLLMService: failingCloud,
      );

      final result = await service.classifyBook('A history book about WWII.');

      expect(lowScoreOllama.isGenerateCalled, isTrue);
      expect(failingCloud.isRefineCalled, isTrue);
      // Fallback is local category & tags
      expect(result.category, 'history');
      expect(result.tags, ['war']);
      expect(result.isRefinedByCloud, isFalse);
      expect(result.score, 0.5);
      expect(result.source, 'local');
    });

    test('JSON extraction cleans markdown blocks and preceding/succeeding noise', () async {
      final ollama = _FakeOllamaService(
        response: 'Here is the result:\n```json\n{"category": "fiction", "tags": ["mystery"], "score": 0.88}\n```\nHope you like it!',
      );
      final service = ClassificationService(ollamaService: ollama);
      final result = await service.classifyBook('A story about Sherlock Holmes.');
      
      expect(result.category, 'fiction');
      expect(result.tags, ['mystery']);
      expect(result.score, 0.88);
      expect(result.source, 'local');
    });
  });
}

class _RecordingOllamaService extends Fake implements OllamaService {
  final String response;
  String? lastPrompt;

  _RecordingOllamaService({required this.response});

  @override
  Future<String> generate(String prompt, {String? systemPrompt, String? format = 'json', Map<String, dynamic>? options}) async {
    lastPrompt = prompt;
    return response;
  }
}

class _FailingCloudLLMService extends Fake implements CloudLLMService {
  bool isRefineCalled = false;

  @override
  Future<String> refineClassification(String localSummary) async {
    isRefineCalled = true;
    throw Exception('Simulated Gemini API error');
  }
}

void testJsonExtraction() {
  // Auxiliary function placeholder if needed, group test is added to main.
}



