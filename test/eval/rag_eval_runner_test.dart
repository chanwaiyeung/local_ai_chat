import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/models/app_settings.dart';
import 'package:local_ai_chat/services/embedding_service.dart';
import 'package:local_ai_chat/services/rag_service.dart';
import 'package:local_ai_chat/services/vector_store.dart';

import 'rag_eval_cases.dart';
import 'rag_eval_runner.dart';

void main() {
  test('runner writes summary and scores relevant citations', () async {
    final tempDir = Directory.systemTemp.createTempSync('rag_eval_runner_');
    addTearDown(() => tempDir.deleteSync(recursive: true));

    final cases = [
      const RagEvalCase(
        id: 1,
        question: 'Where is the answer?',
        expectedStatus: 'exists',
        expectedDoc: 'doc.txt',
        expectedChunk: 7,
      ),
      const RagEvalCase(
        id: 2,
        question: 'What is missing?',
        expectedStatus: 'missing',
      ),
      const RagEvalCase(
        id: 3,
        question: 'First question',
        expectedStatus: 'followUp',
        expectedDoc: 'doc.txt',
        isFollowUp: true,
        followUpQuestion: 'Follow up',
      ),
    ];
    final rag = _FakeRagService({
      'Where is the answer?': [
        _hit('doc.txt', 8, score: 0.9),
      ],
      'What is missing?': const [],
      'First question': [
        _hit('doc.txt', 1, score: 0.5),
      ],
      'Follow up': [
        _hit('doc.txt', 9, score: 0.7),
      ],
    });
    final runner = RagEvalRunner(
      rag: rag,
      embeddingModel: 'bge-m3',
      retrievalMode: RetrievalMode.hybrid,
      cases: cases,
    );

    final output = '${tempDir.path}${Platform.pathSeparator}snapshot.json';
    final payload = await runner.run(
      version: 'test',
      outputPath: output,
      baselineSnapshot: 'baseline.json',
    );

    expect(File(output).existsSync(), isTrue);
    expect(rag.queries, [
      'Where is the answer?',
      'What is missing?',
      'First question',
      'Follow up',
    ]);

    final summary = payload['summary'] as Map<String, Object?>;
    expect(summary['total'], 3);
    expect(summary['pass'], 3);
    expect(summary['fail'], 0);
    expect(summary['passRate'], 1.0);

    final decoded = jsonDecode(File(output).readAsStringSync()) as Map;
    expect(decoded['baselineSnapshot'], 'baseline.json');
    expect(decoded['cases'], hasLength(3));
  });
}

ScoredChunk _hit(String docName, int chunkIndex, {required double score}) {
  return ScoredChunk(
    DocChunk(
      id: '${docName}_$chunkIndex',
      docName: docName,
      chunkIndex: chunkIndex,
      text: 'chunk $chunkIndex',
      embedding: const [1, 0, 0],
    ),
    score,
  );
}

class _FakeRagService extends RagService {
  _FakeRagService(this.responses)
      : super(embedder: _NoopEmbeddingService(), store: VectorStore());

  final Map<String, List<ScoredChunk>> responses;
  final List<String> queries = [];

  @override
  Future<List<ScoredChunk>> retrieve(
    String query, {
    int k = 4,
    String? docName,
    double minScore = 0.0,
    RetrievalMode mode = RetrievalMode.hybrid,
    RrfConfig rrfConfig = const RrfConfig(),
    bool useQueryExpansion = false,
  }) async {
    queries.add(query);
    return responses[query] ?? const [];
  }
}

class _NoopEmbeddingService extends EmbeddingService {
  _NoopEmbeddingService() : super(baseUrl: 'http://unused.invalid');
}
