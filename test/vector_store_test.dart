// test/vector_store_test.dart
//
// In-memory and on-disk tests for VectorStore. Exercises:
//   - cosine similarity ranking (most similar comes first)
//   - docName filter
//   - clear() removes only the named doc
//   - NDJSON load/save round-trip

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/services/vector_store.dart';

Chunk _c(String doc, int idx, String text) =>
    Chunk(docName: doc, chunkIndex: idx, text: text);

void main() {
  group('VectorStore in-memory', () {
    test('search ranks most-similar first', () async {
      final store = VectorStore();
      await store.add(_c('a', 0, 'horizontal'), [1.0, 0.0]);
      await store.add(_c('a', 1, 'vertical'), [0.0, 1.0]);
      await store.add(_c('a', 2, 'diagonal'), [0.7071, 0.7071]);

      // Query closer to "horizontal" axis.
      final hits = store.search([1.0, 0.0], topK: 3);
      expect(hits.map((h) => h.chunk.text),
          ['horizontal', 'diagonal', 'vertical']);
    });

    test('docNames is sorted and unique', () async {
      final store = VectorStore();
      await store.add(_c('zoo.txt', 0, 't'), [1.0]);
      await store.add(_c('apple.txt', 0, 't'), [1.0]);
      await store.add(_c('apple.txt', 1, 't'), [1.0]);
      expect(store.docNames, ['apple.txt', 'zoo.txt']);
    });

    test('docName filter restricts search', () async {
      final store = VectorStore();
      await store.add(_c('a.txt', 0, 'a-text'), [1.0, 0.0]);
      await store.add(_c('b.txt', 0, 'b-text'), [1.0, 0.0]);

      final hits = store.search([1.0, 0.0], topK: 5, docName: 'b.txt');
      expect(hits, hasLength(1));
      expect(hits.single.chunk.text, 'b-text');
    });

    test('topK caps result count', () async {
      final store = VectorStore();
      for (var i = 0; i < 10; i++) {
        await store.add(_c('a', i, 'chunk-$i'), [1.0, 0.0]);
      }
      expect(store.search([1.0, 0.0], topK: 3), hasLength(3));
    });

    test('clear() removes only the named doc', () async {
      final store = VectorStore();
      await store.add(_c('a.txt', 0, 'a'), [1.0]);
      await store.add(_c('b.txt', 0, 'b'), [1.0]);
      await store.clear('a.txt');
      expect(store.docNames, ['b.txt']);
      expect(store.totalChunks, 1);
    });

    test('mismatched dimensions throw on search', () async {
      final store = VectorStore();
      await store.add(_c('a', 0, 't'), [1.0, 0.0, 0.0]);
      expect(() => store.search([1.0, 0.0]), throwsArgumentError);
    });

    test('zero vectors yield zero score, no NaN', () async {
      final store = VectorStore();
      await store.add(_c('a', 0, 't'), [0.0, 0.0]);
      final hits = store.search([1.0, 0.0]);
      expect(hits.single.score, 0.0);
      expect(hits.single.score.isFinite, isTrue);
    });

    test('chunksOf returns chunks of one doc, ordered by chunkIndex', () async {
      final store = VectorStore();
      // Insert out of order.
      await store.add(_c('a.txt', 2, 'a-2'), [1.0]);
      await store.add(_c('b.txt', 0, 'b-0'), [1.0]);
      await store.add(_c('a.txt', 0, 'a-0'), [1.0]);
      await store.add(_c('a.txt', 1, 'a-1'), [1.0]);

      final aChunks = store.chunksOf('a.txt');
      expect(aChunks.map((c) => c.text).toList(), ['a-0', 'a-1', 'a-2']);
      expect(aChunks.every((c) => c.docName == 'a.txt'), isTrue);
    });

    test('chunksOf returns empty for unknown doc', () {
      final store = VectorStore();
      expect(store.chunksOf('does-not-exist.txt'), isEmpty);
    });
  });

  group('VectorStore MMR re-ranking', () {
    test('lambda=1.0 is identical to plain cosine top-K', () async {
      final store = VectorStore();
      await store.add(_c('a', 0, 'top'), [1.0, 0.0]);
      await store.add(_c('a', 1, 'mid'), [0.7, 0.3]);
      await store.add(_c('a', 2, 'low'), [0.0, 1.0]);

      final cosine = store.search([1.0, 0.0], topK: 3);
      final mmr = store.searchMmr([1.0, 0.0], topK: 3, lambda: 1.0);

      expect(mmr.map((h) => h.chunk.text).toList(),
          cosine.map((h) => h.chunk.text).toList());
    });

    test('lambda=0.0 picks the most diverse second chunk', () async {
      final store = VectorStore();
      // Cluster A: three near-identical vectors close to query.
      await store.add(_c('a', 0, 'A1'), [1.0, 0.0]);
      await store.add(_c('a', 1, 'A2'), [0.99, 0.01]);
      await store.add(_c('a', 2, 'A3'), [0.98, 0.02]);
      // Far from A but still retrievable.
      await store.add(_c('a', 3, 'B'), [0.0, 1.0]);

      final hits = store.searchMmr(
        [1.0, 0.0],
        topK: 2,
        lambda: 0.0, // pure diversity for the second pick
      );
      // First pick is the most relevant (A1). With lambda=0, second pick
      // maximises distance from A1 → that's B.
      expect(hits.map((h) => h.chunk.text).toList(), ['A1', 'B']);
    });

    test('lambda=0.4 with a cluster prefers the diverse outlier', () async {
      final store = VectorStore();
      // Three near-duplicates clustered around the query.
      await store.add(_c('a', 0, 'A1'), [1.0, 0.0]);
      await store.add(_c('a', 1, 'A2'), [0.99, 0.01]);
      await store.add(_c('a', 2, 'A3'), [0.98, 0.02]);
      // Slightly less relevant but very different from A.
      await store.add(_c('a', 3, 'B'), [0.5, 0.866]);

      final hits = store.searchMmr([1.0, 0.0], topK: 2, lambda: 0.4);
      // Still picks A1 first (most relevant). But with lambda=0.4 the
      // redundancy penalty against A2/A3 outweighs B's lower relevance,
      // so B wins the second slot.
      expect(hits.map((h) => h.chunk.text).toList(), ['A1', 'B']);
    });

    test('candidatePool caps the cosine prefilter', () async {
      final store = VectorStore();
      for (var i = 0; i < 50; i++) {
        await store.add(_c('a', i, 'chunk-$i'), [1.0, i / 50]);
      }
      final hits = store.searchMmr(
        [1.0, 0.0],
        topK: 5,
        candidatePool: 10, // only the top 10 by cosine survive into MMR
        lambda: 0.5,
      );
      expect(hits, hasLength(5));
    });

    test('docName filter applies to MMR', () async {
      final store = VectorStore();
      await store.add(_c('a.txt', 0, 'a-text'), [1.0, 0.0]);
      await store.add(_c('b.txt', 0, 'b-text'), [1.0, 0.0]);

      final hits = store.searchMmr(
        [1.0, 0.0],
        topK: 5,
        docName: 'b.txt',
      );
      expect(hits, hasLength(1));
      expect(hits.single.chunk.text, 'b-text');
    });

    test('lambda outside [0, 1] throws', () async {
      final store = VectorStore();
      await store.add(_c('a', 0, 't'), [1.0, 0.0]);
      expect(
        () => store.searchMmr([1.0, 0.0], lambda: 1.5),
        throwsArgumentError,
      );
      expect(
        () => store.searchMmr([1.0, 0.0], lambda: -0.1),
        throwsArgumentError,
      );
    });
  });

  group('VectorStore persistence', () {
    late Directory tempDir;
    late String indexPath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('vs-test');
      indexPath = '${tempDir.path}/index.ndjson';
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('add → load round-trip', () async {
      final s1 = VectorStore(storagePath: indexPath);
      await s1.add(_c('a.txt', 0, 'hello'), [0.5, 0.5]);
      await s1.add(_c('a.txt', 1, 'world'), [0.7, 0.3]);

      final s2 = VectorStore(storagePath: indexPath);
      await s2.load();
      expect(s2.totalChunks, 2);
      expect(s2.docNames, ['a.txt']);

      final hits = s2.search([0.5, 0.5], topK: 5);
      expect(hits.map((h) => h.chunk.text), ['hello', 'world']);
    });

    test('clear() rewrites the file', () async {
      final s1 = VectorStore(storagePath: indexPath);
      await s1.add(_c('a.txt', 0, 'a'), [1.0]);
      await s1.add(_c('b.txt', 0, 'b'), [1.0]);
      await s1.clear('a.txt');

      final s2 = VectorStore(storagePath: indexPath);
      await s2.load();
      expect(s2.docNames, ['b.txt']);
      expect(s2.totalChunks, 1);
    });

    test('load() on missing file is a no-op', () async {
      final s = VectorStore(storagePath: '${tempDir.path}/nope.ndjson');
      await s.load();
      expect(s.totalChunks, 0);
    });
  });
}


