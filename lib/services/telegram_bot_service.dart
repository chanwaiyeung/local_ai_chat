// lib/services/telegram_bot_service.dart
//
// HTTP long-polling Telegram bot: text / photo / document / voice.
// Uses PersonalRagService for text & extracted document text; Gemini for
// image / audio when API key is configured.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'app_settings_service.dart';
import 'cloud_llm_service.dart';
import 'cloud_tts_service.dart';
import 'document_loader.dart';
import 'personal_rag_service.dart';

class TelegramBotService {
  TelegramBotService({
    required this.token,
    required this.ragService,
  });

  final String token;
  final PersonalRagService ragService;

  bool _isRunning = false;
  int _lastUpdateId = 0;

  void start() {
    if (_isRunning) return;
    if (token.isEmpty) return;
    _isRunning = true;
    unawaited(_poll());
    debugPrint('TelegramBotService started');
  }

  void stop() {
    _isRunning = false;
    debugPrint('TelegramBotService stopped');
  }

  Future<void> _poll() async {
    while (_isRunning) {
      try {
        final uri = Uri.parse(
          'https://api.telegram.org/bot$token/getUpdates'
          '?offset=${_lastUpdateId + 1}&timeout=30',
        );
        final response =
            await http.get(uri).timeout(const Duration(seconds: 40));

        if (!_isRunning) break;

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['ok'] == true) {
            final updates = data['result'] as List<dynamic>;
            for (final u in updates) {
              final update = u as Map<String, dynamic>;
              final updateId = update['update_id'] as int;
              if (updateId > _lastUpdateId) _lastUpdateId = updateId;

              if (update.containsKey('message')) {
                final msg = update['message'] as Map<String, dynamic>;
                final chatId = msg['chat']['id'];

                if (msg.containsKey('photo')) {
                  final photos = msg['photo'] as List<dynamic>;
                  final fileId = photos.last['file_id'] as String;
                  final caption = msg['caption'] as String? ?? '';
                  unawaited(_handlePhoto(chatId, fileId, caption));
                } else if (msg.containsKey('document')) {
                  final doc = msg['document'] as Map<String, dynamic>;
                  final fileId = doc['file_id'] as String;
                  final fileName =
                      doc['file_name'] as String? ?? 'attachment.bin';
                  final caption = msg['caption'] as String? ?? '';
                  unawaited(
                    _handleDocument(chatId, fileId, fileName, caption),
                  );
                } else if (msg.containsKey('voice')) {
                  final voice = msg['voice'] as Map<String, dynamic>;
                  final fileId = voice['file_id'] as String;
                  unawaited(_handleVoice(chatId, fileId));
                } else if (msg.containsKey('text')) {
                  final text = msg['text'] as String;
                  unawaited(_handleText(chatId, text));
                }
              }
            }
          }
        }
      } catch (e) {
        if (_isRunning) {
          debugPrint('Telegram poll error: $e');
          await Future<void>.delayed(const Duration(seconds: 2));
        }
      }
    }
  }

  Future<void> _handleText(dynamic chatId, String text) async {
    try {
      final ans = await ragService.answer(query: text);
      await _sendMessage(chatId, ans.text);
    } catch (e) {
      await _sendMessage(chatId, '抱歉，處理訊息時發生錯誤：$e');
    }
  }

  Future<List<int>?> _downloadFile(String fileId) async {
    try {
      final uri = Uri.parse(
        'https://api.telegram.org/bot$token/getFile?file_id=$fileId',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['ok'] == true) {
          final filePath = data['result']['file_path'] as String;
          final fileUri = Uri.parse(
            'https://api.telegram.org/file/bot$token/$filePath',
          );
          final fileResponse = await http.get(fileUri);
          if (fileResponse.statusCode == 200) {
            return fileResponse.bodyBytes;
          }
        }
      }
    } catch (e) {
      debugPrint('Telegram file download error: $e');
    }
    return null;
  }

  Future<void> _sendMessage(dynamic chatId, String text) async {
    try {
      await http.post(
        Uri.parse('https://api.telegram.org/bot$token/sendMessage'),
        body: {
          'chat_id': chatId.toString(),
          'text': text,
        },
      );
    } catch (e) {
      debugPrint('Telegram sendMessage error: $e');
    }
  }

  Future<void> _sendVoice(dynamic chatId, Uint8List voiceBytes) async {
    final uri =
        Uri.parse('https://api.telegram.org/bot$token/sendVoice');
    final request = http.MultipartRequest('POST', uri);
    request.fields['chat_id'] = chatId.toString();
    request.files.add(
      http.MultipartFile.fromBytes(
        'voice',
        voiceBytes,
        filename: 'response.ogg',
      ),
    );
    final response = await request.send();
    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      debugPrint('Error sending voice: $body');
    }
  }

  Future<void> _handlePhoto(
    dynamic chatId,
    String fileId,
    String caption,
  ) async {
    try {
      final bytes = await _downloadFile(fileId);
      if (bytes == null) {
        await _sendMessage(chatId, '抱歉，無法下載圖片。');
        return;
      }

      final base64Image = base64Encode(bytes);
      final settings = await AppSettingsService().load();
      if (settings.geminiApiKey == null || settings.geminiApiKey!.isEmpty) {
        await _sendMessage(chatId, '請先在設定中輸入 Gemini API Key。');
        return;
      }

      final cloudLlm = CloudLLMService(apiKey: settings.geminiApiKey!);
      final analysis = await cloudLlm.generateContent(
        systemPrompt: 'You are an expert image analyzer.',
        userPrompt: caption.isNotEmpty
            ? '使用者備註: $caption\n請分析這張圖片。'
            : '請詳細分析這張圖片的內容。',
        mediaBase64: base64Image,
        mediaMimeType: 'image/jpeg',
      );

      final query =
          '[圖片分析]:\n$analysis\n\n[問題]:\n${caption.isNotEmpty ? caption : "總結這張圖片"}';
      final ans = await ragService.answer(query: query);
      await _sendMessage(chatId, ans.text);
    } catch (e) {
      await _sendMessage(chatId, '抱歉，處理圖片時發生錯誤：$e');
    }
  }

  /// Downloads a Telegram document to a temp file, extracts text when
  /// supported (see [isSupportedDocument]), then queries RAG.
  Future<void> _handleDocument(
    dynamic chatId,
    String fileId,
    String fileName,
    String caption,
  ) async {
    Directory? tempDir;
    try {
      final bytes = await _downloadFile(fileId);
      if (bytes == null) {
        await _sendMessage(chatId, '抱歉，無法下載檔案。');
        return;
      }

      final base = p.basename(fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_'));
      final safeName = base.isEmpty ? 'file.bin' : base;

      tempDir = await Directory.systemTemp.createTemp('tg_doc_');
      final filePath = p.join(tempDir.path, safeName);
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      if (!isSupportedDocument(filePath)) {
        await _sendMessage(
          chatId,
          '不支援的檔案類型：${p.extension(filePath)}。'
          '支援：${supportedExtensions.join(", ")}',
        );
        return;
      }

      final text = await loadDocument(filePath);
      const maxLen = 12000;
      final snippet = text.length > maxLen
          ? '${text.substring(0, maxLen)}\n…[已截斷]'
          : text;

      final header = StringBuffer()
        ..writeln('[附件: $safeName]')
        ..writeln(
          caption.isNotEmpty ? '[說明]\n$caption\n' : '',
        )
        ..writeln('[文件內容]')
        ..writeln(snippet);

      final ans = await ragService.answer(query: header.toString());
      await _sendMessage(chatId, ans.text);
    } on FormatException catch (e) {
      await _sendMessage(chatId, '無法解析文件：$e');
    } catch (e) {
      await _sendMessage(chatId, '抱歉，處理文件時發生錯誤：$e');
    } finally {
      if (tempDir != null) {
        try {
          await tempDir.delete(recursive: true);
        } catch (_) {}
      }
    }
  }

  Future<void> _handleVoice(dynamic chatId, String fileId) async {
    try {
      final bytes = await _downloadFile(fileId);
      if (bytes == null) {
        await _sendMessage(chatId, '抱歉，無法下載語音訊息。');
        return;
      }

      final base64Audio = base64Encode(bytes);
      final settings = await AppSettingsService().load();
      if (settings.geminiApiKey == null || settings.geminiApiKey!.isEmpty) {
        await _sendMessage(chatId, '請先在設定中輸入 Gemini API Key。');
        return;
      }

      final cloudLlm = CloudLLMService(apiKey: settings.geminiApiKey!);
      final transcription = await cloudLlm.generateContent(
        systemPrompt: 'You are an expert audio transcriber.',
        userPrompt: '請聽這段語音並轉錄成文字。',
        mediaBase64: base64Audio,
        mediaMimeType: 'audio/ogg',
      );

      final ans =
          await ragService.answer(query: '[語音辨識]:\n$transcription');
      await _sendMessage(chatId, ans.text);

      if (settings.googleTtsApiKey != null &&
          settings.googleTtsApiKey!.isNotEmpty) {
        try {
          final ttsService =
              CloudTTSService(apiKey: settings.googleTtsApiKey!);
          final voiceBytes = await ttsService.synthesize(ans.text);
          await _sendVoice(chatId, voiceBytes);
        } catch (e) {
          debugPrint('TTS Error: $e');
        }
      }
    } catch (e) {
      await _sendMessage(chatId, '抱歉，處理語音時發生錯誤：$e');
    }
  }
}
