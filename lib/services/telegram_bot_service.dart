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
  final String token;
  final PersonalRagService ragService;
  
  bool _isRunning = false;
  int _lastUpdateId = 0;
  
  TelegramBotService({
    required this.token,
    required this.ragService,
  });

  void start() {
    if (_isRunning) return;
    if (token.isEmpty) return;
    _isRunning = true;
    _poll();
    debugPrint('TelegramBotService started');
  }

  void stop() {
    _isRunning = false;
    debugPrint('TelegramBotService stopped');
  }

  Future<void> _poll() async {
    while (_isRunning) {
      try {
        final uri = Uri.parse('https://api.telegram.org/bot$token/getUpdates?offset=${_lastUpdateId + 1}&timeout=30');
        final response = await http.get(uri).timeout(const Duration(seconds: 40));
        
        if (!_isRunning) break;

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['ok'] == true) {
            final updates = data['result'] as List<dynamic>;
            for (var u in updates) {
              final update = u as Map<String, dynamic>;
              final updateId = update['update_id'] as int;
              if (updateId > _lastUpdateId) {
                _lastUpdateId = updateId;
              }
              if (update.containsKey('message')) {
                final message = update['message'] as Map<String, dynamic>;
                final chatId = message['chat']['id'];
                
                if (message.containsKey('photo')) {
                  final photos = message['photo'] as List<dynamic>;
                  final fileId = photos.last['file_id'] as String;
                  final caption = message['caption'] as String? ?? '';
                  _handlePhoto(chatId, fileId, caption);
                } else if (message.containsKey('document')) {
                  final doc = message['document'] as Map<String, dynamic>;
                  final fileId = doc['file_id'] as String;
                  final fileName = doc['file_name'] as String? ?? 'file.pdf';
                  final caption = message['caption'] as String? ?? '';
                  _handleDocument(chatId, fileId, fileName, caption);
                } else if (message.containsKey('voice')) {
                  final voice = message['voice'] as Map<String, dynamic>;
                  final fileId = voice['file_id'] as String;
                  _handleVoice(chatId, fileId);
                } else if (message.containsKey('text')) {
                  final text = message['text'] as String;
                  // Background handling
                  _handleMessage(chatId, text);
                }
              }
            }
          }
        }
      } catch (e) {
        if (_isRunning) {
          debugPrint('Telegram poll error: $e');
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }
  }

  Future<void> _handleMessage(Message message) async {
    final chatId = message.chat.id;
    String userInput = message.text ?? '';
    List<String> attachments = [];

    print('📨 收到訊息 from ${message.from?.username ?? 'unknown'}');

    // 群組 @ 判斷
    if (message.chat.isGroup || message.chat.isSupergroup) {
      final botUsername = AppSettings.instance.telegramBotUsername;
      if (botUsername.isNotEmpty && !userInput.toLowerCase().contains('@${botUsername.toLowerCase()}')) {
        return; // 群組未提及則忽略
      }
      // 移除 @bot 部分
      userInput = userInput.replaceAll(RegExp('@${botUsername}', caseSensitive: false), '').trim();
    }

    // 照片
    if (message.photo != null && message.photo!.isNotEmpty) {
      final photo = message.photo!.last;
      final filePath = await _downloadFile(await _teledart.getFile(photo.fileId));
      attachments.add(filePath);
      userInput += "\n[使用者傳送照片]";
    }

    // 語音
    if (message.voice != null) {
      final filePath = await _downloadFile(await _teledart.getFile(message.voice!.fileId));
      attachments.add(filePath);
      userInput += "\n[使用者傳送語音訊息]";
    }

    // 處理 AI 回應
    final response = await _processWithAI(userInput, attachments, chatId);

    await _teledart.sendMessage(chatId, response);
  }

  // 新增下載檔案方法
  Future<String> _downloadFile(dynamic file) async {
    final directory = await getApplicationSupportDirectory();
    final savePath = '${directory.path}/telegram_downloads/${file.fileId}_${file.filePath.split('/').last}';
    // TODO: 實作下載邏輯
    return savePath;
  }

  Future<String> _processWithAI(String input, List<String> attachments, int chatId) async {
    try {
      String prompt = input.isEmpty ? "請描述這張照片" : input;

      final responseText = await _llmService.generateContent(
        prompt: prompt,
        images: attachments.where((f) => !f.endsWith('.oga') && !f.endsWith('.ogg')).toList(),
      );

      // TTS 語音回覆
      if (_ttsService != null) {
        final voicePath = await _ttsService.textToSpeech(responseText);
        await _teledart.sendVoice(chatId, voicePath, caption: responseText.length > 100 ? responseText.substring(0, 100) + "..." : responseText);
      }

      return responseText;
    } catch (e) {
      print('❌ AI 處理錯誤: $e');
      return "處理時發生錯誤，請稍後再試。";
    }
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
    final uri = Uri.parse('https://api.telegram.org/bot$token/sendVoice');
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

  Future<List<int>?> _downloadFile(String fileId) async {
    try {
      final uri = Uri.parse('https://api.telegram.org/bot$token/getFile?file_id=$fileId');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true) {
          final filePath = data['result']['file_path'] as String;
          final fileUri = Uri.parse('https://api.telegram.org/file/bot$token/$filePath');
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

  Future<void> _handlePhoto(dynamic chatId, String fileId, String caption) async {
    try {
      await http.post(
        Uri.parse('https://api.telegram.org/bot$token/sendChatAction'),
        body: {
          'chat_id': chatId.toString(),
          'action': 'upload_photo',
        },
      );

      final bytes = await _downloadFile(fileId);
      if (bytes == null) {
        await _sendMessage(chatId, '抱歉，無法下載圖片。');
        return;
      }

      final base64Image = base64Encode(bytes);
      final settings = await AppSettingsService().load();
      if (settings.geminiApiKey == null || settings.geminiApiKey!.isEmpty) {
        await _sendMessage(chatId, '抱歉，請先在設定中輸入 Gemini API Key 以啟用影像辨識功能。');
        return;
      }

      final cloudLlm = CloudLLMService(apiKey: settings.geminiApiKey!);
      final analysis = await cloudLlm.generateContent(
        systemPrompt: 'You are an expert image analyzer. Please describe the image in detail. If there is text, transcribe it. If it is a receipt or business card, extract the key information.',
        userPrompt: caption.isNotEmpty ? '使用者備註: $caption\n請分析這張圖片，並盡可能回答使用者的問題。' : '請詳細分析這張圖片的內容。',
        mediaBase64: base64Image,
        mediaMimeType: 'image/jpeg',
      );

      final augmentedQuery = '[圖片分析結果]:\n$analysis\n\n[使用者問題]:\n${caption.isNotEmpty ? caption : "總結這張圖片的重點"}';
      
      final ans = await ragService.answer(query: augmentedQuery);
      await _sendMessage(chatId, ans.text);

    } catch (e) {
      await _sendMessage(chatId, '抱歉，處理圖片時發生錯誤：$e');
    }
  }

  Future<void> _handleDocument(dynamic chatId, String fileId, String fileName, String caption) async {
    try {
      await http.post(
        Uri.parse('https://api.telegram.org/bot$token/sendChatAction'),
        body: {
          'chat_id': chatId.toString(),
          'action': 'upload_document',
        },
      );

      final bytes = await _downloadFile(fileId);
      if (bytes == null) {
        await _sendMessage(chatId, '抱歉，無法下載檔案。');
        return;
      }

      final tempDir = await Directory.systemTemp.createTemp('tg_doc_');
      final file = File(p.join(tempDir.path, fileName));
      await file.writeAsBytes(bytes);

      String extractedText = '';
      try {
        extractedText = await loadDocument(file.path);
      } catch (e) {
        await _sendMessage(chatId, '抱歉，無法解析此檔案格式：$e');
        return;
      } finally {
        if (await file.exists()) {
          await file.delete();
        }
        if (await tempDir.exists()) {
          await tempDir.delete();
        }
      }

      // Truncate if too long to avoid blowing up context immediately
      if (extractedText.length > 50000) {
        extractedText = extractedText.substring(0, 50000) + '... (截斷)';
      }

      final augmentedQuery = '[文件內容擷取]:\n$extractedText\n\n[使用者問題]:\n${caption.isNotEmpty ? caption : "總結這個檔案的重點"}';
      
      final ans = await ragService.answer(query: augmentedQuery);
      await _sendMessage(chatId, ans.text);

    } catch (e) {
      await _sendMessage(chatId, '抱歉，處理檔案時發生錯誤：$e');
    }
  }

  Future<void> _handleVoice(dynamic chatId, String fileId) async {
    try {
      await http.post(
        Uri.parse('https://api.telegram.org/bot$token/sendChatAction'),
        body: {
          'chat_id': chatId.toString(),
          'action': 'record_voice',
        },
      );

      final bytes = await _downloadFile(fileId);
      if (bytes == null) {
        await _sendMessage(chatId, '抱歉，無法下載語音訊息。');
        return;
      }

      final base64Audio = base64Encode(bytes);
      final settings = await AppSettingsService().load();
      if (settings.geminiApiKey == null || settings.geminiApiKey!.isEmpty) {
        await _sendMessage(chatId, '抱歉，請先在設定中輸入 Gemini API Key 以啟用語音辨識功能。');
        return;
      }

      final cloudLlm = CloudLLMService(apiKey: settings.geminiApiKey!);
      final transcription = await cloudLlm.generateContent(
        systemPrompt: 'You are an expert audio transcriber and assistant. Please transcribe the provided voice message accurately. If there is a clear intent or instruction, summarize it.',
        userPrompt: '請聽這段語音，如果裡面有明確的提問或指令，請幫我整理出來，或者直接轉錄成文字。',
        mediaBase64: base64Audio,
        mediaMimeType: 'audio/ogg',
      );

      final augmentedQuery = '[語音辨識結果]:\n$transcription';
      
      final ans = await ragService.answer(query: augmentedQuery);
      await _sendMessage(chatId, ans.text);

      if (settings.googleTtsApiKey != null && settings.googleTtsApiKey!.isNotEmpty) {
        await http.post(
          Uri.parse('https://api.telegram.org/bot$token/sendChatAction'),
          body: {
            'chat_id': chatId.toString(),
            'action': 'record_voice',
          },
        );
        
        try {
          final ttsService = CloudTTSService(apiKey: settings.googleTtsApiKey!);
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
