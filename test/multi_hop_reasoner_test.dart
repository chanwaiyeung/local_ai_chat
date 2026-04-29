import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/services/multi_hop_reasoner.dart';
import 'package:local_ai_chat/services/vector_store.dart';

void main() {
  const reasoner = MultiHopReasoner();

  test('detects and decomposes multi-hop questions deterministically', () {
    const query =
        'How do I release the mouse and then open the keymapper if keyboard controls are wrong?';

    expect(reasoner.isMultiHop(query), isTrue);
    expect(reasoner.decompose(query), contains('How do I release the mouse'));
  });

  test('merges and deduplicates sub-query hits', () async {
    final chunk = DocChunk(
      id: 'doc_1',
      docName: 'doc.txt',
      chunkIndex: 1,
      text: 'mouse and keyboard',
      embedding: const [1.0],
    );
    final other = DocChunk(
      id: 'doc_2',
      docName: 'doc.txt',
      chunkIndex: 2,
      text: 'cycles',
      embedding: const [0.5],
    );

    final result = await reasoner.retrieve(
      query: 'How do I release the mouse and configure keyboard mapping?',
      k: 4,
      retriever: (query, {required k}) async {
        if (query.contains('mouse')) {
          return [ScoredChunk(chunk, 0.8)];
        }
        return [ScoredChunk(chunk, 0.7), ScoredChunk(other, 0.6)];
      },
    );

    expect(result.hits.map((hit) => hit.chunk.id), containsAll(['doc_1']));
    expect(result.hits.where((hit) => hit.chunk.id == 'doc_1'), hasLength(1));
    expect(result.trace.subQueries.length, greaterThanOrEqualTo(2));
  });
}
