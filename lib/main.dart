// lib/main.dart
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'controllers/book_controller.dart';
import 'controllers/church/care_controller.dart';
import 'controllers/church/person_controller.dart';
import 'controllers/contact_controller.dart';
import 'controllers/expense_controller.dart';
import 'controllers/health_controller.dart';
import 'controllers/wealth_controller.dart';
import 'l10n/app_localizations.dart';
import 'screens/personal_hub_screen.dart';
import 'server/api_server.dart';
import 'server/ollama_client.dart';
import 'services/app_settings_service.dart';
import 'services/currency_service.dart';
import 'services/embedding_service.dart';
import 'services/personal_rag_service.dart';
import 'services/rag_service.dart';
import 'services/skills_service.dart';
import 'services/telegram_bot_service.dart';
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

VectorStore? _globalStore;
VectorStore get globalStore => _globalStore ??= VectorStore();

@visibleForTesting
set globalStore(VectorStore store) => _globalStore = store;

late final ExpenseController globalExpenseController;
late final ContactController globalContactController;
late final HealthController globalHealthController;
late final WealthController globalWealthController;
late final BookController globalBookController;
CareController? _globalCareController;
CareController get globalCareController =>
    _globalCareController ??= CareController(globalStore);

@visibleForTesting
set globalCareController(CareController controller) =>
    _globalCareController = controller;

PersonController? _globalPersonController;
PersonController get globalPersonController =>
    _globalPersonController ??= PersonController(globalStore);

@visibleForTesting
set globalPersonController(PersonController controller) =>
    _globalPersonController = controller;

late final PersonalRagService globalPersonalRagService;
late final SkillsService globalSkillsService;
late final OllamaClient globalOllama;
TelegramBotService? globalTelegramBotService;

Future<void> restartTelegramBot(String? token) async {
  globalTelegramBotService?.stop();
  globalTelegramBotService = null;
  if (token != null && token.isNotEmpty) {
    globalTelegramBotService = TelegramBotService(
      token: token,
      ragService: globalPersonalRagService,
    )..start();
  }
}

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
  globalWealthController = WealthController(globalStore);
  globalBookController = BookController(globalStore);
  globalCareController = CareController(globalStore);
  globalPersonController = PersonController(globalStore);
  await globalExpenseController.getAllExpenses();
  await globalContactController.getAllContacts();
  await globalWealthController.loadAll();
  await globalBookController.loadAll();
  await globalCareController.loadAll();
  await globalPersonController.loadAll();
  // HealthController loads synchronously from VectorStore so no await needed here for all records,
  // but if needed, we can call getAllRecords().

  globalOllama = OllamaClient(baseUrl: ollamaUrl, model: ollamaModel);

  final embedder = EmbeddingService(baseUrl: ollamaUrl, model: embedModel);

  globalSkillsService = SkillsService(
    store: globalStore,
    embedder: embedder,
  );

  globalPersonalRagService = PersonalRagService(
    embedder: embedder,
    store: globalStore,
    skillsService: globalSkillsService,
    llmCompleteStream: ({required systemPrompt, required userPrompt}) {
      return globalOllama.generate('$systemPrompt\n\n$userPrompt');
    },
  );

  final settings = await AppSettingsService().load();
  await restartTelegramBot(settings.telegramBotToken);

  await _startServerForDesktop();
  await CurrencyService.instance.load();
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static MyAppState? of(BuildContext c) =>
      c.findAncestorStateOfType<MyAppState>();

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  Locale? _locale = const Locale('en');
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  Locale? get currentLocale => _locale;

  void setLocale(Locale? l) {
    setState(() {
      _locale = l;
    });
  }

  void setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),      // 繁體
        Locale('zh', 'TW'), // 繁體台灣
        Locale('zh', 'CN'), // 簡體
        Locale('ja'),       // ← 新增這一行
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: PersonalHubScreen(
        expenseController: globalExpenseController,
        contactController: globalContactController,
        healthController: globalHealthController,
        wealthController: globalWealthController,
        bookController: globalBookController,
        personalRagService: globalPersonalRagService,
      ),
    );
  }
}
