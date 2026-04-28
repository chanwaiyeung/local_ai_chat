// lib/screens/doc_viewer_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../services/debug_log_service.dart';
import '../services/vector_store.dart';

/// 文件預覽：顯示某份文件嘅所有切塊，支援搜尋同剔選 chunk。
/// 揀好片段後按右上 ➤，會 pop 返一組字串，由 chat_screen 帶入下一輪 context。
class DocViewerScreen extends StatefulWidget {
  final VectorStore store;
  final String docName;
  final int? initialChunkIndex;

  const DocViewerScreen({
    super.key,
    required this.store,
    required this.docName,
    this.initialChunkIndex,
  });

  @override
  State<DocViewerScreen> createState() => _DocViewerScreenState();
}

class _DocViewerScreenState extends State<DocViewerScreen> {
  final _search = TextEditingController();
  final _scrollController = ScrollController();
  final Map<int, GlobalKey> _chunkKeys = {};
  final Set<String> _picked = {};
  String _query = '';
  int? _highlightedChunkIndex;
  bool _didScheduleInitialScroll = false;

  List<DocChunk> get _chunks => widget.store.chunksOf(widget.docName);

  @override
  void dispose() {
    _search.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToInitialChunk();
    });
  }

  GlobalKey _keyForChunk(int index) {
    return _chunkKeys.putIfAbsent(index, () => GlobalKey());
  }

  Future<void> _scrollToInitialChunk() async {
    if (_didScheduleInitialScroll) return;
    _didScheduleInitialScroll = true;

    final index = widget.initialChunkIndex;
    if (index == null) return;

    final chunks = _chunks;
    if (chunks.indexWhere((chunk) => chunk.chunkIndex == index) < 0) {
      await DebugLogService.append(
        'DocViewer scroll: doc=${widget.docName} chunkIndex=$index '
        'success=false reason=missing_chunk',
        level: 'WARN',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('找不到引用段落 #$index')),
      );
      return;
    }

    for (var attempt = 0; attempt < 8; attempt++) {
      if (_chunkKeys[index]?.currentContext != null) break;
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
    }

    final ctx = _chunkKeys[index]?.currentContext;
    if (ctx == null) {
      await DebugLogService.append(
        'DocViewer scroll: doc=${widget.docName} chunkIndex=$index '
        'success=false reason=no_context',
        level: 'WARN',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('無法定位引用段落 #$index')),
      );
      return;
    }

    setState(() {
      _highlightedChunkIndex = index;
    });

    // The target context is obtained from a GlobalKey after retrying layout.
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOut,
      alignment: 0.15,
    );
    await DebugLogService.append(
      'DocViewer scroll: doc=${widget.docName} chunkIndex=$index success=true',
    );

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    if (_highlightedChunkIndex == index) {
      setState(() {
        _highlightedChunkIndex = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chunks = _chunks;
    final filtered = _query.isEmpty
        ? chunks
        : chunks
            .where((c) => c.text.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.docName, overflow: TextOverflow.ellipsis),
        actions: [
          if (_picked.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.send),
              tooltip: '將揀選片段帶返聊天',
              onPressed: () {
                final selected = chunks
                    .where((c) => _picked.contains(c.id))
                    .map((c) => c.text)
                    .toList();
                Navigator.pop(context, selected);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: '在文件中搜尋…',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(
                  '共 ${chunks.length} 片段，配對 ${filtered.length}，已揀 ${_picked.length}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const Spacer(),
                if (_picked.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(_picked.clear),
                    child: const Text('清除揀選'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  for (final c in filtered) ...[
                    Card(
                      key: _keyForChunk(c.chunkIndex),
                      color: c.chunkIndex == _highlightedChunkIndex
                          ? const Color(0xFFFFF3B0)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: c.chunkIndex == _highlightedChunkIndex
                            ? const BorderSide(
                                color: Color(0xFFFFB703),
                                width: 2,
                              )
                            : BorderSide.none,
                      ),
                      child: CheckboxListTile(
                        value: _picked.contains(c.id),
                        tileColor: c.chunkIndex == _highlightedChunkIndex
                            ? const Color(0xFFFFF3B0)
                            : null,
                        selectedTileColor: const Color(0xFFFFF3B0),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _picked.add(c.id);
                            } else {
                              _picked.remove(c.id);
                            }
                          });
                        },
                        title: Text('片段 #${c.chunkIndex}'),
                        subtitle: _Highlight(text: c.text, query: _query),
                        isThreeLine: true,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Highlight extends StatelessWidget {
  final String text;
  final String query;
  const _Highlight({required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium;
    if (query.isEmpty) {
      return Text(text,
          maxLines: 4, overflow: TextOverflow.ellipsis, style: base);
    }
    final lower = text.toLowerCase();
    final q = query.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;
    while (true) {
      final idx = lower.indexOf(q, start);
      if (idx < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + q.length),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          backgroundColor: Color(0x66FFEB3B),
        ),
      ));
      start = idx + q.length;
    }
    return RichText(
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(style: base, children: spans),
    );
  }
}
