class AmbiguousQueryDetector {
  const AmbiguousQueryDetector();

  static const _vaguePhrases = [
    'how do i configure it',
    'configure it',
    'fix it',
    'fix the',
    'make it better',
    'screen better',
    'start it',
    'set it up',
    'what about it',
    'how does it',
    'where do i put',
  ];

  static const _vagueWords = [
    'it',
    'this',
    'that',
    'them',
    'properly',
    'correctly',
  ];

  static const _domainKeywords = [
    'dosbox',
    'cpu',
    'mouse',
    'keyboard',
    'config',
    'configuration',
    'cycles',
    'mount',
    'fullscreen',
    'dosbox.conf',
    'keymapper',
    'core',
    'drive',
    'screen',
    'output',
    'sound',
  ];

  bool isAmbiguous(String query, {String? activeDoc}) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return true;

    if (q.length < 8) return true;

    if (_vaguePhrases.any(q.contains)) return true;

    final tokens = q
        .split(RegExp(r'[^a-z0-9_.-]+'))
        .where((token) => token.isNotEmpty)
        .toList();
    if (tokens.length < 4 && activeDoc == null) return true;

    final hasDomainKeyword = _domainKeywords.any(q.contains);
    final hasVagueWord = tokens.any(_vagueWords.contains);
    if (hasVagueWord && !hasDomainKeyword) return true;

    if (!hasDomainKeyword && activeDoc == null && tokens.length < 6) {
      return true;
    }

    return false;
  }
}
