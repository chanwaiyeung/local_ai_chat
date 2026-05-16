// lib/services/contact_ocr_service.dart

/// A service dedicated to extracting text from business card images.
///
/// This acts as a boundary between the UI and the underlying OCR engine.
/// Currently operates in a "mock" mode for development. Future implementations
/// can swap the internal engine (e.g. Tesseract, ML Kit, Azure) without
/// affecting the UI flow.
class ContactOcrService {
  /// Scans a business card image and returns the extracted raw text.
  /// 
  /// In this mock phase, [imagePath] is optional. If not provided (or even if
  /// provided), it simulates a network/processing delay and returns a sample
  /// business card string.
  Future<String> scanBusinessCard({String? imagePath}) async {
    // Simulate OCR processing delay
    await Future.delayed(const Duration(milliseconds: 600));

    // Hardcoded mock response for Micro Task I & J
    return '''
Global Tech Innovations
John Doe
Senior Software Architect
+1 (555) 123-4567
john.doe@globaltech.xyz
www.globaltech.xyz
''';
  }
}
