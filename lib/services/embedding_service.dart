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
  final http.Client _http;
  final Future<List<double>> Function(String text)? _embedFn;

  EmbeddingService({
    this.baseUrl = 'http://127.0.0.1:11434',
    this.model = 'nomic-embed-text',
    this.timeout = const Duration(minutes: 2),
    http.Client? httpClient,
    Future<List<double>> Function(String text)? embedFn,
  })  : _http = httpClient ?? http.Client(),
        _embedFn = embedFn;

  /// 取單個句子嘅向量
  Future<List<double>> embed(String text) async {
    final embedFn = _embedFn;
    if (embedFn != null) return embedFn(text);

    final results = await embedAll([text]);
    return results.first;
  }

  Future<List<double>> _embedSingle(String text) async {
    final res = await _http
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

  /// 批量取向量。優先用 Ollama `/api/embed` batch endpoint；
  /// 舊 server 或 shape 不符時 fallback 到 `/api/embeddings`。
  Future<List<List<double>>> embedAll(
    List<String> texts, {
    void Function(int done, int total)? onProgress,
  }) async {
    if (texts.isEmpty) return [];
    final embedFn = _embedFn;
    if (embedFn != null) {
      final results = <List<double>>[];
      for (var i = 0; i < texts.length; i++) {
        results.add(await embedFn(texts[i]));
        onProgress?.call(i + 1, texts.length);
      }
      return results;
    }

    final batchResult = await _tryEmbedBatch(texts);
    if (batchResult != null) {
      onProgress?.call(texts.length, texts.length);
      return batchResult;
    }

    return _embedLegacyParallel(texts, onProgress: onProgress);
  }

  Future<List<List<double>>?> _tryEmbedBatch(List<String> texts) async {
    try {
      final res = await _http
          .post(
            Uri.parse('$baseUrl/api/embed'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'model': model, 'input': texts}),
          )
          .timeout(timeout);

      if (res.statusCode == 404) return null;
      if (res.statusCode != 200) {
        throw Exception('Embedding 錯誤 ${res.statusCode}: ${res.body}');
      }

      final data =
          jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final embeddings = data['embeddings'];
      if (embeddings is! List || embeddings.length != texts.length) {
        return null;
      }

      return embeddings
          .map((embedding) => (embedding as List)
              .cast<num>()
              .map((value) => value.toDouble())
              .toList())
          .toList();
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<List<List<double>>> _embedLegacyParallel(
    List<String> texts, {
    void Function(int done, int total)? onProgress,
    int concurrency = 4,
  }) async {
    final results = List<List<double>?>.filled(texts.length, null);
    var done = 0;
    var nextIndex = 0;

    Future<void> worker() async {
      while (true) {
        final index = nextIndex++;
        if (index >= texts.length) return;
        results[index] = await _embedSingle(texts[index]);
        done++;
        onProgress?.call(done, texts.length);
      }
    }

    final workerCount = texts.length < concurrency ? texts.length : concurrency;
    await Future.wait(List.generate(workerCount, (_) => worker()));
    return results.map((embedding) => embedding!).toList();
  }

  void close() {
    _http.close();
  }
}
