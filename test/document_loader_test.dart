// test/document_loader_test.dart
//
// Tests for document_loader.dart. Covers .txt / .md text passthrough,
// HTML → text conversion (the part EPUB depends on), and the negative
// path for unsupported extensions. EPUB end-to-end requires a fixture file
// and is exercised manually via `dart run bin/index.dart`.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/services/document_loader.dart';

void main() {
  group('isSupportedDocument', () {
    test('accepts known extensions (case-insensitive)', () {
      expect(isSupportedDocument('book.txt'), isTrue);
      expect(isSupportedDocument('book.md'), isTrue);
      expect(isSupportedDocument('book.MARKDOWN'), isTrue);
      expect(isSupportedDocument('book.epub'), isTrue);
      expect(isSupportedDocument('book.PDF'), isTrue);
    });

    test('accepts image and CBZ extensions for OCR pipeline', () {
      expect(isSupportedDocument('manga.cbz'), isTrue);
      expect(isSupportedDocument('page.png'), isTrue);
      expect(isSupportedDocument('photo.JPG'), isTrue);
      expect(isSupportedDocument('photo.jpeg'), isTrue);
      expect(isSupportedDocument('scan.WEBP'), isTrue);
    });

    test('rejects everything else', () {
      expect(isSupportedDocument('book.docx'), isFalse);
      expect(isSupportedDocument('book.html'), isFalse);
      expect(
          isSupportedDocument('archive.cbr'), isFalse); // RAR not supported yet
      expect(isSupportedDocument('book'), isFalse);
    });
  });

  group('htmlToText', () {
    test('preserves paragraph breaks for block tags', () {
      const html =
          '<html><body><p>One.</p><p>Two.</p><div>Three.</div></body></html>';
      final text = htmlToText(html);
      // Expect blank-line-separated paragraphs the chunker can split on.
      expect(text.split(RegExp(r'\n\s*\n')).map((s) => s.trim()).toList(),
          ['One.', 'Two.', 'Three.']);
    });

    test('honours <br> as a single newline within a paragraph', () {
      const html = '<p>Line one.<br>Line two.</p>';
      final text = htmlToText(html);
      expect(text, 'Line one.\nLine two.');
    });

    test('decodes HTML entities', () {
      const html = '<p>5 &lt; 10 &amp; 20 &gt; 5</p>';
      final text = htmlToText(html);
      expect(text, '5 < 10 & 20 > 5');
    });

    test('drops script and style content', () {
      const html =
          '<p>Visible.</p><script>alert(1)</script><style>.x{color:red}</style><p>Also visible.</p>';
      final text = htmlToText(html);
      expect(text.contains('alert'), isFalse);
      expect(text.contains('color:red'), isFalse);
      expect(text.contains('Visible.'), isTrue);
      expect(text.contains('Also visible.'), isTrue);
    });

    test('collapses excessive whitespace', () {
      const html = '<p>  too    much\t\twhitespace  </p>';
      final text = htmlToText(html);
      expect(text, 'too much whitespace');
    });

    test('keeps headings as paragraph-level breaks', () {
      const html = '<h1>Title</h1><p>Body.</p>';
      final text = htmlToText(html);
      expect(text.split(RegExp(r'\n\s*\n')).map((s) => s.trim()).toList(),
          ['Title', 'Body.']);
    });
  });

  group('loadDocument', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('docloader-test');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('reads .txt as plain text', () async {
      final f = File('${tempDir.path}/a.txt');
      await f.writeAsString('hello\nworld');
      expect(await loadDocument(f.path), 'hello\nworld');
    });

    test('reads .md as plain text', () async {
      final f = File('${tempDir.path}/a.md');
      await f.writeAsString('# Heading\n\nBody.');
      expect(await loadDocument(f.path), '# Heading\n\nBody.');
    });

    test('throws on unsupported extension', () async {
      final f = File('${tempDir.path}/a.docx');
      await f.writeAsString('not really a docx');
      expect(
        () => loadDocument(f.path),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('Unsupported'))),
      );
    });
  });
}
