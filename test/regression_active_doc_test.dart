import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/models/app_settings.dart';
import 'package:local_ai_chat/services/embedding_service.dart';
import 'package:local_ai_chat/services/rag_service.dart';
import 'package:local_ai_chat/services/vector_store.dart';

void main() {
  group('activeDoc safety regression', () {
    test('missing activeDoc returns empty hits and empty diagnostics',
        () async {
      final store = VectorStore()
        ..add(_chunk('Existing document content.', index: 0));

      final embedder = _CountingEmbeddingService();
      final service = RagService(embedder: embedder, store: store);

      final hits = await service.retrieve(
        'document content',
        docName: 'missing.pdf',
        mode: RetrievalMode.hybrid,
      );

      expect(hits, isEmpty);
      expect(embedder.embedCalls, 0);
      expect(service.lastDiagnostics, isNotNull);
      expect(service.lastDiagnostics!.semanticHits, isEmpty);
      expect(service.lastDiagnostics!.keywordHits, isEmpty);
      expect(service.lastDiagnostics!.fusedHits, isEmpty);
    });

    test('docNames reflects removed documents', () {
      final store = VectorStore()
        ..add(_chunk('Doc A content.', index: 0, docName: 'a.pdf'))
        ..add(_chunk('Doc B content.', index: 0, docName: 'b.pdf'));

      expect(store.docNames, containsAll(['a.pdf', 'b.pdf']));

      store.removeDoc('a.pdf');

      expect(store.docNames, isNot(contains('a.pdf')));
      expect(store.docNames, contains('b.pdf'));
    });
  });
}

DocChunk _chunk(
  String text, {
  required int index,
  String docName = 'doc.pdf',
}) {
  return DocChunk(
    id: '${docName}_$index',
    docName: docName,
    chunkIndex: index,
    text: text,
    embedding: const [1, 0, 0],
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


