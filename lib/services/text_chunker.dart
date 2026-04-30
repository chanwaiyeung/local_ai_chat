// lib/services/text_chunker.dart
//
// Splits a text document into chunks suitable for embedding. Strategy:
//   1. Split on blank lines (paragraphs).
//   2. If a paragraph is longer than maxChars, split at sentence boundaries
//      (. ! ? 。！？), preferring the latest break before maxChars.
//   3. As a last resort, hard-split at maxChars.
//   4. If overlap > 0, prepend the last `overlap` characters of the
//      previous chunk to each chunk (except the first), so concepts
//      that straddle a chunk boundary remain fully visible to the
//      retriever.
//
// `maxChars` is the target body size; with overlap > 0, total chunk size
// is up to (maxChars + overlap).
//
// Pure logic — easy to unit test, no I/O.

import 'vector_store.dart';

class TextChunker {
  /// Splits [text] into chunks suitable for embedding.
  ///
  /// - [maxChars]: target body size per chunk.
  /// - [overlap]: number of trailing characters from the previous chunk
  ///   to prepend to the next chunk (default 0 = no overlap). Helps
  ///   when sentences span chunk boundaries. Must satisfy
  ///   `0 <= overlap < maxChars`.
  static List<Chunk> split(
    String text, {
    required String docName,
    int maxChars = 500,
    int overlap = 0,
  }) {
    if (maxChars < 1) {
      throw ArgumentError.value(maxChars, 'maxChars', 'must be >= 1');
    }
    if (overlap < 0 || overlap >= maxChars) {
      throw ArgumentError.value(
          overlap, 'overlap', 'must satisfy 0 <= overlap < maxChars');
    }

    final bodies = <String>[];

    final paragraphs = text.split(RegExp(r'\n[ \t]*\n'));
    for (final p in paragraphs) {
      final trimmed = p.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.length <= maxChars) {
        bodies.add(trimmed);
        continue;
      }
      bodies.addAll(_splitLong(trimmed, maxChars));
    }

    if (bodies.isEmpty) return const [];

    final chunks = <Chunk>[];
    for (var i = 0; i < bodies.length; i++) {
      final body = bodies[i];
      final text = (overlap == 0 || i == 0)
          ? body
          : _prefixOverlap(bodies[i - 1], overlap) + body;
      chunks.add(Chunk(docName: docName, chunkIndex: i, text: text));
    }
    return chunks;
  }

  /// Take the last [n] chars of [previous] and add a soft separator so
  /// the chunker output is still pleasant for an LLM to read. The
  /// separator (`\n…\n`) makes it obvious in the prompt that the leading
  /// text is context-from-the-previous-chunk, not the chunk's own intro.
  static String _prefixOverlap(String previous, int n) {
    final tail =
        previous.length <= n ? previous : previous.substring(previous.length - n);
    return '$tail\n…\n';
  }

  static List<String> _splitLong(String text, int maxChars) {
    final pieces = <String>[];
    final sentenceEnd = RegExp(r'[.!?。！？]\s');
    var remaining = text;

    while (remaining.length > maxChars) {
      final window = remaining.substring(0, maxChars);
      final matches = sentenceEnd.allMatches(window).toList();
      int splitAt;
      if (matches.isNotEmpty && matches.last.end > maxChars ~/ 2) {
        splitAt = matches.last.end;
      } else {
        // No good sentence break — hard cut at maxChars.
        splitAt = maxChars;
      }
      pieces.add(remaining.substring(0, splitAt).trim());
      remaining = remaining.substring(splitAt).trim();
    }
    if (remaining.isNotEmpty) pieces.add(remaining);
    return pieces;
  }
}
