import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/main.dart';
import 'package:local_ai_chat/screens/lesson_screen.dart';
import 'package:local_ai_chat/services/en_tts_service.dart';
import 'package:local_ai_chat/services/vector_store.dart';

import '../helpers/test_app.dart';

class _FakeEnTtsService extends Fake implements EnTtsService {
  String? lastText;
  bool stopCalled = false;
  Completer<void>? speakCompleter;

  @override
  Future<void> speak(String text) async {
    lastText = text;
    speakCompleter = Completer<void>();
    await speakCompleter!.future;
  }

  @override
  Future<void> stop() async {
    stopCalled = true;
    if (speakCompleter != null && !speakCompleter!.isCompleted) {
      speakCompleter!.complete();
    }
  }
}

void main() {
  group('LessonScreen Widget Tests', () {
    late _FakeEnTtsService fakeTts;
    late Map<String, dynamic> dummyGrammar;
    late Map<String, dynamic> dummyVocab;
    late Map<String, dynamic> dummyQuiz;

    setUp(() {
      fakeTts = _FakeEnTtsService();
      globalEnTtsService = fakeTts;
      globalStore = VectorStore();

      dummyGrammar = {
        'explanation': 'This is a test grammar explanation.',
        'examples': [
          {'en': 'Please sit down.', 'zh': '請坐。'},
          {'en': 'Stand up, please.', 'zh': '請站起來。'},
        ],
        'common_mistakes': 'Do not say stand down.',
        'tts_sentences': [
          'Read this sentence.',
          'Repeat after me.',
        ],
      };

      dummyVocab = {
        'vocabulary': [
          {
            'word': 'apple',
            'part_of_speech': 'n.',
            'meaning': '蘋果',
            'example': {
              'en': 'I eat an apple daily.',
              'zh': '我每天吃一個蘋果。',
            },
            'synonyms': ['pome'],
            'antonyms': ['non-apple'],
          },
          {
            'word': 'banana',
            'part_of_speech': 'n.',
            'meaning': '香蕉',
            'example': {
              'en': 'Bananas are yellow.',
              'zh': '香蕉是黃色的。',
            },
            'synonyms': [],
            'antonyms': [],
          }
        ],
      };

      dummyQuiz = {
        'questions': [
          {
            'question': 'What is the color of banana?',
            'options': ['Red', 'Blue', 'Yellow', 'Green'],
            'correct_answer_index': 2,
            'explanation': 'Bananas are yellow.',
          },
          {
            'question': 'Which word is a fruit?',
            'options': ['Apple', 'Car', 'Desk', 'Run'],
            'correct_answer_index': 0,
            'explanation': 'Apple is a fruit.',
          }
        ],
      };
    });

    testWidgets('renders all tabs and grammar content correctly', (tester) async {
      await tester.pumpWidget(TestApp(
        child: LessonScreen(
          topic: 'Fruit English',
          grammarLesson: dummyGrammar,
          vocabLesson: dummyVocab,
          quiz: dummyQuiz,
        ),
      ));
      await tester.pumpAndSettle();

      // Verify title is rendered
      expect(find.text('Fruit English'), findsOneWidget);

      // Verify tabs are rendered
      expect(find.text('文法課堂'), findsOneWidget);
      expect(find.text('核心單字'), findsOneWidget);
      expect(find.text('課堂測驗'), findsOneWidget);

      // We should be on the Grammar tab first
      expect(find.text('文法要點說明'), findsOneWidget);
      expect(find.text('This is a test grammar explanation.'), findsOneWidget);
      expect(find.text('Please sit down.'), findsOneWidget);
      expect(find.text('請坐。'), findsOneWidget);
      expect(find.text('💡 常見錯誤與提示'), findsOneWidget);
      expect(find.text('Do not say stand down.'), findsOneWidget);
      expect(find.text('🗣️ 朗讀口說練習'), findsOneWidget);
      expect(find.text('Read this sentence.'), findsOneWidget);
    });

    testWidgets('plays grammar TTS examples and oral sentences', (tester) async {
      await tester.pumpWidget(TestApp(
        child: LessonScreen(
          topic: 'Fruit English',
          grammarLesson: dummyGrammar,
          vocabLesson: dummyVocab,
          quiz: dummyQuiz,
        ),
      ));
      await tester.pumpAndSettle();

      // Find all volume_up icons (which trigger speak)
      final speakButtons = find.byIcon(Icons.volume_up);
      // There are 2 examples and 2 tts_sentences, so 4 speak buttons in total
      expect(speakButtons, findsNWidgets(4));

      // Play the first example: "Please sit down."
      final firstBtn = speakButtons.at(0);
      await tester.ensureVisible(firstBtn);
      await tester.tap(firstBtn);
      await tester.pump(); // Starts TTS speak

      expect(fakeTts.lastText, 'Please sit down.');

      // Tapping the stop button
      final stopButton = find.byIcon(Icons.stop_circle);
      expect(stopButton, findsOneWidget);
      await tester.ensureVisible(stopButton);
      await tester.tap(stopButton);
      await tester.pumpAndSettle();

      expect(fakeTts.stopCalled, isTrue);

      // Play the first oral sentence: "Read this sentence."
      // Since we stopped, all buttons should return to volume_up
      expect(find.byIcon(Icons.volume_up), findsNWidgets(4));
      final oralBtn = find.byIcon(Icons.volume_up).at(2); // index 2 is the first tts sentence
      await tester.ensureVisible(oralBtn);
      await tester.tap(oralBtn);
      await tester.pump();

      expect(fakeTts.lastText, 'Read this sentence.');
    });

    testWidgets('vocabulary tab renders, plays TTS, and bookmarks a word successfully', (tester) async {
      await tester.pumpWidget(TestApp(
        child: LessonScreen(
          topic: 'Fruit English',
          grammarLesson: dummyGrammar,
          vocabLesson: dummyVocab,
          quiz: dummyQuiz,
        ),
      ));
      await tester.pumpAndSettle();

      // Switch to vocabulary tab
      await tester.tap(find.text('核心單字'));
      await tester.pumpAndSettle();

      // Verify vocabulary items are rendered
      expect(find.text('apple'), findsOneWidget);
      expect(find.text('banana'), findsOneWidget);
      expect(find.text('蘋果'), findsOneWidget);
      expect(find.text('香蕉'), findsOneWidget);
      expect(find.text('I eat an apple daily.'), findsOneWidget);
      expect(find.text('同義: pome'), findsOneWidget);

      // Click TTS play for apple (the first word)
      // There's a speak button for apple word, apple example, banana word, banana example -> 4 in total
      final speakButtons = find.byIcon(Icons.volume_up);
      expect(speakButtons, findsNWidgets(4));

      final playWordBtn = speakButtons.at(0);
      await tester.ensureVisible(playWordBtn);
      await tester.tap(playWordBtn);
      await tester.pump();
      expect(fakeTts.lastText, 'apple');

      // Stop speaking
      final stopBtn = find.byIcon(Icons.stop_circle);
      await tester.ensureVisible(stopBtn);
      await tester.tap(stopBtn);
      await tester.pumpAndSettle();

      // Click "存入單字本" for apple
      final saveButtons = find.text('存入單字本');
      expect(saveButtons, findsNWidgets(2)); // One button for each word

      final firstSaveBtn = saveButtons.at(0);
      await tester.ensureVisible(firstSaveBtn);
      await tester.tap(firstSaveBtn);
      await tester.pumpAndSettle();

      // Check SnackBar message
      expect(find.text('已存入單字本！'), findsOneWidget);
      expect(find.text('已存入單字本'), findsOneWidget); // Button text changed for first word

      // Check vector store persistence
      final vocabChunks = globalStore.chunks.where((c) => c.collectionName == 'Vocabulary').toList();
      expect(vocabChunks.length, 1);
      expect(vocabChunks.first.docName, 'apple');
      expect(vocabChunks.first.metadata['meaning'], '蘋果');
      expect(vocabChunks.first.metadata['part_of_speech'], 'n.');
    });

    testWidgets('quiz tab renders, allows option selection, shows explanation, and calculates score', (tester) async {
      await tester.pumpWidget(TestApp(
        child: LessonScreen(
          topic: 'Fruit English',
          grammarLesson: dummyGrammar,
          vocabLesson: dummyVocab,
          quiz: dummyQuiz,
        ),
      ));
      await tester.pumpAndSettle();

      // Switch to quiz tab
      await tester.tap(find.text('課堂測驗'));
      await tester.pumpAndSettle();

      // Verify quiz questions are rendered
      expect(find.text('問題 1: What is the color of banana?'), findsOneWidget);
      expect(find.text('問題 2: Which word is a fruit?'), findsOneWidget);

      // Question 1: select 'Yellow' (correct index is 2)
      final yellowOption = find.widgetWithText(OutlinedButton, 'Yellow');
      expect(yellowOption, findsOneWidget);
      
      // Before selecting, explanation is hidden
      expect(find.text('Bananas are yellow.'), findsNothing);
      expect(find.text('答對了！'), findsNothing);

      await tester.ensureVisible(yellowOption);
      await tester.tap(yellowOption);
      await tester.pumpAndSettle();

      // Now explanation is shown
      expect(find.text('Bananas are yellow.'), findsOneWidget);
      expect(find.text('答對了！'), findsOneWidget);

      // Question 2: select 'Car' (incorrect, correct index is 0)
      final carOption = find.widgetWithText(OutlinedButton, 'Car');
      expect(carOption, findsOneWidget);

      expect(find.text('Apple is a fruit.'), findsNothing);
      expect(find.text('答錯了，請看解析！'), findsNothing);

      await tester.ensureVisible(carOption);
      await tester.tap(carOption);
      await tester.pumpAndSettle();

      expect(find.text('Apple is a fruit.'), findsOneWidget);
      expect(find.text('答錯了，請看解析！'), findsOneWidget);

      // Both questions are answered, check if final score card is shown
      final finalScoreText = find.text('🏆 課堂測驗完成！');
      await tester.ensureVisible(finalScoreText);
      expect(finalScoreText, findsOneWidget);
      expect(find.text('答對題數: 1 / 2'), findsOneWidget);
      expect(find.text('做得好！請繼續保持努力！💪'), findsOneWidget);
    });
   group('LessonScreen Error Handling and Empty State Tests', () {
      testWidgets('quiz with empty questions list renders empty state', (tester) async {
        await tester.pumpWidget(TestApp(
          child: LessonScreen(
            topic: 'Empty Quiz topic',
            grammarLesson: dummyGrammar,
            vocabLesson: dummyVocab,
            quiz: const {'questions': []},
          ),
        ));
        await tester.pumpAndSettle();

        // Switch to quiz tab
        await tester.tap(find.text('課堂測驗'));
        await tester.pumpAndSettle();

        expect(find.text('無測驗內容'), findsOneWidget);
      });
    });
  });
}


