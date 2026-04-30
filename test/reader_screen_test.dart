// test/reader_screen_test.dart
//
// Verifies:
//   1. ReaderScreen renders the book title in the AppBar
//   2. Initial prompt asks the user to enter a question
//   3. Tapping "問 AI" streams the AI answer (CitationsEvent + Delta + Done)
//   4. Citations panel renders when chunks arrive
//   5. TTS-ready speak control is present
//   6. Tapping a term in the answer fetches a language explanation

import 'package:ai_library_server/screens/reader_screen.dart';
import 'package:ai_library_server/services/api_client.dart';
import 'package:ai_library_server/services/ocr_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApiClient extends Fake implements ReaderApi {
  _FakeApiClient({
    this.answer = '範例 AI 回答',
    this.citations = const <Map<String, dynamic>>[],
  });
  String answer;
  final List<Map<String, dynamic>> citations;
  int callCount = 0;
  String? lastQuery;
  String? lastDocName;

  @override
  Future<bool> health() async => true;

  @override
  Future<List<String>> getDocs() async => const [];

  @override
  Future<Map<String, dynamic>> query({
    required String query,
    String? docName,
  }) async {
    callCount++;
    lastQuery = query;
    lastDocName = docName;
    return {'answer': answer, 'citations': citations};
  }

  @override
  Stream<QueryEvent> queryStream({
    required String query,
    String? docName,
  }) async* {
    callCount++;
    lastQuery = query;
    lastDocName = docName;
    yield CitationsEvent(citations);
    // Yield the answer in two pieces to mimic real streaming.
    final mid = answer.length ~/ 2;
    yield DeltaEvent(answer.substring(0, mid));
    yield DeltaEvent(answer.substring(mid));
    yield const DoneEvent();
  }
}

class _FakeOcrService extends OcrService {
  int callCount = 0;

  @override
  Future<String> extractTextFromImage(String imagePath) async {
    callCount++;
    return 'OCR extracted text from sample page';
  }
}

void main() {
  testWidgets('renders book title in AppBar', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ReaderScreen(
        bookTitle: '哈姆雷特',
        apiClient: _FakeApiClient(),
      ),
    ));

    expect(find.text('哈姆雷特'), findsOneWidget);
  });

  testWidgets('shows initial question prompt', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ReaderScreen(bookTitle: '書', apiClient: _FakeApiClient()),
    ));

    expect(find.text('請輸入問題，我會根據書籍內容回答。'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '問 AI'), findsOneWidget);
  });

  testWidgets('submitting a question renders the AI answer', (tester) async {
    final fake = _FakeApiClient(answer: '這是根據書籍內容產生的回答。');
    await tester.pumpWidget(MaterialApp(
      home: ReaderScreen(bookTitle: '書', apiClient: fake),
    ));

    await tester.enterText(find.byType(TextField), '這本書在說什麼？');
    await tester.tap(find.widgetWithText(ElevatedButton, '問 AI'));
    await tester.pumpAndSettle();

    expect(fake.callCount, 1);
    expect(fake.lastQuery, '這本書在說什麼？');
    expect(fake.lastDocName, '書');
    expect(find.text('這是根據書籍內容產生的回答。'), findsOneWidget);
  });

  testWidgets('renders citations panel when chunks arrive', (tester) async {
    final fake = _FakeApiClient(
      answer: 'Grounded answer.',
      citations: const [
        {
          'doc': 'rag_concepts.md',
          'chunkIndex': 2,
          'score': 0.91,
          'snippet': 'A small language model with eight billion parameters...',
        },
        {
          'doc': 'about_zhi_du_guan.txt',
          'chunkIndex': 0,
          'score': 0.74,
          'snippet': '智讀館 is a local-first reading companion.',
        },
      ],
    );
    await tester.pumpWidget(MaterialApp(
      home: ReaderScreen(bookTitle: 'rag_concepts.md', apiClient: fake),
    ));

    await tester.enterText(find.byType(TextField), 'Why does RAG work?');
    await tester.tap(find.widgetWithText(ElevatedButton, '問 AI'));
    await tester.pumpAndSettle();

    expect(find.text('引用來源（2）'), findsOneWidget);
    // Expand the panel and verify both rows are present.
    await tester.tap(find.text('引用來源（2）'));
    await tester.pumpAndSettle();
    expect(find.text('rag_concepts.md · #2'), findsOneWidget);
    expect(find.text('about_zhi_du_guan.txt · #0'), findsOneWidget);
    expect(find.text('91%'), findsOneWidget);
    expect(find.text('74%'), findsOneWidget);
  });

  testWidgets('shows TTS speak control', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ReaderScreen(bookTitle: '書', apiClient: _FakeApiClient()),
    ));

    expect(find.widgetWithText(ElevatedButton, '朗讀回答'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('tapping an answer term asks for a language explanation',
      (tester) async {
    final fake =
        _FakeApiClient(answer: 'According to context, latency matters.');
    await tester.pumpWidget(MaterialApp(
      home: ReaderScreen(bookTitle: '書', apiClient: fake),
    ));

    await tester.enterText(find.byType(TextField), '這段在說什麼？');
    await tester.tap(find.widgetWithText(ElevatedButton, '問 AI'));
    await tester.pumpAndSettle();

    fake.answer = 'According 是「根據」的意思。例句：According to the book...';
    await tester.tap(find.widgetWithText(ActionChip, 'According'));
    await tester.pumpAndSettle();

    expect(fake.callCount, 2);
    expect(fake.lastQuery, contains('請用繁體中文簡短解釋'));
    expect(fake.lastQuery, contains('According'));
    expect(find.text('語言解釋：According'), findsOneWidget);
    expect(find.textContaining('根據'), findsOneWidget);
  });

  testWidgets('OCR action is hidden by default', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ReaderScreen(bookTitle: '書', apiClient: _FakeApiClient()),
    ));

    expect(find.widgetWithText(OutlinedButton, 'OCR 問 AI'), findsNothing);
  });

  testWidgets('OCR action extracts text and asks AI when enabled',
      (tester) async {
    final fakeApi = _FakeApiClient(answer: 'OCR 後的 AI 回答');
    final fakeOcr = _FakeOcrService();
    await tester.pumpWidget(MaterialApp(
      home: ReaderScreen(
        bookTitle: '漫畫.cbz',
        apiClient: fakeApi,
        ocrService: fakeOcr,
        enableOcr: true,
      ),
    ));

    await tester.tap(find.widgetWithText(OutlinedButton, 'OCR 問 AI'));
    await tester.pumpAndSettle();

    expect(fakeOcr.callCount, 1);
    expect(fakeApi.callCount, 1);
    expect(fakeApi.lastQuery, 'OCR extracted text from sample page');
    expect(fakeApi.lastDocName, '漫畫.cbz');
    expect(find.text('OCR 後的 AI 回答'), findsOneWidget);
    expect(find.text('OCR 文字提取完成。'), findsOneWidget);
  });
}
