class QueryExpansion {
  const QueryExpansion();

  static const Map<String, List<String>> _synonyms = {
    'mouse cursor': ['release mouse', 'mouse lock'],
    'let go': ['release'],
    'keyboard mapping': ['keymapper'],
    'cpu speed': ['cycles'],
    'configuration file': ['dosbox.conf'],
    'startup config': ['dosbox.conf'],
    'macos': ['mac', 'osx', 'darwin'],
    'windows': ['win32', 'windows'],
  };

  String sparseQueryForRetrieval(
    String query, {
    required bool enabled,
    int maxTerms = 12,
  }) {
    return enabled ? expandSparseQuery(query, maxTerms: maxTerms) : query;
  }

  String expandSparseQuery(String query, {int maxTerms = 12}) {
    final normalized = query.toLowerCase();
    final candidates = <String>[];

    for (final token in normalized
        .split(RegExp(r'[^a-z0-9_.-]+'))
        .where((term) => term.trim().isNotEmpty)) {
      _addUnique(candidates, token.trim());
    }

    for (final entry in _synonyms.entries) {
      if (normalized.contains(entry.key)) {
        for (final synonym in entry.value) {
          _addUnique(candidates, synonym);
        }
      }
    }

    final selected = <String>[];
    var tokenCount = 0;
    for (final candidate in candidates) {
      final width = candidate.split(RegExp(r'\s+')).length;
      if (tokenCount + width > maxTerms) continue;
      selected.add(candidate);
      tokenCount += width;
      if (tokenCount >= maxTerms) break;
    }

    return selected.join(' ');
  }

  void _addUnique(List<String> values, String value) {
    if (!values.contains(value)) values.add(value);
  }
}


