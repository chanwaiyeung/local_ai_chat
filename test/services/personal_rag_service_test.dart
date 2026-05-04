// test/services/personal_rag_service_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/controllers/contact_controller.dart';
import 'package:local_ai_chat/controllers/expense_controller.dart';
import 'package:local_ai_chat/models/contact.dart';
import 'package:local_ai_chat/models/expense.dart';
import 'package:local_ai_chat/models/health_record.dart';
import 'package:local_ai_chat/services/embedding_service.dart';
import 'package:local_ai_chat/services/personal_rag_service.dart';
import 'package:local_ai_chat/services/vector_store.dart';

Future<List<double>> keywordEmbed(String text) async {
  final lower = text.toLowerCase();
  return [
    lower.contains('lunch') ? 1.0 : 0.0,
    lower.contains('dinner') ? 1.0 : 0.0,
    lower.contains('albert') ? 1.0 : 0.0,
    lower.contains('wang') || lower.contains('王') ? 1.0 : 0.0,
    1.0,
  ];
}

class ShortBatchEmbeddingService extends EmbeddingService {
  ShortBatchEmbeddingService() : super(embedFn: (_) async => const [1.0]);

  @override
  Future<List<List<double>>> embedAll(
    List<String> texts, {
    void Function(int done, int total)? onProgress,
  }) async {
    if (texts.isEmpty) return const [];
    return [
      for (var i = 0; i < texts.length - 1; i++) [1.0, 0.0],
    ];
  }
}

void main() {
  late Directory tempDir;
  late VectorStore store;
  late EmbeddingService embedder;
  late ExpenseController expenseController;
  late ContactController contactController;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('personal_rag_');
    store = VectorStore(
      storagePath: '${tempDir.path}${Platform.pathSeparator}vstore.json',
    );
    embedder = EmbeddingService(embedFn: keywordEmbed);
    expenseController = ExpenseController(store);
    contactController = ContactController(store: store);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> seed(PersonalRagService service) async {
    await expenseController.saveExpense(
      Expense(
        id: 'lunch_with_wang',
        amount: 250,
        currency: 'TWD',
        category: 'Meals',
        notes: 'lunch with Wang',
        date: DateTime(2026, 5, 1),
      ),
    );
    await expenseController.saveExpense(
      Expense(
        id: 'dinner_with_albert',
        amount: 500,
        currency: 'TWD',
        category: 'Meals',
        notes: 'dinner with Albert',
        date: DateTime(2026, 5, 2),
      ),
    );
    await contactController.saveContact(
      Contact(
        id: 'wang_card',
        name: 'Wang Manager',
        company: 'Beta Co',
        title: 'Manager',
        scannedAt: DateTime(2026, 5, 1),
      ),
    );
    await service.reindexAll();
  }

  group('PersonalRagService reindex', () {
    test('reindexCollection assigns real embeddings to all chunks', () async {
      await expenseController.saveExpense(
        Expense(
          id: 'e1',
          amount: 250,
          date: DateTime(2026, 5, 1),
          notes: 'lunch with Wang',
        ),
      );
      await expenseController.saveExpense(
        Expense(
          id: 'e2',
          amount: 500,
          date: DateTime(2026, 5, 2),
          notes: 'dinner with Albert',
        ),
      );

      final service = PersonalRagService(embedder: embedder, store: store);
      final count = await service.reindexCollection(
        PersonalRagService.kExpensesCollection,
      );

      expect(count, 2);
      final chunks =
          store.chunksInCollection(PersonalRagService.kExpensesCollection);
      expect(chunks, hasLength(2));
      for (final chunk in chunks) {
        expect(chunk.embedding, hasLength(5));
        expect(chunk.embedding.every((value) => value == 0.0), isFalse);
      }
    });

    test('reindexCollection on empty collection returns 0', () async {
      final service = PersonalRagService(embedder: embedder, store: store);
      expect(await service.reindexCollection('Empty'), 0);
    });

    test('reindexCollection skips batch when embedAll length mismatches',
        () async {
      await store.addToCollection(
        PersonalRagService.kExpensesCollection,
        DocChunk(
          id: 'mismatch_1',
          docName: 'mismatch_1',
          chunkIndex: 0,
          text: 'lunch',
          embedding: const [0.0],
          collectionName: PersonalRagService.kExpensesCollection,
        ),
      );
      await store.addToCollection(
        PersonalRagService.kExpensesCollection,
        DocChunk(
          id: 'mismatch_2',
          docName: 'mismatch_2',
          chunkIndex: 1,
          text: 'dinner',
          embedding: const [0.0],
          collectionName: PersonalRagService.kExpensesCollection,
        ),
      );

      final service = PersonalRagService(
        embedder: ShortBatchEmbeddingService(),
        store: store,
      );

      expect(
        await service.reindexCollection(PersonalRagService.kExpensesCollection),
        0,
      );
      final chunks =
          store.chunksInCollection(PersonalRagService.kExpensesCollection);
      expect(chunks, hasLength(2));
      expect(chunks.every((chunk) => chunk.embedding.length == 1), isTrue);
      expect(chunks.every((chunk) => chunk.embedding.single == 0.0), isTrue);
    });

    test('reindexMissingEmbeddings only touches empty or zero vectors',
        () async {
      await store.addToCollection(
        PersonalRagService.kContactsCollection,
        DocChunk(
          id: 'real',
          docName: 'real',
          chunkIndex: 0,
          text: 'Existing Albert contact',
          embedding: const [0.5, 0.5, 0.0, 0.0, 1.0],
          collectionName: PersonalRagService.kContactsCollection,
          metadata: Contact(id: 'real', name: 'Existing').toJson(),
        ),
      );
      await contactController.saveContact(
        Contact(id: 'missing', name: 'Missing Wang'),
      );

      final service = PersonalRagService(embedder: embedder, store: store);
      final count = await service.reindexMissingEmbeddings();

      expect(count, 1);
      final chunks =
          store.chunksInCollection(PersonalRagService.kContactsCollection);
      final byDocName = {for (final chunk in chunks) chunk.docName: chunk};
      expect(byDocName['real']!.embedding, [0.5, 0.5, 0.0, 0.0, 1.0]);
      expect(byDocName['missing']!.embedding, hasLength(5));
      expect(byDocName['missing']!.embedding.every((value) => value == 0.0),
          isFalse);
    });

    test('reindexMissingEmbeddings treats 384-dim all-zero vectors as missing',
        () async {
      await store.addToCollection(
        PersonalRagService.kExpensesCollection,
        DocChunk(
          id: 'zero',
          docName: 'expense_zero',
          chunkIndex: 0,
          text: 'lunch',
          embedding: List.filled(384, 0.0),
          collectionName: PersonalRagService.kExpensesCollection,
          metadata: {
            'type': ExpenseController.kExpenseTypeTag,
            'data': Expense(
              id: 'zero',
              amount: 100,
              date: DateTime(2026, 5, 1),
              notes: 'lunch',
            ).toJson(),
          },
        ),
      );

      final service = PersonalRagService(embedder: embedder, store: store);
      expect(await service.reindexMissingEmbeddings(), 1);

      final chunks =
          store.chunksInCollection(PersonalRagService.kExpensesCollection);
      expect(chunks.single.embedding, hasLength(5));
      expect(chunks.single.embedding.every((value) => value == 0.0), isFalse);
    });

    test('reindexMissingEmbeddings skips batch when embedAll length mismatches',
        () async {
      await store.addToCollection(
        PersonalRagService.kContactsCollection,
        DocChunk(
          id: 'missing_1',
          docName: 'missing_1',
          chunkIndex: 0,
          text: 'Albert',
          embedding: const [],
          collectionName: PersonalRagService.kContactsCollection,
          metadata: Contact(id: 'missing_1', name: 'Albert').toJson(),
        ),
      );
      await store.addToCollection(
        PersonalRagService.kContactsCollection,
        DocChunk(
          id: 'missing_2',
          docName: 'missing_2',
          chunkIndex: 1,
          text: 'Wang',
          embedding: const [],
          collectionName: PersonalRagService.kContactsCollection,
          metadata: Contact(id: 'missing_2', name: 'Wang').toJson(),
        ),
      );

      final service = PersonalRagService(
        embedder: ShortBatchEmbeddingService(),
        store: store,
      );

      expect(await service.reindexMissingEmbeddings(), 0);
      final chunks =
          store.chunksInCollection(PersonalRagService.kContactsCollection);
      expect(chunks, hasLength(2));
      expect(chunks.every((chunk) => chunk.embedding.isEmpty), isTrue);
    });

    test('reindexAll covers default Personal Hub collections', () async {
      await expenseController.saveExpense(
        Expense(id: 'e1', amount: 1, date: DateTime(2026, 5, 1)),
      );
      await contactController.saveContact(
        Contact(id: 'c1', name: 'Albert'),
      );

      final service = PersonalRagService(embedder: embedder, store: store);

      expect(await service.reindexAll(), 2);
    });

    test('reindex preserves chunk id and text', () async {
      await expenseController.saveExpense(
        Expense(
          id: 'preserve_me',
          amount: 99,
          date: DateTime(2026, 5, 1),
          notes: 'lunch',
        ),
      );

      final service = PersonalRagService(embedder: embedder, store: store);
      await service.reindexAll();

      final chunks =
          store.chunksInCollection(PersonalRagService.kExpensesCollection);
      expect(chunks.single.id, 'preserve_me');
      expect(chunks.single.text, contains('lunch'));
    });

    test('uses Expense metadata data when building reindex text', () async {
      final captured = <String>[];
      final spyEmbedder = EmbeddingService(embedFn: (text) async {
        captured.add(text);
        return keywordEmbed(text);
      });
      await store.addToCollection(
        PersonalRagService.kExpensesCollection,
        DocChunk(
          id: 'expense_metadata',
          docName: 'expense_metadata',
          chunkIndex: 0,
          text: 'opaque display text',
          collectionName: PersonalRagService.kExpensesCollection,
          metadata: {
            'type': ExpenseController.kExpenseTypeTag,
            'data': Expense(
              id: 'expense_metadata',
              amount: 88,
              currency: 'TWD',
              category: 'Meals',
              notes: 'sushi lunch',
              date: DateTime(2026, 5, 3),
            ).toJson(),
          },
        ),
      );

      final service = PersonalRagService(embedder: spyEmbedder, store: store);
      await service.reindexCollection(PersonalRagService.kExpensesCollection);

      expect(captured.single, contains('Meals'));
      expect(captured.single, contains('sushi lunch'));
      expect(captured.single, contains('88'));
      expect(captured.single, isNot(contains('opaque display text')));
    });

    test('uses Health JSON text when building reindex text', () async {
      final captured = <String>[];
      final spyEmbedder = EmbeddingService(embedFn: (text) async {
        captured.add(text);
        return keywordEmbed(text);
      });
      final health = HealthRecord(
        id: 'health_1',
        date: DateTime(2026, 5, 3),
        weight: 70,
        systolic: 120,
        diastolic: 80,
        steps: 8000,
        notes: 'after walk',
        dateAdded: DateTime(2026, 5, 3),
      );
      await store.addToCollection(
        PersonalRagService.kHealthCollection,
        DocChunk(
          id: health.id,
          docName: health.id,
          chunkIndex: 0,
          text: health.encode(),
          collectionName: PersonalRagService.kHealthCollection,
        ),
      );

      final service = PersonalRagService(embedder: spyEmbedder, store: store);
      await service.reindexCollection(PersonalRagService.kHealthCollection);

      expect(captured.single, contains('weight 70'));
      expect(captured.single, contains('blood pressure 120/80'));
      expect(captured.single, contains('8000 steps'));
      expect(captured.single, contains('after walk'));
    });

    test('uses Contact metadata when building reindex text', () async {
      final captured = <String>[];
      final spyEmbedder = EmbeddingService(embedFn: (text) async {
        captured.add(text);
        return keywordEmbed(text);
      });
      await store.addToCollection(
        PersonalRagService.kContactsCollection,
        DocChunk(
          id: 'contact_metadata',
          docName: 'contact_metadata',
          chunkIndex: 0,
          text: 'opaque display text',
          collectionName: PersonalRagService.kContactsCollection,
          metadata: Contact(
            id: 'contact_metadata',
            name: 'Ada Chen',
            company: 'Delta Co',
            title: 'Manager',
            email: 'ada@example.com',
          ).toJson(),
        ),
      );

      final service = PersonalRagService(embedder: spyEmbedder, store: store);
      await service.reindexCollection(PersonalRagService.kContactsCollection);

      expect(captured.single, contains('Ada Chen'));
      expect(captured.single, contains('Delta Co'));
      expect(captured.single, contains('Manager'));
      expect(captured.single, contains('ada@example.com'));
      expect(captured.single, isNot(contains('opaque display text')));
    });

    test('uses Wealth metadata data when available', () async {
      final captured = <String>[];
      final spyEmbedder = EmbeddingService(embedFn: (text) async {
        captured.add(text);
        return keywordEmbed(text);
      });
      await store.addToCollection(
        PersonalRagService.kWealthCollection,
        DocChunk(
          id: 'wealth_metadata',
          docName: 'wealth_metadata',
          chunkIndex: 0,
          text: '股票 AAPL 1000.00 USD 長期投資',
          collectionName: PersonalRagService.kWealthCollection,
          metadata: {
            'type': 'personal_hub_wealth',
            'data': {
              'id': 'wealth_metadata',
              'date': DateTime(2026, 5, 3).toIso8601String(),
              'assetType': 'stock',
              'assetName': 'AAPL',
              'amount': 1000,
              'currency': 'USD',
              'notes': '長期投資',
              'dateAdded': DateTime(2026, 5, 3).toIso8601String(),
            },
          },
        ),
      );

      final service = PersonalRagService(embedder: spyEmbedder, store: store);
      await service.reindexCollection(PersonalRagService.kWealthCollection);

      expect(captured.single, contains('股票'));
      expect(captured.single, contains('stock'));
      expect(captured.single, contains('AAPL'));
      expect(captured.single, contains('1000.00 USD'));
      expect(captured.single, contains('長期投資'));
      expect(captured.single, isNot(contains('opaque')));
    });

    test('malformed JSON text falls back to raw text', () async {
      final captured = <String>[];
      final spyEmbedder = EmbeddingService(embedFn: (text) async {
        captured.add(text);
        return keywordEmbed(text);
      });
      await store.addToCollection(
        PersonalRagService.kHealthCollection,
        DocChunk(
          id: 'bad_health',
          docName: 'bad_health',
          chunkIndex: 0,
          text: '{"date":',
          collectionName: PersonalRagService.kHealthCollection,
        ),
      );

      final service = PersonalRagService(embedder: spyEmbedder, store: store);
      await service.reindexCollection(PersonalRagService.kHealthCollection);

      expect(captured.single, '{"date":');
    });

    test('unknown metadata type falls back to raw text', () async {
      final captured = <String>[];
      final spyEmbedder = EmbeddingService(embedFn: (text) async {
        captured.add(text);
        return keywordEmbed(text);
      });
      await store.addToCollection(
        'Unknown',
        DocChunk(
          id: 'unknown_1',
          docName: 'unknown_1',
          chunkIndex: 0,
          text: 'plain unknown record',
          collectionName: 'Unknown',
          metadata: {'type': 'future_module'},
        ),
      );

      final service = PersonalRagService(embedder: spyEmbedder, store: store);
      await service.reindexCollection('Unknown');

      expect(captured.single, 'plain unknown record');
    });
  });

  group('PersonalRagService retrieveAcross', () {
    test('returns hits from multiple collections', () async {
      final service = PersonalRagService(embedder: embedder, store: store);
      await seed(service);

      final hits = await service.retrieveAcross(query: 'Wang lunch', k: 4);
      final collections = hits.map((hit) => hit.chunk.collectionName).toSet();

      expect(
          collections.contains(PersonalRagService.kExpensesCollection), isTrue);
      expect(
          collections.contains(PersonalRagService.kContactsCollection), isTrue);
    });

    test('sorts by descending cosine score', () async {
      final service = PersonalRagService(embedder: embedder, store: store);
      await seed(service);

      final hits = await service.retrieveAcross(query: 'Wang lunch', k: 4);

      for (var i = 1; i < hits.length; i++) {
        expect(hits[i].score, lessThanOrEqualTo(hits[i - 1].score));
      }
    });

    test('respects minScore', () async {
      final service = PersonalRagService(embedder: embedder, store: store);
      await seed(service);

      final hits = await service.retrieveAcross(
        query: 'Wang lunch',
        k: 10,
        minScore: 1.01,
      );

      expect(hits, isEmpty);
    });

    test('empty query returns empty result without calling embedder', () async {
      var calls = 0;
      final spyEmbedder = EmbeddingService(embedFn: (text) async {
        calls++;
        return keywordEmbed(text);
      });
      final service = PersonalRagService(embedder: spyEmbedder, store: store);

      expect(await service.retrieveAcross(query: '   '), isEmpty);
      expect(calls, 0);
    });

    test('respects custom collections override', () async {
      final service = PersonalRagService(embedder: embedder, store: store);
      await seed(service);

      final hits = await service.retrieveAcross(
        query: 'Wang lunch',
        collectionsOverride: [PersonalRagService.kContactsCollection],
        k: 4,
      );

      expect(hits, isNotEmpty);
      expect(
        hits.every((hit) =>
            hit.chunk.collectionName == PersonalRagService.kContactsCollection),
        isTrue,
      );
    });
  });

  group('PersonalRagService answer', () {
    test('throws when llmComplete is not wired', () async {
      final service = PersonalRagService(embedder: embedder, store: store);

      await expectLater(
        service.answer(query: 'anything'),
        throwsA(isA<StateError>()),
      );
    });

    test('returns no-data message when no hits', () async {
      final service = PersonalRagService(
        embedder: embedder,
        store: store,
        llmComplete: ({
          required String systemPrompt,
          required String userPrompt,
        }) async =>
            'should not be called',
      );

      final answer = await service.answer(query: 'something');

      expect(answer.hits, isEmpty);
      expect(answer.text, contains('找不到相關資料'));
    });

    test('forwards retrieved context to llmComplete and returns reply',
        () async {
      String? capturedSystem;
      String? capturedUser;
      final service = PersonalRagService(
        embedder: embedder,
        store: store,
        llmComplete: ({
          required String systemPrompt,
          required String userPrompt,
        }) async {
          capturedSystem = systemPrompt;
          capturedUser = userPrompt;
          return '王經理那次午餐是 250 TWD（依據 (1)）';
        },
      );
      await expenseController.saveExpense(
        Expense(
          id: 'e1',
          amount: 250,
          currency: 'TWD',
          date: DateTime(2026, 5, 1),
          notes: 'lunch with Wang',
        ),
      );
      await service.reindexAll();

      final answer = await service.answer(query: '上次跟 Wang 吃 lunch 花多少？');

      expect(answer.text, contains('250'));
      expect(answer.hits, isNotEmpty);
      expect(capturedSystem, contains('Personal Hub'));
      expect(capturedUser, contains('lunch with Wang'));
      expect(capturedUser, contains('使用者問題'));
    });

    test('answerStream throws when llmCompleteStream is not wired', () async {
      final service = PersonalRagService(embedder: embedder, store: store);

      await expectLater(
        service.answerStream(query: 'x').toList(),
        throwsA(isA<StateError>()),
      );
    });

    test('answerStream emits no-data message when no hits', () async {
      final service = PersonalRagService(
        embedder: embedder,
        store: store,
        llmCompleteStream: ({
          required String systemPrompt,
          required String userPrompt,
        }) async* {
          yield 'should not be called';
        },
      );

      final output = await service.answerStream(query: 'anything').toList();

      expect(output, hasLength(1));
      expect(output.single, contains('找不到相關資料'));
    });
  });
}
