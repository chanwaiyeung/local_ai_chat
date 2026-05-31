import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CloudTTSService {
  CloudTTSService({required this.apiKey});

  final String apiKey;

  /// Generate TTS audio using Google Cloud Text-to-Speech API.
  /// Returns OGG_OPUS format which is suitable for Telegram voice messages.
  Future<Uint8List> synthesize(String text) async {
    final url = Uri.parse(
        'https://texttospeech.googleapis.com/v1/text:synthesize?key=$apiKey');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'input': {'text': text},
        'voice': {
          'languageCode': 'cmn-TW',
          'name': 'cmn-TW-Wavenet-A', // High quality Chinese female voice
        },
        'audioConfig': {
          'audioEncoding': 'OGG_OPUS',
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to synthesize speech: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final audioContent = data['audioContent'] as String;
    return base64Decode(audioContent);
  }
}


