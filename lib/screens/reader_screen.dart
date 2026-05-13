import 'package:flutter/material.dart';

import '../controllers/reader_controller.dart';
import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../services/ocr_service.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    super.key,
    required this.bookTitle,
    this.apiClient,
    this.ocrService,
    this.enableOcr = false,
  });

  final String bookTitle;

  /// Inject a [ReaderApi] for tests; production code can leave this null
  /// to use the default client.
  final ReaderApi? apiClient;
  final OcrService? ocrService;
  final bool enableOcr;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final ReaderController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ReaderController(
      bookTitle: widget.bookTitle,
      api: widget.apiClient,
      ocr: widget.ocrService,
    );
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.bookTitle)),
      body: ValueListenableBuilder<ReaderState>(
        valueListenable: _controller,
        builder: (context, state, _) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildAnswerArea(context, state)),
                const SizedBox(height: 16),
                _buildInputArea(state),
                const SizedBox(height: 16),
                if (widget.enableOcr) ...[
                  _buildOcrButton(state),
                  const SizedBox(height: 16),
                ],
                _buildTtsButton(state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnswerArea(BuildContext context, ReaderState state) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectableText(
            state.answer,
            style: const TextStyle(fontSize: 16),
          ),
          if (state.statusMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              state.statusMessage!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (state.answerTerms.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final term in state.answerTerms)
                  ActionChip(
                    label: Text(term),
                    avatar: const Icon(Icons.translate, size: 16),
                    onPressed: state.isExplaining
                        ? null
                        : () => _controller.explainText(term),
                  ),
              ],
            ),
          ],
          if (state.citations.isNotEmpty) ...[
            const SizedBox(height: 12),
            _CitationsPanel(citations: state.citations),
          ],
          if (state.languageNote != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.selectedText == null
                          ? '語言解釋'
                          : '語言解釋：${state.selectedText}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(state.languageNote!),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea(ReaderState state) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller.questionController,
            decoration: InputDecoration(
              hintText: l10n.chatInputHint,
              border: const OutlineInputBorder(),
            ),
            minLines: 1,
            maxLines: 3,
            onSubmitted: (_) => _controller.askQuestion(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: state.isLoading ? null : _controller.askQuestion,
          child: state.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('問 AI'),
        ),
      ],
    );
  }

  Widget _buildOcrButton(ReaderState state) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.document_scanner),
      label: const Text('OCR 問 AI'),
      onPressed: state.isLoading ? null : _controller.extractAndAsk,
    );
  }

  Widget _buildTtsButton(ReaderState state) {
    return ElevatedButton.icon(
      icon: Icon(state.isSpeaking ? Icons.stop : Icons.play_arrow),
      label: Text(state.isSpeaking ? '停止朗讀' : '朗讀回答'),
      onPressed: _controller.toggleSpeak,
    );
  }
}

/// Collapsible card showing the chunks the LLM was given as context.
/// Each row: index + doc#chunkIndex + similarity score + truncated snippet.
class _CitationsPanel extends StatelessWidget {
  const _CitationsPanel({required this.citations});

  final List<Map<String, dynamic>> citations;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(Icons.format_quote),
        title: Text('引用來源（${citations.length}）'),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: [
          for (var i = 0; i < citations.length; i++)
            _CitationRow(index: i + 1, citation: citations[i]),
        ],
      ),
    );
  }
}

class _CitationRow extends StatelessWidget {
  const _CitationRow({required this.index, required this.citation});

  final int index;
  final Map<String, dynamic> citation;

  @override
  Widget build(BuildContext context) {
    final doc = citation['doc'] as String? ?? '?';
    final chunkIndex = citation['chunkIndex']?.toString() ?? '?';
    final snippet = (citation['snippet'] as String? ?? '').trim();
    final score = (citation['score'] as num?)?.toDouble() ?? 0.0;

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 14,
        child: Text('$index', style: const TextStyle(fontSize: 12)),
      ),
      title: Text(
        '$doc · #$chunkIndex',
        style: Theme.of(context).textTheme.labelMedium,
      ),
      subtitle: snippet.isEmpty
          ? null
          : Text(snippet, maxLines: 3, overflow: TextOverflow.ellipsis),
      trailing: Text(
        '${(score * 100).clamp(0, 100).toStringAsFixed(0)}%',
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

