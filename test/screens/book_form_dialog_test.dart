import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/models/book.dart';
import 'package:local_ai_chat/widgets/book/book_cover_section.dart';
import 'package:local_ai_chat/widgets/book/book_form_dialog.dart';
import 'package:local_ai_chat/widgets/book/book_metadata_section.dart';
import 'package:local_ai_chat/widgets/book/book_reading_section.dart';
import 'package:local_ai_chat/widgets/book/book_tags_section.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('BookFormDialog shows add title and metadata fields',
      (tester) async {
    await tester.pumpWidget(TestApp(
      child: Builder(
        builder: (ctx) => ElevatedButton(
          onPressed: () => showDialog<void>(
            context: ctx,
            builder: (_) => BookFormDialog(
              onSave: (_) async {},
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Add Book'), findsOneWidget);
    expect(find.byType(BookCoverSection), findsOneWidget);
    expect(find.byType(BookMetadataSection), findsOneWidget);
    expect(find.byType(BookReadingSection), findsOneWidget);
    expect(find.byType(BookTagsSection), findsOneWidget);
    expect(find.text('Title *'), findsOneWidget);
  });

  testWidgets('BookFormDialog validates required title', (tester) async {
    await tester.pumpWidget(TestApp(
      child: Builder(
        builder: (ctx) => ElevatedButton(
          onPressed: () => showDialog<void>(
            context: ctx,
            builder: (_) => BookFormDialog(onSave: (_) async {}),
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add'));
    await tester.pump();

    expect(find.text('Required'), findsOneWidget);
  });

  testWidgets('BookFormDialog pre-fills existing book', (tester) async {
    final book = Book(
      id: '1',
      title: 'Test Title',
      author: 'Test Author',
      tags: const ['fiction'],
      rating: 4.0,
    );
    await tester.pumpWidget(TestApp(
      child: Builder(
        builder: (ctx) => ElevatedButton(
          onPressed: () => showDialog<void>(
            context: ctx,
            builder: (_) => BookFormDialog(
              existing: book,
              onSave: (_) async {},
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Book'), findsOneWidget);
    expect(find.text('Test Title'), findsOneWidget);
    expect(find.text('fiction'), findsOneWidget);
  });

  test('fillEmptyMetadataFromBook only fills empty fields', () {
    final title = TextEditingController(text: 'Kept');
    final author = TextEditingController();
    final publisher = TextEditingController();
    final year = TextEditingController();
    final cover = TextEditingController();
    final n = fillEmptyMetadataFromBook(
      Book(title: 'New', author: 'A', publisher: 'P', year: 2020, coverUrl: 'u'),
      titleCtrl: title,
      authorCtrl: author,
      publisherCtrl: publisher,
      yearCtrl: year,
      coverUrlCtrl: cover,
    );
    expect(title.text, 'Kept');
    expect(author.text, 'A');
    expect(n, 4);
    title.dispose();
    author.dispose();
    publisher.dispose();
    year.dispose();
    cover.dispose();
  });
}


