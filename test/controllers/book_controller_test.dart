// test/controllers/book_controller_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/controllers/book_controller.dart';
import 'package:local_ai_chat/models/book.dart';
import 'package:local_ai_chat/services/classification_service.dart';
import 'package:local_ai_chat/services/vector_store.dart';

void main() {
  group('BookController Interaction API Tests', () {
    late Directory tempDir;
    late VectorStore store;
    late BookController controller;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('book_controller_test_');
      store = VectorStore(
        storagePath: '${tempDir.path}${Platform.pathSeparator}vstore.json',
      );
      controller = BookController(store);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('updateClassification updates book category and tags, then persists', () async {
      // Create a book with empty classification
      final book = Book(
        id: 'book_1',
        title: 'Original Title',
        category: '',
        tags: const [],
      );

      // Add to store chunk manually, then load
      final chunk = DocChunk(
        id: book.id,
        docName: 'book_${book.id}',
        chunkIndex: 0,
        text: book.toSearchText(),
        collectionName: BookController.kBookCollection,
        metadata: {
          'type': BookController.kBookTypeTag,
          'data': book.toJson(),
        },
      );
      await store.add(chunk);
      await controller.loadAll();

      expect(controller.getAllBooks().length, 1);
      expect(controller.getAllBooks().first.category, '');

      // Trigger updateClassification
      bool listenerNotified = false;
      controller.addListener(() {
        listenerNotified = true;
      });

      await controller.updateClassification('book_1', 'technical', ['flutter', 'dart'], classificationSource: 'cloud');

      expect(listenerNotified, isTrue);
      final updated = controller.findById('book_1')!;
      expect(updated.category, 'technical');
      expect(updated.tags, ['flutter', 'dart']);
      expect(updated.interactionMetadata.category, 'technical');
      expect(updated.interactionMetadata.tags, ['flutter', 'dart']);
      expect(updated.interactionMetadata.classificationSource, 'cloud');
    });

    test('updateAudioCache updates audioSummaryPath and persists', () async {
      final book = Book(id: 'book_2', title: 'Audio Book');
      final chunk = DocChunk(
        id: book.id,
        docName: 'book_${book.id}',
        chunkIndex: 0,
        text: book.toSearchText(),
        collectionName: BookController.kBookCollection,
        metadata: {
          'type': BookController.kBookTypeTag,
          'data': book.toJson(),
        },
      );
      await store.add(chunk);
      await controller.loadAll();

      bool listenerNotified = false;
      controller.addListener(() {
        listenerNotified = true;
      });

      await controller.updateAudioCache('book_2', '/cached/audio/file.mp3');

      expect(listenerNotified, isTrue);
      final updated = controller.findById('book_2')!;
      expect(updated.interactionMetadata.audioSummaryPath, '/cached/audio/file.mp3');
    });

    test('syncReadingContext updates ragContext, lastRead and persists', () async {
      final book = Book(id: 'book_3', title: 'RAG Book');
      final chunk = DocChunk(
        id: book.id,
        docName: 'book_${book.id}',
        chunkIndex: 0,
        text: book.toSearchText(),
        collectionName: BookController.kBookCollection,
        metadata: {
          'type': BookController.kBookTypeTag,
          'data': book.toJson(),
        },
      );
      await store.add(chunk);
      await controller.loadAll();

      bool listenerNotified = false;
      controller.addListener(() {
        listenerNotified = true;
      });

      final customContext = {'current_chapter': 5, 'highlights': ['quote1']};
      await controller.syncReadingContext('book_3', customContext);

      expect(listenerNotified, isTrue);
      final updated = controller.findById('book_3')!;
      expect(updated.interactionMetadata.ragContext, customContext);
      expect(updated.interactionMetadata.lastRead, isNotNull);
      // Verify lastRead is recent
      final timeDiff = DateTime.now().difference(updated.interactionMetadata.lastRead!);
      expect(timeDiff.inSeconds, lessThan(5));
    });

    test('tagStatistics counts and updates tag frequencies correctly', () async {
      final book1 = Book(
        id: 'book_1',
        title: 'Book 1',
        interactionMetadata: BookInteractionMetadata(tags: const ['Flutter', 'Dart']),
      );
      final book2 = Book(
        id: 'book_2',
        title: 'Book 2',
        interactionMetadata: BookInteractionMetadata(tags: const ['Flutter', 'RAG']),
      );

      await store.add(DocChunk(
        id: book1.id,
        docName: 'book_${book1.id}',
        chunkIndex: 0,
        text: book1.toSearchText(),
        collectionName: BookController.kBookCollection,
        metadata: {
          'type': BookController.kBookTypeTag,
          'data': book1.toJson(),
        },
      ));
      await store.add(DocChunk(
        id: book2.id,
        docName: 'book_${book2.id}',
        chunkIndex: 0,
        text: book2.toSearchText(),
        collectionName: BookController.kBookCollection,
        metadata: {
          'type': BookController.kBookTypeTag,
          'data': book2.toJson(),
        },
      ));

      await controller.loadAll();

      expect(controller.tagStatistics, {
        'Flutter': 2,
        'Dart': 1,
        'RAG': 1,
      });

      // Update classification on book 1 to change tags
      await controller.updateClassification('book_1', 'technical', const ['Dart', 'AI']);

      expect(controller.tagStatistics, {
        'Dart': 1,
        'AI': 1,
        'Flutter': 1,
        'RAG': 1,
      });
    });

    test('processUnclassifiedBooks sequentially processes unclassified books and updates source', () async {
      final book1 = Book(
        id: 'book_1',
        title: 'Book 1',
        interactionMetadata: BookInteractionMetadata(classificationSource: null),
      );
      final book2 = Book(
        id: 'book_2',
        title: 'Book 2',
        interactionMetadata: BookInteractionMetadata(classificationSource: 'local'),
      );

      await store.add(DocChunk(
        id: book1.id,
        docName: 'book_${book1.id}',
        chunkIndex: 0,
        text: book1.toSearchText(),
        collectionName: BookController.kBookCollection,
        metadata: {
          'type': BookController.kBookTypeTag,
          'data': book1.toJson(),
        },
      ));
      await store.add(DocChunk(
        id: book2.id,
        docName: 'book_${book2.id}',
        chunkIndex: 0,
        text: book2.toSearchText(),
        collectionName: BookController.kBookCollection,
        metadata: {
          'type': BookController.kBookTypeTag,
          'data': book2.toJson(),
        },
      ));

      await controller.loadAll();
      expect(controller.findById('book_1')!.interactionMetadata.classificationSource, isNull);
      expect(controller.findById('book_2')!.interactionMetadata.classificationSource, 'local');

      final fakeService = _FakeClassificationService();

      // Run background processing
      final future = controller.processUnclassifiedBooks(classificationService: fakeService);
      expect(controller.isProcessingBackground, isTrue);
      await future;
      expect(controller.isProcessingBackground, isFalse);

      final updated1 = controller.findById('book_1')!;
      expect(updated1.interactionMetadata.classificationSource, 'local');
      expect(updated1.category, 'fiction');
      expect(updated1.tags, const ['novel', 'adventure']);
    });
  });
}

class _FakeClassificationService extends Fake implements ClassificationService {
  @override
  Future<ClassificationResult> classifyBook(String text) async {
    return const ClassificationResult(
      category: 'fiction',
      tags: ['novel', 'adventure'],
      source: 'local',
    );
  }
}


