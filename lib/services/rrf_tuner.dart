import 'rag_service.dart';

class RrfTuningResult {
  const RrfTuningResult({
    required this.config,
    required this.passRate,
    required this.score,
    required this.pass,
    required this.partial,
    required this.fail,
  });

  final RrfConfig config;
  final double passRate;
  final double score;
  final int pass;
  final int partial;
  final int fail;

  Map<String, Object?> toJson() => {
        'config': config.toJson(),
        'passRate': passRate,
        'score': score,
        'pass': pass,
        'partial': partial,
        'fail': fail,
      };
}

class RrfTuner {
  const RrfTuner();

  static const List<int> rankConstants = [5, 10, 15, 20, 30, 60];
  static const List<double> denseWeights = [0.3, 0.4, 0.5, 0.6, 0.7, 0.8];
  static const List<double> sparseWeights = [0.2, 0.3, 0.4, 0.5, 0.6, 0.7];

  List<RrfConfig> generateGrid() {
    final configs = <RrfConfig>[];
    for (final rankConstant in rankConstants) {
      for (final denseWeight in denseWeights) {
        for (final sparseWeight in sparseWeights) {
          if ((denseWeight + sparseWeight - 1.0).abs() > 0.01) continue;
          configs.add(RrfConfig(
            rankConstant: rankConstant,
            semanticWeight: denseWeight,
            keywordWeight: sparseWeight,
          ));
        }
      }
    }
    return configs;
  }

  double rrfScore(int rank, int rankConstant) {
    return 1.0 / (rankConstant + rank);
  }

  RrfTuningResult bestResult(List<RrfTuningResult> results) {
    if (results.isEmpty) {
      throw ArgumentError.value(results, 'results', 'must not be empty');
    }

    final sorted = [...results]..sort(_compareResults);
    return sorted.first;
  }

  int _compareResults(RrfTuningResult a, RrfTuningResult b) {
    final passRateCompare = b.passRate.compareTo(a.passRate);
    if (passRateCompare != 0) return passRateCompare;

    final scoreCompare = b.score.compareTo(a.score);
    if (scoreCompare != 0) return scoreCompare;

    final rankConstantCompare =
        b.config.rankConstant.compareTo(a.config.rankConstant);
    if (rankConstantCompare != 0) return rankConstantCompare;

    return b.config.keywordWeight.compareTo(a.config.keywordWeight);
  }
}


