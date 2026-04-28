// lib/screens/chat_screen.dart
import 'dart:async';
import 'dart:io' show File;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_settings.dart';
import '../models/message.dart';
import '../services/app_settings_service.dart';
import '../services/chat_session_service.dart';
import '../services/debug_log_service.dart';
import '../services/embedding_service.dart';
import '../services/export_service.dart';
import '../services/ollama_service.dart';
import '../services/pdf_service.dart';
import '../services/rag_service.dart';
import '../services/speech_service.dart';
import '../services/vector_store.dart';
import '../utils/citation_parser.dart';
import '../widgets/code_block.dart';
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
  late final SaveDebouncer _saveDebouncer;

  late OllamaService _ollama;
  late EmbeddingService _embedder;
  late RagService _rag;
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
    _embedder = EmbeddingService(model: _embedModel);
    _rag = RagService(embedder: _embedder, store: _store);
    _saveDebouncer = SaveDebouncer(
      delay: const Duration(milliseconds: 600),
      onSave: ChatSessionService.saveSession,
    );
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadSettings();
    await _store.load();
    await _clearVectorStoreIfEmbeddingMismatch();
    await _loadSessions();
    await _loadModels();
    if (mounted) setState(() {});
  }

  Future<void> _clearVectorStoreIfEmbeddingMismatch() async {
    final storeModel = _store.embeddingModel;
    if (_store.length == 0 || storeModel == _embedModel) return;

    _store.clear();
    await _store.save();
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
    _embedder = EmbeddingService(model: model);
    _rag = RagService(embedder: _embedder, store: _store);
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
      final count = await _rag.ingest(
        docName: name,
        text: text,
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
      if (_cancelIngest) {
        _snack('已取消匯入「$name」');
        return;
      }
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
      if (_activeDoc == name) _activeDoc = null;
    });
    _scheduleSave();
    _snack('已移除：$name');
  }

  Future<void> _openDocViewer(
    String docName, {
    int? initialChunkIndex,
  }) async {
    if (initialChunkIndex != null) {
      unawaited(DebugLogService.append(
        'Citation tapped: doc=$docName chunkIndex=$initialChunkIndex',
      ));
    }

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

  Future<void> _handleProposedSettings(AppSettings proposed) async {
    final oldModel = _settings.embeddingModel;
    final newModel = proposed.embeddingModel;

    if (newModel == oldModel) {
      setState(() {
        _settings = proposed;
        _applyEmbeddingModel(newModel);
      });
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

    final outgoing = <ChatMessage>[
      ChatMessage(role: Role.system, content: _systemPrompt),
    ];

    List<ScoredChunk> hits = const [];
    if (_ragEnabled && _store.length > 0) {
      try {
        final retrieveStarted = DateTime.now();
        final retrieveStartLog =
            'RAG retrieve: start query="$text" embeddingModel=$_embedModel '
            'doc=${_activeDoc ?? '(all)'} topK=$_topK chunks=${_store.length}';
        debugPrint(retrieveStartLog);
        unawaited(DebugLogService.append(retrieveStartLog));
        hits = await _rag.retrieve(text, k: _topK, docName: _activeDoc);
        final retrieveMs =
            DateTime.now().difference(retrieveStarted).inMilliseconds;
        final scores = hits
            .map((hit) =>
                '${hit.chunk.docName}#${hit.chunk.chunkIndex}:${hit.score.toStringAsFixed(3)}')
            .join(', ');
        final diagnostics = _rag.lastDiagnostics?.summary();
        final retrieveDoneLog =
            'RAG retrieve: done hits=${hits.length} durationMs=$retrieveMs '
            'scores=[$scores]'
            '${diagnostics == null ? '' : ' $diagnostics'}';
        debugPrint(retrieveDoneLog);
        unawaited(DebugLogService.append(retrieveDoneLog));
        if (hits.isNotEmpty && !RagService.hasKeywordGrounding(text, hits)) {
          setState(() {
            _messages[_messages.length - 1] = ChatMessage(
              role: Role.assistant,
              content: '在文件中沒有找到相關資訊。請確認已載入正確文件，或換個問法再試。',
            );
          });
          _scrollToEnd();
          if (mounted) setState(() => _busy = false);
          await _saveNow();
          return;
        }

        if (hits.isNotEmpty) {
          outgoing.add(ChatMessage(
            role: Role.system,
            content: RagService.buildContext(hits),
          ));
        }
      } catch (e, st) {
        await DebugLogService.append(
          'RAG retrieve failed: query="$text" embeddingModel=$_embedModel '
          'doc=${_activeDoc ?? '(all)'} error=$e\n$st',
          level: 'ERROR',
        );
        _snack('檢索失敗（將直接問模型）：$e', showLogAction: true);
      }
    }

    outgoing.addAll(_messages.where(
      (m) =>
          m.role != Role.system ||
          m.content.startsWith('【') ||
          m.content.startsWith('【相關段落】'),
    ));

    _scrollToEnd(force: true);

    final buffer = StringBuffer();
    try {
      final stream = _ollama.chatStream(outgoing);
      await for (final chunk in stream) {
        buffer.write(chunk);
        setState(() {
          _messages[_messages.length - 1] = ChatMessage(
            role: Role.assistant,
            content: buffer.toString(),
          );
        });
        _scrollToEnd();
      }
      if (hits.isNotEmpty) {
        final sources = hits.map((h) {
          final docName = h.chunk.docName;
          final doc = Uri.encodeQueryComponent(docName);
          final index = h.chunk.chunkIndex;
          final score = h.score.toStringAsFixed(2);
          return '• [$docName #$index ($score)](chunk:?doc=$doc&i=$index)';
        }).join('\n');
        setState(() {
          _messages[_messages.length - 1] = ChatMessage(
            role: Role.assistant,
            content: '${buffer.toString().trim()}\n\n📚 引用來源：\n$sources',
          );
        });
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
      builder: (_) {
        final docs = _store.docNames;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.library_books),
                  title: const Text('文件庫'),
                  subtitle: Text('共 ${docs.length} 份文件 / ${_store.length} 個片段'),
                ),
                const Divider(height: 1),
                if (docs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('尚未載入任何文件'),
                  ),
                ...docs.map((d) => ListTile(
                      leading: Icon(
                        _activeDoc == d
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                      ),
                      title: Text(d),
                      subtitle: Text('${_store.chunksOf(d).length} 個片段 — 點擊預覽'),
                      onTap: () {
                        Navigator.pop(context);
                        _openDocViewer(d);
                      },
                      onLongPress: () {
                        setState(() => _activeDoc = _activeDoc == d ? null : d);
                        _scheduleSave();
                        Navigator.pop(context);
                        _snack(_activeDoc == null
                            ? '已重設：搜尋全部文件'
                            : '只搜尋：$_activeDoc');
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          Navigator.pop(context);
                          await _removeDoc(d);
                        },
                      ),
                    )),
                if (docs.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: Text(_activeDoc == null ? '搜全部 ✓' : '搜全部'),
                          selected: _activeDoc == null,
                          onSelected: (_) {
                            setState(() => _activeDoc = null);
                            _scheduleSave();
                            Navigator.pop(context);
                          },
                        ),
                        InputChip(
                          avatar: const Icon(Icons.tune, size: 18),
                          label: Text('Top-K：$_topK'),
                          onPressed: () async {
                            final v = await showDialog<int>(
                              context: context,
                              builder: (_) => _TopKPicker(current: _topK),
                            );
                            if (v != null) setState(() => _topK = v);
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const ListTile(
              leading: Icon(Icons.forum),
              title: Text('AI 語言圖書館'),
              subtitle: Text('多對話 sessions'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FilledButton.icon(
                onPressed: _newSession,
                icon: const Icon(Icons.add),
                label: const Text('新對話'),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _sessions.length,
                itemBuilder: (context, index) {
                  final session = _sessions[index];
                  final selected = session.id == _currentSession?.id;
                  return ListTile(
                    selected: selected,
                    leading: const Icon(Icons.chat_bubble_outline),
                    title: Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${session.messages.where((m) => m.role != Role.system).length} 則訊息 · ${_formatTime(session.updatedAt)}',
                    ),
                    onTap: () => _switchSession(session),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'rename':
                            _renameSession(session);
                            break;
                          case 'delete':
                            _deleteSession(session);
                            break;
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'rename',
                          child: Text('重新命名'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('刪除'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    return '${local.month}/${local.day} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final visible = _messages.where((m) => m.role != Role.system).toList();
    final title = _currentSession?.title ?? 'AI 語音圖書館';

    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (_activeDoc != null)
              Text(
                '正在問：$_activeDoc',
                style: Theme.of(context).textTheme.labelSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'RAG 評測記錄',
            icon: const Icon(Icons.fact_check_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RagEvaluationScreen(
                    chatModel: _model,
                    embeddingModel: _embedModel,
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: '設定',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
          if (_availableModels.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButton<String>(
                value: _model,
                underline: const SizedBox(),
                items: _availableModels
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _model = v;
                    _ollama = OllamaService(model: v);
                  });
                },
              ),
            ),
          IconButton(
            icon: Icon(
                _ragEnabled ? Icons.auto_awesome : Icons.auto_awesome_outlined),
            tooltip: _ragEnabled ? '停用 RAG' : '啟用 RAG',
            onPressed: () => setState(() => _ragEnabled = !_ragEnabled),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重整模型列表',
            onPressed: _busy ? null : _loadModels,
          ),
          IconButton(
            icon: const Icon(Icons.library_books),
            tooltip: '文件庫',
            onPressed: _openLibrary,
          ),
          PopupMenuButton<String>(
            onSelected: (k) {
              switch (k) {
                case 'export':
                  _exportChat();
                  break;
                case 'clear':
                  _clearChat();
                  break;
                case 'path':
                  _showSessionsPath();
                  break;
                case 'debugLog':
                  _showDebugLogPath();
                  break;
                case 'settings':
                  _openSettings();
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Embedding 設定'),
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.ios_share),
                  title: Text('匯出對話為 Markdown'),
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.delete_sweep),
                  title: Text('清除目前對話'),
                ),
              ),
              PopupMenuItem(
                value: 'path',
                child: ListTile(
                  leading: Icon(Icons.folder),
                  title: Text('Session 儲存位置'),
                ),
              ),
              PopupMenuItem(
                value: 'debugLog',
                child: ListTile(
                  leading: Icon(Icons.article_outlined),
                  title: Text('RAG debug log 位置'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_store.length > 0)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.secondaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.menu_book, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _activeDoc != null
                          ? '正在問：$_activeDoc'
                          : '搜尋全部文件（${_store.docNames.length} 份）',
                    ),
                  ),
                  Text(
                    'Top-$_topK · $_embedModel',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: visible.length,
              itemBuilder: (_, i) => _Bubble(
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
          if (_ingesting)
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _ingestProgressText ?? '正在建立向量索引…',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _cancelIngest ? null : _cancelCurrentIngest,
                      icon: const Icon(Icons.close),
                      label: const Text('取消'),
                    ),
                  ],
                ),
              ),
            )
          else if (_busy)
            const LinearProgressIndicator(minHeight: 2),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    tooltip: '載入 PDF / TXT',
                    onPressed: _busy ? null : _pickFile,
                  ),
                  IconButton(
                    icon: Icon(_listening ? Icons.mic : Icons.mic_none),
                    color: _listening ? Colors.red : null,
                    tooltip: '語音輸入',
                    onPressed: _busy ? null : _toggleMic,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: '輸入訊息…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  FilledButton.icon(
                    onPressed: _busy ? null : _send,
                    icon: const Icon(Icons.send),
                    label: const Text('傳送'),
                  ),
                ],
              ),
            ),
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

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final Future<void> Function(String docName, int? chunkIndex)? onCitationTap;

  const _Bubble({
    required this.message,
    this.onCitationTap,
  });

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleLink(BuildContext context, String? href) async {
    if (href == null || href.trim().isEmpty) {
      _showSnack(context, '連結格式錯誤');
      return;
    }

    final normalizedHref = href.trim().replaceAll('&amp;', '&');
    final uri = Uri.tryParse(normalizedHref);
    if (uri == null) {
      _showSnack(context, '連結格式錯誤');
      return;
    }

    if (uri.scheme == 'chunk') {
      final target = parseCitationLinkTarget(normalizedHref);
      if (target == null) {
        _showSnack(context, '引用缺少文件名稱');
        return;
      }

      await onCitationTap?.call(target.docName, target.chunkIndex);
      return;
    }

    const allowedSchemes = {'http', 'https', 'mailto', 'tel'};
    if (!allowedSchemes.contains(uri.scheme)) {
      _showSnack(context, '不支援的連結類型');
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      _showSnack(context, '無法開啟連結');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == Role.user;
    final cs = Theme.of(context).colorScheme;
    final codeBlockBuilder = CodeBlockBuilder();
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: MarkdownBody(
          data: message.content.isEmpty ? '…' : message.content,
          selectable: true,
          builders: {
            'pre': codeBlockBuilder,
            'code': codeBlockBuilder,
          },
          onTapLink: (text, href, title) {
            unawaited(_handleLink(context, href));
          },
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            p: TextStyle(
              color: isUser ? cs.onPrimaryContainer : cs.onSurface,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _TopKPicker extends StatefulWidget {
  final int current;
  const _TopKPicker({required this.current});
  @override
  State<_TopKPicker> createState() => _TopKPickerState();
}

class _TopKPickerState extends State<_TopKPicker> {
  late int v = widget.current;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('檢索片段數量 (Top-K)'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: v.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: '$v',
            onChanged: (x) => setState(() => v = x.round()),
          ),
          Text('每次檢索取最相關嘅 $v 個片段'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, v),
          child: const Text('確定'),
        ),
      ],
    );
  }
}
