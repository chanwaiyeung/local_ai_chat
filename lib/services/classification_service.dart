// lib/services/classification_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'app_settings_service.dart';
import 'cloud_llm_service.dart';
import 'ollama_service.dart';

class ClassificationResult {
  final String category;
  final List<String> tags;
  final bool isRefinedByCloud;
  final double score;
  final String source;

  const ClassificationResult({
    required this.category,
    required this.tags,
    this.isRefinedByCloud = false,
    this.score = 0.0,
    this.source = 'local',
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'tags': tags,
        'isRefinedByCloud': isRefinedByCloud,
        'score': score,
        'source': source,
      };

  factory ClassificationResult.fromJson(Map<String, dynamic> json) {
    return ClassificationResult(
      category: json['category'] as String? ?? 'other',
      tags: List<String>.from((json['tags'] as List?)?.map((e) => e.toString()) ?? const []),
      isRefinedByCloud: json['isRefinedByCloud'] as bool? ?? false,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      source: json['source'] as String? ?? 'local',
    );
  }
}

/// 智讀館（Library）自動分類引擎
/// 調用本地 Ollama 進行語義分析，並具備雲端精煉與隱私保護決策鏈
class ClassificationService {
  final OllamaService ollamaService;
  final CloudLLMService? _cloudLLMService;
  static const double confidenceThreshold = 0.7;

  ClassificationService({
    String baseUrl = 'http://127.0.0.1:11434',
    String model = 'gemma4:latest',
    OllamaService? ollamaService,
    CloudLLMService? cloudLLMService,
  })  : ollamaService = ollamaService ?? OllamaService(baseUrl: baseUrl, model: model),
        _cloudLLMService = cloudLLMService;

  /// 接收文件內容（或前 1000 字摘要）並進行分類
  Future<ClassificationResult> classifyBook(String text) async {
    final summary = text.length > 1000 ? text.substring(0, 1000) : text;
    final sanitized = _sanitizeSummary(summary);

    final systemPrompt = 'You are a book classification assistant. Analyze the book content or summary and classify it. '
        'You must determine a single category (string), 3 to 5 tags (list of strings), and a confidence score between 0.0 and 1.0. '
        'Your response must be a JSON object with keys "category", "tags", and "score" (a double between 0.0 and 1.0 representing your confidence). '
        'Do not write any explanation, intro, or markdown code blocks. Just return the raw JSON object. '
        'Example: {"category": "technical", "tags": ["flutter", "dart", "mobile-dev"], "score": 0.95}';

    String localCategory = 'other';
    List<String> localTags = const [];
    double score = 0.0;

    try {
      // 1. 首先調用本地 Ollama 獲取分類結果與信心度分數
      final responseStr = await ollamaService
          .generate(sanitized, systemPrompt: systemPrompt)
          .timeout(const Duration(seconds: 15));

      if (responseStr.isNotEmpty) {
        final cleaned = _extractJson(responseStr);
        final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
        localCategory = parsed['category']?.toString().toLowerCase().trim() ?? 'other';
        localTags = List<String>.from((parsed['tags'] as List?)?.map((e) => e.toString().trim()) ?? const []);
        if (parsed['score'] is num) {
          score = (parsed['score'] as num).toDouble();
        } else {
          // 結構完整性代理指標
          if (parsed.containsKey('category') && parsed.containsKey('tags')) {
            score = 0.5;
          }
        }
      }
    } catch (e) {
      debugPrint('Local classification failed or timed out: $e');
    }

    // 2. 若 score < confidenceThreshold，則調用 CloudLLMService 精煉，但嚴格限制只傳送本地已提取且去識別化的 summary
    if (score < confidenceThreshold) {
      try {
        String cloudResponse = '';
        if (_cloudLLMService != null) {
          cloudResponse = await _cloudLLMService
              .refineClassification(sanitized)
              .timeout(const Duration(seconds: 15));
        } else {
          final settings = await AppSettingsService().load();
          final apiKey = settings.geminiApiKey ?? '';
          if (apiKey.isNotEmpty) {
            final cloudLLM = CloudLLMService(apiKey: apiKey);
            cloudResponse = await cloudLLM
                .refineClassification(sanitized)
                .timeout(const Duration(seconds: 15));
          }
        }

        if (cloudResponse.isNotEmpty) {
          final cleaned = _extractJson(cloudResponse);
          final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
          final refinedCategory = parsed['category']?.toString().toLowerCase().trim() ?? 'other';
          final refinedTags = List<String>.from((parsed['tags'] as List?)?.map((e) => e.toString().trim()) ?? const []);

          return ClassificationResult(
            category: refinedCategory.isNotEmpty ? refinedCategory : localCategory,
            tags: refinedTags.isNotEmpty ? refinedTags : localTags,
            isRefinedByCloud: true,
            score: score,
            source: 'cloud',
          );
        }
      } catch (e) {
        debugPrint('Cloud refinement failed or timed out: $e');
      }
    }

    return ClassificationResult(
      category: localCategory,
      tags: localTags,
      isRefinedByCloud: false,
      score: score,
      source: 'local',
    );
  }

  /// 健壯提取 JSON 部分以避免 Markdown 標籤或雜訊干擾
  String _extractJson(String text) {
    var raw = text.trim();
    if (raw.startsWith('```')) {
      final firstNewline = raw.indexOf('\n');
      if (firstNewline != -1) {
        raw = raw.substring(firstNewline).trim();
      }
      if (raw.endsWith('```')) {
        raw = raw.substring(0, raw.length - 3).trim();
      }
    }
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      raw = raw.substring(start, end + 1);
    }
    return raw;
  }

  /// 資料去識別化 (Data Sanitization)：剔除個人識別資訊與財務金額
  String _sanitizeSummary(String text) {
    var sanitized = text;
    // 1. 移除電子郵件
    sanitized = sanitized.replaceAll(
      RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'),
      '[EMAIL]',
    );
    // 2. 移除財務金額（如 $1000, 100元, NT$500）
    sanitized = sanitized.replaceAll(
      RegExp(r'(?:\$|NT\$|¥|€|£|CAD|USD)\s?\d+(?:,\d{3})*(?:\.\d+)?'),
      '[AMOUNT]',
    );
    sanitized = sanitized.replaceAll(
      RegExp(r'\d+\s?(?:元|TWD|TWD|CAD|USD|HKD)'),
      '[AMOUNT]',
    );
    // 3. 移除電話號碼
    sanitized = sanitized.replaceAll(
      RegExp(r'\+?\d{1,4}(?:[-.\s]\d{1,10}){2,4}'),
      '[PHONE]',
    );
    return sanitized;
  }
}


