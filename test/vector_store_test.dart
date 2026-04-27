import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/services/vector_store.dart';

void main() {
  test('decodes schema v2 snapshot with embedding model', () {
    final snapshot = VectorStore.decodeSnapshot({
      'schemaVersion': 2,
      'embeddingModel': 'bge-m3',
      'chunks': [
        _chunkJson(chunkIndex: 0),
      ],
    });

    expect(snapshot.embeddingModel, 'bge-m3');
    expect(snapshot.chunks, hasLength(1));
    expect(snapshot.chunks.first.docName, 'README.txt');
    expect(snapshot.chunks.first.chunkIndex, 0);
  });

  test('decodes legacy list snapshot', () {
    final snapshot = VectorStore.decodeSnapshot([
      _chunkJson(chunkIndex: 1),
    ]);

    expect(snapshot.embeddingModel, isNull);
    expect(snapshot.chunks, hasLength(1));
    expect(snapshot.chunks.first.chunkIndex, 1);
  });

  test('decodes accidental chunks value wrapper', () {
    final snapshot = VectorStore.decodeSnapshot({
      'schemaVersion': 2,
      'embeddingModel': 'bge-m3',
      'chunks': {
        'value': [
          _chunkJson(chunkIndex: 2),
        ],
      },
    });

    expect(snapshot.embeddingModel, 'bge-m3');
    expect(snapshot.chunks, hasLength(1));
    expect(snapshot.chunks.first.chunkIndex, 2);
  });

  test('ignores malformed chunk entries', () {
    final snapshot = VectorStore.decodeSnapshot({
      'schemaVersion': 2,
      'embeddingModel': 'bge-m3',
      'chunks': [
        'bad',
        _chunkJson(chunkIndex: 3),
      ],
    });

    expect(snapshot.chunks, hasLength(1));
    expect(snapshot.chunks.first.chunkIndex, 3);
  });
}

Map<String, dynamic> _chunkJson({required int chunkIndex}) {
  return {
    'id': 'README.txt::$chunkIndex',
    'docName': 'README.txt',
    'chunkIndex': chunkIndex,
    'text': 'Demo chunk $chunkIndex',
    'embedding': [1, 0, 0],
  };
}
