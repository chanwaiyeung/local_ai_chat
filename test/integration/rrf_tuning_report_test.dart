@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/models/app_settings.dart';
import 'package:local_ai_chat/services/embedding_service.dart';
import 'package:local_ai_chat/services/rag_service.dart';
import 'package:local_ai_chat/services/rrf_tuner.dart';
import 'package:local_ai_chat/services/vector_store.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../eval/rag_eval_runner.dart';

void main() {
  final runIntegration =
      Platform.environment['RUN_RRF_TUNING_INTEGRATION'] == '1';

  test(
    'generates offline RRF tuning report',
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
      final tuner = const RrfTuner();
      final results = <RrfTuningResult>[];

      for (final config in tuner.generateGrid()) {
        final runner = RagEvalRunner(
          rag: rag,
          embeddingModel: 'bge-m3',
          retrievalMode: RetrievalMode.hybrid,
          topK: 4,
          rrfConfig: config,
        );
        final payload = await runner.run(
          version: 'v2.0-phase3b-rrf-tuning',
          outputPath: _tempSnapshotPath(config),
          baselineSnapshot:
              'docs/eval_snapshots/eval_v2_persisted_bm25_auto_2026-04-28.json',
          extraMetadata: const {
            'productionDefaultChanged': false,
            'experiment': 'rrf_weight_tuning',
          },
        );
        final summary = payload['summary'] as Map<String, Object?>;
        results.add(RrfTuningResult(
          config: config,
          passRate: (summary['passRate'] as num).toDouble(),
          score: (summary['score'] as num).toDouble(),
          pass: summary['pass'] as int,
          partial: summary['partial'] as int,
          fail: summary['fail'] as int,
        ));
      }

      final best = tuner.bestResult(results);
      final improvement = best.passRate - 0.962;
      final report = {
        'version': 'v2.0-phase3b-rrf-tuning',
        'date': DateTime.now().toUtc().toIso8601String(),
        'source': 'automated_rrf_tuning_grid',
        'baselinePassRate': 0.962,
        'best': best.toJson(),
        'improvementVsBaseline': double.parse(improvement.toStringAsFixed(3)),
        'recommendProductionDefaultChange': improvement >= 0.02,
        'gridSize': results.length,
        'results': [
          for (final result in results) result.toJson(),
        ],
      };

      final outputPath = Platform.environment['RRF_TUNING_OUTPUT'] ??
          'docs/eval_snapshots/rrf_tuning_report_2026-04-28.json';
      final output = File(outputPath);
      await output.parent.create(recursive: true);
      await output.writeAsString(
        const JsonEncoder.withIndent('  ').convert(report),
        flush: true,
      );

      expect(results, hasLength(36));
      expect(best.passRate, greaterThanOrEqualTo(0.962));
      expect(report['recommendProductionDefaultChange'], isFalse);
    },
    skip: runIntegration
        ? false
        : 'Set RUN_RRF_TUNING_INTEGRATION=1 to run the offline grid.',
    timeout: const Timeout(Duration(minutes: 20)),
  );
}

String _tempSnapshotPath(RrfConfig config) {
  return 'build/eval_snapshots/rrf_tuning/'
      'k${config.rankConstant}_d${config.semanticWeight}_s${config.keywordWeight}.json';
}

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProviderPlatform(this.path);

  final String path;

  @override
  Future<String?> getApplicationSupportPath() async => path;
}
