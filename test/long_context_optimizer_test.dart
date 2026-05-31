import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/services/long_context_optimizer.dart';
import 'package:local_ai_chat/services/vector_store.dart';

void main() {
  const optimizer = LongContextOptimizer();

  test('detects and decomposes long context queries', () {
    const query =
        'Summarize all major configuration sections in the DOSBox manual.';

    expect(optimizer.isLongContext(query), isTrue);
    expect(optimizer.decompose(query).length, greaterThanOrEqualTo(2));
    expect(optimizer.decomposeDeep(query).length, greaterThanOrEqualTo(3));
  });

  test('merges and deduplicates long context hits', () async {
    final chunk = DocChunk(
      id: 'doc_1',
      docName: 'doc.txt',
      chunkIndex: 1,
      text: 'configuration sections',
      embedding: const [1.0],
    );
    final other = DocChunk(
      id: 'doc_2',
      docName: 'doc.txt',
      chunkIndex: 2,
      text: 'input display sound cpu',
      embedding: const [0.5],
    );

    final result = await optimizer.retrieve(
      query: 'Summarize all major configuration sections in detail.',
      k: 4,
      retriever: (query, {required k}) async {
        if (query.contains('input')) {
          return [ScoredChunk(other, 0.7), ScoredChunk(chunk, 0.6)];
        }
        return [ScoredChunk(chunk, 0.8)];
      },
    );

    expect(result.hits.where((hit) => hit.chunk.id == 'doc_1'), hasLength(1));
    expect(result.trace.subQueries.length, greaterThanOrEqualTo(2));
  });

  test('deep mode expands hierarchical subqueries', () async {
    final chunk = DocChunk(
      id: 'doc_1',
      docName: 'doc.txt',
      chunkIndex: 1,
      text: 'cpu core cycles',
      embedding: const [1.0],
    );

    final result = await optimizer.retrieve(
      query:
          'Collect the key facts about input, display, sound, and CPU configuration.',
      k: 4,
      deep: true,
      retriever: (query, {required k}) async => [ScoredChunk(chunk, 0.8)],
    );

    expect(result.trace.subQueries.length, greaterThanOrEqualTo(4));
  });
}


