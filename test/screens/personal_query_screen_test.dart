// test/screens/personal_query_screen_test.dart
//
// Phase 6.5 — Widget tests for PersonalQueryScreen.
// Embedding is faked via EmbeddingService(embedFn: ...). LLM is faked via
// LlmCompletionStream so tests stay offline.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:local_ai_chat/models/contact.dart';
import 'package:local_ai_chat/models/expense.dart';
import 'package:local_ai_chat/screens/personal_query_screen.dart';
import 'package:local_ai_chat/services/embedding_service.dart';
import 'package:local_ai_chat/services/personal_rag_service.dart';
import 'package:local_ai_chat/services/vector_store.dart';

Future<List<double>> keywordEmbed(String text) async {
  final lower = text.toLowerCase();
  return [
    lower.contains('lunch') ? 1.0 : 0.0,
    lower.contains('wang') || lower.contains('王') ? 1.0 : 0.0,
    lower.contains('albert') ? 1.0 : 0.0,
    1.0,
  ];
}

void main() {
  late VectorStore store;
  late EmbeddingService embedder;

  setUp(() async {
    store = VectorStore();
    embedder = EmbeddingService(embedFn: keywordEmbed);
  });

  Future<void> seed() async {
    final expense = Expense(
      id: 'e_lunch_wang',
      amount: 250,
      date: DateTime(2026, 5, 1),
      category: 'Meals',
      notes: 'lunch with Wang',
    );
    final expenseText = expense.toSearchText();
    await store.add(
      DocChunk(
        id: expense.id,
        docName: 'expense_${expense.id}',
        chunkIndex: 0,
        text: expenseText,
        collectionName: 'Expenses',
        metadata: {
          'type': 'personal_hub_expense',
          'data': expense.toJson(),
        },
      ),
      await keywordEmbed(expenseText),
    );

    final contact = Contact(
      id: 'c_wang',
      name: 'Wang Manager',
      company: 'Beta Co',
      scannedAt: DateTime(2026, 5, 1),
    );
    final contactText = contact.toSearchText();
    await store.add(
      DocChunk(
        id: contact.id,
        docName: contact.id,
        chunkIndex: 0,
        text: contactText,
        collectionName: 'Contacts',
        metadata: contact.toJson(),
      ),
      await keywordEmbed(contactText),
    );
  }

  Widget hostFor(PersonalRagService svc) =>
      MaterialApp(home: PersonalQueryScreen(ragService: svc));

  testWidgets('shows placeholder hints before any submission', (tester) async {
    final svc = PersonalRagService(embedder: embedder, store: store);
    await tester.pumpWidget(hostFor(svc));
    expect(find.text('問問你的 Personal Hub'), findsOneWidget);
    expect(
      find.textContaining('上次跟王經理吃飯花了多少'),
      findsOneWidget,
    );
  });

  testWidgets('empty input does not trigger a query', (tester) async {
    var llmCalls = 0;
    final svc = PersonalRagService(
      embedder: embedder,
      store: store,
      llmCompleteStream: ({
        required String systemPrompt,
        required String userPrompt,
      }) async* {
        llmCalls++;
        yield 'noop';
      },
    );
    await tester.pumpWidget(hostFor(svc));

    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    expect(llmCalls, 0);
    // Still shows the placeholder.
    expect(find.text('問問你的 Personal Hub'), findsOneWidget);
  });

  testWidgets('submitting a query renders the user bubble immediately',
      (tester) async {
    final svc = PersonalRagService(
      embedder: embedder,
      store: store,
      llmCompleteStream: ({
        required String systemPrompt,
        required String userPrompt,
      }) async* {
        yield 'fake answer';
      },
    );
    await seed();

    await tester.pumpWidget(hostFor(svc));
    await tester.enterText(find.byType(TextField), 'Wang lunch');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(find.text('Wang lunch'), findsAtLeastNWidgets(1));
  });

  testWidgets('streamed answer is appended to the answer bubble',
      (tester) async {
    final svc = PersonalRagService(
      embedder: embedder,
      store: store,
      llmCompleteStream: ({
        required String systemPrompt,
        required String userPrompt,
      }) async* {
        yield '王經理';
        yield '那次午餐';
        yield ' 250 TWD';
      },
    );
    await seed();

    await tester.pumpWidget(hostFor(svc));
    await tester.enterText(find.byType(TextField), 'Wang lunch');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.textContaining('王經理那次午餐'), findsOneWidget);
    expect(find.textContaining('250 TWD'), findsOneWidget);
  });

  testWidgets('shows source list after successful query', (tester) async {
    final svc = PersonalRagService(
      embedder: embedder,
      store: store,
      llmCompleteStream: ({
        required String systemPrompt,
        required String userPrompt,
      }) async* {
        yield 'done';
      },
    );
    await seed();

    await tester.pumpWidget(hostFor(svc));
    await tester.enterText(find.byType(TextField), 'Wang lunch');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('參考資料'), findsOneWidget);
    expect(find.textContaining('[1]'), findsOneWidget);
  });

  testWidgets('shows "no data" message when nothing matches', (tester) async {
    final svc = PersonalRagService(
      embedder: embedder,
      store: store,
      llmCompleteStream: ({
        required String systemPrompt,
        required String userPrompt,
      }) async* {
        yield 'should not be called';
      },
    );
    // Note: no seed → empty store → retrieveAcross returns []

    await tester.pumpWidget(hostFor(svc));
    await tester.enterText(find.byType(TextField), 'anything');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.textContaining('找不到相關資料'), findsOneWidget);
    // 參考資料 panel should not appear.
    expect(find.text('參考資料'), findsNothing);
  });

  testWidgets('shows error message when LLM stream throws', (tester) async {
    final svc = PersonalRagService(
      embedder: embedder,
      store: store,
      llmCompleteStream: ({
        required String systemPrompt,
        required String userPrompt,
      }) async* {
        throw Exception('ollama down');
      },
    );
    await seed();

    await tester.pumpWidget(hostFor(svc));
    await tester.enterText(find.byType(TextField), 'Wang lunch');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.textContaining('查詢失敗'), findsOneWidget);
  });
}
