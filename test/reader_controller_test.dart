// test/reader_controller_test.dart
//
// Phase 1B: unit tests for ReaderController's retrieve-first read mode.
// Drives the controller directly (no widgets) and asserts on its public
// state surface. Covers: success, failure, blank query, scoped search,
// and clearSearch.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/controllers/reader_controller.dart';
import 'package:local_ai_chat/services/api_client.dart';
import 'package:local_ai_chat/services/ocr_service.dart';

class _FakeReaderApi extends Fake implements ReaderApi {
  _FakeReaderApi({
    this.chunks = const [],
    this.hits = const [],
    this.queryResponse = const {'answer': 'llm answer'},
    this.streamEvents = const [DeltaEvent('stream answer'), DoneEvent()],
    this.throwOnLoad = false,
    this.throwOnRetrieve = false,
    this.throwOnQuery = false,
  });

  List<Map<String, dynamic>> chunks;
  List<Map<String, dynamic>> hits;
  Map<String, dynamic> queryResponse;
  List<QueryEvent> streamEvents;
  bool throwOnLoad;
  bool throwOnRetrieve;
  bool throwOnQuery;

  String? lastChunksDoc;
  String? lastRetrieveQuery;
  String? lastRetrieveDoc;
  int? lastRetrieveTopK;
  String? lastQuery;
  String? lastQueryDoc;
  String? lastStreamQuery;
  String? lastStreamDoc;

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

  @override
  Future<Map<String, dynamic>> query({
    required String query,
    String? docName,
  }) async {
    lastQuery = query;
    lastQueryDoc = docName;
    if (throwOnQuery) throw Exception('boom query');
    return queryResponse;
  }

  @override
  Stream<QueryEvent> queryStream({
    required String query,
    String? docName,
  }) async* {
    lastStreamQuery = query;
    lastStreamDoc = docName;
    for (final event in streamEvents) {
      yield event;
    }
  }
}

class _FakeOcrService extends OcrService {
  _FakeOcrService({
    this.text = 'ocr extracted text',
    this.throwOnImage = false,
  });

  final String text;
  final bool throwOnImage;
  String? lastImagePath;
  var disposed = false;

  @override
  Future<String> extractTextFromImage(String imagePath) async {
    lastImagePath = imagePath;
    if (throwOnImage) throw Exception('boom ocr');
    return text;
  }

  @override
  void dispose() {
    disposed = true;
  }
}

class _PendingOcrService extends OcrService {
  final Completer<String> completer = Completer<String>();

  @override
  Future<String> extractTextFromImage(String imagePath) => completer.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReaderController.loadDocument', () {
    test('populates documentChunks + currentDocName on success', () async {
      final api = _FakeReaderApi(chunks: const [
        {'docName': 'a.txt', 'chunkIndex': 0, 'text': 'first'},
        {'docName': 'a.txt', 'chunkIndex': 1, 'text': 'second'},
      ]);
      final c = ReaderController(bookTitle: 'a.txt', api: api);

      await c.loadDocument('a.txt');

      expect(api.lastChunksDoc, 'a.txt');
      expect(c.value.currentDocName, 'a.txt');
      expect(c.value.documentChunks, ['first', 'second']);
      expect(c.value.statusBanner, '文件已載入，共 2 段文字。');
      // Q&A field must not be polluted by read-mode operations.
      expect(c.value.answer, ReaderState.initial.answer);
      expect(c.value.isLoading, isFalse);
      expect(c.value.isLoadingDocument, isFalse);
      expect(c.value.loadError, isNull);

      c.dispose();
    });

    test('preserves empty-text chunks (list index == chunkIndex)', () async {
      // Reading Mode jump-to-chunk relies on `documentChunks[i]` being the
      // chunk whose server-side chunkIndex is `i`. Dropping empties would
      // break that invariant for any doc with a hole.
      final api = _FakeReaderApi(chunks: const [
        {'text': 'kept'},
        {'text': ''},
        {'text': 'also-kept'},
      ]);
      final c = ReaderController(bookTitle: 'a.txt', api: api);

      await c.loadDocument('a.txt');
      expect(c.value.documentChunks, ['kept', '', 'also-kept']);

      c.dispose();
    });

    test('records error and clears state on failure', () async {
      final api = _FakeReaderApi(throwOnLoad: true);
      final c = ReaderController(bookTitle: 'a.txt', api: api);

      await c.loadDocument('a.txt');

      expect(c.value.loadError, contains('boom load'));
      expect(c.value.statusBanner, contains('載入失敗：'));
      expect(c.value.statusBanner, contains('boom load'));
      // answer stays at initial — read-mode failures don't bleed into Q&A.
      expect(c.value.answer, ReaderState.initial.answer);
      expect(c.value.currentDocName, isNull);
      expect(c.value.documentChunks, isEmpty);
      expect(c.value.isLoading, isFalse);
      expect(c.value.isLoadingDocument, isFalse);

      c.dispose();
    });
  });

  group('ReaderController.search', () {
    test('blank query is a no-op (no API call, no state change)', () async {
      final api = _FakeReaderApi();
      final c = ReaderController(bookTitle: 'a.txt', api: api);
      await c.search('   ');
      expect(api.lastRetrieveQuery, isNull);
      expect(c.value.isSearching, isFalse);
      expect(c.value.answer, ReaderState.initial.answer);
      c.dispose();
    });

    test('populates searchResults and forwards topK', () async {
      final api = _FakeReaderApi(hits: const [
        {'doc': 'a.txt', 'chunkIndex': 0, 'score': 0.9, 'snippet': 'hit'},
      ]);
      final c = ReaderController(bookTitle: 'a.txt', api: api);

      await c.search('what is RAG?', topK: 3);

      expect(api.lastRetrieveQuery, 'what is RAG?');
      expect(api.lastRetrieveTopK, 3);
      expect(c.value.searchResults, hasLength(1));
      expect(c.value.searchResults.first['snippet'], 'hit');
      expect(c.value.statusBanner, '找到 1 段相關內容。\n\nhit');
      // Search must not overwrite a prior LLM answer.
      expect(c.value.answer, ReaderState.initial.answer);
      expect(c.value.isLoading, isFalse);
      expect(c.value.searchError, isNull);

      c.dispose();
    });

    test('search preview leaves short text untouched', () async {
      final api = _FakeReaderApi(hits: const [
        {'doc': 'a.txt', 'chunkIndex': 0, 'score': 0.9, 'text': '短文字'},
      ]);
      final c = ReaderController(bookTitle: 'a.txt', api: api);

      await c.search('q');

      expect(c.value.statusBanner, '找到 1 段相關內容。\n\n短文字');
      expect(c.value.statusBanner!.endsWith('...'), isFalse);
      c.dispose();
    });

    test('search preview truncates long text to 200 chars plus ellipsis',
        () async {
      final longText = 'a' * 201;
      final api = _FakeReaderApi(hits: [
        {'doc': 'a.txt', 'chunkIndex': 0, 'score': 0.9, 'text': longText},
      ]);
      final c = ReaderController(bookTitle: 'a.txt', api: api);

      await c.search('q');

      final preview = c.value.statusBanner!.split('\n\n').last;
      expect(preview.length, 203);
      expect(preview, '${'a' * 200}...');
      c.dispose();
    });

    test('search preview falls back to snippet payload', () async {
      final api = _FakeReaderApi(hits: const [
        {'doc': 'a.txt', 'chunkIndex': 0, 'score': 0.9, 'snippet': 'snippet'},
      ]);
      final c = ReaderController(bookTitle: 'a.txt', api: api);

      await c.search('q');

      expect(c.value.statusBanner, '找到 1 段相關內容。\n\nsnippet');
      c.dispose();
    });

    test('search reports empty result preview', () async {
      final api = _FakeReaderApi();
      final c = ReaderController(bookTitle: 'a.txt', api: api);

      await c.search('q');

      expect(c.value.statusBanner, '找到 0 段相關內容。\n\n沒有找到相關內容');
      expect(c.value.searchResults, isEmpty);
      c.dispose();
    });

    test('scopes by currentDocName once a doc is loaded', () async {
      final api = _FakeReaderApi(
        chunks: const [
          {'text': 't'},
        ],
        hits: const [],
      );
      final c = ReaderController(bookTitle: 'a.txt', api: api);

      await c.loadDocument('book.epub');
      await c.search('x');

      expect(api.lastRetrieveDoc, 'book.epub');
      c.dispose();
    });

    test('records searchError on retrieve failure', () async {
      final api = _FakeReaderApi(throwOnRetrieve: true);
      final c = ReaderController(bookTitle: 'a.txt', api: api);

      await c.search('x');

      expect(c.value.searchError, contains('boom retrieve'));
      expect(c.value.statusBanner, contains('檢索失敗：'));
      expect(c.value.statusBanner, contains('boom retrieve'));
      // Failed search must not bleed into the Q&A field.
      expect(c.value.answer, ReaderState.initial.answer);
      expect(c.value.searchResults, isEmpty);
      expect(c.value.isLoading, isFalse);
      expect(c.value.isSearching, isFalse);

      c.dispose();
    });
  });

  group('ReaderController.clearSearch', () {
    test('clears results and error', () async {
      final api = _FakeReaderApi(hits: const [
        {'doc': 'a', 'chunkIndex': 0, 'score': 1, 'snippet': 's'},
      ]);
      final c = ReaderController(bookTitle: 'a.txt', api: api);

      await c.search('x');
      expect(c.value.searchResults, isNotEmpty);

      c.clearSearch();
      expect(c.value.searchResults, isEmpty);
      expect(c.value.searchError, isNull);

      c.dispose();
    });

    test('is a no-op when nothing to clear', () async {
      final api = _FakeReaderApi();
      final c = ReaderController(bookTitle: 'a.txt', api: api);

      // notifyListeners would fire only if state actually changed.
      var notifyCount = 0;
      c.addListener(() => notifyCount++);
      c.clearSearch();
      expect(notifyCount, 0);

      c.dispose();
    });
  });

  group('ReaderController.extractAndAsk answer purity', () {
    test('writes progress to statusBanner without replacing answer', () async {
      final ocr = _PendingOcrService();
      final c = ReaderController(
        bookTitle: 'a.txt',
        api: _FakeReaderApi(),
        ocr: ocr,
      );
      c.value = c.value.copyWith(answer: 'previous LLM answer');

      final future = c.extractAndAsk();
      await Future<void>.delayed(Duration.zero);

      expect(c.value.answer, 'previous LLM answer');
      expect(c.value.statusBanner, '正在進行 OCR 文字提取...');
      expect(c.value.isLoading, isTrue);

      ocr.completer.complete('ocr words');
      await future;
      c.dispose();
    });

    test('success queries with OCR text and stores only LLM answer in answer',
        () async {
      final api = _FakeReaderApi(queryResponse: const {'answer': 'OCR LLM'});
      final ocr = _FakeOcrService(text: 'extracted words');
      final c = ReaderController(bookTitle: 'book.md', api: api, ocr: ocr);

      await c.extractAndAsk();

      expect(ocr.lastImagePath, 'assets/sample_page.jpg');
      expect(api.lastQuery, 'extracted words');
      expect(api.lastQueryDoc, 'book.md');
      expect(c.value.answer, 'OCR LLM');
      expect(c.value.statusBanner, 'OCR 文字提取完成。');
      expect(c.value.isLoading, isFalse);
      c.dispose();
    });

    test('success fallback answer is treated as generated answer', () async {
      final api = _FakeReaderApi(queryResponse: const {});
      final c = ReaderController(
        bookTitle: 'book.md',
        api: api,
        ocr: _FakeOcrService(),
      );

      await c.extractAndAsk();

      expect(c.value.answer, 'OCR 後無法取得回答');
      expect(c.value.statusBanner, 'OCR 文字提取完成。');
      c.dispose();
    });

    test('OCR extraction failure writes only statusBanner', () async {
      final c = ReaderController(
        bookTitle: 'book.md',
        api: _FakeReaderApi(),
        ocr: _FakeOcrService(throwOnImage: true),
      );
      c.value = c.value.copyWith(answer: 'previous answer');

      await c.extractAndAsk();

      expect(c.value.answer, 'previous answer');
      expect(c.value.statusBanner, contains('OCR 失敗：'));
      expect(c.value.statusBanner, contains('boom ocr'));
      expect(c.value.statusMessage, 'OCR 是 experimental 功能，預設不會啟用。');
      expect(c.value.isLoading, isFalse);
      c.dispose();
    });

    test('query failure after OCR preserves previous answer', () async {
      final c = ReaderController(
        bookTitle: 'book.md',
        api: _FakeReaderApi(throwOnQuery: true),
        ocr: _FakeOcrService(text: 'ocr text'),
      );
      c.value = c.value.copyWith(answer: 'grounded old answer');

      await c.extractAndAsk();

      expect(c.value.answer, 'grounded old answer');
      expect(c.value.statusBanner, contains('OCR 失敗：'));
      expect(c.value.statusBanner, contains('boom query'));
      expect(c.value.isLoading, isFalse);
      c.dispose();
    });

    test('extractAndAsk clears old citations before OCR query', () async {
      final c = ReaderController(
        bookTitle: 'book.md',
        api: _FakeReaderApi(),
        ocr: _FakeOcrService(),
      );
      c.value = c.value.copyWith(citations: const [
        {'doc': 'old', 'chunkIndex': 9},
      ]);

      await c.extractAndAsk();

      expect(c.value.citations, isEmpty);
      c.dispose();
    });

    test('extractAndAsk clears selected text and language note', () async {
      final c = ReaderController(
        bookTitle: 'book.md',
        api: _FakeReaderApi(),
        ocr: _FakeOcrService(),
      );
      c.value = c.value.copyWith(
        selectedText: 'term',
        languageNote: 'note',
      );

      await c.extractAndAsk();

      expect(c.value.selectedText, isNull);
      expect(c.value.languageNote, isNull);
      c.dispose();
    });

    test('extractAndAsk is guarded while a Q&A request is loading', () async {
      final api = _FakeReaderApi();
      final c = ReaderController(
        bookTitle: 'book.md',
        api: api,
        ocr: _FakeOcrService(),
      );
      c.value = c.value.copyWith(isLoading: true, answer: 'current answer');

      await c.extractAndAsk();

      expect(api.lastQuery, isNull);
      expect(c.value.answer, 'current answer');
      c.dispose();
    });

    test('dispose disposes injected OCR service', () {
      final ocr = _FakeOcrService();
      final c = ReaderController(
        bookTitle: 'book.md',
        api: _FakeReaderApi(),
        ocr: ocr,
      );

      c.dispose();

      expect(ocr.disposed, isTrue);
    });
  });

  group('ReaderState statusBanner separation', () {
    test('initial answer has no statusBanner', () {
      expect(ReaderState.initial.answer, isNotEmpty);
      expect(ReaderState.initial.statusBanner, isNull);
    });

    test('copyWith statusBanner leaves answer unchanged', () {
      final next = ReaderState.initial.copyWith(statusBanner: '載入中');
      expect(next.answer, ReaderState.initial.answer);
      expect(next.statusBanner, '載入中');
    });

    test('copyWith answer leaves statusBanner unchanged', () {
      final current = ReaderState.initial.copyWith(statusBanner: '狀態');
      final next = current.copyWith(answer: 'LLM');
      expect(next.answer, 'LLM');
      expect(next.statusBanner, '狀態');
    });

    test('copyWith can clear statusBanner', () {
      final current = ReaderState.initial.copyWith(statusBanner: '狀態');
      expect(current.copyWith(statusBanner: null).statusBanner, isNull);
    });

    test('equality includes statusBanner', () {
      final a = ReaderState.initial.copyWith(statusBanner: 'A');
      final b = ReaderState.initial.copyWith(statusBanner: 'B');
      expect(a == b, isFalse);
    });

    test('hashCode includes statusBanner', () {
      final a = ReaderState.initial.copyWith(statusBanner: 'A');
      final b = ReaderState.initial.copyWith(statusBanner: 'B');
      expect(a.hashCode == b.hashCode, isFalse);
    });

    test('equality includes documentChunks', () {
      final a = ReaderState.initial.copyWith(documentChunks: const ['a']);
      final b = ReaderState.initial.copyWith(documentChunks: const ['b']);
      expect(a == b, isFalse);
    });

    test('equality includes searchResults', () {
      final a = ReaderState.initial.copyWith(searchResults: const [
        {'text': 'a'},
      ]);
      final b = ReaderState.initial.copyWith(searchResults: const [
        {'text': 'b'},
      ]);
      expect(a == b, isFalse);
    });

    test('answerTerms reads only answer, not statusBanner', () {
      final state = ReaderState.initial.copyWith(
        answer: 'RAG explains retrieval augmented generation',
        statusBanner: '載入文件 with hidden terms',
      );
      expect(state.answerTerms, contains('retrieval'));
      expect(state.answerTerms, isNot(contains('hidden')));
    });

    test('initial placeholder has no answerTerms', () {
      expect(ReaderState.initial.answerTerms, isEmpty);
    });
  });

  group('ReaderController non-QA operations preserve answer', () {
    test('loadDocument success preserves custom answer', () async {
      final c = ReaderController(
        bookTitle: 'a.txt',
        api: _FakeReaderApi(chunks: const [
          {'text': 'chunk'},
        ]),
      );
      c.value = c.value.copyWith(answer: 'prior LLM');

      await c.loadDocument('a.txt');

      expect(c.value.answer, 'prior LLM');
      expect(c.value.statusBanner, '文件已載入，共 1 段文字。');
      c.dispose();
    });

    test('loadDocument failure preserves custom answer', () async {
      final c = ReaderController(
        bookTitle: 'a.txt',
        api: _FakeReaderApi(throwOnLoad: true),
      );
      c.value = c.value.copyWith(answer: 'prior LLM');

      await c.loadDocument('a.txt');

      expect(c.value.answer, 'prior LLM');
      expect(c.value.statusBanner, contains('載入失敗：'));
      c.dispose();
    });

    test('search success preserves custom answer', () async {
      final c = ReaderController(
        bookTitle: 'a.txt',
        api: _FakeReaderApi(hits: const [
          {'text': 'hit'},
        ]),
      );
      c.value = c.value.copyWith(answer: 'prior LLM');

      await c.search('rag');

      expect(c.value.answer, 'prior LLM');
      expect(c.value.statusBanner, '找到 1 段相關內容。\n\nhit');
      c.dispose();
    });

    test('search failure preserves custom answer', () async {
      final c = ReaderController(
        bookTitle: 'a.txt',
        api: _FakeReaderApi(throwOnRetrieve: true),
      );
      c.value = c.value.copyWith(answer: 'prior LLM');

      await c.search('rag');

      expect(c.value.answer, 'prior LLM');
      expect(c.value.statusBanner, contains('檢索失敗：'));
      c.dispose();
    });

    test('blank search preserves statusBanner and answer', () async {
      final c = ReaderController(bookTitle: 'a.txt', api: _FakeReaderApi());
      c.value = c.value.copyWith(answer: 'prior LLM', statusBanner: 'old');

      await c.search('   ');

      expect(c.value.answer, 'prior LLM');
      expect(c.value.statusBanner, 'old');
      c.dispose();
    });

    test('clearSearch preserves answer and statusBanner', () async {
      final c = ReaderController(
        bookTitle: 'a.txt',
        api: _FakeReaderApi(hits: const [
          {'text': 'hit'},
        ]),
      );
      c.value = c.value.copyWith(answer: 'prior LLM');
      await c.search('rag');

      c.clearSearch();

      expect(c.value.answer, 'prior LLM');
      expect(c.value.statusBanner, '找到 1 段相關內容。\n\nhit');
      expect(c.value.searchResults, isEmpty);
      c.dispose();
    });

    test('loadDocument start emits statusBanner before completion', () async {
      final api = _FakeReaderApi();
      final c = ReaderController(bookTitle: 'a.txt', api: api);
      c.value = c.value.copyWith(answer: 'prior LLM');
      final states = <ReaderState>[];
      c.addListener(() => states.add(c.value));

      await c.loadDocument('a.txt');

      expect(states.first.answer, 'prior LLM');
      expect(states.first.statusBanner, '載入文件...');
      expect(states.first.isLoadingDocument, isTrue);
      c.dispose();
    });

    test('search start emits statusBanner before completion', () async {
      final c = ReaderController(bookTitle: 'a.txt', api: _FakeReaderApi());
      c.value = c.value.copyWith(answer: 'prior LLM');
      final states = <ReaderState>[];
      c.addListener(() => states.add(c.value));

      await c.search('rag');

      expect(states.first.answer, 'prior LLM');
      expect(states.first.statusBanner, '檢索中...');
      expect(states.first.isSearching, isTrue);
      c.dispose();
    });
  });

  group('ReaderController Q&A remains the only answer writer', () {
    test('askQuestion streaming writes deltas into answer', () async {
      final api = _FakeReaderApi(streamEvents: const [
        DeltaEvent('Hello'),
        DeltaEvent(' world'),
        DoneEvent(),
      ]);
      final c = ReaderController(bookTitle: 'a.txt', api: api);
      c.questionController.text = 'question';

      await c.askQuestion();

      expect(c.value.answer, 'Hello world');
      expect(c.value.statusMessage, '回答完成。可點選下方詞彙取得語言解釋。');
      expect(c.value.isLoading, isFalse);
      c.dispose();
    });

    test('askQuestion stores citations separately from answer', () async {
      final api = _FakeReaderApi(streamEvents: const [
        CitationsEvent([
          {'doc': 'a.txt', 'chunkIndex': 1},
        ]),
        DeltaEvent('A'),
        DoneEvent(),
      ]);
      final c = ReaderController(bookTitle: 'a.txt', api: api);
      c.questionController.text = 'question';

      await c.askQuestion();

      expect(c.value.answer, 'A');
      expect(c.value.citations.single['chunkIndex'], 1);
      c.dispose();
    });

    test('askQuestion blank query leaves answer untouched', () async {
      final api = _FakeReaderApi();
      final c = ReaderController(bookTitle: 'a.txt', api: api);
      c.value = c.value.copyWith(answer: 'prior LLM');
      c.questionController.text = '  ';

      await c.askQuestion();

      expect(api.lastStreamQuery, isNull);
      expect(c.value.answer, 'prior LLM');
      c.dispose();
    });

    test('askQuestion forwards bookTitle as docName', () async {
      final api = _FakeReaderApi();
      final c = ReaderController(bookTitle: 'book.md', api: api);
      c.questionController.text = 'q';

      await c.askQuestion();

      expect(api.lastStreamQuery, 'q');
      expect(api.lastStreamDoc, 'book.md');
      c.dispose();
    });
  });
}
