import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/book.dart';

class BookIsbnService {
  static Future<Book?> lookup(String isbn) async {
    final normalized = _normalizeIsbn(isbn);
    if (normalized.isEmpty) return null;

    final uri = Uri.https(
      'www.googleapis.com',
      '/books/v1/volumes',
      {'q': 'isbn:$normalized'},
    );

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;

      final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final items = data['items'];
      if (items is! List || items.isEmpty) return null;

      final first = items.first;
      if (first is! Map) return null;

      final volumeInfo = first['volumeInfo'];
      if (volumeInfo is! Map) return null;

      final info = Map<String, dynamic>.from(volumeInfo);
      final title = (info['title'] as String? ?? '').trim();
      if (title.isEmpty) return null;

      final authorsRaw = info['authors'];
      final authors = authorsRaw is List
          ? authorsRaw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).join(', ')
          : '';

      final publisher = (info['publisher'] as String? ?? '').trim();
      final year = _parseYear(info['publishedDate'] as String?);

      String coverUrl = '';
      final imageLinksRaw = info['imageLinks'];
      if (imageLinksRaw is Map) {
        final imageLinks = Map<String, dynamic>.from(imageLinksRaw);
        coverUrl = (imageLinks['thumbnail'] as String? ??
                imageLinks['smallThumbnail'] as String? ??
                '')
            .trim();
        if (coverUrl.startsWith('http://')) {
          coverUrl = 'https://${coverUrl.substring('http://'.length)}';
        }
      }

      return Book(
        title: title,
        author: authors,
        publisher: publisher,
        isbn: normalized,
        year: year,
        coverUrl: coverUrl,
        source: 'isbn_lookup',
      );
    } catch (_) {
      return null;
    }
  }

  static String _normalizeIsbn(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.replaceAll(RegExp(r'[^0-9Xx]'), '').toUpperCase();
  }

  static int? _parseYear(String? publishedDate) {
    if (publishedDate == null) return null;
    final m = RegExp(r'^(\d{4})').firstMatch(publishedDate.trim());
    if (m == null) return null;
    return int.tryParse(m.group(1)!);
  }
}


