// test/server/office_ai_router_test.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/server/office_ai_router.dart';
import 'package:local_ai_chat/services/office_ai_service.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

Stream<String> _fakeGenerator(String prompt) async* {
  yield 'Office Response';
}

void main() {
  group('OfficeAiRouter Tests', () {
    late HttpServer httpServer;

    setUp(() async {
      final service = OfficeAiService(generate: _fakeGenerator);
      final officeRouter = OfficeAiRouter(officeService: service);

      final router = Router();
      router.mount('/office/', officeRouter.router.call);

      httpServer = await io.serve(router.call, InternetAddress.loopbackIPv4, 0);
    });

    tearDown(() async {
      await httpServer.close(force: true);
    });

    test('POST /office/ask returns 200 and valid JSON on success', () async {
      final client = HttpClient();
      try {
        final req = await client.postUrl(
          Uri.parse('http://127.0.0.1:${httpServer.port}/office/ask'),
        );
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode({
          'app': 'word',
          'task': 'polish',
          'text': 'Hello world.',
        }));

        final res = await req.close();
        expect(res.statusCode, 200);

        final body = await res.transform(utf8.decoder).join();
        final Map<String, dynamic> json = jsonDecode(body) as Map<String, dynamic>;
        expect(json['ok'], isTrue);
        expect(json['result'], equals('Office Response'));
        expect(json['model'], equals('local'));
      } finally {
        client.close(force: true);
      }
    });

    test('POST /office/ask with invalid parameter type returns 400', () async {
      final client = HttpClient();
      try {
        final req = await client.postUrl(
          Uri.parse('http://127.0.0.1:${httpServer.port}/office/ask'),
        );
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode({
          'app': 123, // invalid: must be String
        }));

        final res = await req.close();
        expect(res.statusCode, 400);
      } finally {
        client.close(force: true);
      }
    });

    test('POST /office/ask with empty body returns 400', () async {
      final client = HttpClient();
      try {
        final req = await client.postUrl(
          Uri.parse('http://127.0.0.1:${httpServer.port}/office/ask'),
        );
        req.headers.contentType = ContentType.json;
        // no body written

        final res = await req.close();
        expect(res.statusCode, 400);
      } finally {
        client.close(force: true);
      }
    });
  });
}


