import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/services/embedding_service.dart';
import 'package:local_ai_chat/services/rag_service.dart';
import 'package:local_ai_chat/services/vector_store.dart';

void main() {
  ScoredChunk scored(String text, {int index = 0, double score = 0.9}) {
    return ScoredChunk(
      DocChunk(
        id: 'doc_$index',
        docName: 'doc.pdf',
        chunkIndex: index,
        text: text,
        embedding: const [1, 0, 0],
      ),
      score,
    );
  }

  test('keyword extraction supports CJK bigrams and trigrams', () {
    final terms = RagService.keywords('請問文件有沒有安全限制？');

    expect(terms, contains('安全'));
    expect(terms, contains('限制'));
    expect(terms, contains('安全限'));
  });

  test('grounding accepts Chinese substring-style matches', () {
    final hits = [
      scored('本文件說明安全限制：只可在本地端使用。'),
    ];

    expect(
      RagService.hasKeywordGrounding('有沒有安全方面的限制？', hits),
      isTrue,
    );
  });

  test('grounding accepts synonym rewrites', () {
    final hits = [
      scored('The deadline is May 15 2026.'),
    ];

    expect(
      RagService.hasKeywordGrounding('What is the due date?', hits),
      isTrue,
    );
  });

  test('bm25 ranks exact keyword matches', () {
    final chunks = [
      _chunk('General introduction only.', index: 0),
      _chunk('The refund policy allows a 14 day return window.', index: 1),
      _chunk('Build instructions and setup.', index: 2),
    ];

    final hits = RagService.bm25Rank('refund policy', chunks, k: 2);

    expect(hits, isNotEmpty);
    expect(hits.first.chunk.chunkIndex, 1);
    expect(hits.first.score, greaterThan(0));
  });

  test('bm25 expands query terms without expanding document terms', () {
    final chunks = [
      _chunk('The risk is noted once.', index: 0),
      _chunk('The risk danger issue problem limitation are all listed.',
          index: 1),
    ];

    final ranked = RagService.bm25Rank(
      'danger issue problem limitation',
      chunks,
      k: 2,
    );

    expect(ranked.first.chunk.chunkIndex, 1);
    expect(ranked.first.score, greaterThan(ranked.last.score));
  });

  test('rrf fusion can recover keyword hit missed by semantic top result',
      () async {
    final store = VectorStore()
      ..add(_chunk('Semantic-looking but irrelevant setup text.', index: 0))
      ..add(_chunk('The customer refund policy is described here.', index: 1));

    final service = RagService(
      embedder: _FakeEmbeddingService(),
      store: store,
    );

    final hits = await service.retrieve('refund policy', k: 1);

    expect(hits, hasLength(1));
    expect(hits.first.chunk.chunkIndex, 1);
    expect(service.lastDiagnostics, isNotNull);
    expect(service.lastDiagnostics!.keywordHits.first.chunk.chunkIndex, 1);
  });

  test('ingest stops before writing chunks when cancelled', () async {
    final store = _InMemoryVectorStore();
    final service = RagService(
      embedder: _FakeEmbeddingService(),
      store: store,
    );

    final count = await service.ingest(
      docName: 'doc.pdf',
      text: 'First paragraph. Second paragraph.',
      cancelCheck: () => true,
    );

    expect(count, 0);
    expect(store.length, 0);
  });

  test('ingest preserves existing document when replacement is cancelled',
      () async {
    final store = _InMemoryVectorStore()
      ..add(_chunk('Existing content.', index: 0));
    final service = RagService(
      embedder: _FakeEmbeddingService(),
      store: store,
    );

    final count = await service.ingest(
      docName: 'doc.pdf',
      text: 'New first paragraph. New second paragraph.',
      cancelCheck: () =>
          service.embedder is _FakeEmbeddingService &&
          (service.embedder as _FakeEmbeddingService).embedCalls >= 1,
    );

    expect(count, 0);
    expect(store.length, 1);
    expect(store.chunks.first.text, 'Existing content.');
  });

  test('grounding rejects absent facts', () {
    final hits = [
      scored('The owner is Albert Chan.', index: 2),
      scored('The mitigation is to restart Ollama and retry.', index: 4),
    ];

    expect(
      RagService.hasKeywordGrounding('What color is the elephant?', hits),
      isFalse,
    );
  });

  group('evaluation checklist grounding cases', () {
    final hits = [
      scored('Chunk zero: The project codename is Blue Lantern.', index: 0),
      scored('Chunk one: The deadline is May 15 2026.', index: 1),
      scored('Chunk two: The owner is Albert Chan.', index: 2),
      scored('Chunk three: The risk is Ollama server downtime.', index: 3),
      scored(
        'Chunk four: The mitigation is to restart Ollama and retry.',
        index: 4,
      ),
      scored('本文件說明安全限制：只可在本地端使用。', index: 5),
    ];

    final presentCases = {
      'What is the risk in the document?': true,
      'What is the mitigation in the document?': true,
      'Who owns the project?': true,
      'What is the project codename?': true,
      'What is the deadline or due date?': true,
    };

    final absentCases = {
      'What is the budget in the document?': false,
      'What color is the elephant in the document?': false,
      'Does the PDF mention a customer refund policy?': false,
    };

    final rewriteCases = {
      'What is the due date?': true,
      'Who is responsible for the project?': true,
      '有沒有安全方面的限制？': true,
    };

    final followUpCases = {
      'What about the mitigation?': true,
      'What is its deadline?': true,
    };

    for (final entry in {
      ...presentCases,
      ...absentCases,
      ...rewriteCases,
      ...followUpCases,
    }.entries) {
      test(entry.key, () {
        expect(
          RagService.hasKeywordGrounding(entry.key, hits),
          entry.value,
        );
      });
    }
  });
}

DocChunk _chunk(String text, {required int index}) {
  return DocChunk(
    id: 'doc_$index',
    docName: 'doc.pdf',
    chunkIndex: index,
    text: text,
    embedding: index == 0 ? const [1, 0, 0] : const [0, 1, 0],
  );
}

class _FakeEmbeddingService extends EmbeddingService {
  _FakeEmbeddingService() : super(baseUrl: 'http://unused.invalid');

  int embedCalls = 0;

  @override
  Future<List<double>> embed(String text) async {
    embedCalls++;
    return const [1, 0, 0];
  }
}

class _InMemoryVectorStore extends VectorStore {
  @override
  Future<void> save() async {}
}
