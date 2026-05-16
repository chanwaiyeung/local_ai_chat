// lib/services/contact_ocr_service.dart

import 'ocr_service.dart';

/// A service dedicated to extracting text from business card images.
///
/// This acts as a boundary between the UI and the underlying OCR engine.
/// Currently operates using the internal Tesseract-based OcrService with a
/// graceful fallback to mock data if OCR fails or Tesseract is missing.
class ContactOcrService {
  final _ocr = OcrService();

  static const _mockBusinessCardText = '''
Global Tech Innovations
John Doe
Senior Software Architect
+1 (555) 123-4567
john.doe@globaltech.xyz
www.globaltech.xyz
''';

  /// Scans a business card image and returns the extracted raw text.
  /// Returns a record with the text and a boolean indicating if it was a fallback.
  Future<(String text, bool isFallback)> scanBusinessCard({required String imagePath}) async {
    try {
      final text = await _ocr.extractTextFromImage(imagePath);
      if (text.trim().isNotEmpty) {
        return (text, false);
      }
    } catch (_) {
      // Fallback to mock data if OCR fails (e.g. tesseract not installed)
    }

    // Simulate OCR processing delay for the mock fallback
    await Future.delayed(const Duration(milliseconds: 600));
    return (_mockBusinessCardText, true);
  }
}
