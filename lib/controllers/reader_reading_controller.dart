import 'package:flutter/foundation.dart';

import '../models/book.dart';
import '../models/message.dart';
import '../services/api_client.dart';
import '../services/ollama_service.dart';
import '../services/tts_service.dart';
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
    TTSService? tts,
    OllamaService? ollama,
  })  : _api = api,
        _state = state,
        _tts = tts,
        _ollama = ollama;

  final ReaderApi _api;
  final ValueNotifier<ReaderState> _state;
  final TTSService? _tts;
  final OllamaService? _ollama;

  bool _disposed = false;

  void dispose() {
    _disposed = true;
  }

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
      if (_disposed) return;
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
      if (_disposed) return;
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
      if (_disposed) return;
      final preview = hits.isEmpty ? '沒有找到相關內容' : safePreview(hits.first);
      _state.value = _state.value.copyWith(
        searchResults: hits,
        isSearching: false,
        statusBanner: '找到 ${hits.length} 段相關內容。\n\n$preview',
      );
    } catch (e) {
      if (_disposed) return;
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

  TtsQuality determineQuality(Book? book) {
    if (book == null) return TtsQuality.fast;
    final tags = book.tags;
    if (tags.contains('語言學習') || tags.contains('日語')) {
      return TtsQuality.learning;
    }
    return TtsQuality.fast;
  }

  /// 調用 Ollama 摘要當前文件內容，並將摘要文字直接傳入 tts_service 播放
  Future<void> generateAndSpeakSummary(String documentId, {TtsQuality quality = TtsQuality.fast}) async {
    final tts = _tts;
    if (tts == null) {
      debugPrint('TTS service is not available.');
      return;
    }

    if (_state.value.isSpeaking) {
      await tts.stop();
      if (_disposed) return;
      _state.value = _state.value.copyWith(isSpeaking: false);
      return;
    }

    _state.value = _state.value.copyWith(
      statusBanner: '正在生成語音摘要...',
      isSpeaking: false,
    );

    try {
      if (_state.value.documentChunks.isEmpty || _state.value.currentDocName != documentId) {
        await loadDocument(documentId);
        if (_disposed) return;
      }

      final chunks = _state.value.documentChunks;
      if (chunks.isEmpty) {
        _state.value = _state.value.copyWith(
          statusBanner: '無法生成摘要：文件無內容。',
        );
        return;
      }

      final textToSummarize = chunks.take(5).join('\n');
      final prompt = '請以繁體中文簡短總結以下文件內容的主要核心大意，字數控制在 150 字以內，語氣簡潔明瞭：\n\n$textToSummarize';
      
      final ollama = _ollama ?? OllamaService();
      final chatMsg = ChatMessage(role: Role.user, content: prompt);
      
      _state.value = _state.value.copyWith(statusBanner: '正在讀取摘要...');
      final summary = await ollama.chat([chatMsg]);
      if (_disposed) return;

      if (summary.trim().isEmpty) {
        _state.value = _state.value.copyWith(
          statusBanner: '生成摘要失敗：模型回傳空內容。',
        );
        return;
      }

      _state.value = _state.value.copyWith(
        statusBanner: '語音播放中：$summary',
        isSpeaking: true,
      );

      tts.onCompletion = () {
        if (_disposed) return;
        _state.value = _state.value.copyWith(
          isSpeaking: false,
          statusBanner: '語音播放結束。',
        );
      };

      await tts.speak(summary, quality: quality);
    } catch (e) {
      if (_disposed) return;
      _state.value = _state.value.copyWith(
        statusBanner: '語音摘要失敗：$e',
        isSpeaking: false,
      );
    }
  }
}


