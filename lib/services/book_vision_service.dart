// lib/services/book_vision_service.dart
//
// Phase 3: Vision LLM book recognition.
// Uses Google Gemini 1.5 Flash (same as VisionLLMService for Wealth)
// to extract book details from a cover or back-cover photo.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class BookVisionException implements Exception {
  const BookVisionException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'BookVisionException: $message';
}

class BookVisionService {
  static const _model = 'gemini-2.5-flash';
  static const _timeout = Duration(seconds: 30);

  /// Scans a book from a local image file path.
  static Future<Book?> scanFromImage(
    String imagePath, {
    required String apiKey,
  }) async {
    final bytes = await File(imagePath).readAsBytes();
    return scanFromBytes(bytes, apiKey: apiKey);
  }

  /// Scans a book from raw image bytes.
  ///
  /// Returns a [Book] with title/author/publisher/year/isbn populated
  /// (only fields the LLM could extract). Returns null if no book
  /// information could be recognized.
  ///
  /// Throws [BookVisionException] on missing API key or API failure.
  static Future<Book?> scanFromBytes(
    Uint8List bytes, {
    required String apiKey,
    int maxRetries = 2,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw const BookVisionException(
        'Gemini API Key 未設定，請先前往 Settings 設定',
      );
    }
    if (bytes.isEmpty) {
      throw const BookVisionException('圖片資料為空');
    }

    const prompt = '''
從這本書的封面或書背圖片中提取資訊，嚴格回傳 JSON（不要任何其他文字、不要 markdown 包裝）：

{
  "title": "書名",
  "author": "作者，多個用逗號分隔",
  "publisher": "出版社",
  "year": 出版年份(整數)或 null,
  "isbn": "ISBN-13 或 ISBN-10，沒看到就空字串"
}

如果完全看不到任何書籍資訊，回傳 {"title": ""}。
''';

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$apiKey',
    );

    Object? lastError;
    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {
                    'parts': [
                      {'text': prompt},
                      {
                        'inlineData': {
                          'mimeType': 'image/jpeg',
                          'data': base64Encode(bytes),
                        },
                      },
                    ],
                  },
                ],
              }),
            )
            .timeout(_timeout);

        if (response.statusCode != 200) {
          lastError = BookVisionException(
            'API 錯誤 ${response.statusCode}',
            statusCode: response.statusCode,
          );
          if (attempt < maxRetries) {
            await Future.delayed(Duration(seconds: attempt));
            continue;
          }
          throw lastError;
        }

        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final text = _extractText(decoded);
        if (text.trim().isEmpty) return null;

        // 1. Strip markdown wrappers if present
        var jsonStr = text
            .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
            .replaceAll(RegExp(r'```\s*$', multiLine: true), '')
            .trim();

        // 2. Try direct parse; on fail, extract first {...} block
        Map<String, dynamic> data;
        try {
          data = jsonDecode(jsonStr) as Map<String, dynamic>;
        } catch (_) {
          final m = RegExp(r'\{[\s\S]*\}').firstMatch(jsonStr);
          if (m == null) return null;
          data = jsonDecode(m.group(0)!) as Map<String, dynamic>;
        }

        final title = (data['title'] as String? ?? '').trim();
        if (title.isEmpty) return null;

        return Book(
          title: title,
          author: (data['author'] as String? ?? '').trim(),
          publisher: (data['publisher'] as String? ?? '').trim(),
          isbn: (data['isbn'] as String? ?? '').trim(),
          year: (data['year'] as num?)?.toInt(),
          source: 'vision_extracted',
        );
      } catch (e) {
        lastError = e;
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt));
          continue;
        }
        if (e is BookVisionException) rethrow;
        throw BookVisionException('辨識失敗: $e');
      }
    }

    if (lastError is BookVisionException) throw lastError;
    return null;
  }

  static String _extractText(dynamic decoded) {
    try {
      final candidates = decoded['candidates'] as List?;
      final content = candidates?.first?['content'] as Map?;
      final parts = content?['parts'] as List?;
      return parts?.first?['text']?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }
}

