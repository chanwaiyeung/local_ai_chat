// lib/services/embedding_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Ollama embedding 客戶端
/// 推薦先 `ollama pull nomic-embed-text`（768 維、英中皆可）
/// 或 `ollama pull bge-m3`（1024 維、多語言更強）
class EmbeddingService {
  final String baseUrl;
  final String model;
  final Duration timeout;

  EmbeddingService({
    this.baseUrl = 'http://127.0.0.1:11434',
    this.model = 'nomic-embed-text',
    this.timeout = const Duration(minutes: 2),
  });

  /// 取單個句子嘅向量
  Future<List<double>> embed(String text) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/api/embeddings'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'model': model, 'prompt': text}),
        )
        .timeout(timeout);

    if (res.statusCode != 200) {
      throw Exception('Embedding 錯誤 ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final emb = (data['embedding'] as List).cast<num>();
    return emb.map((e) => e.toDouble()).toList();
  }

  /// 批量取向量（順序執行，避免本地 GPU 過載）
  Future<List<List<double>>> embedAll(
    List<String> texts, {
    void Function(int done, int total)? onProgress,
  }) async {
    final out = <List<double>>[];
    for (var i = 0; i < texts.length; i++) {
      out.add(await embed(texts[i]));
      onProgress?.call(i + 1, texts.length);
    }
    return out;
  }
}
