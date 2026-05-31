// lib/controllers/book_controller.dart
import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../services/classification_service.dart';
import '../services/vector_store.dart';

class BookController extends ChangeNotifier {
  BookController(this._store);

  static const String kBookCollection = 'Books';
  static const String kBookTypeTag = 'personal_hub_book';

  final VectorStore _store;
  List<Book> _books = const [];
  bool _loaded = false;
  bool _isProcessingBackground = false;
  bool get isProcessingBackground => _isProcessingBackground;

  // ---------- lifecycle ----------
  Future<void> loadAll() async {
    final out = <Book>[];
    for (final c in _store.chunks) {
      if (c.collectionName != kBookCollection) continue;
      if (c.metadata['type'] != kBookTypeTag) continue;
      final data = c.metadata['data'];
      if (data is! Map) continue;
      try {
        out.add(Book.fromJson(Map<String, dynamic>.from(data)));
      } catch (_) {}
    }
    out.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    _books = List.unmodifiable(out);
    _calculateStatistics();
    _loaded = true;
    notifyListeners();
  }

  bool get isLoaded => _loaded;

  Map<String, int> _tagStatistics = const {};
  Map<String, int> get tagStatistics => _tagStatistics;

  void _calculateStatistics() {
    final Map<String, int> counts = {};
    for (final book in _books) {
      final tags = book.interactionMetadata.tags;
      for (final tag in tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    _tagStatistics = Map.unmodifiable(counts);
  }

  String? _sourceFilter;
  String? get sourceFilter => _sourceFilter;

  void setSourceFilter(String? source) {
    _sourceFilter = source;
    notifyListeners();
  }

  List<Book> get filteredBooks {
    if (_sourceFilter == null || _sourceFilter!.isEmpty) {
      return _books;
    }
    return _books
        .where((b) => b.interactionMetadata.classificationSource == _sourceFilter)
        .toList();
  }

  // ---------- reads ----------
  List<Book> getAllBooks() => _books;
  int get count => _books.length;
  int get readCount => _books.where((b) => b.isRead).length;
  int get unreadCount => _books.where((b) => !b.isRead).length;
  int get readingCount => _books.where((b) => b.isReading).length;
  int get tbrCount => _books.where((b) => b.isTbr).length;

  Book? findById(String id) {
    for (final b in _books) {
      if (b.id == id) return b;
    }
    return null;
  }

  List<Book> searchBooks(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _books;
    return _books
        .where((b) => b.toSearchText().toLowerCase().contains(q))
        .toList();
  }

  List<String> getCategories() {
    final set = <String>{
      for (final b in _books)
        if (b.category.isNotEmpty) b.category,
    };
    final list = set.toList()..sort();
    return list;
  }

  List<String> getLocations() {
    final set = <String>{
      for (final b in _books)
        if (b.location.isNotEmpty) b.location,
    };
    final list = set.toList()..sort();
    return list;
  }

  List<String> getAllTags() {
    final set = <String>{
      for (final b in _books)
        for (final t in b.tags) t,
    };
    final list = set.toList()..sort();
    return list;
  }

  List<Book> filterByCategory(String category) =>
      _books.where((b) => b.category == category).toList();

  List<Book> filterByLocation(String location) =>
      _books.where((b) => b.location == location).toList();

  List<Book> filterByReadStatus({required bool read}) =>
      _books.where((b) => b.isRead == read).toList();

  // ---------- writes (Pattern A: delete + add) ----------
  Future<Book> saveBook(Book book) async {
    final isNew = book.id.isEmpty;
    var finalBook = isNew ? book.copyWith(id: _generateId()) : book;

    if (isNew) {
      try {
        final textForClassification = finalBook.notes.trim().isNotEmpty
            ? finalBook.notes
            : '${finalBook.title} ${finalBook.author}';
        final result = await ClassificationService().classifyBook(textForClassification);
        final updatedMetadata = finalBook.interactionMetadata.copyWith(
          category: result.category,
          tags: result.tags,
          classificationSource: result.source,
        );
        finalBook = finalBook.copyWith(
          category: result.category.isNotEmpty ? result.category : finalBook.category,
          tags: {...finalBook.tags, ...result.tags}.toList(),
          metadata: result.toJson(),
          interactionMetadata: updatedMetadata,
        );
      } catch (e) {
        debugPrint('Auto-classification failed: $e');
      }
    }

    await _persistAndLoad(finalBook);
    return finalBook;
  }

  Future<void> _persistAndLoad(Book book) async {
    await _store.deleteById(book.id);
    final chunk = DocChunk(
      id: book.id,
      docName: 'book_${book.id}',
      chunkIndex: 0,
      text: book.toSearchText(),
      embedding: const [],
      collectionName: kBookCollection,
      metadata: {
        'type': kBookTypeTag,
        'data': book.toJson(),
      },
    );
    await _store.add(chunk);
    await _store.save();
    await loadAll();
  }

  Future<void> updateClassification(String bookId, String category, List<String> tags, {String classificationSource = 'local'}) async {
    final book = findById(bookId);
    if (book == null) throw ArgumentError('Book not found: $bookId');
    final updatedMetadata = book.interactionMetadata.copyWith(
      category: category,
      tags: tags,
      classificationSource: classificationSource,
    );
    final updatedBook = book.copyWith(
      category: category,
      tags: tags,
      interactionMetadata: updatedMetadata,
    );
    await _persistAndLoad(updatedBook);
  }

  Future<void> updateAudioCache(String bookId, String filePath) async {
    final book = findById(bookId);
    if (book == null) throw ArgumentError('Book not found: $bookId');
    final updatedMetadata = book.interactionMetadata.copyWith(
      audioSummaryPath: filePath,
    );
    final updatedBook = book.copyWith(
      interactionMetadata: updatedMetadata,
    );
    await _persistAndLoad(updatedBook);
  }

  Future<void> syncReadingContext(String bookId, Map<String, dynamic> context) async {
    final book = findById(bookId);
    if (book == null) throw ArgumentError('Book not found: $bookId');
    final updatedMetadata = book.interactionMetadata.copyWith(
      ragContext: context,
      lastRead: DateTime.now(),
    );
    final updatedBook = book.copyWith(
      interactionMetadata: updatedMetadata,
    );
    await _persistAndLoad(updatedBook);
  }

  Future<void> processUnclassifiedBooks({ClassificationService? classificationService}) async {
    if (_isProcessingBackground) return;
    _isProcessingBackground = true;
    notifyListeners();

    final service = classificationService ?? ClassificationService();

    try {
      final unclassified = _books.where((b) => b.interactionMetadata.classificationSource == null).toList();
      for (final book in unclassified) {
        final currentBook = findById(book.id);
        if (currentBook == null || currentBook.interactionMetadata.classificationSource != null) {
          continue;
        }

        await Future.delayed(const Duration(milliseconds: 500));

        try {
          final text = currentBook.notes.trim().isNotEmpty
              ? currentBook.notes
              : '${currentBook.title} ${currentBook.author}';
          final result = await service.classifyBook(text);
          await updateClassification(
            currentBook.id,
            result.category,
            result.tags,
            classificationSource: result.source,
          );
        } catch (e) {
          debugPrint('Lazy classification failed for book ${book.title}: $e');
        }
      }
    } finally {
      _isProcessingBackground = false;
      notifyListeners();
    }
  }

  Future<void> deleteBook(String id) async {
    await _store.deleteById(id);
    await _store.save();
    await loadAll();
  }

  String _generateId() => 'book_${DateTime.now().microsecondsSinceEpoch}';
}


