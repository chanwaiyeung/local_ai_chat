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

import '../eval/rag_eval_runner.dart';

void main() {
  final runIntegration =
      Platform.environment['RUN_RAG_EVAL_INTEGRATION'] == '1';

  test(
    'v2.0 persisted BM25 auto evaluation baseline',
    () async {
      final appSupportDir = Platform.environment['RAG_EVAL_APP_SUPPORT_DIR'];
      if (appSupportDir != null && appSupportDir.isNotEmpty) {
        PathProviderPlatform.instance =
            _FakePathProviderPlatform(appSupportDir);
      }

      final store = VectorStore();
      await store.load(sparseIndexBuilder: RagService.buildSparseIndex);

      expect(store.length, greaterThan(0));
      expect(
        store.sparseIndex,
        isNotNull,
        reason: 'Should use or migrate to a persisted sparse index.',
      );

      final rag = RagService(
        embedder: EmbeddingService(model: 'bge-m3'),
        store: store,
      );

      final runner = RagEvalRunner(
        rag: rag,
        embeddingModel: 'bge-m3',
        retrievalMode: RetrievalMode.hybrid,
        topK: 4,
      );

      final outputPath = Platform.environment['RAG_EVAL_OUTPUT'] ??
          'docs/eval_snapshots/eval_v2_persisted_bm25_2026-04-28.json';
      final payload = await runner.run(
        version: 'v2.0-persisted-bm25-phase1',
        outputPath: outputPath,
        baselineSnapshot:
            'docs/eval_snapshots/eval_baseline_v1.10_bgem3_hybrid_2026-04-28.json',
        extraMetadata: const {
          'documents': [
            'README.txt',
            'DOSBox 0.74 Manual.txt',
          ],
          'comparisonTarget': 'v1.10.4',
        },
      );

      final summary = payload['summary'] as Map<String, Object?>;
      expect(summary['total'], 13);
      expect(summary['fail'], 0);
      expect(
          (summary['passRate'] as num).toDouble(), greaterThanOrEqualTo(0.962));
    },
    skip: runIntegration
        ? false
        : 'Set RUN_RAG_EVAL_INTEGRATION=1 to run against local Ollama/store.',
  );
}

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProviderPlatform(this.path);

  final String path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}
