// lib/main.dart
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'controllers/contact_controller.dart';
import 'controllers/expense_controller.dart';
import 'controllers/health_controller.dart';
import 'screens/personal_hub_screen.dart';
import 'server/api_server.dart';
import 'server/ollama_client.dart';
import 'services/embedding_service.dart';
import 'services/personal_rag_service.dart';
import 'services/rag_service.dart';
import 'services/vector_store.dart';

// ----------------------------- dart-define config -----------------------------
//
// Compile-time switches. Use --dart-define on the flutter run / build
// command line. dart-define is preferred over Platform.environment for two
// reasons: (1) it works on Flutter web where Platform.environment is empty;
// (2) the value is baked into the compiled artifact, so production builds
// can ship with a known-good config.
//
// Examples:
//   flutter run -d windows
//       (loopback-only, no auth — safe local dev default)
//
//   flutter run -d windows \
//       --dart-define=AI_LIB_LAN=true \
//       --dart-define=AI_LIB_TOKEN=your-secret
//       (LAN-exposed, phone can connect; auth required)
//
const _aiLibLan = bool.fromEnvironment('AI_LIB_LAN', defaultValue: false);
const _aiLibToken = String.fromEnvironment('AI_LIB_TOKEN', defaultValue: '');

late final VectorStore globalStore;
late final ExpenseController globalExpenseController;
late final ContactController globalContactController;
late final HealthController globalHealthController;
late final PersonalRagService globalPersonalRagService;
late final OllamaClient globalOllama;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final embedModel = Platform.environment['EMBED_MODEL'] ?? 'bge-m3';
  final ollamaModel = Platform.environment['OLLAMA_MODEL'] ?? 'llama3.1:8b';
  final ollamaUrl =
      Platform.environment['OLLAMA_URL'] ?? 'http://localhost:11434';

  globalStore = VectorStore();
  await globalStore.load();

  globalExpenseController = ExpenseController(globalStore);
  globalContactController = ContactController(store: globalStore);
  globalHealthController = HealthController(globalStore);
  await globalExpenseController.getAllExpenses();
  await globalContactController.getAllContacts();
  // HealthController loads synchronously from VectorStore so no await needed here for all records,
  // but if needed, we can call getAllRecords().

  globalOllama = OllamaClient(baseUrl: ollamaUrl, model: ollamaModel);

  globalPersonalRagService = PersonalRagService(
    embedder: EmbeddingService(baseUrl: ollamaUrl, model: embedModel),
    store: globalStore,
    llmCompleteStream: ({required systemPrompt, required userPrompt}) {
      return globalOllama.generate('$systemPrompt\n\n$userPrompt');
    },
  );

  await _startServerForDesktop();
  runApp(const MyApp());
}

Future<void> _startServerForDesktop() async {
  if (kIsWeb) return;
  if (defaultTargetPlatform != TargetPlatform.windows &&
      defaultTargetPlatform != TargetPlatform.macOS &&
      defaultTargetPlatform != TargetPlatform.linux) {
    return;
  }

  // These remain Platform.environment (runtime override, no rebuild needed):
  // they are operational tunables, not security-critical settings.
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;

  final embedModel = Platform.environment['EMBED_MODEL'] ?? 'bge-m3';
  final ollamaUrl =
      Platform.environment['OLLAMA_URL'] ?? 'http://localhost:11434';

  final rag = RagService(
    embedder: EmbeddingService(baseUrl: ollamaUrl, model: embedModel),
    store: globalStore,
  );

  // Trim the token before passing on. Inside ApiServer this is what's
  // compared byte-for-byte against the `Authorization: Bearer …` header,
  // so a leading/trailing space sneaking through dart-define would make
  // every request fail with 401 and look like a server bug.
  final trimmedToken = _aiLibToken.trim();
  final server = ApiServer(
    rag: rag,
    store: globalStore,
    generate: globalOllama.generate,
    authToken: trimmedToken.isEmpty ? null : trimmedToken,
  );

  // ApiServer.start() throws StateError if lanMode is true without a
  // non-blank token. Catch it explicitly so a misconfigured release
  // build prints a clear diagnostic instead of a bare uncaught error.
  try {
    await server.start(port: port, lanMode: _aiLibLan);
  } on StateError catch (e) {
    debugPrint('[ai_library_server] startup refused: ${e.message}');
    debugPrint(
      '[ai_library_server] hint: pass --dart-define=AI_LIB_TOKEN=<secret> '
      'or omit AI_LIB_LAN to keep the server loopback-only.',
    );
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '智讀館',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: PersonalHubScreen(
        expenseController: globalExpenseController,
        contactController: globalContactController,
        healthController: globalHealthController,
        personalRagService: globalPersonalRagService,
      ),
    );
  }
}
