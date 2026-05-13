// lib/screens/chat_screen.dart
import 'dart:async';
import 'dart:io' show File;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/chat_send_controller.dart';
import '../controllers/rag_chat_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../models/message.dart';
import '../services/app_settings_service.dart';
import '../services/chat_session_service.dart';
import '../services/debug_log_service.dart';
import '../services/export_service.dart';
import '../services/ollama_service.dart';
import '../services/pdf_service.dart';
import '../services/rag_service.dart';
import '../services/speech_service.dart';
import '../services/vector_store.dart';
import '../widgets/chat_app_bar.dart';
import '../widgets/chat_app_bar_actions.dart';
import '../widgets/chat_ingest_status_bar.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_library_sheet.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_session_drawer.dart';
import '../widgets/rag_context_banner.dart';
import 'doc_viewer_screen.dart';
import 'rag_evaluation_screen.dart';
import 'settings_screen.dart';

const _maxIngestFileBytes = 20 * 1024 * 1024;
const _extractTimeout = Duration(seconds: 60);

Future<String> extractTextForIngest(Map<String, String> args) async {
  final path = args['path']!;
  final name = args['name']!;
  if (name.toLowerCase().endsWith('.pdf')) {
    return PdfService.extractAll(path);
  }
  return File(path).readAsString();
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _speech = SpeechService();
  final _store = VectorStore();
  final _messages = <ChatMessage>[];
  final _availableModels = <String>[];
  final _sendController = const ChatSendController();
  late final SaveDebouncer _saveDebouncer;

  late OllamaService _ollama;
  late RagChatController _ragController;
  RagService get _rag => _ragController.rag;
  final _settingsService = AppSettingsService();

  final _sessions = <ChatSession>[];
  ChatSession? _currentSession;

  String _model = 'qwen2.5:7b';
  AppSettings _settings = const AppSettings(
    embeddingModel: AppSettings.defaultEmbeddingModel,
  );
  String _embedModel = AppSettings.defaultEmbeddingModel;
  bool _busy = false;
  bool _listening = false;
  bool _cancelIngest = false;
  bool _ingesting = false;
  String? _ingestProgressText;
  bool _ragEnabled = true;
  int _topK = 4;
  String? _activeDoc;

  static const _systemPrompt = '你係一個樂於助人嘅 AI 助手。'
      '若有「相關段落」提供，請優先依據引用內容作答，並標註來源。'
      '若資料不足，請誠實說明，再用一般知識補充。';

  @override
  void initState() {
    super.initState();
    _ollama = OllamaService(model: _model);
    _ragController = RagChatController(
      store: _store,
      initialEmbeddingModel: _embedModel,
    );
    _saveDebouncer = SaveDebouncer(
      delay: const Duration(milliseconds: 600),
      onSave: ChatSessionService.saveSession,
    );
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadSettings();
    await _store.load(sparseIndexBuilder: RagService.buildSparseIndex);
    await _clearVectorStoreIfEmbeddingMismatch();
    await _loadSessions();
    if (_normalizeActiveDoc()) {
      _scheduleSave();
    }
    await _loadModels();
    if (mounted) setState(() {});
  }

  Future<void> _clearVectorStoreIfEmbeddingMismatch() async {
    final storeModel = _store.embeddingModel;
    if (!_ragController.hasEmbeddingMismatch(_embedModel)) return;

    await _ragController.clearVectorStore();
    await DebugLogService.append(
      'Embedding mismatch detected: store=$storeModel current=$_embedModel '
      'storeCleared=true',
    );
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.load();
    if (!mounted) return;

    setState(() {
      _settings = settings;
      _applyEmbeddingModel(settings.embeddingModel);
    });
  }

  void _applyEmbeddingModel(String model) {
    _embedModel = model;
    _ragController.applyEmbeddingModel(model);
    unawaited(DebugLogService.append(
      'Embedding apply: embeddingModel=$model',
    ));
  }

  Future<bool> _isOllamaModelInstalled(String model) async {
    try {
      final models = await OllamaService().listModels();
      return models.any((installed) {
        if (installed == model) return true;
        if (!model.contains(':') && installed == '$model:latest') return true;
        if (!model.contains(':') && installed.split(':').first == model) {
          return true;
        }
        return false;
      });
    } catch (e) {
      await DebugLogService.append(
        'Embedding availability check failed: model=$model error=$e',
      );
      return false;
    }
  }

  ChatMessage get _systemMessage =>
      ChatMessage(role: Role.system, content: _systemPrompt);

  Future<void> _loadSessions() async {
    final loaded = await ChatSessionService.loadSessions();
    if (!mounted) return;

    if (loaded.isEmpty) {
      final session =
          await ChatSessionService.createNew(systemPrompt: _systemMessage);
      loaded.add(session);
    }

    setState(() {
      _sessions
        ..clear()
        ..addAll(loaded);
      _currentSession = _sessions.first;
      _syncFromCurrentSession();
    });
  }

  void _syncFromCurrentSession() {
    final session = _currentSession;
    _messages.clear();
    _activeDoc = session?.activeDoc;
    if (session == null) return;

    _messages.addAll(session.messages);
    if (_messages.where((m) => m.role != Role.system).isEmpty) {
      _messages.add(ChatMessage(
        role: Role.assistant,
        content: '你好！👋\n你想聊些什麼？😊',
      ));
    }
  }

  bool _normalizeActiveDoc() {
    final active = _activeDoc;
    if (_ragController.isValidActiveDoc(active)) return false;

    _activeDoc = null;
    unawaited(DebugLogService.append(
      'Active doc cleared: missingDoc=$active reason=not_in_vector_store',
      level: 'WARN',
    ));
    return true;
  }

  void _syncToCurrentSession() {
    final session = _currentSession;
    if (session == null) return;
    session.messages
      ..clear()
      ..addAll(_messages);
    session.activeDoc = _activeDoc;
    session.updatedAt = DateTime.now();
  }

  void _scheduleSave() {
    final session = _currentSession;
    if (session == null) return;
    _syncToCurrentSession();
    _saveDebouncer.schedule(session);
    _resortSessions();
  }

  Future<void> _saveNow() async {
    final session = _currentSession;
    if (session == null) return;
    _syncToCurrentSession();
    await ChatSessionService.saveSession(session);
    unawaited(DebugLogService.append(
      'Session saved: id=${session.id} messages=${session.messages.length} '
      'activeDoc=${session.activeDoc ?? '(none)'}',
    ));
    _resortSessions();
  }

  void _resortSessions() {
    _sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  void _updateTitleFromFirstUserMessage() {
    final session = _currentSession;
    if (session == null || session.title != '新對話') return;
    final firstUser = _messages
        .where((message) => message.role == Role.user)
        .map((message) => message.content.trim())
        .where((text) => text.isNotEmpty)
        .firstOrNull;
    if (firstUser == null) return;

    final compact = firstUser.replaceAll(RegExp(r'\s+'), ' ');
    session.title =
        compact.length > 18 ? '${compact.substring(0, 18)}…' : compact;
  }

  Future<void> _switchSession(ChatSession session) async {
    if (_currentSession?.id == session.id) {
      Navigator.of(context).maybePop();
      return;
    }
    await _saveDebouncer.flush();
    await _saveNow();
    if (!mounted) return;
    setState(() {
      _currentSession = session;
      _syncFromCurrentSession();
    });
    Navigator.of(context).maybePop();
    _scrollToEnd(force: true);
  }

  Future<void> _newSession() async {
    await _saveDebouncer.flush();
    await _saveNow();
    final session =
        await ChatSessionService.createNew(systemPrompt: _systemMessage);
    if (!mounted) return;
    setState(() {
      _sessions.insert(0, session);
      _currentSession = session;
      _syncFromCurrentSession();
    });
    Navigator.of(context).maybePop();
    _scrollToEnd(force: true);
  }

  Future<void> _renameSession(ChatSession session) async {
    final controller = TextEditingController(text: session.title);
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重新命名'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Session 名稱'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('儲存'),
          ),
        ],
      ),
    );
    controller.dispose();

    final trimmed = title?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    setState(() {
      session.title = trimmed;
      session.updatedAt = DateTime.now();
    });
    await ChatSessionService.saveSession(session);
  }

  Future<void> _deleteSession(ChatSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('刪除對話？'),
        content: Text('「${session.title}」會永久刪除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final deletingCurrent = _currentSession?.id == session.id;
    await ChatSessionService.deleteSession(session.id);
    _sessions.removeWhere((item) => item.id == session.id);

    if (_sessions.isEmpty) {
      final replacement =
          await ChatSessionService.createNew(systemPrompt: _systemMessage);
      _sessions.add(replacement);
    }

    if (!mounted) return;
    setState(() {
      if (deletingCurrent) {
        _currentSession = _sessions.first;
        _syncFromCurrentSession();
      }
    });
  }

  Future<void> _showSessionsPath() async {
    final dir = await ChatSessionService.sessionsDirectory();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session 儲存位置'),
        content: SelectableText(dir.path),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDebugLogPath() async {
    final file = await DebugLogService.logFile();
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('RAG debug log'),
        content: SelectableText(file.path),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadModels() async {
    try {
      final list = await _ollama.listModels();
      if (!mounted) return;
      setState(() {
        _availableModels
          ..clear()
          ..addAll(list);
        if (list.isNotEmpty && !list.contains(_model)) {
          _model = list.first;
          _ollama = OllamaService(model: _model);
        }
      });
    } catch (e) {
      await DebugLogService.append(
        'Ollama model list failed: error=$e',
        level: 'ERROR',
      );
      _snack('連接 Ollama 失敗：$e\n請確認已執行 `ollama serve`');
    }
  }

  void _snack(String msg, {bool showLogAction = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        action: showLogAction
            ? SnackBarAction(
                label: '複製 log 路徑',
                onPressed: () => unawaited(_copyDebugLogPath()),
              )
            : null,
      ),
    );
  }

  Future<void> _copyDebugLogPath() async {
    final file = await DebugLogService.logFile();
    await Clipboard.setData(ClipboardData(text: file.path));
    _snack('已複製 debug log 路徑');
  }

  Future<void> _pickFile() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt', 'md'],
    );
    if (res == null || res.files.single.path == null) return;

    final path = res.files.single.path!;
    final name = res.files.single.name;
    final file = File(path);
    final bytes = await file.length();
    if (bytes > _maxIngestFileBytes) {
      _snack('檔案太大（>20MB），請先壓縮或分割檔案再匯入。');
      return;
    }

    _cancelIngest = false;
    setState(() {
      _busy = true;
      _ingesting = true;
      _ingestProgressText = '正在讀取「$name」…';
    });

    try {
      final text = await compute(
        extractTextForIngest,
        {'path': path, 'name': name},
      ).timeout(_extractTimeout);
      if (_cancelIngest) return;

      if (text.trim().length < 20) {
        if (!mounted) return;
        setState(() {
          _messages.add(ChatMessage(
            role: Role.assistant,
            content: '⚠️ 載入「$name」失敗：抽取唔到文字內容。\n\n'
                '可能原因：\n'
                '• 呢份 PDF 係掃瞄圖檔（無文字層），需要先用 OCR 轉換\n'
                '• 檔案損壞或加密\n'
                '• 文件本身內容太少',
          ));
        });
        _scheduleSave();
        return;
      }

      final ingestStarted = DateTime.now();
      final ingestStartLog =
          'RAG ingest: start doc=$name embeddingModel=$_embedModel '
          'chars=${text.length}';
      debugPrint(ingestStartLog);
      unawaited(DebugLogService.append(ingestStartLog));
      _snack('正在用 $_embedModel 切塊並建立向量索引…');
      if (mounted) {
        setState(() {
          _ingestProgressText = '正在用 $_embedModel 切塊並建立向量索引…';
        });
      }
      final ingestResult = await _rag.ingestDetailed(
        docName: name,
        text: text,
        batchSize: 4,
        onProgress: (done, total) {
          if (_cancelIngest) return;
          if (mounted) {
            setState(() {
              _ingestProgressText = '建立向量索引：$done / $total（$_embedModel）';
            });
          }
          if (done == total) _snack('索引完成：$total 個片段（$_embedModel）');
        },
        cancelCheck: () => _cancelIngest,
      );
      if (_cancelIngest || ingestResult.cancelled) {
        _snack('已取消匯入「$name」');
        return;
      }
      if (ingestResult.failed) {
        await DebugLogService.append(
          'RAG ingest: failed doc=$name embeddingModel=$_embedModel '
          'chunksWritten=${ingestResult.chunksWritten} '
          'error=${ingestResult.error}\n${ingestResult.stackTrace}',
          level: 'ERROR',
        );
        _snack('建立向量索引失敗：${ingestResult.error}', showLogAction: true);
        return;
      }
      final count = ingestResult.chunksWritten;
      _store.setEmbeddingModel(_embedModel);
      await _store.save();
      final ingestMs = DateTime.now().difference(ingestStarted).inMilliseconds;
      final ingestDoneLog =
          'RAG ingest: done doc=$name embeddingModel=$_embedModel '
          'chunks=$count durationMs=$ingestMs storeChunks=${_store.length} '
          'storeEmbeddingModel=${_store.embeddingModel}';
      debugPrint(ingestDoneLog);
      unawaited(DebugLogService.append(ingestDoneLog));

      setState(() {
        _activeDoc = name;
        _messages.add(ChatMessage(
          role: Role.assistant,
          content: '已載入「$name」（共 ${text.length} 字，$count 個向量片段）。\n'
              'Embedding model：$_embedModel\n'
              '可以問我關於呢份文件嘅問題；按工具列 📚 可預覽切塊。',
        ));
      });
      _scheduleSave();
      await _saveNow();
    } on TimeoutException catch (e) {
      await DebugLogService.append(
        'RAG ingest: extract timeout doc=$name embeddingModel=$_embedModel '
        'error=$e',
        level: 'WARN',
      );
      _snack('處理超時，請再試一次或使用較小檔案。', showLogAction: true);
    } catch (e, st) {
      await DebugLogService.append(
        'RAG ingest: failed doc=$name embeddingModel=$_embedModel '
        'error=$e\n$st',
        level: 'ERROR',
      );
      _snack('讀取失敗：$e', showLogAction: true);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _ingesting = false;
          _ingestProgressText = null;
        });
      }
      _scrollToEnd(force: true);
    }
  }

  void _cancelCurrentIngest() {
    if (!_ingesting) return;
    setState(() {
      _cancelIngest = true;
      _ingestProgressText = '正在取消匯入…';
    });
  }

  Future<void> _removeDoc(String name) async {
    _store.removeDoc(name);
    await _store.save();
    setState(() {
      _normalizeActiveDoc();
    });
    _scheduleSave();
    _snack('已移除：$name');
  }

  Future<void> _openDocViewer(
    String docName, {
    int? initialChunkIndex,
  }) async {
    final isCitationOpen = initialChunkIndex != null;
    unawaited(DebugLogService.append(
      isCitationOpen
          ? 'Citation tapped: doc=$docName chunkIndex=$initialChunkIndex'
          : 'DocViewer opened: doc=$docName source=library',
    ));

    final selected = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => DocViewerScreen(
          store: _store,
          docName: docName,
          initialChunkIndex: initialChunkIndex,
        ),
      ),
    );
    if (selected != null && selected.isNotEmpty) {
      setState(() {
        _messages.add(
          ChatMessage(
              role: Role.system,
              content: '【用戶手動加入嘅參考片段】\n\n${selected.join("\n\n---\n\n")}'),
        );
        _input.text = '請根據上述片段回答：';
      });
      _scheduleSave();
      _snack('已加入 ${selected.length} 個片段作為下一輪 context');
    }
  }

  Future<void> _openSettings() async {
    final proposed = await Navigator.of(context).push<AppSettings>(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          currentSettings: _settings,
        ),
      ),
    );

    if (proposed == null) return;
    await _handleProposedSettings(proposed);
  }

  void _openRagEvaluation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RagEvaluationScreen(
          chatModel: _model,
          embeddingModel: _embedModel,
        ),
      ),
    );
  }

  void _setChatModel(String model) {
    setState(() {
      _model = model;
      _ollama = OllamaService(model: model);
    });
  }

  Future<void> _handleProposedSettings(AppSettings proposed) async {
    final oldModel = _settings.embeddingModel;
    final newModel = proposed.embeddingModel;

    if (newModel == oldModel) {
      setState(() {
        _settings = proposed;
        _applyEmbeddingModel(newModel);
      });
      await _settingsService.save(proposed);
      await DebugLogService.append(
        'Settings changed: embeddingModel=$newModel '
        'retrievalMode=${proposed.retrievalMode.name}',
      );
      return;
    }

    final installed = await _isOllamaModelInstalled(newModel);
    if (!installed) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      await DebugLogService.append(
        'Embedding change rejected: model=$newModel installed=false',
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Embedding model 未安裝：$newModel。請先執行 ollama pull $newModel。',
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('更換 embedding model？'),
        content: Text(
          '將 embedding model 從 $oldModel 改為 $newModel 會清空目前 vector store。'
          '你需要重新匯入文件。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清空並套用'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      _store.clear();
      await _store.save();
      await _settingsService.save(proposed);
      await DebugLogService.append(
        'Embedding changed: old=$oldModel new=$newModel '
        'storeCleared=true storeChunks=${_store.length} '
        'storeEmbeddingModel=${_store.embeddingModel}',
      );

      if (!mounted) return;

      setState(() {
        _settings = proposed;
        _activeDoc = null;
        _applyEmbeddingModel(newModel);
      });
      _scheduleSave();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已更換 embedding model，請重新匯入文件。'),
        ),
      );
    } catch (e) {
      await DebugLogService.append(
        'Settings save failed: error=$e',
        level: 'ERROR',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('設定儲存失敗：$e'),
          action: SnackBarAction(
            label: '複製 log 路徑',
            onPressed: () => unawaited(_copyDebugLogPath()),
          ),
        ),
      );
    }
  }

  Future<void> _toggleMic() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    try {
      await _speech.start(
        onResult: (text, isFinal) {
          setState(() => _input.text = text);
          if (isFinal) setState(() => _listening = false);
        },
      );
      setState(() => _listening = true);
    } catch (e) {
      await DebugLogService.append(
        'Speech input failed: error=$e',
        level: 'WARN',
      );
      final msg = e.toString().toLowerCase();
      if (msg.contains('missingplugin') ||
          msg.contains('unimplemented') ||
          msg.contains('not implemented')) {
        _snack('Windows 桌面版未原生支援語音輸入。\n'
            '請喺 Windows 設定 → 時間和語言 → 語音 中開啟「線上語音辨識」，\n'
            '或者直接用鍵盤輸入。');
      } else {
        _snack('語音失敗：$e', showLogAction: true);
      }
    }
  }

  Future<void> _exportChat() async {
    if (_messages.where((m) => m.role != Role.system).isEmpty) {
      _snack('未有對話可匯出');
      return;
    }
    setState(() => _busy = true);
    try {
      final path = await ExportService.saveAs(messages: _messages);
      if (path != null) _snack('已匯出：$path');
    } catch (e, st) {
      await DebugLogService.append(
        'Chat export failed: error=$e\n$st',
        level: 'ERROR',
      );
      _snack('匯出失敗：$e', showLogAction: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy) return;

    final userMsg = ChatMessage(role: Role.user, content: text);
    setState(() {
      _input.clear();
      _busy = true;
      _messages.add(userMsg);
      _messages.add(ChatMessage(role: Role.assistant, content: ''));
      _updateTitleFromFirstUserMessage();
    });
    _scheduleSave();

    final context = await _sendController.buildContext(
      query: text,
      ragEnabled: _ragEnabled,
      storeLength: _store.length,
      rag: _rag,
      embeddingModel: _embedModel,
      retrievalMode: _settings.retrievalMode,
      activeDoc: _activeDoc,
      topK: _topK,
      systemPrompt: _systemPrompt,
      currentMessages: _messages,
    );
    if (context.retrieveError != null) {
      _snack('檢索失敗（將直接問模型）：${context.retrieveError}', showLogAction: true);
    }
    if (context.blockedMessage != null) {
      _replaceAssistantMessage(context.blockedMessage!);
      if (mounted) setState(() => _busy = false);
      await _saveNow();
      return;
    }

    _scrollToEnd(force: true);

    try {
      final content = await _sendController.streamAssistantResponse(
        ollama: _ollama,
        outgoing: context.outgoing,
        onContent: _replaceAssistantMessage,
      );
      if (context.hits.isNotEmpty) {
        _replaceAssistantMessage(
          _sendController.appendSources(content, context.hits),
        );
        await _saveNow();
      }
    } catch (e, st) {
      await DebugLogService.append(
        'Ollama chat stream failed: model=$_model error=$e\n$st',
        level: 'ERROR',
      );
      setState(() {
        _messages[_messages.length - 1] =
            ChatMessage(role: Role.assistant, content: '出錯：$e');
      });
      _snack('模型回覆失敗，詳情已寫入 debug log。', showLogAction: true);
    } finally {
      if (mounted) setState(() => _busy = false);
      await _saveNow();
    }
  }

  void _replaceAssistantMessage(String content) {
    setState(() {
      _messages[_messages.length - 1] = ChatMessage(
        role: Role.assistant,
        content: content,
      );
    });
    _scrollToEnd();
  }

  void _scrollToEnd({
    Duration duration = const Duration(milliseconds: 200),
    bool force = false,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final maxScroll = _scroll.position.maxScrollExtent;
      final isNearBottom = _scroll.offset >= maxScroll - 200;
      if (!force && !isNearBottom) return;
      _scroll.animateTo(
        maxScroll,
        duration: duration,
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _clearChat() async {
    final session = _currentSession;
    if (session == null) return;

    setState(() {
      _messages
        ..clear()
        ..add(_systemMessage)
        ..add(ChatMessage(role: Role.assistant, content: '你好！👋'));
      session.title = '新對話';
      _activeDoc = null;
    });
    await _saveNow();
  }

  void _openLibrary() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChatLibrarySheet(
        store: _store,
        activeDoc: _activeDoc,
        topK: _topK,
        onOpenDoc: (docName) => unawaited(_openDocViewer(docName)),
        onRemoveDoc: _removeDoc,
        onSetActiveDoc: (docName) {
          setState(() {
            _activeDoc = docName;
            _normalizeActiveDoc();
          });
          _scheduleSave();
          _snack(docName == null ? '已重設：搜尋全部文件' : '只搜尋：$docName');
        },
        onTopKChanged: (topK) => setState(() => _topK = topK),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visible = _messages.where((m) => m.role != Role.system).toList();
    final title = _currentSession?.title ?? l10n.chatTitle;

    return Scaffold(
      drawer: ChatSessionDrawer(
        sessions: _sessions,
        currentSession: _currentSession,
        onNewSession: _newSession,
        onSwitchSession: _switchSession,
        onRenameSession: _renameSession,
        onDeleteSession: _deleteSession,
      ),
      appBar: ChatAppBar(
        title: title,
        activeDoc: _activeDoc,
        availableModels: _availableModels,
        model: _model,
        busy: _busy,
        ragEnabled: _ragEnabled,
        actions: ChatAppBarActions(
          onOpenEvaluation: _openRagEvaluation,
          onOpenSettings: _openSettings,
          onModelChanged: _setChatModel,
          onToggleRag: () => setState(() => _ragEnabled = !_ragEnabled),
          onLoadModels: _loadModels,
          onOpenLibrary: _openLibrary,
          onExportChat: _exportChat,
          onClearChat: _clearChat,
          onShowSessionsPath: _showSessionsPath,
          onShowDebugLogPath: _showDebugLogPath,
        ),
      ),
      body: Column(
        children: [
          RagContextBanner(
            hasChunks: _store.length > 0,
            docCount: _store.docNames.length,
            activeDoc: _activeDoc,
            topK: _topK,
            embeddingModel: _embedModel,
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: visible.length,
              itemBuilder: (_, i) => ChatMessageBubble(
                message: visible[i],
                onCitationTap: (docName, chunkIndex) async {
                  await _openDocViewer(
                    docName,
                    initialChunkIndex: chunkIndex,
                  );
                },
              ),
            ),
          ),
          ChatIngestStatusBar(
            ingesting: _ingesting,
            busy: _busy,
            cancelIngest: _cancelIngest,
            progressText: _ingestProgressText,
            onCancel: _cancelCurrentIngest,
          ),
          ChatInputBar(
            controller: _input,
            busy: _busy,
            listening: _listening,
            onPickFile: _pickFile,
            onToggleMic: _toggleMic,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cancelIngest = true;
    unawaited(_saveDebouncer.flush());
    _saveDebouncer.dispose();
    _input.dispose();
    _scroll.dispose();
    _speech.cancel();
    super.dispose();
  }
}

