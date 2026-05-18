// test/reader_controller_test.dart
//
// Unit tests for ReaderController Q&A, OCR, and reading-mode delegation.
// Retrieve-first read-mode behavior lives in reader_reading_controller_test.dart.

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
    this.throwOnQuery = false,
  });

  List<Map<String, dynamic>> chunks;
  List<Map<String, dynamic>> hits;
  Map<String, dynamic> queryResponse;
  List<QueryEvent> streamEvents;
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

  group('ReaderController reading delegation', () {
    test('exposes readingController wired to shared state', () {
      final c = ReaderController(bookTitle: 'a.txt', api: _FakeReaderApi());
      expect(c.readingController, isNotNull);
      c.dispose();
    });

    test('loadDocument updates ReaderController state via wrapper', () async {
      final api = _FakeReaderApi(chunks: const [
        {'text': 'chunk'},
      ]);
      final c = ReaderController(bookTitle: 'a.txt', api: api);

      await c.loadDocument('a.txt');

      expect(c.value.documentChunks, ['chunk']);
      expect(c.value.answer, ReaderState.initial.answer);
      c.dispose();
    });

    test('search and clearSearch work via wrapper', () async {
      final api = _FakeReaderApi(hits: const [
        {'text': 'hit'},
      ]);
      final c = ReaderController(bookTitle: 'a.txt', api: api);

      await c.search('rag');
      expect(c.value.searchResults, hasLength(1));

      c.clearSearch();
      expect(c.value.searchResults, isEmpty);
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

      final future = c.extractAndAsk('assets/sample_page.jpg');
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

      await c.extractAndAsk('assets/sample_page.jpg');

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

      await c.extractAndAsk('assets/sample_page.jpg');

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

      await c.extractAndAsk('assets/sample_page.jpg');

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

      await c.extractAndAsk('assets/sample_page.jpg');

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

      await c.extractAndAsk('assets/sample_page.jpg');

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

      await c.extractAndAsk('assets/sample_page.jpg');

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

      await c.extractAndAsk('assets/sample_page.jpg');

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
