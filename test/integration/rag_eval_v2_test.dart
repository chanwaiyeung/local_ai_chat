@Tags(['integration'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/models/app_settings.dart';
import 'package:local_ai_chat/services/embedding_service.dart';
import 'package:local_ai_chat/services/rag_service.dart';
import 'package:local_ai_chat/services/vector_store.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../eval/rag_eval_cases_v2.dart';
import '../eval/rag_eval_runner.dart';

void main() {
  final runIntegration =
      Platform.environment['RUN_RAG_EVAL_V2_INTEGRATION'] == '1';

  test(
    'generates v2 evaluation dataset baseline without changing v1 gate',
    () async {
      final appSupportDir = Platform.environment['RAG_EVAL_APP_SUPPORT_DIR'];
      if (appSupportDir != null && appSupportDir.isNotEmpty) {
        PathProviderPlatform.instance =
            _FakePathProviderPlatform(appSupportDir);
      }

      final store = VectorStore();
      await store.load(sparseIndexBuilder: RagService.buildSparseIndex);
      expect(store.length, greaterThan(0));

      final rag = RagService(
        embedder: EmbeddingService(model: 'bge-m3'),
        store: store,
      );

      final v1Payload = await RagEvalRunner(
        rag: rag,
        embeddingModel: 'bge-m3',
        retrievalMode: RetrievalMode.hybrid,
        dataset: 'v1',
        topK: 4,
      ).run(
        version: 'v2.0-phase3c-v1-gate',
        outputPath: 'build/eval_snapshots/eval_v1_gate_phase3c.json',
        baselineSnapshot:
            'docs/eval_snapshots/eval_v2_persisted_bm25_auto_2026-04-28.json',
      );
      final v1Summary = v1Payload['summary'] as Map<String, Object?>;
      expect(v1Summary['total'], 13);
      expect(v1Summary['pass'], 12);
      expect(v1Summary['partial'], 1);
      expect(v1Summary['fail'], 0);
      expect((v1Summary['passRate'] as num).toDouble(), 0.962);

      final outputPath = Platform.environment['RAG_EVAL_V2_OUTPUT'] ??
          'docs/eval_snapshots/eval_dataset_v2_baseline_2026-04-28.json';
      final v2Payload = await RagEvalRunner(
        rag: rag,
        embeddingModel: 'bge-m3',
        retrievalMode: RetrievalMode.hybrid,
        dataset: 'v2',
        cases: ragEvalCasesV2,
        topK: 4,
      ).run(
        version: 'v2.0-phase3c-eval-dataset-v2',
        outputPath: outputPath,
        baselineSnapshot:
            'docs/eval_snapshots/eval_v2_persisted_bm25_auto_2026-04-28.json',
        extraMetadata: const {
          'productionDefaultChanged': false,
          'purpose': 'analysis_only_dataset_expansion',
        },
      );

      final v2Summary = v2Payload['summary'] as Map<String, Object?>;
      final categoryCounts =
          v2Payload['categoryCounts'] as Map<String, Object?>;

      expect(v2Summary['total'], ragEvalCasesV2.length);
      expect(ragEvalCasesV2.length, 45);
      expect(categoryCounts, containsPair('Fact Retrieval', 10));
      expect(categoryCounts, containsPair('Missing', 5));
      expect(categoryCounts, containsPair('Synonym', 5));
      expect(categoryCounts, containsPair('Multi-hop', 8));
      expect(categoryCounts, containsPair('Ambiguous', 5));
      expect(categoryCounts, containsPair('Long Context', 5));
      expect(categoryCounts, containsPair('Cross-document', 7));
      expect(File(outputPath).existsSync(), isTrue);

      final phase4aOutputPath = Platform
              .environment['RAG_EVAL_PHASE4A_OUTPUT'] ??
          'docs/eval_snapshots/eval_phase4a_ambiguous_handling_2026-04-28.json';
      final phase4aPayload = await RagEvalRunner(
        rag: rag,
        embeddingModel: 'bge-m3',
        retrievalMode: RetrievalMode.hybrid,
        dataset: 'v2-phase4a',
        cases: ragEvalCasesV2,
        topK: 4,
        detectAmbiguous: true,
      ).run(
        version: 'v2.0-phase4a-ambiguous-handling',
        outputPath: phase4aOutputPath,
        baselineSnapshot: outputPath,
        extraMetadata: const {
          'productionDefaultChanged': false,
          'purpose': 'experimental_ambiguous_query_handling',
        },
      );

      final phase4aSummary = phase4aPayload['summary'] as Map<String, Object?>;
      final phase4aCategorySummary =
          phase4aPayload['categorySummary'] as Map<String, Object?>;
      final ambiguousSummary =
          phase4aCategorySummary['Ambiguous'] as Map<String, Object?>;

      expect(
        (phase4aSummary['passRate'] as num).toDouble(),
        greaterThan(0.889),
      );
      expect(
        (ambiguousSummary['passRate'] as num).toDouble(),
        greaterThan(0.5),
      );
      expect(
        phase4aSummary['fail'] as int,
        lessThanOrEqualTo(v2Summary['fail'] as int),
      );
      expect(File(phase4aOutputPath).existsSync(), isTrue);
    },
    skip: runIntegration
        ? false
        : 'Set RUN_RAG_EVAL_V2_INTEGRATION=1 to run against local Ollama/store.',
    timeout: const Timeout(Duration(minutes: 20)),
  );
}

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProviderPlatform(this.path);

  final String path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}
