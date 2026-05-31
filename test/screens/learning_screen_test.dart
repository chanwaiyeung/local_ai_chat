import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/main.dart';
import 'package:local_ai_chat/screens/learning_screen.dart';
import 'package:local_ai_chat/screens/lesson_screen.dart';
import 'package:local_ai_chat/services/en_grammar_lesson_service.dart';
import 'package:local_ai_chat/services/en_grammar_service.dart';
import 'package:local_ai_chat/services/en_quiz_service.dart';
import 'package:local_ai_chat/services/en_sentence_service.dart';
import 'package:local_ai_chat/services/en_tts_service.dart';
import 'package:local_ai_chat/services/en_vocab_lesson_service.dart';
import 'package:local_ai_chat/services/en_vocab_service.dart';
import 'package:local_ai_chat/services/jp_grammar_service.dart';
import 'package:local_ai_chat/services/jp_sentence_service.dart';
import 'package:local_ai_chat/services/jp_tts_service.dart';
import 'package:local_ai_chat/services/jp_vocab_service.dart';
import 'package:local_ai_chat/services/vector_store.dart';
import 'package:local_ai_chat/widgets/ai/ai_button.dart';

import '../helpers/test_app.dart';

class _FakeEnGrammarService extends Fake implements EnGrammarService {
  String? lastSentence;
  Map<String, dynamic> reply = {};
  bool throwError = false;

  @override
  Future<Map<String, dynamic>> analyze(String sentence) async {
    lastSentence = sentence;
    await Future.delayed(const Duration(milliseconds: 100));
    if (throwError) throw Exception('API Error');
    return reply;
  }
}

class _FakeEnVocabService extends Fake implements EnVocabService {
  String? lastWord;
  Map<String, dynamic> reply = {};
  bool throwError = false;

  @override
  Future<Map<String, dynamic>> lookup(String word) async {
    lastWord = word;
    await Future.delayed(const Duration(milliseconds: 100));
    if (throwError) throw Exception('API Error');
    return reply;
  }
}

class _FakeEnSentenceService extends Fake implements EnSentenceService {
  String? lastWord;
  Map<String, dynamic> sentencesReply = {};
  Map<String, dynamic> quizReply = {};
  bool throwError = false;

  @override
  Future<Map<String, dynamic>> makeSentences(String word) async {
    lastWord = word;
    await Future.delayed(const Duration(milliseconds: 100));
    if (throwError) throw Exception('API Error');
    return sentencesReply;
  }

  @override
  Future<Map<String, dynamic>> makeQuiz(String word) async {
    lastWord = word;
    await Future.delayed(const Duration(milliseconds: 100));
    if (throwError) throw Exception('API Error');
    return quizReply;
  }
}

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

class _FakeEnGrammarLessonService extends Fake implements EnGrammarLessonService {
  Map<String, dynamic> reply = {};
  bool throwError = false;

  @override
  Future<Map<String, dynamic>> generateLesson(String topic) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (throwError) throw Exception('API Error');
    return reply;
  }
}

class _FakeEnVocabLessonService extends Fake implements EnVocabLessonService {
  Map<String, dynamic> reply = {};
  bool throwError = false;

  @override
  Future<Map<String, dynamic>> generateVocabSet(String topic) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (throwError) throw Exception('API Error');
    return reply;
  }
}

class _FakeEnQuizService extends Fake implements EnQuizService {
  Map<String, dynamic> reply = {};
  bool throwError = false;

  @override
  Future<Map<String, dynamic>> generateQuiz(String topic) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (throwError) throw Exception('API Error');
    return reply;
  }
}

class _FakeJpGrammarService extends Fake implements JpGrammarService {
  String? lastSentence;
  String reply = '';
  bool throwError = false;

  @override
  Future<String> analyze(String sentence) async {
    lastSentence = sentence;
    await Future.delayed(const Duration(milliseconds: 100));
    if (throwError) throw Exception('API Error');
    return reply;
  }
}

class _FakeJpVocabService extends Fake implements JpVocabService {
  String? lastWord;
  String reply = '';
  bool throwError = false;

  @override
  Future<String> lookup(String word) async {
    lastWord = word;
    await Future.delayed(const Duration(milliseconds: 100));
    if (throwError) throw Exception('API Error');
    return reply;
  }
}

class _FakeJpSentenceService extends Fake implements JpSentenceService {
  String? lastWord;
  String reply = '';
  bool throwError = false;

  @override
  Future<String> makeSentences(String word) async {
    lastWord = word;
    await Future.delayed(const Duration(milliseconds: 100));
    if (throwError) throw Exception('API Error');
    return reply;
  }
}

class _FakeJpTtsService extends Fake implements JpTtsService {
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
  group('LearningScreen Widget Tests', () {
    testWidgets('renders all UI components and analyzes sentence successfully', (tester) async {
      final fakeGrammar = _FakeJpGrammarService();
      fakeGrammar.reply = 'Parsed grammar result:\n1. Topic marker - は';
      globalJpGrammarService = fakeGrammar;

      await tester.pumpWidget(const TestApp(
        child: LearningScreen(),
      ));
      await tester.pumpAndSettle();

      // Check title and labels
      expect(find.text('學習天地'), findsOneWidget);
      expect(find.text('文法解析'), findsWidgets); // matches header card title and button label
      expect(find.text('日本語の勉強はとても面白いです。'), findsOneWidget); // default sentence

      // Tap the AI button to analyze grammar
      final buttonFinder = find.widgetWithText(AiButton, '文法解析');
      expect(buttonFinder, findsOneWidget);
      await tester.tap(buttonFinder);
      await tester.pump(); // Start async call, shows loading

      // Verification of loading state (CircularProgressIndicator)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100)); // Resolve analyze delay
      await tester.pumpAndSettle(); // dismisses loading and renders dialog

      // Check result dialog content
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('文法解析')), findsOneWidget);
      expect(find.text('Parsed grammar result:\n1. Topic marker - は'), findsOneWidget);

      // Close the dialog
      await tester.tap(find.text('關閉'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(fakeGrammar.lastSentence, '日本語の勉強はとても面白いです。');
    });

    testWidgets('handles analyze error and shows snackbar', (tester) async {
      final fakeGrammar = _FakeJpGrammarService();
      fakeGrammar.throwError = true;
      globalJpGrammarService = fakeGrammar;

      await tester.pumpWidget(const TestApp(
        child: LearningScreen(),
      ));
      await tester.pumpAndSettle();

      // Tap analyze button
      await tester.tap(find.widgetWithText(AiButton, '文法解析'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify that snackbar with error message is displayed
      expect(find.text('生成失敗，請稍後再試。'), findsOneWidget);
    });

    testWidgets('empty sentence shows snackbar message', (tester) async {
      await tester.pumpWidget(const TestApp(
        child: LearningScreen(),
      ));
      await tester.pumpAndSettle();

      // Clear input for grammar (first clear button)
      final clearButtons = find.byIcon(Icons.clear);
      expect(clearButtons, findsNWidgets(3));
      await tester.tap(clearButtons.first);
      await tester.pumpAndSettle();

      // Tap analyze button
      await tester.tap(find.widgetWithText(AiButton, '文法解析'));
      await tester.pumpAndSettle();

      expect(find.text('請輸入句子！'), findsOneWidget);
    });

    testWidgets('renders all UI components, analyzes vocabulary, and plays/stops Japanese speech successfully', (tester) async {
      final fakeVocab = _FakeJpVocabService();
      fakeVocab.reply = 'Parsed vocab result:\n1. 詞性 - 名詞';
      globalJpVocabService = fakeVocab;

      final fakeTts = _FakeJpTtsService();
      globalJpTtsService = fakeTts;

      await tester.pumpWidget(const TestApp(
        child: LearningScreen(),
      ));
      await tester.pumpAndSettle();

      // Check title and labels
      expect(find.text('單字解析'), findsWidgets); // matches header card title and button label
      expect(find.text('勉強'), findsOneWidget); // default word

      // Tap the AI button to analyze vocabulary
      final buttonFinder = find.widgetWithText(AiButton, '單字解析');
      expect(buttonFinder, findsOneWidget);
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pump(); // Start async call, shows loading

      // Verification of loading state (CircularProgressIndicator)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100)); // Resolve lookup delay
      await tester.pumpAndSettle(); // dismisses loading and renders bottom sheet

      // Check bottom sheet content
      expect(find.text('勉強'), findsWidgets);
      expect(find.text('Parsed vocab result:\n1. 詞性 - 名詞'), findsOneWidget);

      // Verify TTS speak button is visible and taps successfully
      final speakButton = find.byIcon(Icons.volume_up);
      expect(speakButton, findsOneWidget);
      await tester.tap(speakButton);
      await tester.pump(); // starts speak but awaits speakCompleter

      expect(fakeTts.lastText, '勉強');
      // The icon should toggle to stop_circle because speak hasn't finished yet
      final stopButton = find.byIcon(Icons.stop_circle);
      expect(stopButton, findsOneWidget);

      // Tap again to stop
      await tester.tap(stopButton);
      await tester.pumpAndSettle();
      expect(fakeTts.stopCalled, isTrue);
      expect(find.byIcon(Icons.volume_up), findsOneWidget);

      expect(fakeVocab.lastWord, '勉強');
    });

    testWidgets('handles vocab analyze error and shows snackbar', (tester) async {
      final fakeVocab = _FakeJpVocabService();
      fakeVocab.throwError = true;
      globalJpVocabService = fakeVocab;

      await tester.pumpWidget(const TestApp(
        child: LearningScreen(),
      ));
      await tester.pumpAndSettle();

      // Tap vocab analyze button
      final buttonFinder = find.widgetWithText(AiButton, '單字解析');
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify that snackbar with error message is displayed
      expect(find.text('單字解析失敗，請稍後再試。'), findsOneWidget);
    });

    testWidgets('empty word shows snackbar message', (tester) async {
      await tester.pumpWidget(const TestApp(
        child: LearningScreen(),
      ));
      await tester.pumpAndSettle();

      // Clear input for vocab (second clear button)
      final clearButtons = find.byIcon(Icons.clear);
      expect(clearButtons, findsNWidgets(3));
      final clearBtn = clearButtons.at(1);
      await tester.ensureVisible(clearBtn);
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      // Tap vocab analyze button
      final buttonFinder = find.widgetWithText(AiButton, '單字解析');
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(find.text('請輸入單字！'), findsOneWidget);
    });

    testWidgets('renders all UI components, generates sentences, and plays/stops speech successfully', (tester) async {
      final fakeSentence = _FakeJpSentenceService();
      fakeSentence.reply = '1. 初級句子\n  - Sentence 1';
      globalJpSentenceService = fakeSentence;

      final fakeTts = _FakeJpTtsService();
      globalJpTtsService = fakeTts;

      await tester.pumpWidget(const TestApp(
        child: LearningScreen(),
      ));
      await tester.pumpAndSettle();

      // Check title and labels
      expect(find.text('例句生成'), findsWidgets); // matches header card title and button label
      expect(find.text('練習'), findsOneWidget); // default word

      // Tap the AI button to generate sentences
      final buttonFinder = find.widgetWithText(AiButton, '例句生成');
      expect(buttonFinder, findsOneWidget);
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pump(); // Start async call, shows loading

      // Verification of loading state (CircularProgressIndicator)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100)); // Resolve sentence delay
      await tester.pumpAndSettle(); // dismisses loading and renders dialog

      // Check result dialog content
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('AI 例句')), findsOneWidget);
      expect(find.text('1. 初級句子\n  - Sentence 1'), findsOneWidget);

      // Verify TTS speak button is visible in Dialog and taps successfully
      final speakButton = find.byIcon(Icons.volume_up);
      expect(speakButton, findsOneWidget);
      await tester.tap(speakButton);
      await tester.pump(); // starts speak but awaits speakCompleter

      expect(fakeTts.lastText, '1. 初級句子\n  - Sentence 1');
      final stopButton = find.byIcon(Icons.stop_circle);
      expect(stopButton, findsOneWidget);

      // Tap again to stop
      await tester.tap(stopButton);
      await tester.pumpAndSettle();
      expect(fakeTts.stopCalled, isTrue);
      expect(find.byIcon(Icons.volume_up), findsOneWidget);

      // Close the dialog
      await tester.tap(find.text('關閉'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(fakeSentence.lastWord, '練習');
    });

    testWidgets('handles sentence generation error and shows snackbar', (tester) async {
      final fakeSentence = _FakeJpSentenceService();
      fakeSentence.throwError = true;
      globalJpSentenceService = fakeSentence;

      await tester.pumpWidget(const TestApp(
        child: LearningScreen(),
      ));
      await tester.pumpAndSettle();

      // Tap sentence button
      final buttonFinder = find.widgetWithText(AiButton, '例句生成');
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify that snackbar with error message is displayed
      expect(find.text('例句生成失敗，請稍後再試。'), findsOneWidget);
    });

    testWidgets('empty word for sentence shows snackbar message', (tester) async {
      await tester.pumpWidget(const TestApp(
        child: LearningScreen(),
      ));
      await tester.pumpAndSettle();

      // Clear input for sentence (third clear button)
      final clearButtons = find.byIcon(Icons.clear);
      expect(clearButtons, findsNWidgets(3));
      final clearBtn = clearButtons.last;
      await tester.ensureVisible(clearBtn);
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      // Tap sentence button
      final buttonFinder = find.widgetWithText(AiButton, '例句生成');
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(find.text('請輸入單字！'), findsOneWidget);
    });

    testWidgets('English Lab: renders tab and analyzes sentence successfully', (tester) async {
      final fakeGrammar = _FakeEnGrammarService();
      fakeGrammar.reply = {
        'structure': 'SVO',
        'pos_tags': 'The/det dog/noun barked/verb',
        'grammar_focus': 'Past simple tense',
        'translation': '狗在叫',
        'common_mistakes': 'None'
      };
      globalEnGrammarService = fakeGrammar;

      final fakeTts = _FakeEnTtsService();
      globalEnTtsService = fakeTts;

      await tester.pumpWidget(const TestApp(
        child: LearningScreen(),
      ));
      await tester.pumpAndSettle();

      // Tap English tab
      final tabFinder = find.text('英文學習');
      expect(tabFinder, findsOneWidget);
      await tester.tap(tabFinder);
      await tester.pumpAndSettle();

      // Verify English Grammar Card is visible
      expect(find.text('英文文法解析'), findsWidgets);
      expect(find.text('The quick brown fox jumps over the lazy dog.'), findsOneWidget);

      // Click analyze
      final buttonFinder = find.widgetWithText(AiButton, '英文文法解析');
      expect(buttonFinder, findsOneWidget);
      await tester.tap(buttonFinder);
      await tester.pump(); // Loading

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify AlertDialog content
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('SVO'), findsOneWidget);
      expect(find.text('狗在叫'), findsOneWidget);
      expect(find.text('Past simple tense'), findsOneWidget);

      // Verify TTS playing in AlertDialog
      final speakButton = find.byIcon(Icons.volume_up);
      expect(speakButton, findsOneWidget);
      await tester.tap(speakButton);
      await tester.pump(); // Starts play but awaits completer

      expect(fakeTts.lastText, 'The quick brown fox jumps over the lazy dog.');
      
      final stopButton = find.byIcon(Icons.stop_circle);
      expect(stopButton, findsOneWidget);
      await tester.tap(stopButton);
      await tester.pumpAndSettle();

      expect(fakeTts.stopCalled, isTrue);

      // Close Dialog
      await tester.tap(find.text('關閉'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('English Lab: analyzes vocabulary, displays cefr/definition and plays TTS successfully', (tester) async {
      globalStore = VectorStore(); // reset the store for clean testing
      final fakeVocab = _FakeEnVocabService();
      fakeVocab.reply = {
        'word': 'abandon',
        'part_of_speech': 'v.',
        'meaning': '放棄，遺棄',
        'collocations': ['abandon the project', 'abandon the ship'],
        'examples': [
          {'en': 'They had to abandon the ship.', 'zh': '他們不得不棄船。'},
          {'en': 'Never abandon your dreams.', 'zh': '永遠不要放棄你的夢想。'}
        ],
        'synonyms_antonyms': '同義詞: desert, leave / 反義詞: keep, retain',
        'cefr_level': 'B2'
      };
      globalEnVocabService = fakeVocab;

      final fakeTts = _FakeEnTtsService();
      globalEnTtsService = fakeTts;

      await tester.pumpWidget(const TestApp(
        child: LearningScreen(),
      ));
      await tester.pumpAndSettle();

      // Tap English Tab
      await tester.tap(find.text('英文學習'));
      await tester.pumpAndSettle();

      final buttonFinder = find.widgetWithText(AiButton, '英文單字解析');
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify BottomSheet content
      expect(find.text('abandon'), findsWidgets);
      expect(find.text('B2'), findsOneWidget);
      expect(find.text('v.'), findsOneWidget);
      expect(find.text('放棄，遺棄'), findsOneWidget);
      
      // Verify collocations tags are rendered
      expect(find.text('abandon the project'), findsOneWidget);
      expect(find.text('abandon the ship'), findsOneWidget);

      // Verify multiple examples are rendered
      expect(find.text('They had to abandon the ship.'), findsOneWidget);
      expect(find.text('Never abandon your dreams.'), findsOneWidget);

      // Play word TTS (first speak icon)
      final speakButtons = find.byIcon(Icons.volume_up);
      // Word speak button is at index 0, examples are at 1 and 2
      expect(speakButtons, findsNWidgets(3));
      
      final wordSpeakBtn = speakButtons.at(0);
      await tester.tap(wordSpeakBtn);
      await tester.pump();

      expect(fakeTts.lastText, 'abandon');
      
      final stopButtons = find.byIcon(Icons.stop_circle);
      expect(stopButtons, findsOneWidget);
      await tester.tap(stopButtons.first);
      await tester.pumpAndSettle();

      expect(fakeTts.stopCalled, isTrue);

      // Test "Save to Vocabulary List" (存入單字本) button
      final saveBtn = find.text('存入單字本');
      expect(saveBtn, findsOneWidget);
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verify SnackBar or save status text change
      expect(find.text('已存入單字本！'), findsOneWidget);
      expect(find.text('已存入單字本'), findsOneWidget); // the button text changes
      
      // Verify it was actually saved in globalStore
      final vocabChunks = globalStore.chunks.where((c) => c.collectionName == 'Vocabulary').toList();
      expect(vocabChunks.length, 1);
      final chunk = vocabChunks.first;
      expect(chunk.collectionName, 'Vocabulary');
      expect(chunk.docName, 'abandon');
      expect(chunk.metadata['meaning'], '放棄，遺棄');
      expect(chunk.metadata['cefr_level'], 'B2');
    });

    testWidgets('English Lab: generates sentence and quiz, interacts with option tapping successfully', (tester) async {
      final fakeSentence = _FakeEnSentenceService();
      fakeSentence.sentencesReply = {
        'beginner': {'en': 'Beginner sentence.', 'zh': '初級翻譯'},
        'intermediate': {'en': 'Intermediate sentence.', 'zh': '中級翻譯'},
        'advanced': {'en': 'Advanced sentence.', 'zh': '高級翻譯'},
        'slang_or_spoken': {'en': 'Spoken slang.', 'zh': '口語翻譯'}
      };
      fakeSentence.quizReply = {
        'questions': [
          {
            'question': 'The company decided to ___ the project.',
            'options': ['evaluate', 'abandon', 'bark', 'run'],
            'correct_answer_index': 0,
            'explanation': '答案是 evaluate，因為公司要評估項目。'
          }
        ]
      };
      globalEnSentenceService = fakeSentence;

      final fakeTts = _FakeEnTtsService();
      globalEnTtsService = fakeTts;

      await tester.pumpWidget(const TestApp(
        child: LearningScreen(),
      ));
      await tester.pumpAndSettle();

      // Tap English Tab
      await tester.tap(find.text('英文學習'));
      await tester.pumpAndSettle();

      final buttonFinder = find.widgetWithText(AiButton, '英文例句與測驗');
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify Sentence Dialog Content
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Beginner sentence.'), findsOneWidget);
      expect(find.text('The company decided to ___ the project.'), findsOneWidget);

      // Select Option 'evaluate' (correct option)
      final optionBtn = find.widgetWithText(OutlinedButton, 'evaluate');
      expect(optionBtn, findsOneWidget);
      
      // Before selecting, explanation is not shown
      expect(find.text('答案是 evaluate，因為公司要評估項目。'), findsNothing);

      await tester.ensureVisible(optionBtn);
      await tester.tap(optionBtn);
      await tester.pumpAndSettle();

      // After selecting, explanation is shown
      expect(find.text('答案是 evaluate，因為公司要評估項目。'), findsOneWidget);
      expect(find.text('答對了！'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('關閉'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('English Lab: records TTS speech to Listening History and can clear it', (tester) async {
      globalStore = VectorStore();
      
      final fakeGrammar = _FakeEnGrammarService();
      fakeGrammar.reply = {
        'structure': 'SVO',
        'pos_tags': 'The/det dog/noun barked/verb',
        'grammar_focus': 'Past simple',
        'translation': '狗在叫',
        'common_mistakes': 'None'
      };
      globalEnGrammarService = fakeGrammar;

      final fakeTts = _FakeEnTtsService();
      globalEnTtsService = fakeTts;

      await tester.pumpWidget(const TestApp(
        child: LearningScreen(),
      ));
      await tester.pumpAndSettle();

      // Tap English Tab
      await tester.tap(find.text('英文學習'));
      await tester.pumpAndSettle();

      // Verify history is empty initially
      expect(find.text('尚無聽力紀錄，請在上方點擊語音播放！'), findsOneWidget);

      // Trigger a grammar analysis to play TTS and populate history
      final buttonFinder = find.widgetWithText(AiButton, '英文文法解析');
      await tester.tap(buttonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Play TTS in the dialog
      final speakButton = find.byIcon(Icons.volume_up);
      expect(speakButton, findsOneWidget);
      await tester.tap(speakButton);
      await tester.pump(); // Starts play

      // Close the dialog
      await tester.tap(find.text('關閉'));
      await tester.pumpAndSettle();

      // Verify that the item is recorded in Listening History list
      final historyCard = find.widgetWithText(Card, '聽力歷史紀錄 (Listening History)');
      expect(historyCard, findsOneWidget);
      expect(find.text('尚無聽力紀錄，請在上方點擊語音播放！'), findsNothing);
      expect(find.descendant(of: historyCard, matching: find.text('The quick brown fox jumps over the lazy dog.')), findsOneWidget);
      expect(find.descendant(of: historyCard, matching: find.text('句型文法檢查')), findsOneWidget);

      // Tap play button inside the history card
      final historyPlayBtn = find.descendant(
        of: historyCard,
        matching: find.byIcon(Icons.volume_up),
      );
      expect(historyPlayBtn, findsOneWidget);
      await tester.ensureVisible(historyPlayBtn);
      await tester.tap(historyPlayBtn);
      await tester.pump();

      expect(fakeTts.lastText, 'The quick brown fox jumps over the lazy dog.');

      // Tap the "清除" button to clear history
      final clearBtn = find.text('清除');
      expect(clearBtn, findsOneWidget);
      await tester.ensureVisible(clearBtn);
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      // Verify history is empty again
      expect(find.text('尚無聽力紀錄，請在上方點擊語音播放！'), findsOneWidget);
      expect(find.descendant(of: historyCard, matching: find.text('The quick brown fox jumps over the lazy dog.')), findsNothing);
    });

    testWidgets('English Lab: triggers AI English Classroom and navigates to LessonScreen successfully', (tester) async {
      final fakeGrammarLesson = _FakeEnGrammarLessonService();
      fakeGrammarLesson.reply = {
        'explanation': 'Welcome to Restaurant English.',
        'examples': [{'en': 'May I have a menu?', 'zh': '我可以要一份菜單嗎？'}],
        'common_mistakes': 'None',
        'tts_sentences': ['Check, please.'],
      };
      globalEnGrammarLessonService = fakeGrammarLesson;

      final fakeVocabLesson = _FakeEnVocabLessonService();
      fakeVocabLesson.reply = {
        'vocabulary': [
          {
            'word': 'menu',
            'part_of_speech': 'n.',
            'meaning': '菜單',
            'example': {'en': 'Here is the menu.', 'zh': '這是菜單。'},
            'synonyms': ['bill of fare'],
            'antonyms': []
          }
        ]
      };
      globalEnVocabLessonService = fakeVocabLesson;

      final fakeQuiz = _FakeEnQuizService();
      fakeQuiz.reply = {
        'questions': [
          {
            'question': 'Can I see the ___?',
            'options': ['menu', 'car', 'dog', 'run'],
            'correct_answer_index': 0,
            'explanation': 'We look at menu in a restaurant.'
          }
        ]
      };
      globalEnQuizService = fakeQuiz;

      await tester.pumpWidget(const TestApp(
        child: LearningScreen(),
      ));
      await tester.pumpAndSettle();

      // Tap English Tab
      await tester.tap(find.text('英文學習'));
      await tester.pumpAndSettle();

      // Verify AI English Classroom card is visible
      expect(find.text('AI 英文課堂 (AI English Classroom)'), findsOneWidget);
      expect(find.text('Restaurant English'), findsOneWidget); // default text prefilled

      // Find and tap the "開始課堂" button
      final startBtn = find.widgetWithText(AiButton, '開始課堂');
      expect(startBtn, findsOneWidget);
      await tester.tap(startBtn);
      await tester.pump(); // Starts parallel calls, shows loading

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100)); // Resolve delay
      await tester.pumpAndSettle(); // Navigate and settle

      // Verify LessonScreen is pushed
      expect(find.byType(LessonScreen), findsOneWidget);
      expect(find.text('Restaurant English'), findsOneWidget);
      expect(find.text('Welcome to Restaurant English.'), findsOneWidget);
    });
  });
}


