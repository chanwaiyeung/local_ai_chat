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
    expect(snapshot.needsSparseIndexMigration, isTrue);
  });

  test('decodes schema v3 snapshot with sparse index', () {
    final snapshot = VectorStore.decodeSnapshot({
      'schemaVersion': 3,
      'embeddingModel': 'bge-m3',
      'chunks': [
        _chunkJson(chunkIndex: 0),
      ],
      'sparseIndex': {
        'docCount': 1,
        'avgDocLength': 2.0,
        'chunkLengths': {'README.txt::0': 2},
        'documentFrequency': {'demo': 1},
        'termFrequency': {
          'README.txt::0': {'demo': 1, 'chunk': 1},
        },
      },
    });

    expect(snapshot.embeddingModel, 'bge-m3');
    expect(snapshot.chunks, hasLength(1));
    expect(snapshot.sparseIndex, isNotNull);
    expect(snapshot.sparseIndex!.docCount, 1);
    expect(snapshot.sparseIndex!.termFrequency['README.txt::0']!['demo'], 1);
    expect(snapshot.needsSparseIndexMigration, isFalse);
  });

  test('decodes schema v3 without sparse index as migration candidate', () {
    final snapshot = VectorStore.decodeSnapshot({
      'schemaVersion': 3,
      'embeddingModel': 'bge-m3',
      'chunks': [
        _chunkJson(chunkIndex: 0),
      ],
    });

    expect(snapshot.sparseIndex, isNull);
    expect(snapshot.needsSparseIndexMigration, isTrue);
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

  test('clear resets sparse index', () {
    final store = VectorStore()
      ..add(DocChunk.fromJson(_chunkJson(chunkIndex: 0)))
      ..setSparseIndex(
        const SparseIndexSnapshot(
          docCount: 1,
          avgDocLength: 1,
          chunkLengths: {'README.txt::0': 1},
          documentFrequency: {'demo': 1},
          termFrequency: {
            'README.txt::0': {'demo': 1},
          },
        ),
      );

    store.clear();

    expect(store.length, 0);
    expect(store.embeddingModel, isNull);
    expect(store.sparseIndex, isNull);
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
