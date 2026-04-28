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
    expect(snapshot.migratedFromLegacy, isFalse);
  });

  test('decodes legacy list snapshot', () {
    final snapshot = VectorStore.decodeSnapshot([
      _chunkJson(chunkIndex: 1),
    ]);

    expect(snapshot.embeddingModel, isNull);
    expect(snapshot.chunks, hasLength(1));
    expect(snapshot.chunks.first.chunkIndex, 1);
    expect(snapshot.migratedFromLegacy, isTrue);
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
    expect(snapshot.migratedFromLegacy, isTrue);
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

  test('decodeSnapshot skips malformed chunks without dropping valid chunks',
      () {
    final snapshot = VectorStore.decodeSnapshot({
      'schemaVersion': 2,
      'embeddingModel': 'bge-m3',
      'chunks': [
        {
          'id': 'ok_0',
          'docName': 'ok.txt',
          'chunkIndex': 0,
          'text': 'valid chunk',
          'embedding': [1, 0, 0],
        },
        {
          'id': 'bad_1',
          'docName': 'bad.txt',
          'text': 'broken chunk',
          'embedding': [1, 0, 0],
        },
      ],
    });

    expect(snapshot.embeddingModel, 'bge-m3');
    expect(snapshot.chunks, hasLength(1));
    expect(snapshot.chunks.first.docName, 'ok.txt');
  });

  test('decodeSnapshot accepts chunks.value malformed PowerShell shape', () {
    final snapshot = VectorStore.decodeSnapshot({
      'schemaVersion': 2,
      'embeddingModel': 'bge-m3',
      'chunks': {
        'value': [
          {
            'id': 'doc_0',
            'docName': 'doc.txt',
            'chunkIndex': 0,
            'text': 'hello',
            'embedding': [1, 0, 0],
          },
        ],
        'Count': 1,
      },
    });

    expect(snapshot.migratedFromLegacy, isTrue);
    expect(snapshot.embeddingModel, 'bge-m3');
    expect(snapshot.chunks, hasLength(1));
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
