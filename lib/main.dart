// lib/main.dart
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'controllers/contact_controller.dart';
import 'controllers/expense_controller.dart';
import 'controllers/health_controller.dart';
import 'controllers/wealth_controller.dart';
import 'core/locator.dart';
import 'l10n/app_localizations.dart';
import 'screens/personal_hub_screen.dart';
import 'server/api_server.dart';
import 'server/ollama_client.dart';
import 'services/embedding_service.dart';
import 'services/personal_rag_service.dart';
import 'services/rag_service.dart';
import 'services/secure_storage_service.dart';
import 'services/vector_store.dart';

const _aiLibLan = bool.fromEnvironment('AI_LIB_LAN', defaultValue: false);
const _aiLibToken = String.fromEnvironment('AI_LIB_TOKEN', defaultValue: '');

late final VectorStore globalStore;
@Deprecated('Use Locator.xxx for v2.7+')
late final ExpenseController globalExpenseController;
@Deprecated('Use Locator.xxx for v2.7+')
late final ContactController globalContactController;
@Deprecated('Use Locator.xxx for v2.7+')
late final HealthController globalHealthController;
@Deprecated('Use Locator.xxx for v2.7+')
late final WealthController globalWealthController;
@Deprecated('Use Locator.xxx for v2.7+')
late final PersonalRagService globalPersonalRagService;
late final OllamaClient globalOllama;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SecureStorageService.instance.init();
  await Locator.init();

  final embedModel = Platform.environment['EMBED_MODEL'] ?? 'bge-m3';
  final ollamaModel = Platform.environment['OLLAMA_MODEL'] ?? 'llama3.1:8b';
  final ollamaUrl =
      Platform.environment['OLLAMA_URL'] ?? 'http://localhost:11434';

  globalStore = VectorStore(
    encryptionKeyProvider: SecureStorageService.instance.getEncryptionKey,
  );
  await globalStore.load();

  globalExpenseController = ExpenseController(globalStore);
  globalContactController = ContactController(store: globalStore);
  globalHealthController = HealthController(globalStore);
  globalWealthController = WealthController(globalStore);

  await globalExpenseController.getAllExpenses();
  await globalContactController.getAllContacts();
  await globalWealthController.loadAll();

  globalOllama = OllamaClient(baseUrl: ollamaUrl, model: ollamaModel);

  globalPersonalRagService = PersonalRagService(
    embedder: EmbeddingService(baseUrl: ollamaUrl, model: embedModel),
    store: globalStore,
    llmCompleteStream: ({required systemPrompt, required userPrompt}) {
      return globalOllama.generate('$systemPrompt\n\n$userPrompt');
    },
  );

  Locator.registerAppServices(
    store: globalStore,
    expenseController: globalExpenseController,
    contactController: globalContactController,
    healthController: globalHealthController,
    wealthController: globalWealthController,
    personalRagService: globalPersonalRagService,
    ollamaClient: globalOllama,
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

  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;

  final embedModel = Platform.environment['EMBED_MODEL'] ?? 'bge-m3';
  final ollamaUrl =
      Platform.environment['OLLAMA_URL'] ?? 'http://localhost:11434';

  final rag = RagService(
    embedder: EmbeddingService(baseUrl: ollamaUrl, model: embedModel),
    store: globalStore,
  );

  final trimmedToken = _aiLibToken.trim();
  final server = ApiServer(
    rag: rag,
    store: globalStore,
    generate: globalOllama.generate,
    authToken: trimmedToken.isEmpty ? null : trimmedToken,
  );

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
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: PersonalHubScreen(
        expenseController: globalExpenseController,
        contactController: globalContactController,
        healthController: globalHealthController,
        wealthController: globalWealthController,
        personalRagService: globalPersonalRagService,
      ),
    );
  }
}
