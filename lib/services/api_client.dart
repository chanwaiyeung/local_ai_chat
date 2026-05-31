// lib/services/api_client.dart
//
// Mobile-side client for the Local AI Server.
//
// Notes on baseUrl:
//   - Android emulator → http://10.0.2.2:8080 (loopback to host)
//   - iOS simulator    → http://127.0.0.1:8080
//   - Real device      → http://<your-LAN-ip>:8080  (see server startup logs)
//
// Notes on auth: pass `authToken` if the server has AI_LIB_TOKEN set; leave
// null when the server runs in open mode.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// One streamed event from `/query/stream`.
sealed class QueryEvent {
  const QueryEvent();
}

class CitationsEvent extends QueryEvent {
  const CitationsEvent(this.citations);
  final List<Map<String, dynamic>> citations;
}

class DeltaEvent extends QueryEvent {
  const DeltaEvent(this.text);
  final String text;
}

class DoneEvent extends QueryEvent {
  const DoneEvent();
}

class ErrorEvent extends QueryEvent {
  const ErrorEvent(this.message);
  final String message;
}

abstract interface class ReaderApi {
  Future<bool> health();

  Future<List<String>> getDocs();

  Future<Map<String, dynamic>> query({
    required String query,
    String? docName,
  });

  Stream<QueryEvent> queryStream({
    required String query,
    String? docName,
  });

  /// Read mode: every chunk of [docName] in original order.
  /// Returns each chunk as `{docName, chunkIndex, text}`.
  Future<List<Map<String, dynamic>>> getDocumentChunks(String docName);

  /// Pure retrieve (no LLM). Returns hits as
  /// `{doc, chunkIndex, score, snippet}`.
  Future<List<Map<String, dynamic>>> retrieve({
    required String query,
    String? docName,
    int topK = 6,
  });
}

class ApiClient implements ReaderApi {
  ApiClient({
    String? baseUrl,
    this.authToken,
    http.Client? client,
  })  : baseUrl = baseUrl ?? _defaultBaseUrl(),
        _client = client ?? http.Client();

  String baseUrl;
  final String? authToken;
  final http.Client _client;

  static String _defaultBaseUrl() {
    if (kIsWeb) return 'http://127.0.0.1:8080';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'http://10.0.2.2:8080',
      TargetPlatform.iOS => 'http://127.0.0.1:8080',
      TargetPlatform.windows ||
      TargetPlatform.macOS ||
      TargetPlatform.linux =>
        'http://127.0.0.1:8080',
      _ => 'http://10.0.2.2:8080',
    };
  }

  /// Replace the base URL at runtime. Used by the IP dialog and by
  /// `LibraryScreen._autoDetectAndConnect`.
  void updateBaseUrl(String newUrl) => baseUrl = newUrl;

  Map<String, String> get _authHeader =>
      (authToken == null || authToken!.isEmpty)
          ? const {}
          : {'Authorization': 'Bearer $authToken'};

  // ----------------------------- /health -----------------------------

  @override
  Future<bool> health() async {
    try {
      final res = await _client
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ----------------------------- /docs -----------------------------

  @override
  Future<List<String>> getDocs() async {
    final res = await _client
        .get(Uri.parse('$baseUrl/docs'), headers: _authHeader)
        .timeout(const Duration(seconds: 10));
    _ensureOk(res, 'getDocs');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return List<String>.from(data['docs'] as List);
  }

  // ----------------------------- /query -----------------------------

  @override
  Future<Map<String, dynamic>> query({
    required String query,
    String? docName,
  }) async {
    final res = await _client
        .post(
          Uri.parse('$baseUrl/query'),
          headers: {
            'Content-Type': 'application/json',
            ..._authHeader,
          },
          body: jsonEncode({
            'query': query,
            if (docName != null) 'docName': docName,
          }),
        )
        .timeout(const Duration(seconds: 60));
    _ensureOk(res, 'query');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ----------------------------- /docs/<doc>/chunks -----------------------------

  @override
  Future<List<Map<String, dynamic>>> getDocumentChunks(String docName) async {
    final encoded = Uri.encodeComponent(docName);
    final res = await _client
        .get(Uri.parse('$baseUrl/docs/$encoded/chunks'),
            headers: _authHeader)
        .timeout(const Duration(seconds: 10));
    _ensureOk(res, 'getDocumentChunks');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final raw = (data['chunks'] as List?) ?? const [];
    return raw
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
  }

  // ----------------------------- /rag/retrieve -----------------------------

  @override
  Future<List<Map<String, dynamic>>> retrieve({
    required String query,
    String? docName,
    int topK = 6,
  }) async {
    final res = await _client
        .post(
          Uri.parse('$baseUrl/rag/retrieve'),
          headers: {
            'Content-Type': 'application/json',
            ..._authHeader,
          },
          body: jsonEncode({
            'query': query,
            if (docName != null) 'docName': docName,
            'topK': topK,
          }),
        )
        .timeout(const Duration(seconds: 30));
    _ensureOk(res, 'retrieve');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final raw = (data['hits'] as List?) ?? const [];
    return raw
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
  }

  // ----------------------------- /query/stream -----------------------------

  /// Streams server events as they arrive. The stream completes after
  /// `DoneEvent` or `ErrorEvent`.
  @override
  Stream<QueryEvent> queryStream({
    required String query,
    String? docName,
  }) async* {
    final req = http.Request('POST', Uri.parse('$baseUrl/query/stream'))
      ..headers['Content-Type'] = 'application/json'
      ..headers.addAll(_authHeader)
      ..body = jsonEncode({
        'query': query,
        if (docName != null) 'docName': docName,
      });

    final res = await _client.send(req);
    if (res.statusCode != 200) {
      final body = await res.stream.bytesToString();
      yield ErrorEvent('HTTP ${res.statusCode}: ${_extractError(body)}');
      return;
    }

    // SSE frames are terminated by a blank line. We accumulate `data:` lines
    // per frame, then decode the JSON payload.
    final buf = StringBuffer();
    await for (final line in res.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      if (line.isEmpty) {
        if (buf.isEmpty) continue;
        final payload = buf.toString();
        buf.clear();
        final event = _parseEvent(payload);
        if (event != null) yield event;
        if (event is DoneEvent || event is ErrorEvent) return;
      } else if (line.startsWith('data:')) {
        // Multi-line `data:` fields are joined with a single newline per spec.
        if (buf.isNotEmpty) buf.write('\n');
        buf.write(line.substring(5).trimLeft());
      }
      // Ignore comment lines (starting with `:`) and other field types.
    }
  }

  QueryEvent? _parseEvent(String payload) {
    final Map<String, dynamic> j;
    try {
      j = jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return ErrorEvent('Bad SSE payload: $payload');
    }
    switch (j['type']) {
      case 'citations':
        final raw = (j['citations'] as List? ?? const []);
        return CitationsEvent(
          raw.map((e) => (e as Map).cast<String, dynamic>()).toList(),
        );
      case 'delta':
        return DeltaEvent((j['text'] as String?) ?? '');
      case 'done':
        return const DoneEvent();
      case 'error':
        return ErrorEvent((j['message'] as String?) ?? 'unknown error');
      default:
        return null;
    }
  }

  // ----------------------------- helpers -----------------------------

  void _ensureOk(http.Response res, String op) {
    if (res.statusCode == 200) return;
    throw ApiException(
      op: op,
      statusCode: res.statusCode,
      message: _extractError(res.body),
    );
  }

  String _extractError(String body) {
    if (body.isEmpty) return '<empty body>';
    try {
      final j = jsonDecode(body);
      if (j is Map && j['error'] is String) return j['error'] as String;
    } catch (_) {/* fall through */}
    return body;
  }

  void close() => _client.close();
}

class ApiException implements Exception {
  ApiException({
    required this.op,
    required this.statusCode,
    required this.message,
  });

  final String op;
  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($op, $statusCode): $message';
}


