// bin/server.dart
//
// Dart-only entry point for the Local AI Server.
//
// Use this when you don't want to spin up the Flutter desktop window — for
// headless smoke tests, CI runs, or running the server on a Linux box with
// no display. The server itself has no Flutter dependency, so `dart run`
// works after a one-time `flutter pub get`.
//
// Usage:
//   flutter pub get               # once, to populate .dart_tool/
//   dart run bin/server.dart      # starts on :8080
//
//   $env:AI_LIB_TOKEN = "secret"  # PowerShell — enables Bearer auth
//   $env:PORT = "9000"            # PowerShell — override port
//   dart run bin/server.dart

import 'dart:async';
import 'dart:io';

import 'package:ai_library_server/server/api_server.dart';
import 'package:ai_library_server/server/ollama_client.dart';
import 'package:ai_library_server/services/embedding_service.dart';
import 'package:ai_library_server/services/rag_service.dart';
import 'package:ai_library_server/services/vector_store.dart';

Future<void> main(List<String> args) async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final token = Platform.environment['AI_LIB_TOKEN'];
  final ollamaModel = Platform.environment['OLLAMA_MODEL'] ?? 'llama3.1:8b';
  final embedModel = Platform.environment['EMBED_MODEL'] ?? 'bge-m3';
  final ollamaUrl =
      Platform.environment['OLLAMA_URL'] ?? 'http://localhost:11434';
  final indexPath =
      Platform.environment['AI_LIB_INDEX'] ?? 'data/vectors.ndjson';
  // LAN mode is opt-in. Recognised truthy values: 1, true, yes, on (case-insensitive).
  final lanMode = const {'1', 'true', 'yes', 'on'}
      .contains((Platform.environment['AI_LIB_LAN'] ?? '').toLowerCase());

  final store = VectorStore(storagePath: indexPath);
  await store.load();
  stdout.writeln(
      'Loaded ${store.totalChunks} chunks across ${store.docNames.length} docs from $indexPath');

  final rag = RagService(
    embedder:
        EmbeddingService(baseUrl: ollamaUrl, model: embedModel),
    store: store,
  );

  final ollama = OllamaClient(baseUrl: ollamaUrl, model: ollamaModel);

  final server = ApiServer(
    rag: rag,
    store: store,
    generate: ollama.generate,
    authToken: token,
  );

  final httpServer = await server.start(port: port, lanMode: lanMode);

  stdout.writeln('');
  stdout.writeln('Press Ctrl+C to stop.');

  // Graceful shutdown on SIGINT (and SIGTERM where supported).
  final completer = Completer<void>();
  StreamSubscription<ProcessSignal>? sigInt;
  StreamSubscription<ProcessSignal>? sigTerm;

  void shutdown(ProcessSignal sig) {
    if (completer.isCompleted) return;
    stdout.writeln('Caught $sig, shutting down...');
    completer.complete();
  }

  sigInt = ProcessSignal.sigint.watch().listen(shutdown);
  if (!Platform.isWindows) {
    sigTerm = ProcessSignal.sigterm.watch().listen(shutdown);
  }

  await completer.future;
  await sigInt.cancel();
  await sigTerm?.cancel();
  await httpServer.close(force: true);
  exit(0);
}
