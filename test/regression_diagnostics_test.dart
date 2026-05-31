import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/models/app_settings.dart';
import 'package:local_ai_chat/services/embedding_service.dart';
import 'package:local_ai_chat/services/rag_service.dart';
import 'package:local_ai_chat/services/vector_store.dart';

void main() {
  group('diagnostics regression', () {
    test('empty store clears stale diagnostics', () async {
      final service = RagService(
        embedder: _CountingEmbeddingService(),
        store: VectorStore(),
      );

      service.lastDiagnostics = RagSearchDiagnostics(
        semanticHits: [_scored('old semantic')],
        keywordHits: [_scored('old keyword')],
        fusedHits: [_scored('old fused')],
      );

      final hits = await service.retrieve('anything');

      expect(hits, isEmpty);
      expect(service.lastDiagnostics, isNotNull);
      expect(service.lastDiagnostics!.semanticHits, isEmpty);
      expect(service.lastDiagnostics!.keywordHits, isEmpty);
      expect(service.lastDiagnostics!.fusedHits, isEmpty);
    });

    test('successful retrieve replaces stale diagnostics', () async {
      final store = VectorStore()
        ..add(_chunk('Semantic-looking but irrelevant text.', index: 0))
        ..add(_chunk('Refund policy content appears here.', index: 1));
      final service = RagService(
        embedder: _CountingEmbeddingService(),
        store: store,
      );

      service.lastDiagnostics = RagSearchDiagnostics(
        semanticHits: [_scored('old semantic')],
        keywordHits: [_scored('old keyword')],
        fusedHits: [_scored('old fused')],
      );

      final hits = await service.retrieve(
        'refund policy',
        k: 1,
        mode: RetrievalMode.hybrid,
      );

      expect(hits, hasLength(1));
      expect(service.lastDiagnostics, isNotNull);
      expect(
        service.lastDiagnostics!.fusedHits.map((hit) => hit.chunk.text),
        isNot(contains('old fused')),
      );
      expect(service.lastDiagnostics!.fusedHits, isNotEmpty);
    });

    test('sparse mode does not call embedding', () async {
      final embedder = _CountingEmbeddingService();
      final service = RagService(
        embedder: embedder,
        store: VectorStore()
          ..add(_chunk('Refund policy content appears here.', index: 0)),
      );

      final hits = await service.retrieve(
        'refund policy',
        mode: RetrievalMode.sparse,
      );

      expect(hits, isNotEmpty);
      expect(embedder.embedCalls, 0);
    });
  });
}

ScoredChunk _scored(String text, {int index = 0, double score = 0.9}) {
  return ScoredChunk(_chunk(text, index: index), score);
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

class _CountingEmbeddingService extends EmbeddingService {
  _CountingEmbeddingService() : super(baseUrl: 'http://unused.invalid');

  int embedCalls = 0;

  @override
  Future<List<double>> embed(String text) async {
    embedCalls++;
    return const [1, 0, 0];
  }
}


