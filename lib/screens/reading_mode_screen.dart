// lib/screens/reading_mode_screen.dart
//
// Phase 1C: Reading Mode — full-text view of a single doc, with an
// in-book search bar that calls the retrieve-first `/rag/retrieve`
// endpoint (no LLM generation). Tapping a search hit scrolls the body
// to the matching chunk and briefly highlights it.
//
// Wires up the `documentChunks` / `searchResults` fields that landed on
// `ReaderController` in Phase 1B but were so far only exposed by tests.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/book_controller.dart';
import '../controllers/reader_controller.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/book.dart';
import '../models/message.dart';
import '../services/api_client.dart';
import '../services/ollama_service.dart';
import '../services/tts_service.dart';
import 'ai_processing_screen.dart';
import 'ai_qa_screen.dart';

class ReadingModeScreen extends StatefulWidget {
  const ReadingModeScreen({
    super.key,
    required this.bookTitle,
    this.apiClient,
    this.tts,
    this.ollama,
    this.bookController,
  });

  /// Doc to load via `GET /docs/<doc>/chunks` on init.
  final String bookTitle;

  /// Test seam — when null, the controller spins up a default ApiClient.
  final ReaderApi? apiClient;

  /// Test seam — mock TTS service
  final TTSService? tts;

  /// Test seam — mock Ollama service
  final OllamaService? ollama;

  final BookController? bookController;

  @override
  State<ReadingModeScreen> createState() => _ReadingModeScreenState();
}

class _ReadingModeScreenState extends State<ReadingModeScreen> {
  late final ReaderController _controller;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _chunkKeys = {};
  int? _highlightedChunkIndex;
  int? _selectedChunkIndex;
  final Map<int, List<String>> _chunkHighlights = {};

  Future<void> _summarizeSelectedChunk(
      BuildContext context, String text) async {
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AiProcessingScreen(message: 'AI 正在進行段落大綱分析與總結...'),
    );

    try {
      final ollama = widget.ollama ?? OllamaService();
      final prompt = '請以繁體中文簡短總結以下這段內容的核心大意，字數控制在 100 字以內，語氣簡潔明瞭：\n\n$text';
      final summary =
          await ollama.chat([ChatMessage(role: Role.user, content: prompt)]);

      if (context.mounted) {
        navigator.pop(); // Close processing screen

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text('段落摘要'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        summary.isEmpty ? '無法生成摘要' : summary,
                        style: const TextStyle(fontSize: 15, height: 1.4),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('複製'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: summary));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已複製摘要內容！')),
                    );
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.volume_up),
                  label: const Text('朗讀'),
                  onPressed: () {
                    final book = _getCurrentBook();
                    final quality =
                        _controller.readingController.determineQuality(book);
                    _controller.tts.speak(summary, quality: quality);
                  },
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('關閉'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        navigator.pop(); // Close processing screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成摘要失敗：$e')),
        );
      }
    }
  }

  Future<void> _handleAutoNotes(
      BuildContext context, String currentParagraph) async {
    if (currentParagraph.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先點選以選擇書中的任一段落進行註解！')),
      );
      return;
    }

    // 1. 顯示載入中
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AiProcessingScreen(message: "正在萃取關鍵字彙..."),
    );

    try {
      // 2. 取得 AI 註解
      final notes =
          await globalBookAiService.generateAutoNotes(currentParagraph);
      if (!context.mounted) return;
      Navigator.pop(context); // 關閉載入

      // 3. 顯示單字卡 BottomSheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.8,
          expand: false,
          builder: (_, controller) => ListView.separated(
            controller: controller,
            padding: const EdgeInsets.all(16),
            itemCount: notes.length + 1,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text('💡 本段關鍵詞彙',
                      style: Theme.of(context).textTheme.titleLarge),
                );
              }
              final note = notes[index - 1];
              return ListTile(
                title: Row(
                  children: [
                    Text((note['word'] as String?) ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(width: 8),
                    Text((note['reading'] as String?) ?? '',
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text((note['meaning'] as String?) ?? '',
                        style: const TextStyle(color: Colors.blue)),
                    const SizedBox(height: 4),
                    Text((note['explanation'] as String?) ?? ''),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.bookmark_border),
                  onPressed: () {
                    // TODO: 未來可實作存入「個人單字本」
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('已存入單字本')));
                  },
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _handleAutoNotesText(
      BuildContext context, String currentParagraph) async {
    if (currentParagraph.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先點選以選擇書中的任一段落進行註解！')),
      );
      return;
    }

    // 1. 顯示載入中
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AiProcessingScreen(message: "正在生成段落註解..."),
    );

    try {
      // 2. 取得 AI 註解
      final notes = await globalAiNotesService.generateNotes(currentParagraph);
      if (!context.mounted) return;
      Navigator.pop(context); // 關閉載入

      // 3. 顯示精美 BottomSheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).aiNotes,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Text(
                  notes,
                  style: const TextStyle(fontSize: 16, height: 1.6),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('註解生成失敗: $e')),
      );
    }
  }

  Future<void> _handleMindMap(
      BuildContext context, String currentChapter) async {
    if (currentChapter.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('沒有可分析的章節內容！')),
      );
      return;
    }

    // 1. 顯示載入中
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AiProcessingScreen(message: "正在生成 AI 思維導圖..."),
    );

    try {
      // 2. 取得 AI 思維導圖
      final map = await globalAiMindMapService.generateMindMap(currentChapter);
      if (!context.mounted) return;
      Navigator.pop(context); // 關閉載入

      // 3. 顯示 AlertDialog
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.account_tree, color: Colors.purple),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context).aiMindMap),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite, // 讓 Dialog 寬度足夠顯示樹狀結構
            child: SingleChildScrollView(
              child: Text(
                map,
                style: const TextStyle(
                  fontFamily: 'monospace', // 建議使用等寬字體，樹狀結構的縮排會更整齊
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).close),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('生成思維導圖失敗: $e')),
      );
    }
  }

  Future<void> _handleAutoHighlight(
      BuildContext context, String currentParagraph) async {
    if (currentParagraph.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先點選以選擇書中的任一段落進行高亮分析！')),
      );
      return;
    }

    final selectedIdx = _selectedChunkIndex;
    if (selectedIdx == null) return;

    // 1. 顯示載入中
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AiProcessingScreen(message: "正在分析關鍵句子與主題段落..."),
    );

    try {
      // 2. 取得 AI 高亮
      final highlights =
          await globalAiHighlightService.getHighlights(currentParagraph);
      if (!context.mounted) return;
      Navigator.pop(context); // 關閉載入

      setState(() {
        _chunkHighlights[selectedIdx] = highlights;
      });

      if (highlights.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('此段落未偵測到明顯的主題句或關鍵概念')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已成功高亮標記 ${highlights.length} 個關鍵處！')),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('高亮失敗: $e')));
    }
  }

  BookController? get _bookController {
    if (widget.bookController != null) return widget.bookController;
    try {
      return globalBookController;
    } catch (_) {
      return null;
    }
  }

  Book? _getCurrentBook() {
    final controller = _bookController;
    if (controller == null) return null;
    final baseName = widget.bookTitle
        .replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '')
        .toLowerCase()
        .trim();
    for (final book in controller.getAllBooks()) {
      if (book.title.toLowerCase().trim() == baseName ||
          book.title.toLowerCase().trim() ==
              widget.bookTitle.toLowerCase().trim()) {
        return book;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _controller = ReaderController(
      bookTitle: widget.bookTitle,
      api: widget.apiClient,
      tts: widget.tts,
      ollama: widget.ollama,
    );
    // Fire and forget — the controller surfaces success / error in its
    // own state, so we don't await here. Listeners rebuild on change.
    _controller.loadDocument(widget.bookTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _runSearch() {
    final q = _searchController.text;
    _controller.search(q);
  }

  Future<void> _jumpToChunk(int chunkIndex) async {
    final ctx = _chunkKeys[chunkIndex]?.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: 0.1,
    );
    if (!mounted) return;
    setState(() => _highlightedChunkIndex = chunkIndex);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted || _highlightedChunkIndex != chunkIndex) return;
    setState(() => _highlightedChunkIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.readingModeTitle}：${widget.bookTitle}'),
        actions: [
          ValueListenableBuilder<ReaderState>(
            valueListenable: _controller,
            builder: (context, state, _) {
              final activeQuality = _controller.tts.activeQuality;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TtsModeIndicator(
                    isSpeaking: state.isSpeaking,
                    quality: activeQuality,
                  ),
                  IconButton(
                    tooltip: '語音總結',
                    icon: Icon(
                      state.isSpeaking ? Icons.stop_circle : Icons.summarize,
                      color: state.isSpeaking ? Colors.red : null,
                    ),
                    onPressed: () {
                      final book = _getCurrentBook();
                      final quality =
                          _controller.readingController.determineQuality(book);
                      _controller.readingController.generateAndSpeakSummary(
                        widget.bookTitle,
                        quality: quality,
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<ReaderState>(
        valueListenable: _controller,
        builder: (context, state, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SearchBar(
                controller: _searchController,
                isSearching: state.isSearching,
                onSubmit: _runSearch,
              ),
              if (state.searchError != null) _ErrorBanner(state.searchError!),
              if (state.statusBanner != null &&
                  state.statusBanner!.isNotEmpty &&
                  state.loadError == null &&
                  state.searchError == null)
                _StatusBanner(state.statusBanner!),
              if (state.searchResults.isNotEmpty)
                _SearchHitsCard(
                  hits: state.searchResults,
                  onTap: _jumpToChunk,
                ),
              const Divider(height: 1),
              Expanded(
                  child: _BodyArea(
                state: state,
                chunkKeys: _chunkKeys,
                scrollController: _scrollController,
                highlightedChunkIndex:
                    _highlightedChunkIndex ?? _selectedChunkIndex,
                chunkHighlights: _chunkHighlights,
                onTapChunk: (index) {
                  setState(() {
                    if (_selectedChunkIndex == index) {
                      _selectedChunkIndex = null;
                    } else {
                      _selectedChunkIndex = index;
                    }
                  });
                },
              )),
            ],
          );
        },
      ),
      bottomNavigationBar: ValueListenableBuilder<ReaderState>(
        valueListenable: _controller,
        builder: (context, state, _) {
          final isSpeaking = state.isSpeaking;
          final hasSelection = _selectedChunkIndex != null;

          return BottomAppBar(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    icon: Icon(isSpeaking ? Icons.stop_circle : Icons.volume_up,
                        color: isSpeaking ? Colors.red : null),
                    label: Text(
                        isSpeaking ? '停止' : (hasSelection ? '朗讀此段' : '朗讀大綱')),
                    onPressed: () async {
                      final book = _getCurrentBook();
                      final quality =
                          _controller.readingController.determineQuality(book);

                      if (state.isSpeaking) {
                        await _controller.tts.stop();
                        setState(() {});
                      } else {
                        if (_selectedChunkIndex != null &&
                            _selectedChunkIndex! <
                                state.documentChunks.length) {
                          final text =
                              state.documentChunks[_selectedChunkIndex!];
                          await _controller.tts.speak(text, quality: quality);
                          setState(() {});
                        } else {
                          await _controller.readingController
                              .generateAndSpeakSummary(
                            widget.bookTitle,
                            quality: quality,
                          );
                        }
                      }
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.short_text),
                    label: const Text('摘要本段'),
                    onPressed: () {
                      if (_selectedChunkIndex != null &&
                          _selectedChunkIndex! < state.documentChunks.length) {
                        final text = state.documentChunks[_selectedChunkIndex!];
                        _summarizeSelectedChunk(context, text);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('請先點選以選擇書中的任一段落進行摘要！')),
                        );
                      }
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.border_color),
                    label: Text(AppLocalizations.of(context).aiHighlight),
                    onPressed: () {
                      final currentParagraph = (_selectedChunkIndex != null &&
                              _selectedChunkIndex! <
                                  state.documentChunks.length)
                          ? state.documentChunks[_selectedChunkIndex!]
                          : '';
                      _handleAutoHighlight(context, currentParagraph);
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.translate),
                    label: Text(AppLocalizations.of(context).aiWordCard),
                    onPressed: () {
                      final currentParagraph = (_selectedChunkIndex != null &&
                              _selectedChunkIndex! <
                                  state.documentChunks.length)
                          ? state.documentChunks[_selectedChunkIndex!]
                          : '';
                      _handleAutoNotes(context, currentParagraph);
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.note_alt),
                    label: Text(AppLocalizations.of(context).aiNotes),
                    onPressed: () {
                      final currentParagraph = (_selectedChunkIndex != null &&
                              _selectedChunkIndex! <
                                  state.documentChunks.length)
                          ? state.documentChunks[_selectedChunkIndex!]
                          : '';
                      _handleAutoNotesText(context, currentParagraph);
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.account_tree),
                    label: Text(AppLocalizations.of(context).aiMindMap),
                    onPressed: () {
                      final currentChapter = state.documentChunks.isNotEmpty
                          ? state.documentChunks.join('\n\n')
                          : '';
                      _handleMindMap(context, currentChapter);
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.help_outline),
                    label: Text(hasSelection ? '問這一段' : '問這本書'),
                    onPressed: () {
                      String? text;
                      if (_selectedChunkIndex != null &&
                          _selectedChunkIndex! < state.documentChunks.length) {
                        text = state.documentChunks[_selectedChunkIndex!];
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AiQaScreen(
                            bookTitle: widget.bookTitle,
                            initialChunk: text,
                            apiClient: widget.apiClient,
                            ollama: widget.ollama,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// --------------------------------------------------------------------------

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.isSearching,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isSearching;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '在此書中搜尋…',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onSubmitted: (_) => onSubmit(),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: isSearching ? null : onSubmit,
            child: isSearching
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('送出'),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Text(
        '搜尋失敗：$message',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.indigo.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.indigo, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.indigo,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchHitsCard extends StatelessWidget {
  const _SearchHitsCard({required this.hits, required this.onTap});

  final List<Map<String, dynamic>> hits;
  final void Function(int chunkIndex) onTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: hits.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final hit = hits[i];
            final chunkIndex = (hit['chunkIndex'] as num?)?.toInt() ?? 0;
            final score = ((hit['score'] as num?)?.toDouble() ?? 0) * 100;
            final snippet = (hit['snippet'] as String? ?? '').trim();
            return ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                child: Text('${i + 1}', style: const TextStyle(fontSize: 12)),
              ),
              title: Text(
                '#$chunkIndex · ${score.clamp(0, 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              subtitle: snippet.isEmpty
                  ? null
                  : Text(snippet, maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () => onTap(chunkIndex),
            );
          },
        ),
      ),
    );
  }
}

class _BodyArea extends StatelessWidget {
  const _BodyArea({
    required this.state,
    required this.chunkKeys,
    required this.scrollController,
    required this.highlightedChunkIndex,
    required this.onTapChunk,
    required this.chunkHighlights,
  });

  final ReaderState state;
  final Map<int, GlobalKey> chunkKeys;
  final ScrollController scrollController;
  final int? highlightedChunkIndex;
  final void Function(int index) onTapChunk;
  final Map<int, List<String>> chunkHighlights;

  List<TextSpan> _buildHighlightSpans(
      String text, List<String> highlights, BuildContext context) {
    if (highlights.isEmpty) {
      return [TextSpan(text: text)];
    }

    final matches = <_HighlightRange>[];
    for (final h in highlights) {
      final cleanH = h.trim();
      if (cleanH.isEmpty) continue;

      var startIndex = 0;
      while (true) {
        final index = text.indexOf(cleanH, startIndex);
        if (index == -1) break;
        matches.add(_HighlightRange(index, index + cleanH.length));
        startIndex = index + cleanH.length;
      }
    }

    if (matches.isEmpty) {
      return [TextSpan(text: text)];
    }

    matches.sort((a, b) => a.start.compareTo(b.start));
    final merged = <_HighlightRange>[];
    for (final range in matches) {
      if (merged.isEmpty) {
        merged.add(range);
      } else {
        final last = merged.last;
        if (range.start <= last.end) {
          if (range.end > last.end) {
            merged[merged.length - 1] = _HighlightRange(last.start, range.end);
          }
        } else {
          merged.add(range);
        }
      }
    }

    final spans = <TextSpan>[];
    var lastIdx = 0;
    final highlightColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.yellow.shade900.withValues(alpha: 0.4)
        : Colors.yellow.shade200;

    for (final range in merged) {
      if (range.start > lastIdx) {
        spans.add(TextSpan(text: text.substring(lastIdx, range.start)));
      }
      spans.add(TextSpan(
        text: text.substring(range.start, range.end),
        style: TextStyle(backgroundColor: highlightColor),
      ));
      lastIdx = range.end;
    }
    if (lastIdx < text.length) {
      spans.add(TextSpan(text: text.substring(lastIdx)));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingDocument) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '載入失敗：${state.loadError}',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }
    if (state.documentChunks.isEmpty) {
      return const Center(child: Text('（這本書沒有索引內容）'));
    }
    return ListView.builder(
      controller: scrollController,
      itemCount: state.documentChunks.length,
      itemBuilder: (context, i) {
        final text = state.documentChunks[i];
        final key = chunkKeys.putIfAbsent(i, GlobalKey.new);
        final isHighlighted = highlightedChunkIndex == i;
        final highlights = chunkHighlights[i] ?? const [];
        return InkWell(
          onTap: () => onTapChunk(i),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            key: key,
            color: isHighlighted
                ? (Theme.of(context).brightness == Brightness.dark
                    ? Colors.amber.shade900.withValues(alpha: 0.3)
                    : Colors.yellow.shade100)
                : null,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('#$i', style: Theme.of(context).textTheme.labelSmall),
                    if (isHighlighted)
                      Icon(
                        Icons.bookmark_added,
                        size: 14,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.amber.shade200
                            : Colors.amber.shade800,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                SelectableText.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    children: _buildHighlightSpans(
                      text.isEmpty ? '（空段落）' : text,
                      highlights,
                      context,
                    ),
                  ),
                  onTap: () => onTapChunk(i),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HighlightRange {
  final int start;
  final int end;
  _HighlightRange(this.start, this.end);
}

class TtsModeIndicator extends StatefulWidget {
  const TtsModeIndicator({
    super.key,
    required this.isSpeaking,
    required this.quality,
  });

  final bool isSpeaking;
  final TtsQuality quality;

  @override
  State<TtsModeIndicator> createState() => _TtsModeIndicatorState();
}

class _TtsModeIndicatorState extends State<TtsModeIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isSpeaking) {
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        _controller.forward();
      } else {
        _controller.repeat(reverse: true);
      }
    }
  }

  @override
  void didUpdateWidget(covariant TtsModeIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking && !oldWidget.isSpeaking) {
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        _controller.forward();
      } else {
        _controller.repeat(reverse: true);
      }
    } else if (!widget.isSpeaking && oldWidget.isSpeaking) {
      _controller.stop();
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCloud = widget.quality == TtsQuality.learning;
    final icon = isCloud ? Icons.cloud_queue : Icons.offline_bolt;
    final color = isCloud ? Colors.blue.shade400 : Colors.green.shade400;
    final tooltip = isCloud ? '高品質雲端語音已啟用' : '本地引擎（極速模式）';

    return Tooltip(
      message: tooltip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final opacity = widget.isSpeaking ? _animation.value : 0.2;
          return Opacity(
            opacity: opacity,
            child: child,
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }
}
