// test/api_server_test.dart
//
// Server-side integration test. Boots a real ApiServer on an ephemeral port
// with an in-memory VectorStore (pre-populated with two fixture chunks),
// a deterministic fake embedder, and a deterministic fake LLM generator —
// then drives it via the real ApiClient over real HTTP.
//
// What this catches:
//   - JSON request validation
//   - Bearer auth (accept / reject)
//   - /query end-to-end (retrieve → prompt → generate → citations)
//   - SSE wire format on /query/stream (citations → delta → done)
//   - Error path on /query/stream (LLM throws → ErrorEvent)
//
// No Ollama, no disk, no network beyond loopback. Runs offline in CI.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/server/api_server.dart';
import 'package:local_ai_chat/services/api_client.dart';
import 'package:local_ai_chat/services/embedding_service.dart';
import 'package:local_ai_chat/services/rag_service.dart';
import 'package:local_ai_chat/services/vector_store.dart';

/// Deterministic streaming generator: yields two tokens, then ends.
Stream<String> _fakeGen(String prompt) async* {
  yield 'Hello ';
  yield 'world.';
}

/// Streaming generator that throws partway through.
Stream<String> _failingGen(String prompt) async* {
  yield 'partial ';
  throw StateError('boom');
}

const _testToken = 'test-token-abc';

/// Returns a constant 4-D embedding so all chunks score equally — retrieval
/// just walks them in store order. Good enough for these tests.
Future<List<double>> _fakeEmbed(String _) async => const [1.0, 0.0, 0.0, 0.0];

/// Pre-populate an in-memory VectorStore with two fixture chunks across two
/// fictitious "books".
Future<VectorStore> _seededStore() async {
  final store = VectorStore(); // null storagePath → in-memory only
  await store.add(
    Chunk(
      docName: 'sample_book_1.epub',
      chunkIndex: 0,
      text: 'This is fixture content from sample_book_1.',
    ),
    const [1.0, 0.0, 0.0, 0.0],
  );
  await store.add(
    Chunk(
      docName: 'sample_book_2.pdf',
      chunkIndex: 0,
      text: 'This is fixture content from sample_book_2.',
    ),
    const [1.0, 0.0, 0.0, 0.0],
  );
  return store;
}

Future<({HttpServer http, ApiClient auth, ApiClient noAuth})> _boot({
  LlmStreamGenerator generator = _fakeGen,
}) async {
  final store = await _seededStore();
  final rag = RagService(
    embedder: EmbeddingService(embedFn: _fakeEmbed),
    store: store,
  );
  final server = ApiServer(
    rag: rag,
    store: store,
    generate: generator,
    authToken: _testToken,
  );
  // Port 0 → OS picks a free port. Returned HttpServer exposes the real port.
  final http = await server.start(port: 0);
  final base = 'http://127.0.0.1:${http.port}';
  return (
    http: http,
    auth: ApiClient(baseUrl: base, authToken: _testToken),
    noAuth: ApiClient(baseUrl: base),
  );
}

void main() {
  group('ApiServer integration', () {
    late HttpServer httpServer;
    late ApiClient authApi;
    late ApiClient noAuthApi;

    setUp(() async {
      final boot = await _boot();
      httpServer = boot.http;
      authApi = boot.auth;
      noAuthApi = boot.noAuth;
    });

    tearDown(() async {
      authApi.close();
      noAuthApi.close();
      await httpServer.close(force: true);
    });

    test('/health returns true without auth', () async {
      expect(await noAuthApi.health(), isTrue);
    });

    test('/docs returns seeded docs with valid token', () async {
      final docs = await authApi.getDocs();
      expect(docs, contains('sample_book_1.epub'));
      expect(docs, contains('sample_book_2.pdf'));
    });

    test('/docs without token → 401', () async {
      await expectLater(
        noAuthApi.getDocs(),
        throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test('/docs with wrong token → 401', () async {
      final wrong = ApiClient(
        baseUrl: 'http://127.0.0.1:${httpServer.port}',
        authToken: 'nope',
      );
      try {
        await expectLater(
          wrong.getDocs(),
          throwsA(isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)),
        );
      } finally {
        wrong.close();
      }
    });

    test('/query returns concatenated LLM output and citations', () async {
      final res = await authApi.query(query: 'what is this book about?');
      expect(res['answer'], 'Hello world.');
      final citations = res['citations'] as List;
      expect(citations, isNotEmpty);
      final first = citations.first as Map<String, dynamic>;
      expect(
          first.keys, containsAll(['doc', 'chunkIndex', 'score', 'snippet']));
    });

    test('/query honours docName filter', () async {
      final res = await authApi.query(
        query: 'summary',
        docName: 'sample_book_1.epub',
      );
      final citations = (res['citations'] as List).cast<Map<String, dynamic>>();
      expect(citations, isNotEmpty);
      expect(citations.every((c) => c['doc'] == 'sample_book_1.epub'), isTrue);
    });

    test('/query rejects empty body → 400', () async {
      final emptyClient = HttpClient();
      try {
        final req = await emptyClient.postUrl(
          Uri.parse('http://127.0.0.1:${httpServer.port}/query'),
        );
        req.headers.set('Authorization', 'Bearer $_testToken');
        req.headers.contentType = ContentType.json;
        // Empty body
        final res = await req.close();
        expect(res.statusCode, 400);
      } finally {
        emptyClient.close(force: true);
      }
    });

    test('/docs/<doc>/chunks returns ordered chunks for the doc', () async {
      final body = await _httpGetJson(
        Uri.parse(
            'http://127.0.0.1:${httpServer.port}/docs/sample_book_1.epub/chunks'),
        token: _testToken,
      );
      expect(body['docName'], 'sample_book_1.epub');
      final chunks = (body['chunks'] as List).cast<Map<String, dynamic>>();
      expect(chunks, isNotEmpty);
      expect(chunks.first['docName'], 'sample_book_1.epub');
      expect(
          chunks.first['text'], 'This is fixture content from sample_book_1.');
      expect(chunks.first.keys, containsAll(['docName', 'chunkIndex', 'text']));
    });

    test('/docs/<doc>/chunks without token → 401', () async {
      final res = await _httpGetRaw(
        Uri.parse(
            'http://127.0.0.1:${httpServer.port}/docs/sample_book_1.epub/chunks'),
      );
      expect(res.statusCode, 401);
    });

    test('/docs/<doc>/chunks for unknown doc returns empty list', () async {
      final body = await _httpGetJson(
        Uri.parse('http://127.0.0.1:${httpServer.port}/docs/nope.txt/chunks'),
        token: _testToken,
      );
      expect(body['docName'], 'nope.txt');
      expect(body['chunks'], isEmpty);
    });

    test('/rag/retrieve returns hits with default topK', () async {
      final body = await _httpPostJson(
        Uri.parse('http://127.0.0.1:${httpServer.port}/rag/retrieve'),
        token: _testToken,
        payload: {'query': 'sample question'},
      );
      expect(body['query'], 'sample question');
      expect(body['topK'], ApiServer.defaultRetrieveTopK);
      final hits = (body['hits'] as List).cast<Map<String, dynamic>>();
      expect(hits, isNotEmpty);
      expect(hits.first.keys,
          containsAll(['doc', 'chunkIndex', 'score', 'snippet']));
    });

    test('/rag/retrieve clamps topK to the server maximum', () async {
      final body = await _httpPostJson(
        Uri.parse('http://127.0.0.1:${httpServer.port}/rag/retrieve'),
        token: _testToken,
        payload: {'query': 'q', 'topK': 9999},
      );
      // Server is constructed with default topK=6 in _boot(), so the
      // requested 9999 must be clamped to 6.
      expect(body['topK'], lessThanOrEqualTo(6));
      expect(body['topK'], greaterThanOrEqualTo(1));
    });

    test('/rag/retrieve honours docName filter', () async {
      final body = await _httpPostJson(
        Uri.parse('http://127.0.0.1:${httpServer.port}/rag/retrieve'),
        token: _testToken,
        payload: {'query': 'q', 'docName': 'sample_book_1.epub', 'topK': 4},
      );
      final hits = (body['hits'] as List).cast<Map<String, dynamic>>();
      expect(hits, isNotEmpty);
      expect(hits.every((h) => h['doc'] == 'sample_book_1.epub'), isTrue);
    });

    test('/rag/retrieve without token → 401', () async {
      final res = await _httpPostRaw(
        Uri.parse('http://127.0.0.1:${httpServer.port}/rag/retrieve'),
        payload: {'query': 'q'},
      );
      expect(res.statusCode, 401);
    });

    test('/rag/retrieve with non-int topK → 400', () async {
      final res = await _httpPostRaw(
        Uri.parse('http://127.0.0.1:${httpServer.port}/rag/retrieve'),
        token: _testToken,
        payload: {'query': 'q', 'topK': 'four'},
      );
      expect(res.statusCode, 400);
    });
  });

  group('ApiServer safety guards', () {
    test('default bind is loopback only', () async {
      final store = await _seededStore();
      final server = ApiServer(
        rag: RagService(
          embedder: EmbeddingService(embedFn: _fakeEmbed),
          store: store,
        ),
        store: store,
        generate: _fakeGen,
        authToken: null,
      );
      final http = await server.start(port: 0);
      try {
        // 127.x is loopback. Anything else (0.0.0.0, real LAN) would mean
        // we're exposed.
        expect(http.address.address.startsWith('127.'), isTrue,
            reason: 'Default bind should be loopback, got '
                '${http.address.address}');
      } finally {
        await http.close(force: true);
      }
    });

    test('lanMode without authToken throws StateError before binding',
        () async {
      final store = await _seededStore();
      final server = ApiServer(
        rag: RagService(
          embedder: EmbeddingService(embedFn: _fakeEmbed),
          store: store,
        ),
        store: store,
        generate: _fakeGen,
        authToken: null,
      );
      await expectLater(
        server.start(port: 0, lanMode: true),
        throwsStateError,
      );
    });

    test('lanMode with whitespace-only authToken still throws', () async {
      // Defends against sloppy shell quoting like
      // `--dart-define=AI_LIB_TOKEN=" "` accidentally enabling LAN mode
      // with no real auth.
      final store = await _seededStore();
      final server = ApiServer(
        rag: RagService(
          embedder: EmbeddingService(embedFn: _fakeEmbed),
          store: store,
        ),
        store: store,
        generate: _fakeGen,
        authToken: '   ',
      );
      await expectLater(
        server.start(port: 0, lanMode: true),
        throwsStateError,
      );
    });

    test('lanMode with authToken binds to 0.0.0.0', () async {
      final store = await _seededStore();
      final server = ApiServer(
        rag: RagService(
          embedder: EmbeddingService(embedFn: _fakeEmbed),
          store: store,
        ),
        store: store,
        generate: _fakeGen,
        authToken: _testToken,
      );
      final http = await server.start(port: 0, lanMode: true);
      try {
        expect(http.address.address, '0.0.0.0');
      } finally {
        await http.close(force: true);
      }
    });
  });

  group('/query/stream SSE', () {
    test('emits citations → delta(s) → done in order', () async {
      final boot = await _boot();
      try {
        final events = await boot.auth.queryStream(query: 'q').toList();

        expect(events.first, isA<CitationsEvent>());
        expect(events.last, isA<DoneEvent>());

        final deltas = events.whereType<DeltaEvent>().toList();
        expect(deltas, isNotEmpty);
        expect(deltas.map((d) => d.text).join(), 'Hello world.');

        final citations = (events.first as CitationsEvent).citations;
        expect(citations, isNotEmpty);
      } finally {
        boot.auth.close();
        boot.noAuth.close();
        await boot.http.close(force: true);
      }
    });

    test('LLM error mid-stream surfaces as ErrorEvent', () async {
      final boot = await _boot(generator: _failingGen);
      try {
        final events = await boot.auth.queryStream(query: 'q').toList();
        expect(events.last, isA<ErrorEvent>());
        // Partial delta should still have arrived before the failure.
        expect(events.whereType<DeltaEvent>(), isNotEmpty);
      } finally {
        boot.auth.close();
        boot.noAuth.close();
        await boot.http.close(force: true);
      }
    });

    test('rejects stream without token', () async {
      final boot = await _boot();
      try {
        final events = await boot.noAuth.queryStream(query: 'q').toList();
        expect(events, hasLength(1));
        expect(events.single, isA<ErrorEvent>());
        expect(
          (events.single as ErrorEvent).message,
          contains('401'),
        );
      } finally {
        boot.auth.close();
        boot.noAuth.close();
        await boot.http.close(force: true);
      }
    });
  });
}

// ----------------------------- Test helpers -----------------------------

/// Raw GET → returns response, leaves status / headers inspectable.
Future<HttpClientResponse> _httpGetRaw(Uri uri, {String? token}) async {
  final c = HttpClient();
  try {
    final req = await c.getUrl(uri);
    if (token != null) req.headers.set('Authorization', 'Bearer $token');
    final res = await req.close();
    // Drain so the connection is freed even if caller doesn't read body.
    await res.drain<void>();
    return res;
  } finally {
    c.close(force: true);
  }
}

/// GET that returns the parsed JSON body. Asserts 200.
Future<Map<String, dynamic>> _httpGetJson(Uri uri, {String? token}) async {
  final c = HttpClient();
  try {
    final req = await c.getUrl(uri);
    if (token != null) req.headers.set('Authorization', 'Bearer $token');
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode != 200) {
      throw StateError('GET $uri → ${res.statusCode}: $body');
    }
    return jsonDecode(body) as Map<String, dynamic>;
  } finally {
    c.close(force: true);
  }
}

/// Raw POST → returns response, leaves status / headers inspectable.
Future<HttpClientResponse> _httpPostRaw(
  Uri uri, {
  String? token,
  required Map<String, dynamic> payload,
}) async {
  final c = HttpClient();
  try {
    final req = await c.postUrl(uri);
    req.headers.contentType = ContentType.json;
    if (token != null) req.headers.set('Authorization', 'Bearer $token');
    req.write(jsonEncode(payload));
    final res = await req.close();
    await res.drain<void>();
    return res;
  } finally {
    c.close(force: true);
  }
}

/// POST that returns the parsed JSON body. Asserts 200.
Future<Map<String, dynamic>> _httpPostJson(
  Uri uri, {
  String? token,
  required Map<String, dynamic> payload,
}) async {
  final c = HttpClient();
  try {
    final req = await c.postUrl(uri);
    req.headers.contentType = ContentType.json;
    if (token != null) req.headers.set('Authorization', 'Bearer $token');
    req.write(jsonEncode(payload));
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode != 200) {
      throw StateError('POST $uri → ${res.statusCode}: $body');
    }
    return jsonDecode(body) as Map<String, dynamic>;
  } finally {
    c.close(force: true);
  }
}


