import 'vector_store.dart';

typedef LongContextRetriever = Future<List<ScoredChunk>> Function(
  String query, {
  required int k,
});

class LongContextTrace {
  const LongContextTrace({
    required this.originalQuery,
    required this.subQueries,
    required this.subQueryHits,
    required this.mergedHits,
  });

  final String originalQuery;
  final List<String> subQueries;
  final Map<String, List<ScoredChunk>> subQueryHits;
  final List<ScoredChunk> mergedHits;

  Map<String, Object?> toJson() => {
        'originalQuery': originalQuery,
        'subQueries': subQueries,
        'subQueryHits': {
          for (final entry in subQueryHits.entries)
            entry.key: [
              for (final hit in entry.value)
                {
                  'docName': hit.chunk.docName,
                  'chunkIndex': hit.chunk.chunkIndex,
                  'score': double.parse(hit.score.toStringAsFixed(6)),
                },
            ],
        },
        'mergedHits': [
          for (final hit in mergedHits)
            {
              'docName': hit.chunk.docName,
              'chunkIndex': hit.chunk.chunkIndex,
              'score': double.parse(hit.score.toStringAsFixed(6)),
            },
        ],
      };
}

class LongContextResult {
  const LongContextResult({
    required this.hits,
    required this.trace,
  });

  final List<ScoredChunk> hits;
  final LongContextTrace trace;
}

class LongContextOptimizer {
  const LongContextOptimizer();

  static const _keywords = [
    'summarize',
    'summary',
    'explain in detail',
    'all',
    'major',
    'overview',
    'comprehensive',
    'compare',
    'relationship',
    'how does',
    'collect',
    'list the main',
    'troubleshooting guide',
  ];

  bool isLongContext(String query) {
    final q = query.toLowerCase().trim();
    if (q.length < 30) return false;
    return _keywords.any(q.contains);
  }

  List<String> decompose(String query) {
    final q = query.toLowerCase();
    final subQueries = <String>[query.trim()];

    if (q.contains('summarize') ||
        q.contains('overview') ||
        q.contains('all major')) {
      subQueries.add(_replaceSummaryLanguage(query, 'main sections'));
      subQueries.add('configuration sections input display sound cpu');
    }

    if (q.contains('compare') ||
        q.contains('relationship') ||
        q.contains('difference')) {
      subQueries.add('mounting drives configuration running programs');
      subQueries.add('key features common issues');
    }

    if (q.contains('explain in detail') || q.contains('how does')) {
      subQueries.add(query.replaceAll(
        RegExp('explain in detail', caseSensitive: false),
        'basic principle',
      ));
    }

    if (q.contains('troubleshooting') || q.contains('issues')) {
      subQueries.add('mouse keyboard input troubleshooting');
      subQueries.add('cpu speed cycles configuration troubleshooting');
    }

    if (q.contains('setup') || q.contains('running')) {
      subQueries.add('mount drive run game setup');
      subQueries.add('dosbox.conf startup configuration');
    }

    return _dedupe(subQueries).take(4).toList();
  }

  Future<LongContextResult> retrieve({
    required String query,
    required int k,
    required LongContextRetriever retriever,
  }) async {
    final subQueries = decompose(query);
    final subQueryHits = <String, List<ScoredChunk>>{};
    final merged = <String, ScoredChunk>{};

    for (final subQuery in subQueries) {
      final hits = await retriever(subQuery, k: k);
      subQueryHits[subQuery] = hits;
      for (var rank = 0; rank < hits.length; rank++) {
        final hit = hits[rank];
        final key = hit.chunk.id;
        final weightedScore = hit.score + (1.0 / (rank + 1));
        final current = merged[key];
        if (current == null || weightedScore > current.score) {
          merged[key] = ScoredChunk(hit.chunk, weightedScore);
        }
      }
    }

    final mergedHits = merged.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    final finalHits = mergedHits.take(k).toList();
    return LongContextResult(
      hits: finalHits,
      trace: LongContextTrace(
        originalQuery: query,
        subQueries: subQueries,
        subQueryHits: subQueryHits,
        mergedHits: finalHits,
      ),
    );
  }

  String _replaceSummaryLanguage(String query, String replacement) {
    return query.replaceAll(
      RegExp('summarize|overview|all major', caseSensitive: false),
      replacement,
    );
  }

  List<String> _dedupe(List<String> values) {
    final result = <String>[];
    for (final value in values) {
      final cleaned = value.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (cleaned.isNotEmpty && !result.contains(cleaned)) {
        result.add(cleaned);
      }
    }
    return result;
  }
}
