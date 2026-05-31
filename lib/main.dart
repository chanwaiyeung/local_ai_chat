// lib/main.dart
import 'dart:io' show Platform, HttpServer;

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
import 'models/app_settings.dart';
import 'screens/personal_hub_screen.dart';
import 'server/api_server.dart';
import 'server/ollama_client.dart';
import 'services/ai_highlight_service.dart';
import 'services/ai_mindmap_service.dart';
import 'services/ai_notes_service.dart';
import 'services/ai_router_service.dart';
import 'services/app_settings_service.dart';
import 'services/book_ai_service.dart';
import 'services/cloud_llm_service.dart';
import 'services/currency_service.dart';
import 'services/embedding_service.dart';
import 'services/en_grammar_lesson_service.dart';
import 'services/en_grammar_service.dart';
import 'services/en_quiz_service.dart';
import 'services/en_sentence_service.dart';
import 'services/en_tts_service.dart';
import 'services/en_vocab_lesson_service.dart';
import 'services/en_vocab_service.dart';
import 'services/jp_grammar_service.dart';
import 'services/jp_sentence_service.dart';
import 'services/jp_tts_service.dart';
import 'services/jp_vocab_service.dart';
import 'services/office_prompt_template_service.dart';
import 'services/ollama_service.dart';
import 'services/personal_rag_service.dart';
import 'services/rag_service.dart';
import 'services/skills_service.dart';
import 'services/telegram_bot_service.dart';
import 'services/tts_service.dart';
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
// _aiLibToken 已移除，避免 unused_element 警告。

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
late OllamaClient globalOllama;

BookAiService? _globalBookAiService;
BookAiService get globalBookAiService =>
    _globalBookAiService ??= BookAiService(globalAiRouterService);

@visibleForTesting
set globalBookAiService(BookAiService service) =>
    _globalBookAiService = service;

AiRouterService? _globalAiRouterService;
AiRouterService get globalAiRouterService =>
    _globalAiRouterService ??= AiRouterService(
      local: OllamaService(),
      cloud: CloudLLMService(apiKey: ''),
      rag: RagService(
        embedder: EmbeddingService(),
        store: globalStore,
      ),
    );

@visibleForTesting
set globalAiRouterService(AiRouterService service) =>
    _globalAiRouterService = service;

AiHighlightService? _globalAiHighlightService;
AiHighlightService get globalAiHighlightService =>
    _globalAiHighlightService ??= AiHighlightService(globalAiRouterService);

@visibleForTesting
set globalAiHighlightService(AiHighlightService service) =>
    _globalAiHighlightService = service;

AiNotesService? _globalAiNotesService;
AiNotesService get globalAiNotesService =>
    _globalAiNotesService ??= AiNotesService(globalAiRouterService);

@visibleForTesting
set globalAiNotesService(AiNotesService service) =>
    _globalAiNotesService = service;

AiMindMapService? _globalAiMindMapService;
AiMindMapService get globalAiMindMapService =>
    _globalAiMindMapService ??= AiMindMapService(globalAiRouterService);

@visibleForTesting
set globalAiMindMapService(AiMindMapService service) =>
    _globalAiMindMapService = service;

JpGrammarService? _globalJpGrammarService;
JpGrammarService get globalJpGrammarService =>
    _globalJpGrammarService ??= JpGrammarService(globalAiRouterService);

@visibleForTesting
set globalJpGrammarService(JpGrammarService service) =>
    _globalJpGrammarService = service;

JpVocabService? _globalJpVocabService;
JpVocabService get globalJpVocabService =>
    _globalJpVocabService ??= JpVocabService(globalAiRouterService);

@visibleForTesting
set globalJpVocabService(JpVocabService service) =>
    _globalJpVocabService = service;

JpSentenceService? _globalJpSentenceService;
JpSentenceService get globalJpSentenceService =>
    _globalJpSentenceService ??= JpSentenceService(globalAiRouterService);

@visibleForTesting
set globalJpSentenceService(JpSentenceService service) =>
    _globalJpSentenceService = service;

TTSService? _globalTtsService;
TTSService get globalTtsService =>
    _globalTtsService ??= TTSService();

@visibleForTesting
set globalTtsService(TTSService service) =>
    _globalTtsService = service;

JpTtsService? _globalJpTtsService;
JpTtsService get globalJpTtsService =>
    _globalJpTtsService ??= JpTtsService(globalTtsService);

@visibleForTesting
set globalJpTtsService(JpTtsService service) =>
    _globalJpTtsService = service;

EnGrammarService? _globalEnGrammarService;
EnGrammarService get globalEnGrammarService =>
    _globalEnGrammarService ??= EnGrammarService(globalAiRouterService);

@visibleForTesting
set globalEnGrammarService(EnGrammarService service) =>
    _globalEnGrammarService = service;

EnVocabService? _globalEnVocabService;
EnVocabService get globalEnVocabService =>
    _globalEnVocabService ??= EnVocabService(globalAiRouterService);

@visibleForTesting
set globalEnVocabService(EnVocabService service) =>
    _globalEnVocabService = service;

EnSentenceService? _globalEnSentenceService;
EnSentenceService get globalEnSentenceService =>
    _globalEnSentenceService ??= EnSentenceService(globalAiRouterService);

@visibleForTesting
set globalEnSentenceService(EnSentenceService service) =>
    _globalEnSentenceService = service;

EnTtsService? _globalEnTtsService;
EnTtsService get globalEnTtsService =>
    _globalEnTtsService ??= EnTtsService(globalTtsService);

@visibleForTesting
set globalEnTtsService(EnTtsService service) =>
    _globalEnTtsService = service;

EnGrammarLessonService? _globalEnGrammarLessonService;
EnGrammarLessonService get globalEnGrammarLessonService =>
    _globalEnGrammarLessonService ??= EnGrammarLessonService(globalAiRouterService);

@visibleForTesting
set globalEnGrammarLessonService(EnGrammarLessonService service) =>
    _globalEnGrammarLessonService = service;

EnVocabLessonService? _globalEnVocabLessonService;
EnVocabLessonService get globalEnVocabLessonService =>
    _globalEnVocabLessonService ??= EnVocabLessonService(globalAiRouterService);

@visibleForTesting
set globalEnVocabLessonService(EnVocabLessonService service) =>
    _globalEnVocabLessonService = service;

EnQuizService? _globalEnQuizService;
EnQuizService get globalEnQuizService =>
    _globalEnQuizService ??= EnQuizService(globalAiRouterService);

@visibleForTesting
set globalEnQuizService(EnQuizService service) =>
    _globalEnQuizService = service;

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
  await OfficePromptTemplateService().init();

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

  globalAiRouterService = AiRouterService(
    local: OllamaService(
      baseUrl: ollamaUrl,
      model: ollamaModel,
    ),
    cloud: CloudLLMService(
      apiKey: settings.geminiApiKey ?? '',
    ),
    rag: RagService(
      embedder: embedder,
      store: globalStore,
    ),
  );

  globalBookAiService = BookAiService(globalAiRouterService);
  globalAiHighlightService = AiHighlightService(globalAiRouterService);
  globalAiNotesService = AiNotesService(globalAiRouterService);
  globalAiMindMapService = AiMindMapService(globalAiRouterService);
  globalJpGrammarService = JpGrammarService(globalAiRouterService);
  globalJpVocabService = JpVocabService(globalAiRouterService);
  globalJpSentenceService = JpSentenceService(globalAiRouterService);
  globalTtsService = TTSService();
  await globalTtsService.init();
  globalJpTtsService = JpTtsService(globalTtsService);
  globalEnGrammarService = EnGrammarService(globalAiRouterService);
  globalEnVocabService = EnVocabService(globalAiRouterService);
  globalEnSentenceService = EnSentenceService(globalAiRouterService);
  globalEnTtsService = EnTtsService(globalTtsService);
  globalEnGrammarLessonService = EnGrammarLessonService(globalAiRouterService);
  globalEnVocabLessonService = EnVocabLessonService(globalAiRouterService);
  globalEnQuizService = EnQuizService(globalAiRouterService);

  await _startServerForDesktop();
  await CurrencyService.instance.load();
  runApp(const MyApp());
}

HttpServer? activeHttpServer;

Future<void> startOrRestartServer(AppSettings settings) async {
  if (kIsWeb) return;
  if (defaultTargetPlatform != TargetPlatform.windows &&
      defaultTargetPlatform != TargetPlatform.macOS &&
      defaultTargetPlatform != TargetPlatform.linux) {
    return;
  }

  // 1. Stop existing server if running
  if (activeHttpServer != null) {
    debugPrint('[ai_library_server] Stopping existing server...');
    await activeHttpServer!.close(force: true);
    activeHttpServer = null;
  }

  // 2. If Office Bridge is disabled, do not start
  if (!settings.enableOfficeBridge) {
    debugPrint('[ai_library_server] Office Bridge is disabled in settings.');
    return;
  }

  // 3. Prepare RagService and ApiServer
  final embedModel = Platform.environment['EMBED_MODEL'] ?? 'bge-m3';
  final ollamaUrl = Platform.environment['OLLAMA_URL'] ?? 'http://localhost:11434';
  
  final rag = RagService(
    embedder: EmbeddingService(baseUrl: ollamaUrl, model: embedModel),
    store: globalStore,
  );

  final token = settings.officeBridgeToken.trim();
  final server = ApiServer(
    rag: rag,
    store: globalStore,
    generate: globalOllama.generate,
    authToken: token.isEmpty ? null : token,
  );

  // ApiServer.start() throws StateError if lanMode is true without a
  // non-blank token. Catch it explicitly so a misconfigured release
  // build prints a clear diagnostic instead of a bare uncaught error.
  try {
    activeHttpServer = await server.start(port: settings.officeBridgePort, lanMode: _aiLibLan);
    debugPrint('[ai_library_server] Server started successfully on port ${settings.officeBridgePort}');
  } on StateError catch (e) {
    debugPrint('[ai_library_server] startup refused: ${e.message}');
    debugPrint(
      '[ai_library_server] hint: pass --dart-define=AI_LIB_TOKEN=<secret> '
      'or omit AI_LIB_LAN to keep the server loopback-only.',
    );
  } catch (e) {
    debugPrint('[ai_library_server] startup error: $e');
  }
}

Future<void> _startServerForDesktop() async {
  final settings = await AppSettingsService().load();
  await startOrRestartServer(settings);
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



