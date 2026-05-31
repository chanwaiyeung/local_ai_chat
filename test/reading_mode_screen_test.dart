// test/reading_mode_screen_test.dart
//
// Phase 1C widget tests for ReadingModeScreen + the long-press entry point
// from LibraryScreen. The screen pulls full-text via /docs/<doc>/chunks
// and runs in-book search via /rag/retrieve.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/controllers/book_controller.dart';
import 'package:local_ai_chat/main.dart';
import 'package:local_ai_chat/models/book.dart';
import 'package:local_ai_chat/models/message.dart';
import 'package:local_ai_chat/screens/ai_qa_screen.dart';
import 'package:local_ai_chat/screens/library_screen.dart';
import 'package:local_ai_chat/screens/reading_mode_screen.dart';
import 'package:local_ai_chat/services/ai_highlight_service.dart';
import 'package:local_ai_chat/services/ai_mindmap_service.dart';
import 'package:local_ai_chat/services/ai_notes_service.dart';
import 'package:local_ai_chat/services/api_client.dart';
import 'package:local_ai_chat/services/book_ai_service.dart';
import 'package:local_ai_chat/services/ollama_service.dart';
import 'package:local_ai_chat/services/tts_service.dart';
import 'package:local_ai_chat/services/vector_store.dart';

import 'helpers/test_app.dart';

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
  _FakeOllamaService({this.reply = 'Summary reply', this.delay = Duration.zero});
  final String reply;
  final Duration delay;
  List<ChatMessage>? lastChatMessages;

  @override
  Future<String> chat(List<ChatMessage> messages) async {
    lastChatMessages = messages;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return reply;
  }
}

class _FakeApi extends Fake implements ReaderApi {
  _FakeApi({
    this.docs = const [],
    this.chunks = const [],
    this.hits = const [],
    this.throwOnLoad = false,
  });

  List<String> docs;
  List<Map<String, dynamic>> chunks;
  List<Map<String, dynamic>> hits;
  bool throwOnLoad;

  String? lastSearchQuery;
  String? lastSearchDoc;

  @override
  Future<List<String>> getDocs() async => docs;

  @override
  Future<bool> health() async => true;

  @override
  Future<List<Map<String, dynamic>>> getDocumentChunks(String docName) async {
    if (throwOnLoad) throw Exception('boom load');
    return chunks;
  }

  @override
  Future<List<Map<String, dynamic>>> retrieve({
    required String query,
    String? docName,
    int topK = 6,
  }) async {
    lastSearchQuery = query;
    lastSearchDoc = docName;
    return hits;
  }
}

void main() {
  group('ReadingModeScreen', () {
    testWidgets('loads chunks and renders body text', (tester) async {
      final api = _FakeApi(chunks: const [
        {'docName': 'b', 'chunkIndex': 0, 'text': 'first paragraph'},
        {'docName': 'b', 'chunkIndex': 1, 'text': 'second paragraph'},
      ]);
      await tester.pumpWidget(TestApp(
        child: ReadingModeScreen(bookTitle: 'b', apiClient: api),
      ));
      await tester.pumpAndSettle();

      expect(find.text('first paragraph'), findsOneWidget);
      expect(find.text('second paragraph'), findsOneWidget);
      expect(find.text('#0'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
    });

    testWidgets('shows placeholder when book has no indexed chunks',
        (tester) async {
      final api = _FakeApi(chunks: const []);
      await tester.pumpWidget(TestApp(
        child: ReadingModeScreen(bookTitle: 'b', apiClient: api),
      ));
      await tester.pumpAndSettle();

      expect(find.text('（這本書沒有索引內容）'), findsOneWidget);
    });

    testWidgets('renders load error from server', (tester) async {
      final api = _FakeApi(throwOnLoad: true);
      await tester.pumpWidget(TestApp(
        child: ReadingModeScreen(bookTitle: 'b', apiClient: api),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('載入失敗'), findsOneWidget);
    });

    testWidgets('search bar populates the hit card and forwards query',
        (tester) async {
      final api = _FakeApi(
        chunks: const [
          {'chunkIndex': 0, 'text': 'A'},
        ],
        hits: const [
          {
            'doc': 'b',
            'chunkIndex': 7,
            'score': 0.81,
            'snippet': 'snippet text from chunk seven',
          },
        ],
      );
      await tester.pumpWidget(TestApp(
        child: ReadingModeScreen(bookTitle: 'b', apiClient: api),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'hello world');
      await tester.tap(find.widgetWithText(FilledButton, '送出'));
      await tester.pumpAndSettle();

      expect(api.lastSearchQuery, 'hello world');
      expect(api.lastSearchDoc, 'b');
      // "#7 · 81%" rendered as title; subtitle has the snippet.
      expect(find.text('#7 · 81%'), findsOneWidget);
      expect(find.text('snippet text from chunk seven'), findsOneWidget);
    });

    testWidgets('empty-text chunk renders the (空段落) placeholder',
        (tester) async {
      final api = _FakeApi(chunks: const [
        {'chunkIndex': 0, 'text': 'real'},
        {'chunkIndex': 1, 'text': ''},
      ]);
      await tester.pumpWidget(TestApp(
        child: ReadingModeScreen(bookTitle: 'b', apiClient: api),
      ));
      await tester.pumpAndSettle();

      // Index alignment is preserved (Phase 1C invariant), so chunk #1
      // exists in the body — even though its text is empty. The screen
      // labels it explicitly so the user knows it's intentional.
      expect(find.text('（空段落）'), findsOneWidget);
    });

    testWidgets('tapping a paragraph chunk toggles selection', (tester) async {
      final api = _FakeApi(chunks: const [
        {'docName': 'b', 'chunkIndex': 0, 'text': 'first paragraph'},
      ]);
      await tester.pumpWidget(TestApp(
        child: ReadingModeScreen(bookTitle: 'b', apiClient: api),
      ));
      await tester.pumpAndSettle();

      // Tap on chunk
      await tester.tap(find.text('first paragraph'));
      await tester.pumpAndSettle();

      // Bookmark added icon should be displayed on selected chunk
      expect(find.byIcon(Icons.bookmark_added), findsOneWidget);

      // Tap on chunk again to deselect
      await tester.tap(find.text('first paragraph'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.bookmark_added), findsNothing);
    });

    testWidgets('tapping 朗讀此段 calls tts speak with paragraph content when selected', (tester) async {
      final api = _FakeApi(chunks: const [
        {'docName': 'b', 'chunkIndex': 0, 'text': 'specific content to read'},
      ]);
      final tts = _FakeTTSService();
      await tester.pumpWidget(TestApp(
        child: ReadingModeScreen(bookTitle: 'b', apiClient: api, tts: tts),
      ));
      await tester.pumpAndSettle();

      // Tap on chunk to select it
      await tester.tap(find.text('specific content to read'));
      await tester.pumpAndSettle();

      // Click "朗讀此段"
      await tester.tap(find.text('朗讀此段'));
      await tester.pumpAndSettle();

      expect(tts.lastSpokenText, 'specific content to read');
    });

    testWidgets('tapping 摘要本段 triggers Ollama summary dialog when selected', (tester) async {
      final api = _FakeApi(chunks: const [
        {'docName': 'b', 'chunkIndex': 0, 'text': 'specific text to summarize'},
      ]);
      final ollama = _FakeOllamaService(
        reply: 'Ollama chunk summary reply',
        delay: const Duration(milliseconds: 100),
      );
      await tester.pumpWidget(TestApp(
        child: ReadingModeScreen(bookTitle: 'b', apiClient: api, ollama: ollama),
      ));
      await tester.pumpAndSettle();

      // Tap to select chunk
      await tester.tap(find.text('specific text to summarize'));
      await tester.pumpAndSettle();

      // Click "摘要本段"
      await tester.tap(find.text('摘要本段'));
      await tester.pump(); // Start async process (shows loader dialog)
      await tester.pump(const Duration(milliseconds: 50)); // let dialog render

      expect(find.text('AI 正在進行段落大綱分析與總結...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100)); // Resolve Ollama future delay
      await tester.pumpAndSettle(); // Resolve animations

      // Should show summary result dialog
      expect(find.text('段落摘要'), findsOneWidget);
      expect(find.text('Ollama chunk summary reply'), findsOneWidget);
      expect(find.text('複製'), findsOneWidget);
      expect(find.text('關閉'), findsOneWidget);
    });

    testWidgets('tapping 問這一段 pushes AiQaScreen with chunk parameters', (tester) async {
      final api = _FakeApi(chunks: const [
        {'docName': 'b', 'chunkIndex': 0, 'text': 'grounding context text'},
      ]);
      await tester.pumpWidget(TestApp(
        child: ReadingModeScreen(bookTitle: 'b', apiClient: api),
      ));
      await tester.pumpAndSettle();

      // Select chunk
      await tester.tap(find.text('grounding context text'));
      await tester.pumpAndSettle();

      // Click "問這一段"
      final buttonFinder = find.text('問這一段');
      await tester.ensureVisible(buttonFinder);
      await tester.pumpAndSettle();
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      // Should push AiQaScreen
      expect(find.byType(AiQaScreen), findsOneWidget);
      expect(find.text('AI 深度問答'), findsOneWidget);
      expect(find.text('當前段落參考來源'), findsOneWidget);
      expect(find.text('grounding context text'), findsOneWidget);
    });
  });

  group('LibraryScreen → ReadingModeScreen long-press route', () {
    testWidgets('long-press on a book opens ReadingModeScreen', (tester) async {
      final api = _FakeApi(docs: const ['rag_concepts.md']);
      await tester.pumpWidget(TestApp(
        child: LibraryScreen(apiClient: api),
      ));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('rag_concepts.md'));
      await tester.pumpAndSettle();

      expect(find.byType(ReadingModeScreen), findsOneWidget);
      // The pushed screen's AppBar shows the book title.
      expect(find.text('閱讀模式：rag_concepts.md'), findsOneWidget);
    });

    testWidgets(
        'regular tap still opens the Q&A ReaderScreen, not Reading Mode',
        (tester) async {
      final api = _FakeApi(docs: const ['rag_concepts.md']);
      await tester.pumpWidget(TestApp(
        child: LibraryScreen(apiClient: api),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('rag_concepts.md'));
      await tester.pumpAndSettle();

      // Reading Mode must NOT be on the stack — Q&A path is unchanged.
      expect(find.byType(ReadingModeScreen), findsNothing);
    });

    testWidgets('tapping summarize button calls generateAndSpeakSummary and updates UI status banner', (tester) async {
      final api = _FakeApi(chunks: const [
        {'chunkIndex': 0, 'text': 'Para 1'},
        {'chunkIndex': 1, 'text': 'Para 2'},
      ]);
      final tts = _FakeTTSService();
      final ollama = _FakeOllamaService(reply: 'Fake summary reply');

      await tester.pumpWidget(TestApp(
        child: ReadingModeScreen(
          bookTitle: 'b',
          apiClient: api,
          tts: tts,
          ollama: ollama,
        ),
      ));
      await tester.pumpAndSettle();

      final summarizeButton = find.byTooltip('語音總結');
      expect(summarizeButton, findsOneWidget);

      await tester.tap(summarizeButton);
      await tester.pumpAndSettle();

      expect(find.text('語音播放中：Fake summary reply'), findsOneWidget);
      expect(tts.lastSpokenText, 'Fake summary reply');
      expect(tts.isSpeaking, isTrue);

      tts.complete();
      await tester.pumpAndSettle();

      expect(find.text('語音播放結束。'), findsOneWidget);
      expect(tts.isSpeaking, isFalse);
    });

    testWidgets('summarize routes quality dynamically based on book tags', (tester) async {
      final store = VectorStore();
      final controller = BookController(store);

      final bookLearning = Book(
        id: 'jp_book',
        title: 'japanese_learning.txt',
        tags: const ['日語', '學習'],
      );
      final bookNormal = Book(
        id: 'history_book',
        title: 'church_history.txt',
        tags: const ['教會歷史'],
      );

      await store.add(DocChunk(
        id: bookLearning.id,
        docName: 'book_${bookLearning.id}',
        chunkIndex: 0,
        text: bookLearning.toSearchText(),
        collectionName: BookController.kBookCollection,
        metadata: {
          'type': BookController.kBookTypeTag,
          'data': bookLearning.toJson(),
        },
      ));
      await store.add(DocChunk(
        id: bookNormal.id,
        docName: 'book_${bookNormal.id}',
        chunkIndex: 0,
        text: bookNormal.toSearchText(),
        collectionName: BookController.kBookCollection,
        metadata: {
          'type': BookController.kBookTypeTag,
          'data': bookNormal.toJson(),
        },
      ));
      await controller.loadAll();

      // Test language learning book -> TtsQuality.learning
      final api = _FakeApi(chunks: const [{'chunkIndex': 0, 'text': 'こんにちは'}]);
      final tts = _FakeTTSService();
      final ollama = _FakeOllamaService(reply: 'Japanese summary');

      await tester.pumpWidget(TestApp(
        child: ReadingModeScreen(
          key: const ValueKey('learning'),
          bookTitle: 'japanese_learning.txt',
          apiClient: api,
          tts: tts,
          ollama: ollama,
          bookController: controller,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('語音總結'));
      await tester.pumpAndSettle();

      expect(tts.lastSpokenQuality, TtsQuality.learning);

      // Test normal book -> TtsQuality.fast
      final api2 = _FakeApi(chunks: const [{'chunkIndex': 0, 'text': 'Normal text'}]);
      final tts2 = _FakeTTSService();
      final ollama2 = _FakeOllamaService(reply: 'Normal summary');

      await tester.pumpWidget(TestApp(
        child: ReadingModeScreen(
          key: const ValueKey('normal'),
          bookTitle: 'church_history.txt',
          apiClient: api2,
          tts: tts2,
          ollama: ollama2,
          bookController: controller,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('語音總結'));
      await tester.pumpAndSettle();

      expect(tts2.lastSpokenQuality, TtsQuality.fast);
    });

    testWidgets('TtsModeIndicator displays local/cloud status based on determined quality', (tester) async {
      final store = VectorStore();
      final controller = BookController(store);

      final bookLang = Book(
        id: 'lang_book',
        title: 'japanese_learning.txt',
        tags: const ['日語'],
      );
      final bookNormal = Book(
        id: 'norm_book',
        title: 'normal_book.txt',
        tags: const ['科幻'],
      );

      await store.add(DocChunk(
        id: bookLang.id,
        docName: 'book_${bookLang.id}',
        chunkIndex: 0,
        text: bookLang.toSearchText(),
        collectionName: BookController.kBookCollection,
        metadata: {
          'type': BookController.kBookTypeTag,
          'data': bookLang.toJson(),
        },
      ));
      await store.add(DocChunk(
        id: bookNormal.id,
        docName: 'book_${bookNormal.id}',
        chunkIndex: 0,
        text: bookNormal.toSearchText(),
        collectionName: BookController.kBookCollection,
        metadata: {
          'type': BookController.kBookTypeTag,
          'data': bookNormal.toJson(),
        },
      ));
      await controller.loadAll();

      // 1. Language book (Cloud)
      final api = _FakeApi(chunks: const [{'chunkIndex': 0, 'text': 'こんにちは'}]);
      final tts = _FakeTTSService();
      final ollama = _FakeOllamaService(reply: 'Cloud Voice');

      await tester.pumpWidget(TestApp(
        child: ReadingModeScreen(
          bookTitle: 'japanese_learning.txt',
          apiClient: api,
          tts: tts,
          ollama: ollama,
          bookController: controller,
        ),
      ));
      await tester.pumpAndSettle();

      // Initially, it's not speaking, so opacity is 0.2
      final opacityFinder = find.descendant(
        of: find.byType(TtsModeIndicator),
        matching: find.byType(Opacity),
      ).first;
      var opacityWidget = tester.widget<Opacity>(opacityFinder);
      expect(opacityWidget.opacity, 0.2);

      // Tap to speak
      await tester.tap(find.byTooltip('語音總結'));
      await tester.pumpAndSettle(); // Wait for summary generation and animation to settle!

      // Should show cloud queue icon and tooltip
      expect(find.byIcon(Icons.cloud_queue), findsOneWidget);
      expect(find.byTooltip('高品質雲端語音已啟用'), findsOneWidget);

      // Stop speech
      await tester.tap(find.byTooltip('語音總結'));
      await tester.pumpAndSettle();

      // 2. Normal book (Local)
      final api2 = _FakeApi(chunks: const [{'chunkIndex': 0, 'text': 'Normal text'}]);
      final tts2 = _FakeTTSService();
      final ollama2 = _FakeOllamaService(reply: 'Local Voice');

      await tester.pumpWidget(TestApp(
        child: ReadingModeScreen(
          bookTitle: 'normal_book.txt',
          apiClient: api2,
          tts: tts2,
          ollama: ollama2,
          bookController: controller,
        ),
      ));
      await tester.pumpAndSettle();

      // Tap to speak
      await tester.tap(find.byTooltip('語音總結'));
      await tester.pumpAndSettle(); // Wait for summary generation and animation to settle!

      // Should show offline bolt icon and tooltip
      expect(find.byIcon(Icons.offline_bolt), findsOneWidget);
      expect(find.byTooltip('本地引擎（極速模式）'), findsOneWidget);


    });

    testWidgets('tapping AI 單字 fetches language notes and shows DraggableScrollableSheet bottom sheet', (tester) async {
      final api = _FakeApi(chunks: const [
        {'docName': 'b', 'chunkIndex': 0, 'text': '日本語のテキスト'},
      ]);
      final fakeBookAi = _FakeBookAiService();
      fakeBookAi.notesReply = [
        {
          'word': '日本語',
          'reading': 'にほんご',
          'meaning': '日文',
          'explanation': 'Language of Japan',
        }
      ];
      
      // Inject fake BookAiService
      globalBookAiService = fakeBookAi;

      await tester.pumpWidget(TestApp(
        child: ReadingModeScreen(bookTitle: 'b', apiClient: api),
      ));
      await tester.pumpAndSettle();

      // Tap chunk to select it
      await tester.tap(find.text('日本語のテキスト'));
      await tester.pumpAndSettle();

      // Tap "AI 單字"
      await tester.tap(find.text('AI 單字'));
      await tester.pump(); // starts async call
      await tester.pump(const Duration(milliseconds: 50)); // let dialog render
      
      expect(find.text('正在萃取關鍵字彙...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100)); // Resolve generateAutoNotes delay
      await tester.pumpAndSettle(); // completes the future and dismisses dialog

      // Check BottomSheet content
      expect(find.text('💡 本段關鍵詞彙'), findsOneWidget);
      expect(find.text('日本語'), findsOneWidget);
      expect(find.text('にほんご'), findsOneWidget);
      expect(find.text('日文'), findsOneWidget);
      expect(find.text('Language of Japan'), findsOneWidget);

      // Bookmark / Save action
      await tester.tap(find.byIcon(Icons.bookmark_border));
      await tester.pumpAndSettle();
      expect(find.text('已存入單字本'), findsOneWidget);
    });

    testWidgets('tapping AI 高亮 fetches highlights and highlights matched text in body', (tester) async {
      final api = _FakeApi(chunks: const [
        {'docName': 'b', 'chunkIndex': 0, 'text': 'This is key sentence. And normal text.'},
      ]);
      final fakeHighlight = _FakeAiHighlightService();
      fakeHighlight.highlightsReply = ['This is key sentence.'];
      globalAiHighlightService = fakeHighlight;

      await tester.pumpWidget(TestApp(
        child: ReadingModeScreen(bookTitle: 'b', apiClient: api),
      ));
      await tester.pumpAndSettle();

      // Tap chunk to select it
      await tester.tap(find.text('This is key sentence. And normal text.'));
      await tester.pumpAndSettle();

      // Tap "AI 高亮"
      await tester.tap(find.text('AI 高亮'));
      await tester.pump(); // starts async call
      await tester.pump(const Duration(milliseconds: 50)); // let dialog render
      
      expect(find.text('正在分析關鍵句子與主題段落...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100)); // Resolve getHighlights delay
      await tester.pumpAndSettle(); // completes the future and dismisses dialog

      // Check success snackbar
      expect(find.text('已成功高亮標記 1 個關鍵處！'), findsOneWidget);

      // Verify that matched text has highlighted background style
      final selectableTextFinder = find.byType(SelectableText).first;
      final SelectableText selectableText = tester.widget(selectableTextFinder);
      final TextSpan textSpan = selectableText.textSpan!;
      
      bool foundHighlight = false;
      textSpan.visitChildren((span) {
        if (span is TextSpan && span.text == 'This is key sentence.') {
          if (span.style?.backgroundColor != null) {
            foundHighlight = true;
          }
        }
        return true;
      });
      expect(foundHighlight, isTrue);
    });

    testWidgets('tapping AI 註記 fetches notes and shows bottom sheet', (tester) async {
      final api = _FakeApi(chunks: const [
        {'docName': 'b', 'chunkIndex': 0, 'text': 'Original paragraph text.'},
      ]);
      final fakeNotes = _FakeAiNotesService();
      fakeNotes.notesReply = 'This is the paragraph note explanation.';
      globalAiNotesService = fakeNotes;

      await tester.pumpWidget(TestApp(
        child: ReadingModeScreen(bookTitle: 'b', apiClient: api),
      ));
      await tester.pumpAndSettle();

      // Tap chunk to select it
      await tester.tap(find.text('Original paragraph text.'));
      await tester.pumpAndSettle();

      // Tap "AI 註記"
      await tester.tap(find.text('AI 註記'));
      await tester.pump(); // starts async call
      await tester.pump(const Duration(milliseconds: 50)); // let dialog render
      
      expect(find.text('正在生成段落註解...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100)); // Resolve generateNotes delay
      await tester.pumpAndSettle(); // completes the future and dismisses dialog

      // Check BottomSheet content
      expect(find.text('AI 註記'), findsWidgets);
      expect(find.text('This is the paragraph note explanation.'), findsOneWidget);
    });

    testWidgets('tapping 思維導圖 fetches mind map and shows monospace AlertDialog', (tester) async {
      final api = _FakeApi(chunks: const [
        {'docName': 'b', 'chunkIndex': 0, 'text': 'First chunk of document.'},
        {'docName': 'b', 'chunkIndex': 1, 'text': 'Second chunk of document.'},
      ]);
      final fakeMindMap = _FakeAiMindMapService();
      fakeMindMap.mindMapReply = 'Introduction\n  - Concept 1\n  - Concept 2';
      globalAiMindMapService = fakeMindMap;

      await tester.pumpWidget(TestApp(
        child: ReadingModeScreen(bookTitle: 'b', apiClient: api),
      ));
      await tester.pumpAndSettle();

      // Tap "AI 思維導圖" button
      await tester.tap(find.text('AI 思維導圖'));
      await tester.pump(); // starts async call
      await tester.pump(const Duration(milliseconds: 50)); // let dialog render
      
      expect(find.text('正在生成 AI 思維導圖...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100)); // Resolve generateMindMap delay
      await tester.pumpAndSettle(); // completes the future and dismisses loading dialog

      // Check AlertDialog content
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('AI 思維導圖')), findsOneWidget);
      expect(find.text('Introduction\n  - Concept 1\n  - Concept 2'), findsOneWidget);
      
      // Verify it has fontFamily: 'monospace'
      final textFinder = find.text('Introduction\n  - Concept 1\n  - Concept 2');
      final Text textWidget = tester.widget(textFinder);
      expect(textWidget.style?.fontFamily, 'monospace');

      // Tap "關閉"
      await tester.tap(find.text('關閉'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}

class _FakeBookAiService extends Fake implements BookAiService {
  String? lastParagraph;
  List<Map<String, dynamic>> notesReply = [];

  @override
  Future<List<Map<String, dynamic>>> generateAutoNotes(String paragraph) async {
    lastParagraph = paragraph;
    await Future.delayed(const Duration(milliseconds: 100));
    return notesReply;
  }
}

class _FakeAiHighlightService extends Fake implements AiHighlightService {
  String? lastParagraph;
  List<String> highlightsReply = [];

  @override
  Future<List<String>> getHighlights(String paragraph) async {
    lastParagraph = paragraph;
    await Future.delayed(const Duration(milliseconds: 100));
    return highlightsReply;
  }
}

class _FakeAiNotesService extends Fake implements AiNotesService {
  String? lastParagraph;
  String notesReply = '';

  @override
  Future<String> generateNotes(String text) async {
    lastParagraph = text;
    await Future.delayed(const Duration(milliseconds: 100));
    return notesReply;
  }
}

class _FakeAiMindMapService extends Fake implements AiMindMapService {
  String? lastChapterText;
  String mindMapReply = '';

  @override
  Future<String> generateMindMap(String chapterText) async {
    lastChapterText = chapterText;
    await Future.delayed(const Duration(milliseconds: 100));
    return mindMapReply;
  }
}



