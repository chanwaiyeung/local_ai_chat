// test/reading_mode_screen_test.dart
//
// Phase 1C widget tests for ReadingModeScreen + the long-press entry point
// from LibraryScreen. The screen pulls full-text via /docs/<doc>/chunks
// and runs in-book search via /rag/retrieve.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/screens/library_screen.dart';
import 'package:local_ai_chat/screens/reading_mode_screen.dart';
import 'package:local_ai_chat/services/api_client.dart';

class _FakeApi extends Fake implements ReaderApi {
  _FakeApi({
    this.docs = const [],
    this.chunks = const [],
    this.hits = const [],
    this.throwOnLoad = false,
  });

  List<String> docs;
  List<Map<String, dynamic>> chunks;
  List<Map<String, dynamic>> hits;
  bool throwOnLoad;

  String? lastSearchQuery;
  String? lastSearchDoc;

  @override
  Future<List<String>> getDocs() async => docs;

  @override
  Future<bool> health() async => true;

  @override
  Future<List<Map<String, dynamic>>> getDocumentChunks(String docName) async {
    if (throwOnLoad) throw Exception('boom load');
    return chunks;
  }

  @override
  Future<List<Map<String, dynamic>>> retrieve({
    required String query,
    String? docName,
    int topK = 6,
  }) async {
    lastSearchQuery = query;
    lastSearchDoc = docName;
    return hits;
  }
}

void main() {
  group('ReadingModeScreen', () {
    testWidgets('loads chunks and renders body text', (tester) async {
      final api = _FakeApi(chunks: const [
        {'docName': 'b', 'chunkIndex': 0, 'text': 'first paragraph'},
        {'docName': 'b', 'chunkIndex': 1, 'text': 'second paragraph'},
      ]);
      await tester.pumpWidget(MaterialApp(
        home: ReadingModeScreen(bookTitle: 'b', apiClient: api),
      ));
      await tester.pumpAndSettle();

      expect(find.text('first paragraph'), findsOneWidget);
      expect(find.text('second paragraph'), findsOneWidget);
      expect(find.text('#0'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
    });

    testWidgets('shows placeholder when book has no indexed chunks',
        (tester) async {
      final api = _FakeApi(chunks: const []);
      await tester.pumpWidget(MaterialApp(
        home: ReadingModeScreen(bookTitle: 'b', apiClient: api),
      ));
      await tester.pumpAndSettle();

      expect(find.text('（這本書沒有索引內容）'), findsOneWidget);
    });

    testWidgets('renders load error from server', (tester) async {
      final api = _FakeApi(throwOnLoad: true);
      await tester.pumpWidget(MaterialApp(
        home: ReadingModeScreen(bookTitle: 'b', apiClient: api),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('載入失敗'), findsOneWidget);
    });

    testWidgets('search bar populates the hit card and forwards query',
        (tester) async {
      final api = _FakeApi(
        chunks: const [
          {'chunkIndex': 0, 'text': 'A'},
        ],
        hits: const [
          {
            'doc': 'b',
            'chunkIndex': 7,
            'score': 0.81,
            'snippet': 'snippet text from chunk seven',
          },
        ],
      );
      await tester.pumpWidget(MaterialApp(
        home: ReadingModeScreen(bookTitle: 'b', apiClient: api),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'hello world');
      await tester.tap(find.widgetWithText(FilledButton, '送出'));
      await tester.pumpAndSettle();

      expect(api.lastSearchQuery, 'hello world');
      expect(api.lastSearchDoc, 'b');
      // "#7 · 81%" rendered as title; subtitle has the snippet.
      expect(find.text('#7 · 81%'), findsOneWidget);
      expect(find.text('snippet text from chunk seven'), findsOneWidget);
    });

    testWidgets('empty-text chunk renders the (空段落) placeholder',
        (tester) async {
      final api = _FakeApi(chunks: const [
        {'chunkIndex': 0, 'text': 'real'},
        {'chunkIndex': 1, 'text': ''},
      ]);
      await tester.pumpWidget(MaterialApp(
        home: ReadingModeScreen(bookTitle: 'b', apiClient: api),
      ));
      await tester.pumpAndSettle();

      // Index alignment is preserved (Phase 1C invariant), so chunk #1
      // exists in the body — even though its text is empty. The screen
      // labels it explicitly so the user knows it's intentional.
      expect(find.text('（空段落）'), findsOneWidget);
    });
  });

  group('LibraryScreen → ReadingModeScreen long-press route', () {
    testWidgets('long-press on a book opens ReadingModeScreen', (tester) async {
      final api = _FakeApi(docs: const ['rag_concepts.md']);
      await tester.pumpWidget(MaterialApp(
        home: LibraryScreen(apiClient: api),
      ));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('rag_concepts.md'));
      await tester.pumpAndSettle();

      expect(find.byType(ReadingModeScreen), findsOneWidget);
      // The pushed screen's AppBar shows the book title.
      expect(find.text('閱讀：rag_concepts.md'), findsOneWidget);
    });

    testWidgets(
        'regular tap still opens the Q&A ReaderScreen, not Reading Mode',
        (tester) async {
      final api = _FakeApi(docs: const ['rag_concepts.md']);
      await tester.pumpWidget(MaterialApp(
        home: LibraryScreen(apiClient: api),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('rag_concepts.md'));
      await tester.pumpAndSettle();

      // Reading Mode must NOT be on the stack — Q&A path is unchanged.
      expect(find.byType(ReadingModeScreen), findsNothing);
    });
  });
}
