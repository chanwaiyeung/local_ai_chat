// lib/models/book.dart
//
// Phase 7.1 — Library / book record model.
// Pattern A storage (matches WealthRecord): record JSON lives in
// DocChunk.metadata['data']; chunk.text holds a search-friendly summary.
// notes field is fed to PersonalRagService for "ask the books I've read".

class Book {
  Book({
    this.id = '',
    required this.title,
    this.author = '',
    this.publisher = '',
    this.isbn = '',
    this.year,
    this.coverUrl = '',
    this.coverPath = '',
    this.location = '',
    this.category = '',
    this.tags = const [],
    this.rating,
    this.notes = '',
    this.readAt,
    this.startedReadingAt,
    DateTime? addedAt,
    this.source = 'manual',
    this.metadata = const {},
    BookInteractionMetadata? interactionMetadata,
  }) : addedAt = addedAt ?? DateTime.now(),
       interactionMetadata = interactionMetadata ?? BookInteractionMetadata();

  final String id;
  final String title;
  final String author;
  final String publisher;
  final String isbn;
  final int? year;
  final String coverUrl;     // remote URL (Google Books / Open Library)
  final String coverPath;    // local file path (camera capture)
  final String location;     // shelf location e.g. "客廳書架 A-2"
  final String category;     // see BookCategory constants
  final List<String> tags;
  final double? rating;      // 0.0 - 5.0
  final String notes;        // 心得 / 摘錄 — fed to RAG
  final DateTime? readAt;    // null = not yet finished
  /// First day user marked as "started reading"; null = not started.
  final DateTime? startedReadingAt;
  final DateTime addedAt;
  final String source;       // 'manual' | 'isbn_lookup' | 'vision_extracted'
  final Map<String, dynamic> metadata;
  final BookInteractionMetadata interactionMetadata;

  bool get isRead => readAt != null; // 讀完了
  bool get isReading =>
      startedReadingAt != null && readAt == null; // 正在讀
  bool get isTbr =>
      startedReadingAt == null && readAt == null; // 還沒開始

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? publisher,
    String? isbn,
    int? year,
    String? coverUrl,
    String? coverPath,
    String? location,
    String? category,
    List<String>? tags,
    double? rating,
    String? notes,
    DateTime? readAt,
    DateTime? startedReadingAt,
    DateTime? addedAt,
    String? source,
    Map<String, dynamic>? metadata,
    BookInteractionMetadata? interactionMetadata,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      publisher: publisher ?? this.publisher,
      isbn: isbn ?? this.isbn,
      year: year ?? this.year,
      coverUrl: coverUrl ?? this.coverUrl,
      coverPath: coverPath ?? this.coverPath,
      location: location ?? this.location,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      readAt: readAt ?? this.readAt,
      startedReadingAt: startedReadingAt ?? this.startedReadingAt,
      addedAt: addedAt ?? this.addedAt,
      source: source ?? this.source,
      metadata: metadata ?? this.metadata,
      interactionMetadata: interactionMetadata ?? this.interactionMetadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'publisher': publisher,
        'isbn': isbn,
        'year': year,
        'coverUrl': coverUrl,
        'coverPath': coverPath,
        'location': location,
        'category': category,
        'tags': tags,
        'rating': rating,
        'notes': notes,
        'readAt': readAt?.toIso8601String(),
        'startedReadingAt': startedReadingAt?.toIso8601String(),
        'addedAt': addedAt.toIso8601String(),
        'source': source,
        'metadata': metadata,
        'interactionMetadata': interactionMetadata.toJson(),
      };

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      publisher: json['publisher'] as String? ?? '',
      isbn: json['isbn'] as String? ?? '',
      year: json['year'] is int ? json['year'] as int : null,
      coverUrl: json['coverUrl'] as String? ?? '',
      coverPath: json['coverPath'] as String? ?? '',
      location: json['location'] as String? ?? '',
      category: json['category'] as String? ?? '',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      rating: (json['rating'] as num?)?.toDouble(),
      notes: json['notes'] as String? ?? '',
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'] as String)
          : null,
      startedReadingAt: json['startedReadingAt'] != null
          ? DateTime.tryParse(json['startedReadingAt'] as String)
          : null,
      addedAt: json['addedAt'] != null
          ? (DateTime.tryParse(json['addedAt'] as String) ?? DateTime.now())
          : DateTime.now(),
      source: json['source'] as String? ?? 'manual',
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? const {}),
      interactionMetadata: json['interactionMetadata'] != null
          ? BookInteractionMetadata.fromJson(
              Map<String, dynamic>.from(json['interactionMetadata'] as Map))
          : null,
    );
  }

  String toSearchText() {
    final buf = StringBuffer();
    buf.write('$title $author $publisher $isbn $category $location $notes');
    for (final t in tags) {
      buf.write(' $t');
    }
    if (year != null) buf.write(' $year');
    if (rating != null) buf.write(' rating:${rating!.toStringAsFixed(1)}');
    if (isRead) {
      buf.write(' read');
    } else if (isReading) {
      buf.write(' reading');
    } else if (isTbr) {
      buf.write(' tbr');
    }
    return buf.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Book &&
        other.id == id &&
        other.title == title &&
        other.author == author &&
        other.publisher == publisher &&
        other.isbn == isbn &&
        other.year == year &&
        other.coverUrl == coverUrl &&
        other.coverPath == coverPath &&
        other.location == location &&
        other.category == category &&
        _listEquals(other.tags, tags) &&
        other.rating == rating &&
        other.notes == notes &&
        other.readAt == readAt &&
        other.startedReadingAt == startedReadingAt &&
        other.addedAt == addedAt &&
        other.source == source &&
        _mapEquals(other.metadata, metadata) &&
        other.interactionMetadata == interactionMetadata;
  }

  @override
  int get hashCode => Object.hash(
        id,
        title,
        author,
        publisher,
        isbn,
        year,
        coverUrl,
        coverPath,
        location,
        category,
        Object.hashAll(tags),
        rating,
        notes,
        readAt,
        startedReadingAt,
        addedAt,
        source,
        Object.hashAll(metadata.keys),
        interactionMetadata,
      );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  @override
  String toString() => 'Book($title by $author, isbn: $isbn)';
}

class BookInteractionMetadata {
  final String category;             // 分類模組寫入
  final List<String> tags;           // 分類模組寫入
  final String? audioSummaryPath;    // 語音模組寫入
  final DateTime? lastRead;          // 閱讀模組寫入
  final Map<String, dynamic> ragContext; // 閱讀+問答模組寫入
  final String? classificationSource; // 分類來源 (local 或 cloud)

  BookInteractionMetadata({
    this.category = '',
    this.tags = const [],
    this.audioSummaryPath,
    this.lastRead,
    this.ragContext = const {},
    this.classificationSource,
  });

  BookInteractionMetadata copyWith({
    String? category,
    List<String>? tags,
    String? audioSummaryPath,
    DateTime? lastRead,
    Map<String, dynamic>? ragContext,
    String? classificationSource,
  }) {
    return BookInteractionMetadata(
      category: category ?? this.category,
      tags: tags ?? this.tags,
      audioSummaryPath: audioSummaryPath ?? this.audioSummaryPath,
      lastRead: lastRead ?? this.lastRead,
      ragContext: ragContext ?? this.ragContext,
      classificationSource: classificationSource ?? this.classificationSource,
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'tags': tags,
        'audioSummaryPath': audioSummaryPath,
        'lastRead': lastRead?.toIso8601String(),
        'ragContext': ragContext,
        'classificationSource': classificationSource,
      };

  factory BookInteractionMetadata.fromJson(Map<String, dynamic> json) {
    return BookInteractionMetadata(
      category: json['category'] as String? ?? '',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      audioSummaryPath: json['audioSummaryPath'] as String?,
      lastRead: json['lastRead'] != null
          ? DateTime.tryParse(json['lastRead'] as String)
          : null,
      ragContext: Map<String, dynamic>.from(json['ragContext'] as Map? ?? const {}),
      classificationSource: json['classificationSource'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookInteractionMetadata &&
        other.category == category &&
        _listEquals(other.tags, tags) &&
        other.audioSummaryPath == audioSummaryPath &&
        other.lastRead == lastRead &&
        _mapEquals(other.ragContext, ragContext) &&
        other.classificationSource == classificationSource;
  }

  @override
  int get hashCode => Object.hash(
        category,
        Object.hashAll(tags),
        audioSummaryPath,
        lastRead,
        Object.hashAll(ragContext.keys),
        classificationSource,
      );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}

/// Common book categories. Use as a hint; users may store any string.
class BookCategory {
  static const String fiction = 'fiction';
  static const String nonfiction = 'nonfiction';
  static const String technical = 'technical';
  static const String history = 'history';
  static const String biography = 'biography';
  static const String religion = 'religion';
  static const String selfHelp = 'self_help';
  static const String poetry = 'poetry';
  static const String reference = 'reference';
  static const String other = 'other';

  static const List<String> all = [
    fiction,
    nonfiction,
    technical,
    history,
    biography,
    religion,
    selfHelp,
    poetry,
    reference,
    other,
  ];
}


