// lib/controllers/book_controller.dart
import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../services/vector_store.dart';

class BookController extends ChangeNotifier {
  BookController(this._store);

  static const String kBookCollection = 'Books';
  static const String kBookTypeTag = 'personal_hub_book';

  final VectorStore _store;
  List<Book> _books = const [];
  bool _loaded = false;

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
    _loaded = true;
    notifyListeners();
  }

  bool get isLoaded => _loaded;

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
    final finalBook = isNew ? book.copyWith(id: _generateId()) : book;

    if (!isNew) {
      await _store.deleteById(finalBook.id);
    }

    final chunk = DocChunk(
      id: finalBook.id,
      docName: 'book_${finalBook.id}',
      chunkIndex: 0,
      text: finalBook.toSearchText(),
      embedding: const [],
      collectionName: kBookCollection,
      metadata: {
        'type': kBookTypeTag,
        'data': finalBook.toJson(),
      },
    );

    await _store.add(chunk);
    await _store.save();
    await loadAll();
    return finalBook;
  }

  Future<void> deleteBook(String id) async {
    await _store.deleteById(id);
    await _store.save();
    await loadAll();
  }

  String _generateId() => 'book_${DateTime.now().microsecondsSinceEpoch}';
}
