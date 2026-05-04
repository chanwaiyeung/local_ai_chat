// lib/services/vision_llm_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/wealth_record.dart';

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

  Future<WealthRecord?> scanWealthFromBytes(Uint8List bytes, {required String apiKey}) async {
    if (apiKey.trim().isEmpty) {
      throw const VisionLlmException('Gemini API Key 未設定，請先前往 Settings 頁面設定');
    }
    if (bytes.isEmpty) throw const VisionLlmException('圖片資料為空');

    final prompt = '''
請分析這張圖片中的資產/投資/理財相關資訊，並**嚴格**以以下 JSON 格式回覆（不要任何額外文字、解釋或 markdown）：

{
  "assetType": "stock | fund | bond | crypto | real_estate | cash | insurance | other",
  "assetName": "資產名稱或代號（例如：台積電、AAPL、美債）",
  "currency": "TWD | USD | HKD | CNY | ...",
  "amount": 數字（例如：892.5 或 15000）,
  "note": "簡短備註（可包含日期、來源等）"
}

如果圖片中無法辨識明確資產資訊，請直接回傳 null。
''';

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

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

    if (response.statusCode != 200) {
      throw VisionLlmException('API 呼叫失敗，請檢查網路或 API Key', statusCode: response.statusCode);
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final text = _extractText(decoded);

    if (text.trim().isEmpty) return null;

    try {
      final jsonStr = text.replaceAll(RegExp(r'^```json|```$|\n'), '').trim();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      return WealthRecord(
        id: '',
        assetType: (data['assetType'] ?? 'other').toString(),
        assetName: (data['assetName'] ?? '未知資產').toString(),
        currency: (data['currency'] ?? 'TWD').toString(),
        amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
        date: DateTime.now(),
        note: (data['note'] ?? 'AI Vision 自動辨識').toString(),
      );
    } catch (_) {
      return null;
    }
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
