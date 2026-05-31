// lib/services/ollama_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/message.dart';

/// 本地 Ollama 客戶端
/// 預設連接 http://localhost:11434
/// 需先安裝 Ollama 並 `ollama pull <model>`，例如：
///   ollama pull qwen2.5:7b
///   ollama pull llama3.2:3b
class OllamaService {
  final String baseUrl;
  final String model;
  final Duration timeout;

  OllamaService({
    this.baseUrl = 'http://127.0.0.1:11434',
    this.model = 'qwen2.5:7b',
    this.timeout = const Duration(minutes: 5),
  });

  /// 一次性取得完整回覆（非串流）
  Future<String> chat(List<ChatMessage> messages) async {
    final uri = Uri.parse('$baseUrl/api/chat');
    final body = jsonEncode({
      'model': model,
      'messages': messages.map((m) => m.toOllamaJson()).toList(),
      'stream': false,
    });

    late http.Response res;
    try {
      res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(timeout);
    } catch (e) {
      throw Exception(_friendlyConnectionError(e));
    }

    if (res.statusCode != 200) {
      throw Exception('Ollama 錯誤 ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final msg = data['message'] as Map<String, dynamic>?;
    return (msg?['content'] as String?)?.trim() ?? '';
  }

  /// 串流回覆 — 逐個 token 推送
  Stream<String> chatStream(List<ChatMessage> messages) async* {
    final uri = Uri.parse('$baseUrl/api/chat');
    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'model': model,
        'messages': messages.map((m) => m.toOllamaJson()).toList(),
        'stream': true,
      });

    late http.StreamedResponse streamed;
    try {
      streamed = await request.send().timeout(timeout);
    } catch (e) {
      throw Exception(_friendlyConnectionError(e));
    }
    if (streamed.statusCode != 200) {
      final err = await streamed.stream.bytesToString();
      throw Exception('Ollama 錯誤 ${streamed.statusCode}: $err');
    }

    final lines =
        streamed.stream.transform(utf8.decoder).transform(const LineSplitter());

    await for (final line in lines) {
      if (line.trim().isEmpty) continue;
      try {
        final obj = jsonDecode(line) as Map<String, dynamic>;
        final msg = obj['message'] as Map<String, dynamic>?;
        final content = msg?['content'] as String?;
        if (content != null && content.isNotEmpty) yield content;
        if (obj['done'] == true) break;
      } catch (_) {
        // 個別行解析失敗時忽略，繼續讀下一行
      }
    }
  }

  /// 列出本機已下載嘅模型
  Future<List<String>> listModels() async {
    late http.Response res;
    try {
      res = await http
          .get(Uri.parse('$baseUrl/api/tags'))
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      throw Exception(_friendlyConnectionError(e));
    }
    if (res.statusCode != 200) {
      throw Exception('無法取得模型列表: ${res.statusCode}');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final models = (data['models'] as List?) ?? [];
    return models
        .map((m) => (m as Map<String, dynamic>)['name'] as String)
        .toList();
  }

  /// 健康檢查
  Future<bool> ping() async {
    try {
      final res = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<String> generate(String prompt, {String? systemPrompt, String? format = 'json', Map<String, dynamic>? options}) async {
    final uri = Uri.parse('$baseUrl/api/generate');
    final body = jsonEncode({
      'model': model,
      'prompt': prompt,
      if (systemPrompt != null) 'system': systemPrompt,
      'stream': false,
      if (format != null) 'format': format,
      if (options != null) 'options': options,
    });

    late http.Response res;
    try {
      res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(timeout);
    } catch (e) {
      throw Exception(_friendlyConnectionError(e));
    }

    if (res.statusCode != 200) {
      throw Exception('Ollama 錯誤 ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return (data['response'] as String?)?.trim() ?? '';
  }

  String _friendlyConnectionError(Object error) {
    if (error is TimeoutException ||
        error is SocketException ||
        error.toString().contains('SocketException') ||
        error.toString().contains('Connection refused') ||
        error.toString().contains('遠端電腦拒絕網路連線')) {
      return 'Ollama 未啟動或 API 無法連線。\n'
          '請先開啟 Ollama，或在 PowerShell 執行：\n'
          '& "C:\\Users\\Albert Chan\\AppData\\Local\\Programs\\Ollama\\ollama.exe" serve\n'
          '然後再按右上角重整模型列表。';
    }
    return error.toString();
  }
}


