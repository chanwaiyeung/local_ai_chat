// lib/services/vision_llm_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/wealth_record.dart';
import 'currency_service.dart';

class VisionLlmException implements Exception {
  const VisionLlmException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
}

class VisionLLMService {
  VisionLLMService({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  Future<WealthRecord?> scanWealthFromImage(String imagePath, {required String apiKey}) async {
    final bytes = await File(imagePath).readAsBytes();
    return scanWealthFromBytes(bytes, apiKey: apiKey);
  }

  Future<WealthRecord?> scanWealthFromBytes(Uint8List bytes, {required String apiKey, int maxRetries = 2}) async {
    if (apiKey.trim().isEmpty) {
      throw const VisionLlmException('Gemini API Key 未設定，請先前往 Settings 設定');
    }
    if (bytes.isEmpty) throw const VisionLlmException('圖片資料為空');

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final prompt = '''
請從圖片中提取資產資訊，嚴格回傳 JSON（不要任何其他文字）：

{
  "assetType": "stock|fund|bond|crypto|real_estate|cash|insurance|other",
  "assetName": "資產名稱",
  "currency": "TWD|USD|HKD|...",
  "amount": 數字,
  "note": "備註"
}

無法辨識請回傳 null。
''';

        final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey');

        final response = await _http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                  {'inlineData': {'mimeType': 'image/jpeg', 'data': base64Encode(bytes)}},
                ],
              },
            ],
          }),
        );

        if (response.statusCode == 200) {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          final text = _extractText(decoded);
          if (text.trim().isEmpty) return null;

          final jsonStr = text.replaceAll(RegExp(r'^```json|```$|\n'), '').trim();
          final data = jsonDecode(jsonStr) as Map<String, dynamic>;

          return WealthRecord(
            id: '',
            assetType: (data['assetType'] ?? 'other').toString(),
            assetName: (data['assetName'] ?? '未知資產').toString(),
            currency: (data['currency'] ?? CurrencyService.instance.code).toString(),
            amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
            date: DateTime.now(),
            notes: (data['note'] ?? data['notes'] ?? 'AI Vision 自動辨識')
                .toString(),
            source: 'ai_extracted',
          );
        }
      } catch (e) {
        if (attempt == maxRetries) rethrow;
        await Future.delayed(Duration(seconds: attempt)); // 簡單重試延遲
      }
    }
    return null;
  }

  String _extractText(dynamic decoded) {
    try {
      final candidates = decoded['candidates'] as List?;
      final content = candidates?.first?['content'] as Map?;
      final parts = content?['parts'] as List?;
      return parts?.first?['text']?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  void close() => _http.close();
}




