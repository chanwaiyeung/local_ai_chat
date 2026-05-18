// test/controllers/reader_reading_controller_test.dart
//
// Phase 1: unit tests for ReaderReadingController (retrieve-first read mode).

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/controllers/reader_controller.dart';
import 'package:local_ai_chat/controllers/reader_reading_controller.dart';
import 'package:local_ai_chat/services/api_client.dart';

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
}
