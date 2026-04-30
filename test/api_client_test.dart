// test/api_client_test.dart
//
// Pure-Dart tests for ApiClient (no Flutter UI involved). Verifies:
//   - Bearer auth header is attached when authToken is set
//   - getDocs() parses the docs list
//   - 4xx/5xx responses surface as ApiException with parsed `error` field
//   - health() returns false on connection failure

import 'dart:convert';

import 'package:ai_library_server/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiClient.getDocs', () {
    test('attaches Bearer token and parses docs', () async {
      String? seenAuth;
      final client = MockClient((req) async {
        seenAuth = req.headers['authorization'];
        expect(req.url.path, '/docs');
        return http.Response(
            jsonEncode({
              'docs': ['a.epub', 'b.pdf']
            }),
            200);
      });
      final api = ApiClient(
        baseUrl: 'http://example.com',
        authToken: 'secret',
        client: client,
      );

      expect(await api.getDocs(), ['a.epub', 'b.pdf']);
      expect(seenAuth, 'Bearer secret');
    });

    test('omits auth header when token is null', () async {
      String? seenAuth;
      final client = MockClient((req) async {
        seenAuth = req.headers['authorization'];
        return http.Response(jsonEncode({'docs': []}), 200);
      });
      final api = ApiClient(
        baseUrl: 'http://example.com',
        client: client,
      );

      await api.getDocs();
      expect(seenAuth, isNull);
    });

    test('throws ApiException with parsed message on 401', () async {
      final client = MockClient((req) async => http.Response(
            jsonEncode({'error': 'Invalid token'}),
            401,
          ));
      final api = ApiClient(
        baseUrl: 'http://example.com',
        authToken: 'wrong',
        client: client,
      );

      await expectLater(
        api.getDocs(),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 401)
            .having((e) => e.message, 'message', 'Invalid token')),
      );
    });

    test('falls back to raw body when error JSON has no error field', () async {
      final client =
          MockClient((req) async => http.Response('plain text', 500));
      final api = ApiClient(baseUrl: 'http://example.com', client: client);

      await expectLater(
        api.getDocs(),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 500)
            .having((e) => e.message, 'message', 'plain text')),
      );
    });
  });

  group('ApiClient.query', () {
    test('posts JSON body with query and docName', () async {
      Map<String, dynamic>? sentBody;
      final client = MockClient((req) async {
        sentBody = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({'answer': 'A', 'citations': []}),
          200,
        );
      });
      final api = ApiClient(baseUrl: 'http://example.com', client: client);

      final res = await api.query(query: 'hello', docName: 'book');
      expect(sentBody, {'query': 'hello', 'docName': 'book'});
      expect(res['answer'], 'A');
    });

    test('omits docName when null', () async {
      Map<String, dynamic>? sentBody;
      final client = MockClient((req) async {
        sentBody = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'answer': '', 'citations': []}), 200);
      });
      final api = ApiClient(baseUrl: 'http://example.com', client: client);

      await api.query(query: 'hi');
      expect(sentBody, {'query': 'hi'});
      expect(sentBody!.containsKey('docName'), isFalse);
    });
  });

  group('ApiClient.health', () {
    test('returns true on 200', () async {
      final client =
          MockClient((req) async => http.Response('{"status":"ok"}', 200));
      final api = ApiClient(baseUrl: 'http://example.com', client: client);
      expect(await api.health(), isTrue);
    });

    test('returns false on connection failure', () async {
      final client = MockClient((req) async => throw Exception('net down'));
      final api = ApiClient(baseUrl: 'http://example.com', client: client);
      expect(await api.health(), isFalse);
    });
  });
}
