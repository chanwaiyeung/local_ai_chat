// lib/services/pdf_service.dart
import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  /// 抽取整份 PDF 文字
  static Future<String> extractAll(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    try {
      return PdfTextExtractor(document).extractText();
    } finally {
      document.dispose();
    }
  }

  /// 抽取指定頁範圍 (0-based, 包頭包尾)
  static Future<String> extractRange(
    String filePath, {
    required int startPage,
    required int endPage,
  }) async {
    final bytes = await File(filePath).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    try {
      return PdfTextExtractor(document).extractText(
        startPageIndex: startPage,
        endPageIndex: endPage,
      );
    } finally {
      document.dispose();
    }
  }

  /// 取得 PDF 頁數
  static Future<int> pageCount(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    try {
      return document.pages.count;
    } finally {
      document.dispose();
    }
  }

  /// 將長文字切細，避免一次塞太多 token 入 LLM
  static List<String> chunk(String text, {int maxChars = 3000}) {
    final chunks = <String>[];
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    for (var i = 0; i < clean.length; i += maxChars) {
      final end = (i + maxChars).clamp(0, clean.length);
      chunks.add(clean.substring(i, end));
    }
    return chunks;
  }
}


