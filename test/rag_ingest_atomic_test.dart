import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/services/embedding_service.dart';
import 'package:local_ai_chat/services/rag_service.dart';
import 'package:local_ai_chat/services/vector_store.dart';

void main() {
  test('ingestDetailed rollback on save failure preserves old doc', () async {
    final store = _FailingSaveVectorStore()
      ..add(_chunk('Existing content.', index: 0));
    final service = RagService(
      embedder: _FakeEmbeddingService(),
      store: store,
    );

    final result = await service.ingestDetailed(
      docName: 'doc.pdf',
      text: 'New paragraph one. New paragraph two.',
      batchSize: 1,
    );

    expect(result.success, isFalse);
    expect(result.failed, isTrue);
    expect(result.error, isA<StateError>());
    expect(store.length, 1);
    expect(store.chunks.first.text, 'Existing content.');
  });
}

DocChunk _chunk(String text, {required int index}) {
  return DocChunk(
    id: 'doc_$index',
    docName: 'doc.pdf',
    chunkIndex: index,
    text: text,
    embedding: const [0, 1, 0],
  );
}

class _FakeEmbeddingService extends EmbeddingService {
  _FakeEmbeddingService() : super(baseUrl: 'http://unused.invalid');

  @override
  Future<List<List<double>>> embedAll(
    List<String> texts, {
    void Function(int done, int total)? onProgress,
  }) async {
    return [
      for (var i = 0; i < texts.length; i++) const [1.0, 0.0, 0.0],
    ];
  }
}

class _FailingSaveVectorStore extends VectorStore {
  @override
  Future<void> save() async {
    throw StateError('commit failed');
  }
}


