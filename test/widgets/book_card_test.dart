import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/controllers/book_controller.dart';
import 'package:local_ai_chat/models/book.dart';
import 'package:local_ai_chat/services/vector_store.dart';
import 'package:local_ai_chat/widgets/book/book_card.dart';
import '../helpers/test_app.dart';

class _MockBookController extends BookController {
  _MockBookController(super.store);

  String? lastUpdatedBookId;
  String? lastUpdatedCategory;
  List<String>? lastUpdatedTags;

  @override
  Future<void> updateClassification(String bookId, String category, List<String> tags, {String classificationSource = 'local'}) async {
    lastUpdatedBookId = bookId;
    lastUpdatedCategory = category;
    lastUpdatedTags = tags;
  }
}

void main() {
  testWidgets('BookCard renders details and AI button', (tester) async {
    final book = Book(
      id: 'test_id',
      title: 'Flutter Design Patterns',
      author: 'Unknown Author',
      tags: const ['Mobile', 'Design'],
    );

    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: BookCard(book: book),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Flutter Design Patterns'), findsOneWidget);
    expect(find.text('Unknown Author'), findsOneWidget);
    expect(find.text('✨ AI'), findsOneWidget);
  });

  testWidgets('Tapping ✨ AI opens menu and selecting reclassify updates controller', (tester) async {
    final book = Book(
      id: 'test_id',
      title: 'Flutter Design Patterns',
      author: 'Unknown Author',
      tags: const ['Mobile', 'Design'],
    );

    final store = VectorStore();
    final controller = _MockBookController(store);

    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: BookCard(
            book: book,
            bookController: controller,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap ✨ AI button
    await tester.tap(find.text('✨ AI'));
    await tester.pumpAndSettle();

    // Check menu items
    expect(find.text('重算分類/標籤'), findsOneWidget);
    expect(find.text('生成摘要'), findsOneWidget);
    expect(find.text('深度問答'), findsOneWidget);

    // Tap "重算分類/標籤"
    await tester.tap(find.text('重算分類/標籤'));
    await tester.pump(); // Start async classification

    // Check if reclassify SnackBar shows up
    expect(find.text('正在重算分類與標籤...'), findsOneWidget);
    // Verify loading progress indicator replaces the AI button
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('BookCard renders source badge when classification source is present', (tester) async {
    final book = Book(
      id: 'test_id',
      title: 'Flutter Design Patterns',
      author: 'Unknown Author',
      tags: const ['Mobile', 'Design'],
      interactionMetadata: BookInteractionMetadata(
        classificationSource: 'local',
      ),
    );

    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: BookCard(book: book),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('本地 AI'), findsOneWidget);
    expect(find.byIcon(Icons.memory), findsOneWidget);
  });
}


