// lib/server/office_ai_router.dart

import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../models/office_ai_request.dart';
import '../services/office_ai_service.dart';

class OfficeAiRouter {
  final OfficeAiService officeService;

  OfficeAiRouter({required this.officeService});

  Router get router {
    final router = Router();
    const jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

    router.post('/ask', (Request req) async {
      try {
        final body = await req.readAsString();
        if (body.isEmpty) {
          return Response(
            HttpStatus.badRequest,
            body: jsonEncode({'error': 'Request body is empty.'}),
            headers: jsonHeaders,
          );
        }

        final dynamic data = jsonDecode(body);
        if (data is! Map<String, dynamic>) {
          return Response(
            HttpStatus.badRequest,
            body: jsonEncode({'error': 'Request body must be a JSON object.'}),
            headers: jsonHeaders,
          );
        }

        // Parameter type validation to ensure 400 Bad Request matches specification
        if (data.containsKey('app') && data['app'] is! String) {
          return Response(
            HttpStatus.badRequest,
            body: jsonEncode({'error': '"app" must be a string.'}),
            headers: jsonHeaders,
          );
        }
        if (data.containsKey('task') && data['task'] is! String) {
          return Response(
            HttpStatus.badRequest,
            body: jsonEncode({'error': '"task" must be a string.'}),
            headers: jsonHeaders,
          );
        }
        if (data.containsKey('text') && data['text'] is! String) {
          return Response(
            HttpStatus.badRequest,
            body: jsonEncode({'error': '"text" must be a string.'}),
            headers: jsonHeaders,
          );
        }
        if (data.containsKey('tone') && data['tone'] is! String) {
          return Response(
            HttpStatus.badRequest,
            body: jsonEncode({'error': '"tone" must be a string.'}),
            headers: jsonHeaders,
          );
        }
        if (data.containsKey('target') && data['target'] is! String) {
          return Response(
            HttpStatus.badRequest,
            body: jsonEncode({'error': '"target" must be a string.'}),
            headers: jsonHeaders,
          );
        }
        if (data.containsKey('prompt') && data['prompt'] is! String) {
          return Response(
            HttpStatus.badRequest,
            body: jsonEncode({'error': '"prompt" must be a string.'}),
            headers: jsonHeaders,
          );
        }
        if (data.containsKey('metadata') && data['metadata'] is! Map) {
          return Response(
            HttpStatus.badRequest,
            body: jsonEncode({'error': '"metadata" must be a JSON object.'}),
            headers: jsonHeaders,
          );
        }

        final officeReq = OfficeAiRequest.fromJson(data);
        final officeRes = await officeService.ask(officeReq);

        return Response.ok(
          jsonEncode(officeRes.toJson()),
          headers: jsonHeaders,
        );
      } on FormatException catch (e) {
        return Response(
          HttpStatus.badRequest,
          body: jsonEncode({'error': 'Invalid JSON format: ${e.message}'}),
          headers: jsonHeaders,
        );
      } catch (e) {
        return Response(
          HttpStatus.internalServerError,
          body: jsonEncode({'error': 'Internal server error: $e'}),
          headers: jsonHeaders,
        );
      }
    });

    return router;
  }
}


