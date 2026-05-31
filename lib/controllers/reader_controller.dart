import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/language_learning_service.dart';
import '../services/ocr_service.dart';
import '../services/ollama_service.dart';
import '../services/tts_service.dart';
import 'reader_reading_controller.dart';

/// Container for every piece of state the Reader experience can show.
///
/// The fields are grouped by feature so it's easy to see which method
/// owns which slice. **A method should only mutate fields inside its
/// own group**; if you find yourself reaching into another group's
/// fields you're probably re-implementing one of the other features
/// and should call its method instead.
///
///   ┌── Q&A (askQuestion / streaming LLM answer) ──────
///   │   answer, statusMessage, citations, isLoading
///   │
///   ┌── Language helper (explainText) ──────────────────
///   │   selectedText, languageNote, isExplaining
///   │
///   ┌── TTS (toggleSpeak) ─────────────────────────────
///   │   isSpeaking
///   │
///   ┌── Read mode (loadDocument / search) ─────────────
///       currentDocName, documentChunks, isLoadingDocument,
///       loadError, searchResults, isSearching, searchError,
///       statusBanner
///
/// `answer` is **only ever a real LLM answer**. Reading-mode and OCR status
/// operations surface their user-facing text in [statusBanner] — never in
/// `answer` — so a stale answer survives load/search/OCR progress and
/// failures.
class ReaderState {
  const ReaderState({
    // Q&A
    required this.answer,
    this.statusMessage,
    this.citations = const [],
    this.isLoading = false,
    // Language helper
    this.selectedText,
    this.languageNote,
    this.isExplaining = false,
    // TTS
    this.isSpeaking = false,
    // Read mode
    this.currentDocName,
    this.documentChunks = const [],
    this.isLoadingDocument = false,
    this.loadError,
    this.searchResults = const [],
    this.isSearching = false,
    this.searchError,
    this.statusBanner,
  });

  // --- Q&A (askQuestion) ---
  final String answer;
  final String? statusMessage;
  final List<Map<String, dynamic>> citations;
  final bool isLoading;

  // --- Language helper (explainText) ---
  final String? selectedText;
  final String? languageNote;
  final bool isExplaining;

  // --- TTS (toggleSpeak) ---
  final bool isSpeaking;

  // --- Read mode (loadDocument / search) ---
  final String? currentDocName;
  final List<String> documentChunks;
  final bool isLoadingDocument;
  final String? loadError;
  final List<Map<String, dynamic>> searchResults;
  final bool isSearching;
  final String? searchError;

  /// Short user-facing line for read-mode operations: load progress /
  /// load summary / search summary / OCR progress / load/search/OCR failure.
  /// Null when nothing relevant has happened yet. Decoupled from [answer] so
  /// non-LLM status text cannot overwrite a real LLM answer.
  final String? statusBanner;

  static const initial = ReaderState(
    answer: '請輸入問題，我會根據書籍內容回答。',
  );

  ReaderState copyWith({
    String? answer,
    Object? statusMessage = _unset,
    Object? selectedText = _unset,
    Object? languageNote = _unset,
    List<Map<String, dynamic>>? citations,
    bool? isLoading,
    bool? isExplaining,
    bool? isSpeaking,
    Object? currentDocName = _unset,
    List<String>? documentChunks,
    bool? isLoadingDocument,
    Object? loadError = _unset,
    List<Map<String, dynamic>>? searchResults,
    bool? isSearching,
    Object? searchError = _unset,
    Object? statusBanner = _unset,
  }) {
    return ReaderState(
      answer: answer ?? this.answer,
      statusMessage: statusMessage == _unset
          ? this.statusMessage
          : statusMessage as String?,
      selectedText:
          selectedText == _unset ? this.selectedText : selectedText as String?,
      languageNote:
          languageNote == _unset ? this.languageNote : languageNote as String?,
      citations: citations ?? this.citations,
      isLoading: isLoading ?? this.isLoading,
      isExplaining: isExplaining ?? this.isExplaining,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      currentDocName: currentDocName == _unset
          ? this.currentDocName
          : currentDocName as String?,
      documentChunks: documentChunks ?? this.documentChunks,
      isLoadingDocument: isLoadingDocument ?? this.isLoadingDocument,
      loadError: loadError == _unset ? this.loadError : loadError as String?,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      searchError:
          searchError == _unset ? this.searchError : searchError as String?,
      statusBanner:
          statusBanner == _unset ? this.statusBanner : statusBanner as String?,
    );
  }

  /// Value equality — lets `ValueNotifier.value = next` short-circuit
  /// the `notifyListeners()` call when nothing actually changed.
  /// Without this, every `copyWith` rebuild fires listeners regardless.
  /// Lists are compared element-wise via [listEquals]; their inner Maps
  /// fall back to identity equality, which is acceptable because
  /// `ApiClient.retrieve` always returns fresh map instances.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ReaderState) return false;
    return answer == other.answer &&
        statusMessage == other.statusMessage &&
        listEquals(citations, other.citations) &&
        isLoading == other.isLoading &&
        selectedText == other.selectedText &&
        languageNote == other.languageNote &&
        isExplaining == other.isExplaining &&
        isSpeaking == other.isSpeaking &&
        currentDocName == other.currentDocName &&
        listEquals(documentChunks, other.documentChunks) &&
        isLoadingDocument == other.isLoadingDocument &&
        loadError == other.loadError &&
        listEquals(searchResults, other.searchResults) &&
        isSearching == other.isSearching &&
        searchError == other.searchError &&
        statusBanner == other.statusBanner;
  }

  @override
  int get hashCode => Object.hash(
        answer,
        statusMessage,
        Object.hashAll(citations),
        isLoading,
        selectedText,
        languageNote,
        isExplaining,
        isSpeaking,
        currentDocName,
        Object.hashAll(documentChunks),
        isLoadingDocument,
        loadError,
        Object.hashAll(searchResults),
        isSearching,
        searchError,
        statusBanner,
      );

  List<String> get answerTerms {
    if (answer == initial.answer ||
        answer == '思考中...' ||
        answer.startsWith('連接失敗')) {
      return const [];
    }

    final seen = <String>{};
    final terms = <String>[];
    for (final match in RegExp(
      r"[\p{L}\p{N}][\p{L}\p{N}'-]*",
      unicode: true,
    ).allMatches(answer)) {
      final term = match.group(0)!;
      if (term.length < 3 || !seen.add(term.toLowerCase())) continue;
      terms.add(term);
      if (terms.length == 10) break;
    }
    return terms;
  }
}

const Object _unset = Object();

class ReaderController extends ValueNotifier<ReaderState> {
  ReaderController({
    required this.bookTitle,
    ReaderApi? api,
    OcrService? ocr,
    TTSService? tts,
    OllamaService? ollama,
  })  : _api = api ?? ApiClient(),
        _ocr = ocr ?? OcrService(),
        _tts = tts ?? TTSService(),
        super(ReaderState.initial) {
    readingController = ReaderReadingController(
      api: _api,
      state: this,
      tts: _tts,
      ollama: ollama,
    );
    _languageService = LanguageLearningService(api: _api);
  }

  late final ReaderReadingController readingController;

  final String bookTitle;
  final ReaderApi _api;
  final OcrService _ocr;
  final TTSService _tts;
  late final LanguageLearningService _languageService;
  final TextEditingController questionController = TextEditingController();
  StreamSubscription<QueryEvent>? _querySub;

  TTSService get tts => _tts;

  Future<void> init() => _tts.init();


  Future<void> askQuestion() async {
    final question = questionController.text.trim();
    if (question.isEmpty) return;

    await _querySub?.cancel();
    _querySub = null;

    value = value.copyWith(
      answer: '',
      statusMessage: '思考中...',
      selectedText: null,
      languageNote: null,
      citations: const [],
      isLoading: true,
    );

    final buf = StringBuffer();
    final completer = Completer<void>();

    _querySub = _api.queryStream(query: question, docName: bookTitle).listen(
      (event) {
        switch (event) {
          case CitationsEvent(:final citations):
            value = value.copyWith(citations: citations);
          case DeltaEvent(:final text):
            buf.write(text);
            value = value.copyWith(answer: buf.toString());
          case DoneEvent():
            value = value.copyWith(
              isLoading: false,
              statusMessage: '回答完成。可點選下方詞彙取得語言解釋。',
            );
            if (!completer.isCompleted) completer.complete();
          case ErrorEvent(:final message):
            value = value.copyWith(
              isLoading: false,
              answer: buf.isEmpty ? '連接失敗：$message' : buf.toString(),
              statusMessage: '中途失敗：$message\n請確認 Server 正在運行且 Ollama 模型已載入。',
            );
            if (!completer.isCompleted) completer.complete();
        }
      },
      onError: (Object error) {
        value = value.copyWith(
          isLoading: false,
          answer: '連接失敗：$error',
          statusMessage: '如果模型回應較慢，請稍後再試或切換較小模型。',
        );
        if (!completer.isCompleted) completer.complete();
      },
      onDone: () {
        if (value.isLoading) {
          value = value.copyWith(
            isLoading: false,
            answer: buf.isEmpty ? '無法取得回答' : null,
          );
        }
        if (!completer.isCompleted) completer.complete();
      },
      cancelOnError: false,
    );

    return completer.future;
  }

  Future<void> explainText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || value.isLoading || value.isExplaining) return;

    value = value.copyWith(
      selectedText: trimmed,
      languageNote: '解釋中...',
      isExplaining: true,
    );

    try {
      final explanation = await _languageService.explainWord(
        word: trimmed,
        context: value.answer,
        docName: bookTitle,
      );
      value = value.copyWith(languageNote: explanation);
    } catch (error) {
      value = value.copyWith(languageNote: '解釋失敗：$error');
    } finally {
      value = value.copyWith(isExplaining: false);
    }
  }

  Future<void> extractAndAsk(String imagePath) async {
    if (value.isLoading) return;

    await _querySub?.cancel();
    _querySub = null;

    value = value.copyWith(
      isLoading: true,
      statusMessage: null,
      statusBanner: '正在進行 OCR 文字提取...',
      selectedText: null,
      languageNote: null,
      citations: const [],
    );

    try {
      final extractedText = await _ocr.extractTextFromImage(imagePath);
      final result = await _api.query(
        query: extractedText,
        docName: bookTitle,
      );
      value = value.copyWith(
        isLoading: false,
        answer: result['answer'] as String? ?? 'OCR 後無法取得回答',
        statusMessage: 'OCR 文字提取完成。',
        statusBanner: 'OCR 文字提取完成。',
      );
    } catch (error) {
      value = value.copyWith(
        isLoading: false,
        statusMessage: 'OCR 是 experimental 功能，預設不會啟用。',
        statusBanner: 'OCR 失敗：$error',
      );
    }
  }

  Future<void> loadDocument(String docName) =>
      readingController.loadDocument(docName);

  Future<void> search(String query, {int topK = 4}) =>
      readingController.search(query, topK: topK);

  void clearSearch() => readingController.clearSearch();

  Future<void> toggleSpeak() async {
    if (value.isSpeaking) {
      await _tts.stop();
    } else {
      await _tts.speak(value.answer);
    }
    value = value.copyWith(isSpeaking: _tts.isSpeaking);
  }

  @override
  void dispose() {
    readingController.dispose();
    unawaited(_querySub?.cancel());
    questionController.dispose();
    _ocr.dispose();
    unawaited(_tts.stop());
    super.dispose();
  }
}


