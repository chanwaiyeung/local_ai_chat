// test/text_chunker_test.dart
//
// Pure-logic tests for TextChunker. No I/O, runs in milliseconds.

import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/services/text_chunker.dart';

void main() {
  group('TextChunker.split', () {
    test('keeps short paragraphs as one chunk each', () {
      final chunks = TextChunker.split(
        'Para one.\n\nPara two.\n\nPara three.',
        docName: 'a.txt',
      );
      expect(chunks.map((c) => c.text), [
        'Para one.',
        'Para two.',
        'Para three.',
      ]);
      expect(chunks.map((c) => c.chunkIndex), [0, 1, 2]);
      expect(chunks.every((c) => c.docName == 'a.txt'), isTrue);
    });

    test('skips blank-only paragraphs', () {
      final chunks = TextChunker.split(
        'A.\n\n   \n\nB.',
        docName: 'a.txt',
      );
      expect(chunks.map((c) => c.text), ['A.', 'B.']);
    });

    test('splits long paragraphs at sentence boundaries', () {
      const long = 'Sentence one. Sentence two! Sentence three? Trailing.';
      final chunks = TextChunker.split(long, docName: 'a.txt', maxChars: 25);
      // Each chunk must respect the cap.
      for (final c in chunks) {
        expect(c.text.length, lessThanOrEqualTo(25));
      }
      // Joined content (modulo whitespace) recovers the input.
      final joined = chunks.map((c) => c.text).join(' ');
      expect(joined.replaceAll(RegExp(r'\s+'), ' '),
          long.replaceAll(RegExp(r'\s+'), ' '));
    });

    test('hard-splits when no sentence break is available', () {
      // 60 chars, no sentence terminator — must hard-split at maxChars.
      final wall = 'a' * 60;
      final chunks = TextChunker.split(wall, docName: 'a.txt', maxChars: 25);
      for (final c in chunks) {
        expect(c.text.length, lessThanOrEqualTo(25));
      }
      expect(chunks.map((c) => c.text).join(), wall);
    });

    test('handles CJK punctuation as sentence ends', () {
      const cjk = '第一句話。 第二句話！ 第三句話？';
      final chunks = TextChunker.split(cjk, docName: 'a.txt', maxChars: 8);
      // No chunk longer than the cap.
      for (final c in chunks) {
        expect(c.text.length, lessThanOrEqualTo(8));
      }
    });

    test('throws on bad maxChars', () {
      expect(
        () => TextChunker.split('x', docName: 'a.txt', maxChars: 0),
        throwsArgumentError,
      );
    });

    test('chunk indices are sequential per call', () {
      final chunks = TextChunker.split(
        'A.\n\nB.\n\nC.\n\nD.',
        docName: 'doc.txt',
      );
      expect(chunks.map((c) => c.chunkIndex).toList(), [0, 1, 2, 3]);
    });
  });

  group('TextChunker.split with overlap', () {
    test('overlap=0 produces no repeated content (default)', () {
      final chunks = TextChunker.split(
        'First paragraph here.\n\nSecond paragraph here.',
        docName: 'a.txt',
      );
      expect(chunks, hasLength(2));
      expect(chunks[0].text, 'First paragraph here.');
      expect(chunks[1].text, 'Second paragraph here.');
    });

    test('overlap > 0 prepends the tail of the previous chunk', () {
      const a = 'AAAAAAAAAA';
      const b = 'BBBBBBBBBB';
      final chunks = TextChunker.split(
        '$a\n\n$b',
        docName: 'a.txt',
        maxChars: 50,
        overlap: 5,
      );
      expect(chunks, hasLength(2));
      expect(chunks[0].text, a);
      // Last 5 chars of 'AAAAAAAAAA' (= 'AAAAA') prepended with separator.
      expect(chunks[1].text, contains('AAAAA\n…\n'));
      expect(chunks[1].text, endsWith(b));
    });

    test('first chunk is never prefixed with overlap', () {
      final chunks = TextChunker.split(
        'Para one.\n\nPara two.',
        docName: 'a.txt',
        overlap: 3,
      );
      expect(chunks.first.text, 'Para one.');
    });

    test('overlap shorter than the previous chunk takes whole prev', () {
      // Previous chunk is shorter than the overlap window: take all of it.
      final chunks = TextChunker.split(
        'Hi.\n\nLong second paragraph.',
        docName: 'a.txt',
        overlap: 10,
      );
      expect(chunks[1].text, startsWith('Hi.\n…\n'));
    });

    test('overlap >= maxChars throws', () {
      expect(
        () =>
            TextChunker.split('x', docName: 'a.txt', maxChars: 50, overlap: 50),
        throwsArgumentError,
      );
    });

    test('negative overlap throws', () {
      expect(
        () => TextChunker.split('x', docName: 'a.txt', overlap: -1),
        throwsArgumentError,
      );
    });
  });
}


