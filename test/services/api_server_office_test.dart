import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/server/api_server.dart';
import 'package:local_ai_chat/services/embedding_service.dart';
import 'package:local_ai_chat/services/rag_service.dart';
import 'package:local_ai_chat/services/vector_store.dart';

Stream<String> _fakeGen(String prompt) async* {
  yield 'Office Response for: ';
  yield prompt.toLowerCase().contains('word') ? 'Word' : 'General';
}

const _testToken = 'office-secret-123';

Future<List<double>> _fakeEmbed(String _) async => const [1.0, 0.0, 0.0, 0.0];

Future<({HttpServer http, ApiServer server})> _boot() async {
  final store = VectorStore();
  final rag = RagService(
    embedder: EmbeddingService(embedFn: _fakeEmbed),
    store: store,
  );
  final server = ApiServer(
    rag: rag,
    store: store,
    generate: _fakeGen,
    authToken: _testToken,
  );
  final http = await server.start(port: 0);
  return (http: http, server: server);
}

void main() {
  group('ApiServer Office Bridge Endpoint Tests', () {
    late HttpServer httpServer;

    setUp(() async {
      final boot = await _boot();
      httpServer = boot.http;
    });

    tearDown(() async {
      await httpServer.close(force: true);
    });

    test('POST /office/ask returns result with valid token', () async {
      final client = HttpClient();
      try {
        final req = await client.postUrl(
          Uri.parse('http://127.0.0.1:${httpServer.port}/office/ask'),
        );
        req.headers.contentType = ContentType.json;
        req.headers.set('Authorization', 'Bearer $_testToken');
        req.write(jsonEncode({
          'app': 'word',
          'task': 'summarize',
          'text': 'Hello standard office text.',
          'tone': 'formal',
          'target': 'zh-TW',
        }));
        
        final res = await req.close();
        expect(res.statusCode, 200);
        
        final body = await res.transform(utf8.decoder).join();
        final Map<String, dynamic> json = jsonDecode(body) as Map<String, dynamic>;
        expect(json['ok'], isTrue);
        expect(json.containsKey('result'), isTrue);
        expect(json['result'], contains('Office Response for: Word'));
        expect(json['citations'], isEmpty);
        expect(json['model'], 'local');
      } finally {
        client.close(force: true);
      }
    });

    test('POST /office/ask without token → 401', () async {
      final client = HttpClient();
      try {
        final req = await client.postUrl(
          Uri.parse('http://127.0.0.1:${httpServer.port}/office/ask'),
        );
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode({
          'app': 'word',
          'task': 'summarize',
          'text': 'Hello standard office text.',
        }));
        
        final res = await req.close();
        expect(res.statusCode, 401);
      } finally {
        client.close(force: true);
      }
    });

    test('POST /office/ask with invalid parameter type → 400', () async {
      final client = HttpClient();
      try {
        final req = await client.postUrl(
          Uri.parse('http://127.0.0.1:${httpServer.port}/office/ask'),
        );
        req.headers.contentType = ContentType.json;
        req.headers.set('Authorization', 'Bearer $_testToken');
        req.write(jsonEncode({
          'app': 12345, // invalid type, should be String
        }));
        
        final res = await req.close();
        expect(res.statusCode, 400);
      } finally {
        client.close(force: true);
      }
    });
  });
}


