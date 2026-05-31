// test/integration_v3_persistence_test.dart
//
// A2 integration test: Schema v3 持久化端到端驗證。
//
// 規格依據：docs/v2_schema_v3_spec.md
// 測試生命週期：ingest -> save -> reload -> retrieve
//
// 驗證重點：
//   1. save() 寫入磁碟的 JSON 必須含 schemaVersion=3 + sparseIndex (5 個 TF/IDF 欄位)
//   2. reload 透過 decodeSnapshot() 直接還原 sparseIndex，不重建（builder 不應被呼叫）
//   3. BM25 keyword 分數在 save/reload 前後 byte-equivalent
//   4. v2 (無 sparseIndex) 自動觸發 builder 並回寫為 v3
//   5. PowerShell-wrapped chunks.value 結構自動 unwrap + 升級為 v3
//
// 測試環境：用 _FakePathProviderPlatform 把 getApplicationSupportPath() 重定向
// 至 per-test 臨時目錄，避免污染使用者實際資料。

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/models/app_settings.dart';
import 'package:local_ai_chat/services/embedding_service.dart';
import 'package:local_ai_chat/services/rag_service.dart';
import 'package:local_ai_chat/services/vector_store.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('v3_persist_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Schema v3 persistence — save side', () {
    test('save() writes schemaVersion=3 + complete sparseIndex JSON to disk',
        () async {
      final store = VectorStore();
      _seed(store);
      store.setSparseIndex(RagService.buildSparseIndex(store.chunks));

      await store.save();

      final f = File(
        '${tempDir.path}${Platform.pathSeparator}local_ai_chat'
        '${Platform.pathSeparator}vector_store.json',
      );
      expect(await f.exists(), isTrue,
          reason: 'vector_store.json was not written');

      final json = jsonDecode(await f.readAsString()) as Map<String, dynamic>;

      // Top-level shape per spec §5
      expect(json['schemaVersion'], 3);
      expect(json['embeddingModel'], 'bge-m3');
      expect(json['chunks'], isA<List>());
      expect((json['chunks'] as List).length, _seedChunkCount);
      expect(json['sparseIndex'], isA<Map>());

      // sparseIndex 5 fields per spec §5
      final sparse = json['sparseIndex'] as Map<String, dynamic>;
      expect(sparse['docCount'], _seedChunkCount);
      expect(sparse['avgDocLength'], greaterThan(0));
      expect(sparse['chunkLengths'], isA<Map>());
      expect((sparse['chunkLengths'] as Map).length, _seedChunkCount);
      expect(sparse['documentFrequency'], isA<Map>());
      expect((sparse['documentFrequency'] as Map).isNotEmpty, isTrue);
      expect(sparse['termFrequency'], isA<Map>());
      expect((sparse['termFrequency'] as Map).length, _seedChunkCount);
    });
  });

  group('Schema v3 persistence — load side', () {
    test('load() restores chunks + sparseIndex without invoking builder',
        () async {
      // Pre-restart: ingest + save
      final original = VectorStore();
      _seed(original);
      original.setSparseIndex(RagService.buildSparseIndex(original.chunks));
      await original.save();
      final originalSparse = original.sparseIndex!;

      // Post-restart: fresh store, load with builder available
      final reloaded = VectorStore();
      var builderCalls = 0;
      final stopwatch = Stopwatch()..start();
      await reloaded.load(sparseIndexBuilder: (chunks) {
        builderCalls++;
        return RagService.buildSparseIndex(chunks);
      });
      stopwatch.stop();
      final loadElapsedMicros = stopwatch.elapsedMicroseconds;

      // Builder must NOT run when sparseIndex already on disk (v3 fast path)
      expect(builderCalls, 0,
          reason:
              'sparseIndexBuilder should NOT be invoked when disk has sparseIndex');

      // Chunks restored
      expect(reloaded.length, original.length);
      expect(reloaded.embeddingModel, 'bge-m3');

      // SparseIndex byte-equivalent
      final reloadedSparse = reloaded.sparseIndex!;
      expect(reloadedSparse.docCount, originalSparse.docCount);
      expect(reloadedSparse.avgDocLength,
          closeTo(originalSparse.avgDocLength, 1e-9));
      expect(reloadedSparse.chunkLengths, originalSparse.chunkLengths);
      expect(
          reloadedSparse.documentFrequency, originalSparse.documentFrequency);
      expect(reloadedSparse.termFrequency, originalSparse.termFrequency);

      // Informational only — gates correctness, not perf.
      // 在小 seed 上 (~12 chunks) IO 主導，差異不大；放大 seed 才能看出 v3 的實際效益。
      // ignore: avoid_print
      debugPrint(
          'A2-timing: cold load() with persisted sparseIndex took $loadElapsedMicrosµs');
    });
  });

  group('Schema v3 persistence — retrieval parity', () {
    test('BM25 keyword scores byte-equivalent across save/reload cycle',
        () async {
      // Pre-restart store
      final original = VectorStore();
      _seed(original);
      original.setSparseIndex(RagService.buildSparseIndex(original.chunks));
      await original.save();

      final ragOriginal = RagService(
        embedder: _DeterministicEmbedder(),
        store: original,
      );
      const query = 'BM25 lexical retrieval';
      await ragOriginal.retrieve(query, mode: RetrievalMode.sparse, k: 4);
      final preHits = ragOriginal.lastDiagnostics!.keywordHits;
      expect(preHits, isNotEmpty,
          reason:
              'sparse retrieval produced no hits; check seed data overlap with query terms');

      // Post-restart store
      final reloaded = VectorStore();
      await reloaded.load(sparseIndexBuilder: RagService.buildSparseIndex);

      final ragReloaded = RagService(
        embedder: _DeterministicEmbedder(),
        store: reloaded,
      );
      await ragReloaded.retrieve(query, mode: RetrievalMode.sparse, k: 4);
      final postHits = ragReloaded.lastDiagnostics!.keywordHits;

      expect(postHits.length, preHits.length,
          reason: 'keyword hit count drift across save/reload');
      for (var i = 0; i < preHits.length; i++) {
        expect(postHits[i].chunk.id, preHits[i].chunk.id,
            reason: 'BM25 rank order changed at position $i');
        expect(postHits[i].score, closeTo(preHits[i].score, 1e-9),
            reason:
                'BM25 score drifted at position $i (chunk ${preHits[i].chunk.id})');
      }
    });
  });

  group('Schema v3 migration matrix (subset of spec §6)', () {
    test(
        'shape #2: v2 file with chunks but no sparseIndex → builder runs once + auto-rewrite as v3',
        () async {
      final supportDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}local_ai_chat',
      );
      await supportDir.create(recursive: true);
      final f =
          File('${supportDir.path}${Platform.pathSeparator}vector_store.json');

      final v2Json = {
        'schemaVersion': 2,
        'embeddingModel': 'bge-m3',
        'chunks': [
          {
            'id': 'sample.md_0',
            'docName': 'sample.md',
            'chunkIndex': 0,
            'text': 'BM25 lexical retrieval scoring documents.',
            'embedding': [0.1, 0.2, 0.3],
          },
          {
            'id': 'sample.md_1',
            'docName': 'sample.md',
            'chunkIndex': 1,
            'text': 'Inverse document frequency smoothing formula details.',
            'embedding': [0.2, 0.3, 0.4],
          },
        ],
        // intentionally no sparseIndex
      };
      await f.writeAsString(jsonEncode(v2Json));

      final store = VectorStore();
      var builderCalls = 0;
      final stopwatch = Stopwatch()..start();
      await store.load(sparseIndexBuilder: (chunks) {
        builderCalls++;
        return RagService.buildSparseIndex(chunks);
      });
      stopwatch.stop();

      expect(builderCalls, 1,
          reason: 'builder must run once for v2 → v3 migration');
      expect(store.length, 2);
      expect(store.sparseIndex, isNotNull);

      // Disk file should now be v3 with sparseIndex
      final json2 = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      expect(json2['schemaVersion'], 3,
          reason: 'in-place upgrade should rewrite schemaVersion=3');
      expect(json2['sparseIndex'], isNotNull,
          reason: 'sparseIndex should be persisted after migration');

      // ignore: avoid_print
      debugPrint(
          'A2-timing: cold load() with rebuild from v2 took ${stopwatch.elapsedMicroseconds}µs');
    });

    test(
        'shape #3: PowerShell-wrapped {chunks: {value: [...]}} unwraps + auto-rewrite as v3',
        () async {
      final supportDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}local_ai_chat',
      );
      await supportDir.create(recursive: true);
      final f =
          File('${supportDir.path}${Platform.pathSeparator}vector_store.json');

      // Simulates Windows ConvertTo-Json artifact
      final wrapped = {
        'schemaVersion': 2,
        'embeddingModel': 'bge-m3',
        'chunks': {
          'value': [
            {
              'id': 'sample.md_0',
              'docName': 'sample.md',
              'chunkIndex': 0,
              'text': 'PowerShell wrapper recovery test.',
              'embedding': [0.1, 0.2, 0.3],
            },
          ],
        },
      };
      await f.writeAsString(jsonEncode(wrapped));

      final store = VectorStore();
      await store.load(sparseIndexBuilder: RagService.buildSparseIndex);

      expect(store.length, 1, reason: 'PowerShell wrapper not unwrapped');
      expect(store.chunks.first.id, 'sample.md_0');

      final json2 = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      expect(json2['schemaVersion'], 3);
      expect(json2['chunks'], isA<List>(),
          reason: 'rewritten chunks should be unwrapped List, not wrapped');
    });
  });
}

// ---------------------------------------------------------------------------
// Test fixtures
// ---------------------------------------------------------------------------

const int _seedChunkCount = 12;

void _seed(VectorStore store) {
  store.setEmbeddingModel('bge-m3');
  final samples = <(String, List<String>)>[
    (
      'rag_concepts.md',
      [
        'RAG combines retrieval with language generation. Dense embeddings encode semantic meaning of text passages.',
        'BM25 is a lexical retrieval algorithm using term frequency and inverse document frequency to score relevance.',
        'Hybrid retrieval fuses dense and sparse retrieval via reciprocal rank fusion across multiple retrievers.',
        'Reciprocal rank fusion combines rankings from multiple retrievers without requiring score calibration.',
      ]
    ),
    (
      'embeddings.md',
      [
        'Sentence embedding models like bge produce dense vectors capturing semantic similarity in high dimensional space.',
        'Cosine similarity measures the angle between two vectors, the standard choice for dense retrieval scoring.',
        'Multilingual embeddings allow cross-lingual retrieval across mixed-language document corpora effectively.',
        'Vector stores persist embeddings on disk to avoid recomputing embeddings from raw text on every restart.',
      ]
    ),
    (
      'bm25_details.md',
      [
        'BM25 length normalization penalizes overly long documents to prevent term frequency saturation from biasing retrieval.',
        'The k1 parameter in BM25 controls term frequency saturation; typical values range from one point two to two.',
        'The b parameter in BM25 controls length normalization aggressiveness; zero point seven five is a widely used default.',
        'Inverse document frequency in BM25 uses a smoothed logarithm formula handling terms appearing in many documents.',
      ]
    ),
  ];

  var idx = 0;
  for (final (docName, texts) in samples) {
    for (var i = 0; i < texts.length; i++) {
      store.add(DocChunk(
        id: '${docName}_$i',
        docName: docName,
        chunkIndex: i,
        text: texts[i],
        // Deterministic toy embedding (BM25 doesn't read it; only cosine path does)
        embedding: List.generate(8, (j) => ((idx * 7 + j * 3) % 17) / 17.0),
      ));
      idx++;
    }
  }
}

/// 確定性 embedder：相同 input 永遠產出相同 vector，無網路。
/// 對 BM25 路徑無影響（BM25 只看 chunk.text）；只用於 dense/hybrid path 的穩定性。
class _DeterministicEmbedder extends EmbeddingService {
  _DeterministicEmbedder() : super(baseUrl: 'http://unused.invalid');

  @override
  Future<List<double>> embed(String text) async {
    final hash =
        text.codeUnits.fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff);
    return List.generate(8, (j) => ((hash + j * 13) % 19) / 19.0);
  }

  @override
  Future<List<List<double>>> embedAll(
    List<String> texts, {
    void Function(int done, int total)? onProgress,
  }) async {
    onProgress?.call(texts.length, texts.length);
    return [for (final t in texts) await embed(t)];
  }
}

/// 把 path_provider 重定向到測試 temp dir。模式來自既有的 test/integration/*。
class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProviderPlatform(this.appSupportPath);
  final String appSupportPath;

  @override
  Future<String?> getApplicationSupportPath() async => appSupportPath;
}


