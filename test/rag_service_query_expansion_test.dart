import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/models/app_settings.dart';
import 'package:local_ai_chat/services/embedding_service.dart';
import 'package:local_ai_chat/services/rag_service.dart';
import 'package:local_ai_chat/services/vector_store.dart';

void main() {
  test('hybrid retrieval uses query expansion only when explicitly enabled',
      () async {
    final store = VectorStore()
      ..add(_chunk('Semantic-looking setup text.', index: 0))
      ..add(_chunk('Open the keymapper command to edit bindings.', index: 1));
    store.setSparseIndex(RagService.buildSparseIndex(store.chunks));

    final service = RagService(
      embedder: _FakeEmbeddingService(),
      store: store,
    );

    final defaultHits = await service.retrieve(
      'keyboard mapping',
      k: 1,
      mode: RetrievalMode.hybrid,
    );
    final expandedHits = await service.retrieve(
      'keyboard mapping',
      k: 1,
      mode: RetrievalMode.hybrid,
      useQueryExpansion: true,
    );

    expect(defaultHits.first.chunk.chunkIndex, 0);
    expect(expandedHits.first.chunk.chunkIndex, 1);
  });
}

DocChunk _chunk(String text, {required int index}) {
  return DocChunk(
    id: 'doc_$index',
    docName: 'doc.txt',
    chunkIndex: index,
    text: text,
    embedding: index == 0 ? const [1, 0, 0] : const [0, 1, 0],
  );
}

class _FakeEmbeddingService extends EmbeddingService {
  _FakeEmbeddingService() : super(baseUrl: 'http://unused.invalid');

  @override
  Future<List<double>> embed(String text) async {
    return const [1, 0, 0];
  }
}


