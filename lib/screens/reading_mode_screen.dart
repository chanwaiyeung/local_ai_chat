// lib/screens/reading_mode_screen.dart
//
// Phase 1C: Reading Mode — full-text view of a single doc, with an
// in-book search bar that calls the retrieve-first `/rag/retrieve`
// endpoint (no LLM generation). Tapping a search hit scrolls the body
// to the matching chunk and briefly highlights it.
//
// Wires up the `documentChunks` / `searchResults` fields that landed on
// `ReaderController` in Phase 1B but were so far only exposed by tests.

import 'package:flutter/material.dart';

import '../controllers/reader_controller.dart';
import '../l10n/app_localizations.dart';
import '../services/api_client.dart';

class ReadingModeScreen extends StatefulWidget {
  const ReadingModeScreen({
    super.key,
    required this.bookTitle,
    this.apiClient,
  });

  /// Doc to load via `GET /docs/<doc>/chunks` on init.
  final String bookTitle;

  /// Test seam — when null, the controller spins up a default ApiClient.
  final ReaderApi? apiClient;

  @override
  State<ReadingModeScreen> createState() => _ReadingModeScreenState();
}

class _ReadingModeScreenState extends State<ReadingModeScreen> {
  late final ReaderController _controller;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _chunkKeys = {};
  int? _highlightedChunkIndex;

  @override
  void initState() {
    super.initState();
    _controller = ReaderController(
      bookTitle: widget.bookTitle,
      api: widget.apiClient,
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
      appBar: AppBar(title: Text('${l10n.readingModeTitle}：${widget.bookTitle}')),
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
              if (state.searchResults.isNotEmpty)
                _SearchHitsCard(
                  hits: state.searchResults,
                  onTap: _jumpToChunk,
                ),
              const Divider(height: 1),
              Expanded(child: _BodyArea(
                state: state,
                chunkKeys: _chunkKeys,
                scrollController: _scrollController,
                highlightedChunkIndex: _highlightedChunkIndex,
              )),
            ],
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
  });

  final ReaderState state;
  final Map<int, GlobalKey> chunkKeys;
  final ScrollController scrollController;
  final int? highlightedChunkIndex;

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
        // Invariant from server + controller: list index i == chunkIndex i.
        final text = state.documentChunks[i];
        final key = chunkKeys.putIfAbsent(i, GlobalKey.new);
        final isHighlighted = highlightedChunkIndex == i;
        return Container(
          key: key,
          color: isHighlighted ? Colors.yellow.shade100 : null,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('#$i', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 4),
              SelectableText(
                text.isEmpty ? '（空段落）' : text,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ],
          ),
        );
      },
    );
  }
}

