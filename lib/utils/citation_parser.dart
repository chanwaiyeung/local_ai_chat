class CitationLinkTarget {
  const CitationLinkTarget({
    required this.docName,
    required this.chunkIndex,
  });

  final String docName;
  final int? chunkIndex;
}

CitationLinkTarget? parseCitationLinkTarget(String? href) {
  if (href == null || href.trim().isEmpty) return null;

  final normalizedHref =
      href.trim().replaceAll('&amp;', '&').replaceAll(RegExp(r'&\s+'), '&');
  final uri = Uri.tryParse(normalizedHref);
  if (uri == null || uri.scheme.toLowerCase() != 'chunk') return null;

  final docName = uri.queryParameters['id'] ?? uri.queryParameters['doc'];
  if (docName == null || docName.trim().isEmpty) return null;

  final rawIndex = uri.queryParameters['chunk'] ?? uri.queryParameters['i'];
  return CitationLinkTarget(
    docName: _decodeCitationDocName(docName),
    chunkIndex: int.tryParse(rawIndex ?? ''),
  );
}

String _decodeCitationDocName(String docName) {
  try {
    return Uri.decodeQueryComponent(docName);
  } catch (_) {
    return docName;
  }
}


