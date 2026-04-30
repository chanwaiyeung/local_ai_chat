// lib/services/embedding_service.dart
//
// Real Ollama-backed embedding service. Calls /api/embeddings to convert
// text to a vector. Backwards-compatible with the stub: callers that did
// `EmbeddingService(model: 'bge-m3')` still work.
//
// For tests / offline runs, pass `embedFn` to bypass the network entirely:
//
//   final embedder = EmbeddingService(
//     embedFn: (text) async => [text.length.toDouble(), 0, 0],
//   );

import 'dart:convert';
import 'package:http/http.dart' as http;

class EmbeddingService {
  EmbeddingService({
    this.baseUrl = 'http://localhost:11434',
    this.model = 'bge-m3',
    this.embedFn,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String model;

  /// Optional override. When set, [embed] delegates to this and skips Ollama.
  final Future<List<double>> Function(String text)? embedFn;

  final http.Client _client;

  Future<List<double>> embed(String text) async {
    final overrideFn = embedFn;
    if (overrideFn != null) return overrideFn(text);

    final res = await _client.post(
      Uri.parse('$baseUrl/api/embeddings'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({'model': model, 'prompt': text}),
    );
    if (res.statusCode != 200) {
      throw Exception(
          'Embedding HTTP ${res.statusCode}: ${res.body.isEmpty ? '<empty>' : res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final raw = data['embedding'];
    if (raw is! List) {
      throw Exception('Embedding response missing "embedding" array.');
    }
    return raw.cast<num>().map((n) => n.toDouble()).toList();
  }

  void close() => _client.close();
}
