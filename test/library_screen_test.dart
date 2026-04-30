// test/library_screen_test.dart
//
// Verifies:
//   1. LibraryScreen renders the book list returned by ApiClient.getDocs()
//   2. Tapping a list item navigates to ReaderScreen with the right title
//   3. Empty list shows the placeholder

import 'package:ai_library_server/screens/library_screen.dart';
import 'package:ai_library_server/screens/reader_screen.dart';
import 'package:ai_library_server/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
    await tester.pumpWidget(MaterialApp(
      home: LibraryScreen(
        apiClient: _FakeApiClient(['哈姆雷特', '老人與海']),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('哈姆雷特'), findsOneWidget);
    expect(find.text('老人與海'), findsOneWidget);
    expect(find.byIcon(Icons.book), findsNWidgets(2));
  });

  testWidgets('shows placeholder when library is empty', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: LibraryScreen(apiClient: _FakeApiClient(const [])),
    ));
    await tester.pumpAndSettle();

    expect(find.text('目前沒有書籍'), findsOneWidget);
  });

  testWidgets('tapping a book pushes ReaderScreen with that title',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: LibraryScreen(apiClient: _FakeApiClient(['哈姆雷特'])),
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
    await tester.pumpWidget(MaterialApp(
      home: LibraryScreen(
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
    await tester.pumpWidget(MaterialApp(
      home: LibraryScreen(apiClient: _FakeApiClient(['書'])),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.wifi));
    await tester.pumpAndSettle();

    expect(find.text('實機 IP'), findsOneWidget);
    expect(find.text('套用'), findsOneWidget);
  });
}
