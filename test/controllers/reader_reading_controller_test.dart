// test/controllers/reader_reading_controller_test.dart
//
// Phase 1: unit tests for ReaderReadingController (retrieve-first read mode).

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/controllers/reader_controller.dart';
import 'package:local_ai_chat/controllers/reader_reading_controller.dart';
import 'package:local_ai_chat/models/book.dart';
import 'package:local_ai_chat/models/message.dart';
import 'package:local_ai_chat/services/api_client.dart';
import 'package:local_ai_chat/services/ollama_service.dart';
import 'package:local_ai_chat/services/tts_service.dart';

class _FakeReaderApi extends Fake implements ReaderApi {
  _FakeReaderApi({
    this.chunks = const [],
    this.hits = const [],
    this.throwOnLoad = false,
    this.throwOnRetrieve = false,
  });

  List<Map<String, dynamic>> chunks;
  List<Map<String, dynamic>> hits;
  bool throwOnLoad;
  bool throwOnRetrieve;

  String? lastChunksDoc;
  String? lastRetrieveQuery;
  String? lastRetrieveDoc;
  int? lastRetrieveTopK;

  @override
  Future<List<Map<String, dynamic>>> getDocumentChunks(String docName) async {
    lastChunksDoc = docName;
    if (throwOnLoad) throw Exception('boom load');
    return chunks;
  }

  @override
  Future<List<Map<String, dynamic>>> retrieve({
    required String query,
    String? docName,
    int topK = 6,
  }) async {
    lastRetrieveQuery = query;
    lastRetrieveDoc = docName;
    lastRetrieveTopK = topK;
    if (throwOnRetrieve) throw Exception('boom retrieve');
    return hits;
  }
}

({ReaderReadingController reading, ValueNotifier<ReaderState> state})
    _fixture(ReaderApi api) {
  final state = ValueNotifier(ReaderState.initial);
  return (
    reading: ReaderReadingController(api: api, state: state),
    state: state,
  );
}

({ReaderReadingController reading, ValueNotifier<ReaderState> state})
    _fixtureWithTtsAndOllama(ReaderApi api, TTSService tts, OllamaService ollama) {
  final state = ValueNotifier(ReaderState.initial);
  return (
    reading: ReaderReadingController(api: api, state: state, tts: tts, ollama: ollama),
    state: state,
  );
}

class _FakeTTSService extends Fake implements TTSService {
  String? lastSpokenText;
  TtsQuality? lastSpokenQuality;
  bool isStopped = false;
  bool _isSpeaking = false;
  @override
  VoidCallback? onCompletion;

  @override
  Future<void> speak(String text, {TtsQuality quality = TtsQuality.fast, String? lang}) async {
    lastSpokenText = text;
    lastSpokenQuality = quality;
    _isSpeaking = true;
  }

  @override
  Future<void> stop() async {
    isStopped = true;
    _isSpeaking = false;
  }

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  TtsQuality get activeQuality => lastSpokenQuality ?? TtsQuality.fast;

  void complete() {
    _isSpeaking = false;
    if (onCompletion != null) onCompletion!();
  }

}

class _FakeOllamaService extends Fake implements OllamaService {
  _FakeOllamaService({this.reply = 'Summary reply'});
  final String reply;
  List<ChatMessage>? lastChatMessages;

  @override
  Future<String> chat(List<ChatMessage> messages) async {
    lastChatMessages = messages;
    return reply;
  }
}

void main() {
  group('ReaderReadingController.loadDocument', () {
    test('populates documentChunks + currentDocName on success', () async {
      final api = _FakeReaderApi(chunks: const [
        {'docName': 'a.txt', 'chunkIndex': 0, 'text': 'first'},
        {'docName': 'a.txt', 'chunkIndex': 1, 'text': 'second'},
      ]);
      final f = _fixture(api);

      await f.reading.loadDocument('a.txt');

      expect(api.lastChunksDoc, 'a.txt');
      expect(f.state.value.currentDocName, 'a.txt');
      expect(f.state.value.documentChunks, ['first', 'second']);
      expect(f.state.value.statusBanner, '文件已載入，共 2 段文字。');
      expect(f.state.value.answer, ReaderState.initial.answer);
      expect(f.state.value.isLoading, isFalse);
      expect(f.state.value.isLoadingDocument, isFalse);
      expect(f.state.value.loadError, isNull);
    });

    test('preserves empty-text chunks (list index == chunkIndex)', () async {
      final api = _FakeReaderApi(chunks: const [
        {'text': 'kept'},
        {'text': ''},
        {'text': 'also-kept'},
      ]);
      final f = _fixture(api);

      await f.reading.loadDocument('a.txt');
      expect(f.state.value.documentChunks, ['kept', '', 'also-kept']);
    });

    test('records error and clears state on failure', () async {
      final api = _FakeReaderApi(throwOnLoad: true);
      final f = _fixture(api);

      await f.reading.loadDocument('a.txt');

      expect(f.state.value.loadError, contains('boom load'));
      expect(f.state.value.statusBanner, contains('載入失敗：'));
      expect(f.state.value.statusBanner, contains('boom load'));
      expect(f.state.value.answer, ReaderState.initial.answer);
      expect(f.state.value.currentDocName, isNull);
      expect(f.state.value.documentChunks, isEmpty);
      expect(f.state.value.isLoading, isFalse);
      expect(f.state.value.isLoadingDocument, isFalse);
    });
  });

  group('ReaderReadingController.search', () {
    test('blank query is a no-op (no API call, no state change)', () async {
      final api = _FakeReaderApi();
      final f = _fixture(api);
      await f.reading.search('   ');
      expect(api.lastRetrieveQuery, isNull);
      expect(f.state.value.isSearching, isFalse);
      expect(f.state.value.answer, ReaderState.initial.answer);
    });

    test('populates searchResults and forwards topK', () async {
      final api = _FakeReaderApi(hits: const [
        {'doc': 'a.txt', 'chunkIndex': 0, 'score': 0.9, 'snippet': 'hit'},
      ]);
      final f = _fixture(api);

      await f.reading.search('what is RAG?', topK: 3);

      expect(api.lastRetrieveQuery, 'what is RAG?');
      expect(api.lastRetrieveTopK, 3);
      expect(f.state.value.searchResults, hasLength(1));
      expect(f.state.value.searchResults.first['snippet'], 'hit');
      expect(f.state.value.statusBanner, '找到 1 段相關內容。\n\nhit');
      expect(f.state.value.answer, ReaderState.initial.answer);
      expect(f.state.value.isLoading, isFalse);
      expect(f.state.value.searchError, isNull);
    });

    test('search preview leaves short text untouched', () async {
      final api = _FakeReaderApi(hits: const [
        {'doc': 'a.txt', 'chunkIndex': 0, 'score': 0.9, 'text': '短文字'},
      ]);
      final f = _fixture(api);

      await f.reading.search('q');

      expect(f.state.value.statusBanner, '找到 1 段相關內容。\n\n短文字');
      expect(f.state.value.statusBanner!.endsWith('...'), isFalse);
    });

    test('search preview truncates long text to 200 chars plus ellipsis',
        () async {
      final longText = 'a' * 201;
      final api = _FakeReaderApi(hits: [
        {'doc': 'a.txt', 'chunkIndex': 0, 'score': 0.9, 'text': longText},
      ]);
      final f = _fixture(api);

      await f.reading.search('q');

      final preview = f.state.value.statusBanner!.split('\n\n').last;
      expect(preview.length, 203);
      expect(preview, '${'a' * 200}...');
    });

    test('search preview falls back to snippet payload', () async {
      final api = _FakeReaderApi(hits: const [
        {'doc': 'a.txt', 'chunkIndex': 0, 'score': 0.9, 'snippet': 'snippet'},
      ]);
      final f = _fixture(api);

      await f.reading.search('q');

      expect(f.state.value.statusBanner, '找到 1 段相關內容。\n\nsnippet');
    });

    test('search reports empty result preview', () async {
      final api = _FakeReaderApi();
      final f = _fixture(api);

      await f.reading.search('q');

      expect(f.state.value.statusBanner, '找到 0 段相關內容。\n\n沒有找到相關內容');
      expect(f.state.value.searchResults, isEmpty);
    });

    test('scopes by currentDocName once a doc is loaded', () async {
      final api = _FakeReaderApi(
        chunks: const [
          {'text': 't'},
        ],
        hits: const [],
      );
      final f = _fixture(api);

      await f.reading.loadDocument('book.epub');
      await f.reading.search('x');

      expect(api.lastRetrieveDoc, 'book.epub');
    });

    test('records searchError on retrieve failure', () async {
      final api = _FakeReaderApi(throwOnRetrieve: true);
      final f = _fixture(api);

      await f.reading.search('x');

      expect(f.state.value.searchError, contains('boom retrieve'));
      expect(f.state.value.statusBanner, contains('檢索失敗：'));
      expect(f.state.value.statusBanner, contains('boom retrieve'));
      expect(f.state.value.answer, ReaderState.initial.answer);
      expect(f.state.value.searchResults, isEmpty);
      expect(f.state.value.isLoading, isFalse);
      expect(f.state.value.isSearching, isFalse);
    });
  });

  group('ReaderReadingController.clearSearch', () {
    test('clears results and error', () async {
      final api = _FakeReaderApi(hits: const [
        {'doc': 'a', 'chunkIndex': 0, 'score': 1, 'snippet': 's'},
      ]);
      final f = _fixture(api);

      await f.reading.search('x');
      expect(f.state.value.searchResults, isNotEmpty);

      f.reading.clearSearch();
      expect(f.state.value.searchResults, isEmpty);
      expect(f.state.value.searchError, isNull);
    });

    test('is a no-op when nothing to clear', () {
      final api = _FakeReaderApi();
      final f = _fixture(api);

      var notifyCount = 0;
      f.state.addListener(() => notifyCount++);
      f.reading.clearSearch();
      expect(notifyCount, 0);
    });
  });

  group('ReaderReadingController non-QA operations preserve answer', () {
    test('loadDocument success preserves custom answer', () async {
      final api = _FakeReaderApi(chunks: const [
        {'text': 'chunk'},
      ]);
      final f = _fixture(api);
      f.state.value = f.state.value.copyWith(answer: 'prior LLM');

      await f.reading.loadDocument('a.txt');

      expect(f.state.value.answer, 'prior LLM');
      expect(f.state.value.statusBanner, '文件已載入，共 1 段文字。');
    });

    test('loadDocument failure preserves custom answer', () async {
      final api = _FakeReaderApi(throwOnLoad: true);
      final f = _fixture(api);
      f.state.value = f.state.value.copyWith(answer: 'prior LLM');

      await f.reading.loadDocument('a.txt');

      expect(f.state.value.answer, 'prior LLM');
      expect(f.state.value.statusBanner, contains('載入失敗：'));
    });

    test('search success preserves custom answer', () async {
      final api = _FakeReaderApi(hits: const [
        {'text': 'hit'},
      ]);
      final f = _fixture(api);
      f.state.value = f.state.value.copyWith(answer: 'prior LLM');

      await f.reading.search('rag');

      expect(f.state.value.answer, 'prior LLM');
      expect(f.state.value.statusBanner, '找到 1 段相關內容。\n\nhit');
    });

    test('search failure preserves custom answer', () async {
      final api = _FakeReaderApi(throwOnRetrieve: true);
      final f = _fixture(api);
      f.state.value = f.state.value.copyWith(answer: 'prior LLM');

      await f.reading.search('rag');

      expect(f.state.value.answer, 'prior LLM');
      expect(f.state.value.statusBanner, contains('檢索失敗：'));
    });

    test('blank search preserves statusBanner and answer', () async {
      final api = _FakeReaderApi();
      final f = _fixture(api);
      f.state.value =
          f.state.value.copyWith(answer: 'prior LLM', statusBanner: 'old');

      await f.reading.search('   ');

      expect(f.state.value.answer, 'prior LLM');
      expect(f.state.value.statusBanner, 'old');
    });

    test('clearSearch preserves answer and statusBanner', () async {
      final api = _FakeReaderApi(hits: const [
        {'text': 'hit'},
      ]);
      final f = _fixture(api);
      f.state.value = f.state.value.copyWith(answer: 'prior LLM');
      await f.reading.search('rag');

      f.reading.clearSearch();

      expect(f.state.value.answer, 'prior LLM');
      expect(f.state.value.statusBanner, '找到 1 段相關內容。\n\nhit');
      expect(f.state.value.searchResults, isEmpty);
    });

    test('loadDocument start emits statusBanner before completion', () async {
      final api = _FakeReaderApi();
      final f = _fixture(api);
      f.state.value = f.state.value.copyWith(answer: 'prior LLM');
      final states = <ReaderState>[];
      f.state.addListener(() => states.add(f.state.value));

      await f.reading.loadDocument('a.txt');

      expect(states.first.answer, 'prior LLM');
      expect(states.first.statusBanner, '載入文件...');
      expect(states.first.isLoadingDocument, isTrue);
    });

    test('search start emits statusBanner before completion', () async {
      final api = _FakeReaderApi();
      final f = _fixture(api);
      f.state.value = f.state.value.copyWith(answer: 'prior LLM');
      final states = <ReaderState>[];
      f.state.addListener(() => states.add(f.state.value));

      await f.reading.search('rag');

      expect(states.first.answer, 'prior LLM');
      expect(states.first.statusBanner, '檢索中...');
      expect(states.first.isSearching, isTrue);
    });
  });

  group('ReaderReadingController.generateAndSpeakSummary', () {
    test('loads document chunks if empty, generates summary and speaks it', () async {
      final api = _FakeReaderApi(chunks: const [
        {'text': 'first line'},
        {'text': 'second line'},
      ]);
      final tts = _FakeTTSService();
      final ollama = _FakeOllamaService(reply: 'Custom summary');
      final f = _fixtureWithTtsAndOllama(api, tts, ollama);

      await f.reading.generateAndSpeakSummary('doc.txt');

      expect(f.state.value.currentDocName, 'doc.txt');
      expect(f.state.value.documentChunks, ['first line', 'second line']);
      expect(ollama.lastChatMessages, isNotNull);
      expect(ollama.lastChatMessages!.first.content, contains('first line\nsecond line'));
      expect(tts.lastSpokenText, 'Custom summary');
      expect(f.state.value.isSpeaking, isTrue);
      expect(f.state.value.statusBanner, '語音播放中：Custom summary');

      // Simulate completion
      tts.complete();
      expect(f.state.value.isSpeaking, isFalse);
      expect(f.state.value.statusBanner, '語音播放結束。');
    });

    test('stops speech if already speaking', () async {
      final api = _FakeReaderApi(chunks: const [{'text': 'content'}]);
      final tts = _FakeTTSService();
      final ollama = _FakeOllamaService();
      final f = _fixtureWithTtsAndOllama(api, tts, ollama);

      // Set speaking to true initially
      f.state.value = f.state.value.copyWith(isSpeaking: true);
      await tts.speak('existing');

      await f.reading.generateAndSpeakSummary('doc.txt');

      expect(tts.isStopped, isTrue);
      expect(f.state.value.isSpeaking, isFalse);
    });

    test('does not update state after dispose', () async {
      final api = _FakeReaderApi(chunks: const [{'text': 'content'}]);
      final tts = _FakeTTSService();
      final ollama = _FakeOllamaService(reply: 'Summary');
      final f = _fixtureWithTtsAndOllama(api, tts, ollama);

      final future = f.reading.generateAndSpeakSummary('doc.txt');
      f.reading.dispose();

      await future;

      // Verify that the state didn't proceed to "語音播放中"
      expect(f.state.value.isSpeaking, isFalse);
      expect(f.state.value.statusBanner, isNot(contains('語音播放中')));
    });

    test('determineQuality returns learning for language learning and Japanese tags', () {
      final api = _FakeReaderApi();
      final f = _fixture(api);

      final bookLang = Book(title: 'Book 1', tags: const ['語言學習']);
      final bookJp = Book(title: 'Book 2', tags: const ['日語']);
      final bookNormal = Book(title: 'Book 3', tags: const ['歷史', '教會歷史']);

      expect(f.reading.determineQuality(bookLang), TtsQuality.learning);
      expect(f.reading.determineQuality(bookJp), TtsQuality.learning);
      expect(f.reading.determineQuality(bookNormal), TtsQuality.fast);
      expect(f.reading.determineQuality(null), TtsQuality.fast);
    });

    test('generateAndSpeakSummary propagates custom quality setting', () async {
      final api = _FakeReaderApi(chunks: const [
        {'text': 'learning content'},
      ]);
      final tts = _FakeTTSService();
      final ollama = _FakeOllamaService(reply: 'Learning summary');
      final f = _fixtureWithTtsAndOllama(api, tts, ollama);

      await f.reading.generateAndSpeakSummary('doc.txt', quality: TtsQuality.learning);

      expect(tts.lastSpokenText, 'Learning summary');
      expect(tts.lastSpokenQuality, TtsQuality.learning);
    });
  });
}


