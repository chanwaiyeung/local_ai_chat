// test/library_screen_test.dart
//
// Verifies:
//   1. LibraryScreen renders the book list returned by ApiClient.getDocs()
//   2. Tapping a list item navigates to ReaderScreen with the right title
//   3. Empty list shows the placeholder

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/controllers/book_controller.dart';
import 'package:local_ai_chat/models/book.dart';
import 'package:local_ai_chat/screens/library_screen.dart';
import 'package:local_ai_chat/screens/reader_screen.dart';
import 'package:local_ai_chat/services/api_client.dart';
import 'package:local_ai_chat/services/classification_service.dart';
import 'package:local_ai_chat/services/vector_store.dart';

import 'helpers/test_app.dart';

class _FakeApiClient extends Fake implements ReaderApi {
  _FakeApiClient(this._docs, {this.delay = Duration.zero});
  final List<String> _docs;
  final Duration delay;

  @override
  Future<List<String>> getDocs() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return _docs;
  }

  @override
  Future<bool> health() async => true;

  @override
  Future<Map<String, dynamic>> query({
    required String query,
    String? docName,
  }) async {
    return {'answer': 'fake answer', 'citations': const []};
  }

  @override
  Stream<QueryEvent> queryStream({
    required String query,
    String? docName,
  }) async* {}
}

void main() {
  testWidgets('renders book titles from ApiClient', (tester) async {
    await tester.pumpWidget(TestApp(
      child: LibraryScreen(
        apiClient: _FakeApiClient(['哈姆雷特', '老人與海']),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('哈姆雷特'), findsOneWidget);
    expect(find.text('老人與海'), findsOneWidget);
    expect(find.byIcon(Icons.book), findsNWidgets(2));
  });

  testWidgets('shows placeholder when library is empty', (tester) async {
    await tester.pumpWidget(TestApp(
      child: LibraryScreen(apiClient: _FakeApiClient(const [])),
    ));
    await tester.pumpAndSettle();

    expect(find.text('尚無項目'), findsOneWidget);
  });

  testWidgets('tapping a book pushes ReaderScreen with that title',
      (tester) async {
    await tester.pumpWidget(TestApp(
      child: LibraryScreen(apiClient: _FakeApiClient(['哈姆雷特'])),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('哈姆雷特'));
    await tester.pumpAndSettle();

    expect(find.byType(ReaderScreen), findsOneWidget);
    // The pushed ReaderScreen has the title in its AppBar.
    final reader = tester.widget<ReaderScreen>(find.byType(ReaderScreen));
    expect(reader.bookTitle, '哈姆雷特');
  });

  testWidgets('shows progress indicator while loading', (tester) async {
    await tester.pumpWidget(TestApp(
      child: LibraryScreen(
        apiClient: _FakeApiClient(
          ['書'],
          delay: const Duration(milliseconds: 200),
        ),
      ),
    ));
    // Don't settle — the future is still pending.
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('書'), findsOneWidget);
  });

  testWidgets('shows real-device IP dialog', (tester) async {
    await tester.pumpWidget(TestApp(
      child: LibraryScreen(apiClient: _FakeApiClient(['書'])),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.wifi));
    await tester.pumpAndSettle();

    expect(find.text('實機 IP'), findsOneWidget);
    expect(find.text('套用'), findsOneWidget);
  });

  testWidgets('source filtering works correctly', (tester) async {
    final store = VectorStore();
    final controller = BookController(store);

    // 1. Add 2 books to the database: one with local, one with cloud classification
    final bookLocal = Book(
      id: '1',
      title: '哈姆雷特',
      interactionMetadata: BookInteractionMetadata(
        classificationSource: 'local',
      ),
    );
    final bookCloud = Book(
      id: '2',
      title: '老人與海',
      interactionMetadata: BookInteractionMetadata(
        classificationSource: 'cloud',
      ),
    );

    await store.add(DocChunk(
      id: bookLocal.id,
      docName: 'book_${bookLocal.id}',
      chunkIndex: 0,
      text: bookLocal.toSearchText(),
      collectionName: BookController.kBookCollection,
      metadata: {
        'type': BookController.kBookTypeTag,
        'data': bookLocal.toJson(),
      },
    ));
    await store.add(DocChunk(
      id: bookCloud.id,
      docName: 'book_${bookCloud.id}',
      chunkIndex: 0,
      text: bookCloud.toSearchText(),
      collectionName: BookController.kBookCollection,
      metadata: {
        'type': BookController.kBookTypeTag,
        'data': bookCloud.toJson(),
      },
    ));
    await controller.loadAll();

    // 2. Pump LibraryScreen with a FakeApiClient returning these docs
    await tester.pumpWidget(TestApp(
      child: LibraryScreen(
        apiClient: _FakeApiClient(['哈姆雷特', '老人與海']),
        bookController: controller,
      ),
    ));
    await tester.pumpAndSettle();

    // Both books should initially be visible under "全部 (2)"
    expect(find.text('哈姆雷特'), findsOneWidget);
    expect(find.text('老人與海'), findsOneWidget);

    // 3. Tap on "本地處理 (1)" chip
    await tester.tap(find.text('本地處理 (1)'));
    await tester.pumpAndSettle();

    // Only the local book should be shown
    expect(find.text('哈姆雷特'), findsOneWidget);
    expect(find.text('老人與海'), findsNothing);

    // 4. Tap on "全部 (2)" chip
    await tester.tap(find.text('全部 (2)'));
    await tester.pumpAndSettle();

    // Both books should be visible again
    expect(find.text('哈姆雷特'), findsOneWidget);
    expect(find.text('老人與海'), findsOneWidget);
  });

  testWidgets('AI management button opens bottom sheet with options', (tester) async {
    final store = VectorStore();
    final controller = BookController(store);

    final book = Book(
      id: '1',
      title: '哈姆雷特',
      category: '', // unclassified
      tags: const ['Drama', 'Tragedy'],
    );

    await store.add(DocChunk(
      id: book.id,
      docName: 'book_${book.id}',
      chunkIndex: 0,
      text: book.toSearchText(),
      collectionName: BookController.kBookCollection,
      metadata: {
        'type': BookController.kBookTypeTag,
        'data': book.toJson(),
      },
    ));
    await controller.loadAll();

    await tester.pumpWidget(TestApp(
      child: LibraryScreen(
        apiClient: _FakeApiClient(['哈姆雷特']),
        bookController: controller,
      ),
    ));
    await tester.pumpAndSettle();

    // Verify AI management button is in AppBar
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);

    // Tap it to open Bottom Sheet
    await tester.tap(find.byIcon(Icons.auto_awesome));
    await tester.pumpAndSettle();

    // Verify options in Bottom Sheet
    expect(find.text('圖書館 AI 管理'), findsOneWidget);
    expect(find.text('批次掃描圖書館'), findsOneWidget);
    expect(find.text('檢視全部標籤'), findsOneWidget);

    // Tap "檢視全部標籤"
    await tester.tap(find.text('檢視全部標籤'));
    await tester.pumpAndSettle();

    // Verify Tag Stats sub-page
    expect(find.text('全部標籤統計'), findsOneWidget);
    expect(find.text('Drama'), findsOneWidget);
    expect(find.text('Tragedy'), findsOneWidget);
    expect(find.text('1 本書'), findsNWidgets(2));

    // Tap back button
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Verify back to main menu
    expect(find.text('圖書館 AI 管理'), findsOneWidget);
  });

  testWidgets('Reading Profile displays top 5 tags in ActionChips and hides others', (tester) async {
    final store = VectorStore();
    final controller = BookController(store);
    
    // Add 6 books with different tags to test top 5 ordering and threshold
    // T1 (6), T2 (5), T3 (4), T4 (3), T5 (2), T6 (1)
    final tags = ['T1', 'T2', 'T3', 'T4', 'T5', 'T6'];
    for (int i = 0; i < tags.length; i++) {
      final tag = tags[i];
      final count = 6 - i;
      for (int j = 0; j < count; j++) {
        final book = Book(
          id: 'book_${tag}_$j',
          title: 'Title_${tag}_$j',
          interactionMetadata: BookInteractionMetadata(
            tags: [tag],
          ),
        );
        await store.add(DocChunk(
          id: book.id,
          docName: 'book_${book.id}',
          chunkIndex: 0,
          text: book.toSearchText(),
          collectionName: BookController.kBookCollection,
          metadata: {
            'type': BookController.kBookTypeTag,
            'data': book.toJson(),
          },
        ));
      }
    }
    await controller.loadAll();
    
    await tester.pumpWidget(TestApp(
      child: LibraryScreen(
        apiClient: _FakeApiClient(const ['書']),
        bookController: controller,
      ),
    ));
    await tester.pumpAndSettle();
    
    // Should show the title
    expect(find.text('閱讀輪廓'), findsOneWidget);
    
    // Should show top 5 tags: T1 (6), T2 (5), T3 (4), T4 (3), T5 (2)
    expect(find.text('T1 (6)'), findsOneWidget);
    expect(find.text('T2 (5)'), findsOneWidget);
    expect(find.text('T3 (4)'), findsOneWidget);
    expect(find.text('T4 (3)'), findsOneWidget);
    expect(find.text('T5 (2)'), findsOneWidget);
    
    // Should NOT show T6 (1)
    expect(find.text('T6 (1)'), findsNothing);
  });

  testWidgets('LibraryScreen correctly renders tags with counts like 神學 (5)', (tester) async {
    final store = VectorStore();
    final controller = BookController(store);
    
    for (int i = 0; i < 5; i++) {
      final book = Book(
        id: 'theology_book_$i',
        title: 'Theology_$i',
        interactionMetadata: BookInteractionMetadata(
          tags: const ['神學'],
        ),
      );
      await store.add(DocChunk(
        id: book.id,
        docName: 'book_${book.id}',
        chunkIndex: 0,
        text: book.toSearchText(),
        collectionName: BookController.kBookCollection,
        metadata: {
          'type': BookController.kBookTypeTag,
          'data': book.toJson(),
        },
      ));
    }
    await controller.loadAll();
    
    await tester.pumpWidget(TestApp(
      child: LibraryScreen(
        apiClient: _FakeApiClient(const ['書']),
        bookController: controller,
      ),
    ));
    await tester.pumpAndSettle();
    
    expect(find.text('神學 (5)'), findsOneWidget);
  });

  testWidgets('triggers background processing after a 3-second delay', (tester) async {
    final store = VectorStore();
    final spyController = _SpyBookController(store);
    
    await tester.pumpWidget(TestApp(
      child: LibraryScreen(
        apiClient: _FakeApiClient(const ['書']),
        bookController: spyController,
      ),
    ));
    
    // Initially processUnclassifiedBooks should not be called (since it's delayed by 3s)
    expect(spyController.processUnclassifiedBooksCalled, isFalse);
    
    // Pump 3 seconds
    await tester.pump(const Duration(seconds: 3));
    
    // Now it should have been called!
    expect(spyController.processUnclassifiedBooksCalled, isTrue);
  });
}

class _SpyBookController extends BookController {
  _SpyBookController(super.store);
  bool processUnclassifiedBooksCalled = false;
  
  @override
  Future<void> processUnclassifiedBooks({ClassificationService? classificationService}) async {
    processUnclassifiedBooksCalled = true;
  }
}


