// test/models/book_interaction_metadata_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/models/book.dart';

void main() {
  group('BookInteractionMetadata Tests', () {
    test('default constructor initializes with correct defaults', () {
      final meta = BookInteractionMetadata();
      expect(meta.category, '');
      expect(meta.tags, isEmpty);
      expect(meta.audioSummaryPath, isNull);
      expect(meta.lastRead, isNull);
      expect(meta.ragContext, isEmpty);
    });

    test('copyWith updates values correctly', () {
      final meta = BookInteractionMetadata();
      final now = DateTime.now();
      
      final updated = meta.copyWith(
        category: 'technical',
        tags: ['flutter', 'dart'],
        audioSummaryPath: '/path/to/audio.mp3',
        lastRead: now,
        ragContext: {'last_pos': 42},
      );

      expect(updated.category, 'technical');
      expect(updated.tags, ['flutter', 'dart']);
      expect(updated.audioSummaryPath, '/path/to/audio.mp3');
      expect(updated.lastRead, now);
      expect(updated.ragContext, {'last_pos': 42});
    });

    test('JSON serialization/deserialization roundtrip in Book', () {
      final lastReadTime = DateTime(2026, 5, 27, 10, 0, 0);
      final meta = BookInteractionMetadata(
        category: 'fiction',
        tags: ['scifi', 'classic'],
        audioSummaryPath: '/local/media/book1.mp3',
        lastRead: lastReadTime,
        ragContext: {'query_count': 15, 'tokens': 512},
      );

      final book = Book(
        title: 'Dune',
        author: 'Frank Herbert',
        interactionMetadata: meta,
      );

      // Serialize
      final jsonMap = book.toJson();
      expect(jsonMap.containsKey('interactionMetadata'), isTrue);
      
      final metaJson = jsonMap['interactionMetadata'] as Map<String, dynamic>;
      expect(metaJson['category'], 'fiction');
      expect(metaJson['tags'], ['scifi', 'classic']);
      expect(metaJson['audioSummaryPath'], '/local/media/book1.mp3');
      expect(metaJson['lastRead'], lastReadTime.toIso8601String());
      expect(metaJson['ragContext'], {'query_count': 15, 'tokens': 512});

      // Deserialize
      final deserializedBook = Book.fromJson(jsonMap);
      expect(deserializedBook, equals(book));
      expect(deserializedBook.interactionMetadata.category, 'fiction');
      expect(deserializedBook.interactionMetadata.tags, ['scifi', 'classic']);
      expect(deserializedBook.interactionMetadata.audioSummaryPath, '/local/media/book1.mp3');
      expect(deserializedBook.interactionMetadata.lastRead, lastReadTime);
      expect(deserializedBook.interactionMetadata.ragContext, {'query_count': 15, 'tokens': 512});
    });

    test('default book contains empty BookInteractionMetadata', () {
      final book = Book(title: 'Test Book');
      expect(book.interactionMetadata, isNotNull);
      expect(book.interactionMetadata.category, '');
      expect(book.interactionMetadata.tags, isEmpty);
      expect(book.interactionMetadata.audioSummaryPath, isNull);
      expect(book.interactionMetadata.lastRead, isNull);
      expect(book.interactionMetadata.ragContext, isEmpty);
    });
  });
}


