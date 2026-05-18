import 'package:flutter/foundation.dart';

import '../services/api_client.dart';
import 'reader_controller.dart' show ReaderState;

/// Retrieve-first reading mode: load full document chunks and in-book search.
///
/// Mutates [state] read-mode fields only (`currentDocName`, `documentChunks`,
/// `loadError`, `searchResults`, `isSearching`, `searchError`, `statusBanner`).
/// Never touches Q&A fields (`answer`, `isLoading`, etc.).
class ReaderReadingController {
  ReaderReadingController({
    required ReaderApi api,
    required ValueNotifier<ReaderState> state,
  })  : _api = api,
        _state = state;

  final ReaderApi _api;
  final ValueNotifier<ReaderState> _state;

  /// Loads every chunk of [docName] in original chunkIndex order via
  /// `GET /docs/<doc>/chunks`. No LLM call.
  Future<void> loadDocument(String docName) async {
    _state.value = _state.value.copyWith(
      isLoadingDocument: true,
      loadError: null,
      statusBanner: '載入文件...',
    );

    try {
      final chunks = await _api.getDocumentChunks(docName);
      final texts = chunks
          .map((c) => (c['text'] as String?) ?? '')
          .toList(growable: false);
      _state.value = _state.value.copyWith(
        currentDocName: docName,
        documentChunks: texts,
        isLoadingDocument: false,
        statusBanner: '文件已載入，共 ${chunks.length} 段文字。',
      );
    } catch (e) {
      _state.value = _state.value.copyWith(
        isLoadingDocument: false,
        loadError: e.toString(),
        currentDocName: null,
        documentChunks: const [],
        statusBanner: '載入失敗：$e',
      );
    }
  }

  /// Pure RAG retrieve via `POST /rag/retrieve` (no LLM generation).
  /// Scoped to [ReaderState.currentDocName] when one is loaded.
  Future<void> search(String query, {int topK = 4}) async {
    if (query.trim().isEmpty) return;

    _state.value = _state.value.copyWith(
      isSearching: true,
      searchError: null,
      statusBanner: '檢索中...',
    );

    try {
      final hits = await _api.retrieve(
        query: query,
        docName: _state.value.currentDocName,
        topK: topK,
      );
      final preview = hits.isEmpty ? '沒有找到相關內容' : safePreview(hits.first);
      _state.value = _state.value.copyWith(
        searchResults: hits,
        isSearching: false,
        statusBanner: '找到 ${hits.length} 段相關內容。\n\n$preview',
      );
    } catch (e) {
      _state.value = _state.value.copyWith(
        isSearching: false,
        searchError: e.toString(),
        searchResults: const [],
        statusBanner: '檢索失敗：$e',
      );
    }
  }

  /// Drops any cached search results / errors. Cheap; no network.
  void clearSearch() {
    final v = _state.value;
    if (v.searchResults.isEmpty && v.searchError == null) return;
    _state.value = v.copyWith(
      searchResults: const [],
      searchError: null,
    );
  }

  @visibleForTesting
  String safePreview(Map<String, dynamic> hit) {
    final raw = hit['text'] ?? hit['snippet'] ?? '';
    final text = raw is String ? raw : raw.toString();
    return text.length > 200 ? '${text.substring(0, 200)}...' : text;
  }
}
