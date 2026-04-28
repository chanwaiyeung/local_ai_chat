import 'dart:convert';
import 'dart:io';

import 'package:local_ai_chat/models/app_settings.dart';
import 'package:local_ai_chat/services/rag_service.dart';
import 'package:local_ai_chat/services/vector_store.dart';

import 'rag_eval_cases.dart';

class RagEvalResult {
  const RagEvalResult({
    required this.id,
    required this.question,
    required this.expectedStatus,
    required this.verdict,
    required this.hits,
    required this.citations,
    required this.mainCitation,
    this.expectedDoc,
    this.expectedChunk,
    this.followUpQuestion,
    this.error,
    this.notes,
  });

  final int id;
  final String question;
  final String expectedStatus;
  final String verdict;
  final int hits;
  final List<Map<String, Object?>> citations;
  final String? mainCitation;
  final String? expectedDoc;
  final int? expectedChunk;
  final String? followUpQuestion;
  final String? error;
  final String? notes;

  double get score => switch (verdict) {
        'PASS' => 1.0,
        'PARTIAL' => 0.5,
        _ => 0.0,
      };

  Map<String, Object?> toJson() => {
        'id': id,
        'question': question,
        if (followUpQuestion != null) 'followUpQuestion': followUpQuestion,
        'expectedStatus': expectedStatus,
        if (expectedDoc != null) 'expectedDoc': expectedDoc,
        if (expectedChunk != null) 'expectedChunk': expectedChunk,
        'verdict': verdict,
        'hits': hits,
        'mainCitation': mainCitation,
        'citations': citations,
        if (notes != null) 'notes': notes,
        if (error != null) 'error': error,
      };
}

class RagEvalRunner {
  const RagEvalRunner({
    required this.rag,
    required this.embeddingModel,
    required this.retrievalMode,
    this.topK = 4,
    this.cases = ragEvalCases,
  });

  final RagService rag;
  final String embeddingModel;
  final RetrievalMode retrievalMode;
  final int topK;
  final List<RagEvalCase> cases;

  Future<Map<String, Object?>> run({
    required String version,
    required String outputPath,
    String? baselineSnapshot,
    Map<String, Object?> extraMetadata = const {},
  }) async {
    final results = <RagEvalResult>[];

    for (final evalCase in cases) {
      try {
        final hits = await _retrieveForCase(evalCase);
        results.add(_scoreCase(evalCase, hits));
      } catch (error, stackTrace) {
        results.add(
          RagEvalResult(
            id: evalCase.id,
            question: evalCase.question,
            followUpQuestion:
                evalCase.isFollowUp ? evalCase.followUpQuestion : null,
            expectedStatus: evalCase.expectedStatus,
            expectedDoc: evalCase.expectedDoc,
            expectedChunk: evalCase.expectedChunk,
            verdict: 'FAIL',
            hits: 0,
            citations: const [],
            mainCitation: null,
            error: '$error',
            notes: stackTrace.toString().split('\n').take(3).join('\n'),
          ),
        );
      }
    }

    final pass = results.where((result) => result.verdict == 'PASS').length;
    final partial =
        results.where((result) => result.verdict == 'PARTIAL').length;
    final fail = results.where((result) => result.verdict == 'FAIL').length;
    final score = results.fold<double>(0, (sum, result) => sum + result.score);
    final passRate = cases.isEmpty ? 0.0 : score / cases.length;

    final payload = <String, Object?>{
      'version': version,
      'date': DateTime.now().toUtc().toIso8601String(),
      'source': 'automated_rag_eval_runner',
      'embeddingModel': embeddingModel,
      'retrievalMode': retrievalMode.name,
      'topK': topK,
      if (baselineSnapshot != null) 'baselineSnapshot': baselineSnapshot,
      ...extraMetadata,
      'summary': {
        'total': cases.length,
        'pass': pass,
        'partial': partial,
        'fail': fail,
        'score': score,
        'passRate': double.parse(passRate.toStringAsFixed(3)),
      },
      'cases': [for (final result in results) result.toJson()],
    };

    final out = File(outputPath);
    await out.parent.create(recursive: true);
    await out.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
      flush: true,
    );
    return payload;
  }

  Future<List<ScoredChunk>> _retrieveForCase(RagEvalCase evalCase) async {
    if (!evalCase.isFollowUp) {
      return rag.retrieve(
        evalCase.question,
        k: topK,
        mode: retrievalMode,
      );
    }

    await rag.retrieve(
      evalCase.question,
      k: topK,
      mode: retrievalMode,
    );
    return rag.retrieve(
      evalCase.followUpQuestion,
      k: topK,
      mode: retrievalMode,
    );
  }

  RagEvalResult _scoreCase(RagEvalCase evalCase, List<ScoredChunk> hits) {
    final citations = [
      for (final hit in hits)
        <String, Object?>{
          'docName': hit.chunk.docName,
          'chunkIndex': hit.chunk.chunkIndex,
          'score': double.parse(hit.score.toStringAsFixed(6)),
        },
    ];
    final effectiveHits = _effectiveHits(evalCase, hits);
    final mainCitation = effectiveHits.isEmpty
        ? null
        : '${effectiveHits.first.chunk.docName} #${effectiveHits.first.chunk.chunkIndex}';
    final verdict = _determineVerdict(evalCase, hits);

    return RagEvalResult(
      id: evalCase.id,
      question: evalCase.question,
      followUpQuestion: evalCase.isFollowUp ? evalCase.followUpQuestion : null,
      expectedStatus: evalCase.expectedStatus,
      expectedDoc: evalCase.expectedDoc,
      expectedChunk: evalCase.expectedChunk,
      verdict: verdict,
      hits: effectiveHits.length,
      citations: citations,
      mainCitation: mainCitation,
      notes: _notesFor(evalCase, hits, verdict),
    );
  }

  String _determineVerdict(RagEvalCase evalCase, List<ScoredChunk> hits) {
    final effectiveHits = _effectiveHits(evalCase, hits);
    if (evalCase.expectedStatus == 'missing') {
      return effectiveHits.isEmpty ? 'PASS' : 'PARTIAL';
    }

    if (effectiveHits.isEmpty) {
      return evalCase.allowPartial ? 'PARTIAL' : 'FAIL';
    }

    final expectedDoc = evalCase.expectedDoc;
    if (expectedDoc == null) return 'PASS';

    final hasRelevantDoc =
        effectiveHits.any((hit) => hit.chunk.docName == expectedDoc);
    if (!hasRelevantDoc) return evalCase.allowPartial ? 'PARTIAL' : 'FAIL';
    if (evalCase.allowPartial) return 'PARTIAL';

    return 'PASS';
  }

  List<ScoredChunk> _effectiveHits(
      RagEvalCase evalCase, List<ScoredChunk> hits) {
    if (evalCase.expectedStatus == 'missing') {
      return const [];
    }
    return hits;
  }

  String? _notesFor(
    RagEvalCase evalCase,
    List<ScoredChunk> hits,
    String verdict,
  ) {
    if (evalCase.expectedStatus == 'missing' &&
        verdict == 'PARTIAL' &&
        hits.isNotEmpty) {
      return 'Expected no supporting citation, but retrieval returned hits.';
    }
    if (evalCase.allowPartial && verdict == 'PARTIAL') {
      return 'Allowed partial result for limited source coverage.';
    }
    return null;
  }
}
