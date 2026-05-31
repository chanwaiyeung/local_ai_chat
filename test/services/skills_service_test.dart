import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/services/embedding_service.dart';
import 'package:local_ai_chat/services/skills_service.dart';
import 'package:local_ai_chat/services/vector_store.dart';

class _FakeEmbeddingService extends EmbeddingService {
  _FakeEmbeddingService() : super(baseUrl: 'http://unused.invalid');

  @override
  Future<List<double>> embed(String text) async {
    if (text.contains('short')) return [1.0, 0.0, 0.0];
    if (text.contains('longer')) return [0.0, 1.0, 0.0];
    return [0.0, 0.0, 1.0];
  }

  @override
  Future<List<List<double>>> embedAll(List<String> texts, {void Function(int, int)? onProgress}) async {
    return [for (final t in texts) await embed(t)];
  }
}

void main() {
  group('SkillsService', () {
    late VectorStore store;
    late _FakeEmbeddingService embedder;
    late SkillsService skillsService;

    setUp(() {
      store = VectorStore(); // In-memory
      embedder = _FakeEmbeddingService();
      skillsService = SkillsService(store: store, embedder: embedder);
    });

    test('extractAndSaveSkill saves a skill to the store', () async {
      final card = await skillsService.extractAndSaveSkill(
        query: 'How to calculate net worth?',
        reasoningPath: 'Use the wealth module sum.',
        answer: 'You sum all assets.',
        domain: 'wealth',
      );

      expect(card.query, 'How to calculate net worth?');
      expect(card.answer, 'You sum all assets.');

      final allSkills = skillsService.getAllSkills();
      expect(allSkills.length, 1);
      expect(allSkills.first.id, card.id);
    });

    test('getRelevantSkills returns skills with matching embeddings', () async {
      await skillsService.extractAndSaveSkill(
        query: 'short',
        answer: 'short answer',
      );
      await skillsService.extractAndSaveSkill(
        query: 'a bit longer query',
        answer: 'long answer',
      );

      // We search with 'short', the fake embedder will give an identical vector
      // to the first query, making cosine similarity = 1.0
      final hits = await skillsService.getRelevantSkills('short', threshold: 0.99);
      expect(hits.length, 1);
      expect(hits.first.query, 'short');
    });

    test('incrementSuccessCount updates the count', () async {
      final card = await skillsService.extractAndSaveSkill(
        query: 'test',
        answer: 'ans',
      );

      expect(card.successCount, 1);

      await skillsService.incrementSuccessCount(card.id);

      final all = skillsService.getAllSkills();
      expect(all.length, 1);
      expect(all.first.successCount, 2);
    });

    test('deleteSkill removes the skill', () async {
      final card = await skillsService.extractAndSaveSkill(
        query: 'test',
        answer: 'ans',
      );
      
      expect(skillsService.getAllSkills().length, 1);
      await skillsService.deleteSkill(card.id);
      expect(skillsService.getAllSkills().length, 0);
    });
  });
}


