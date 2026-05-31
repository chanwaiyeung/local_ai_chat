import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/models/book.dart';
import 'package:local_ai_chat/widgets/book/book_tags_section.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('BookTagsSection displays local AI badge when source is local', (tester) async {
    final book = Book(
      title: 'Test Book',
      interactionMetadata: BookInteractionMetadata(
        classificationSource: 'local',
      ),
    );

    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: BookTagsSection(
            book: book,
            tags: const ['flutter', 'dart'],
            tagInputCtrl: TextEditingController(),
            onAddTag: () {},
            onRemoveTag: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('本地 AI'), findsOneWidget);
    expect(find.byIcon(Icons.memory), findsOneWidget);
    expect(find.text('雲端精煉'), findsNothing);
  });

  testWidgets('BookTagsSection displays cloud refine badge when source is cloud', (tester) async {
    final book = Book(
      title: 'Test Book',
      interactionMetadata: BookInteractionMetadata(
        classificationSource: 'cloud',
      ),
    );

    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: BookTagsSection(
            book: book,
            tags: const ['flutter', 'dart'],
            tagInputCtrl: TextEditingController(),
            onAddTag: () {},
            onRemoveTag: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('雲端精煉'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    expect(find.text('本地 AI'), findsNothing);
  });

  testWidgets('BookTagsSection displays no badge when book is null', (tester) async {
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: BookTagsSection(
            book: null,
            tags: const ['flutter', 'dart'],
            tagInputCtrl: TextEditingController(),
            onAddTag: () {},
            onRemoveTag: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('本地 AI'), findsNothing);
    expect(find.text('雲端精煉'), findsNothing);
  });
}


