import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'cloud_llm_service.dart';
import 'ollama_service.dart';
import 'rag_service.dart';

class AiRouterService {
  final OllamaService local;
  final CloudLLMService cloud;
  final RagService rag;

  // 定義幾多字元以下當做「短文本」
  static const int _shortTextThreshold = 250; 
  
  // Local LLM 的最大等待時間
  static const Duration _localTimeout = Duration(seconds: 12);

  AiRouterService({
    required this.local,
    required this.cloud,
    required this.rag,
  });

  bool _isShort(String text) => text.length < _shortTextThreshold;

  /// 智能路由核心邏輯
  /// [prompt] 完整的 AI 指令
  /// [inputText] 用戶原始輸入（用來判斷長度）
  /// [forceCloud] 如果某些 Task（例如長文深度分析）一定要用 Cloud，可以設為 true
  Future<String> smartRoute(String prompt, String inputText, {bool forceCloud = false}) async {
    // 1. 強制 Cloud 模式 或 長文本
    if (forceCloud || !_isShort(inputText)) {
      debugPrint("☁️ Routing to Cloud AI (Length: ${inputText.length})");
      return await _callCloudLlm(prompt);
    }

    // 2. 短文本：優先嘗試 Local LLM，並帶有 Timeout 與 Fallback
    debugPrint("💻 Routing to Local LLM (Length: ${inputText.length})");
    try {
      // 嘗試呼叫 Local，如果超過 _localTimeout 未回應，會 throw TimeoutException
      final localResponse = await _callLocalLlm(prompt).timeout(_localTimeout);
      
      // 檢查回傳內容是否太空泛或出現錯誤碼
      if (localResponse.trim().isEmpty || localResponse.contains("Error generating response")) {
        throw Exception("Local LLM returned empty or error response");
      }
      
      return localResponse;

    } on TimeoutException catch (_) {
      debugPrint("⚠️ Local LLM Timeout! Falling back to Cloud AI...");
      return await _callCloudLlm(prompt);
      
    } catch (e) {
      debugPrint("⚠️ Local LLM Failed: $e. Falling back to Cloud AI...");
      return await _callCloudLlm(prompt);
    }
  }

  Future<String> _callLocalLlm(String prompt) async {
    return await local.generate(prompt);
  }

  Future<String> _callCloudLlm(String prompt) async {
    return await cloudLlmGeneral(prompt);
  }

  /// 雲端 LLM 一般內容生成（用作本地 Fallback 或是通用的雲端生成）
  Future<String> cloudLlmGeneral(
    String prompt, {
    String? systemPrompt,
  }) async {
    return await cloud.generateContent(
      systemPrompt: systemPrompt ?? 'You are a helpful AI assistant.',
      userPrompt: prompt,
    );
  }

  /// 單純的 Local LLM 呼叫，並附帶 Cloud AI 容錯 (Fallback) 機制與 10 秒 Timeout
  Future<String> localLlm(String prompt) async {
    try {
      final response = await local
          .generate(prompt)
          .timeout(const Duration(seconds: 10));
      return response;
    } catch (e) {
      debugPrint("Local LLM failed or timed out, falling back to Cloud AI: $e");
      return await cloudLlmGeneral(prompt);
    }
  }

  /// Local LLM JSON 呼叫，並附帶 Cloud AI 容錯 (Fallback) 機制、10 秒 Timeout 與防禦性解析
  Future<Map<String, dynamic>> localLlmJson(String prompt) async {
    String rawText;
    try {
      rawText = await local
          .generate(prompt)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint("Local LLM JSON failed or timed out, falling back to Cloud AI: $e");
      rawText = await cloudLlmGeneral(
        prompt,
        systemPrompt: 'You are a helpful AI assistant. You must respond strictly in valid JSON format.',
      );
    }

    // 防禦性清理：剝除 Markdown 標籤與雜訊
    String cleaned = rawText;
    if (cleaned.contains('```json')) {
      cleaned = cleaned.split('```json')[1].split('```')[0].trim();
    } else if (cleaned.contains('```')) {
      cleaned = cleaned.split('```')[1].split('```')[0].trim();
    }
    
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start != -1 && end != -1 && end >= start) {
      cleaned = cleaned.substring(start, end + 1);
    }

    return jsonDecode(cleaned) as Map<String, dynamic>;
  }

  /// RAG 本地檢索與問答
  Future<String> localRag({
    required String question,
    required String bookId,
  }) async {
    // 呼叫實際的 RagService.retrieve
    final contextChunks = await rag.retrieve(
      question,
      docName: bookId,
    );
    final contextString = contextChunks.map((c) => c.chunk.text).join('\n');
    
    final prompt = "以下是參考資料：\n$contextString\n\n請根據以上資料回答問題：$question";
    return await localLlm(prompt);
  }

  /// 雲端 LLM 呼叫
  Future<String> cloudLlm(String prompt) async {
    // 呼叫 CloudLLMService，將 prompt 傳入
    return await cloud.queryCloudRAG(prompt, []);
  }
}


