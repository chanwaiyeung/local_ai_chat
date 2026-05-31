import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../services/vector_store.dart';
import '../widgets/ai/ai_button.dart';
import 'lesson_screen.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  // Japanese controllers
  final TextEditingController _controller = TextEditingController(
    text: '日本語の勉強はとても面白いです。',
  );
  final TextEditingController _vocabController = TextEditingController(
    text: '勉強',
  );
  final TextEditingController _sentenceController = TextEditingController(
    text: '練習',
  );

  // English controllers
  final TextEditingController _enGrammarController = TextEditingController(
    text: 'The quick brown fox jumps over the lazy dog.',
  );
  final TextEditingController _enVocabController = TextEditingController(
    text: 'abandon',
  );
  final TextEditingController _enSentenceController = TextEditingController(
    text: 'evaluate',
  );
  final TextEditingController _enLessonController = TextEditingController(
    text: 'Restaurant English',
  );

  // Japanese Handlers
  Future<void> _onGrammar(BuildContext context, String inputSentence) async {
    if (inputSentence.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入句子！')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await globalJpGrammarService.analyze(inputSentence);

      if (!context.mounted) return;
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.language, color: Colors.green),
              const SizedBox(width: 8),
              Text(AppLocalizations.of(context).grammarAnalysis),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              result,
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).close),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).generateFailed)),
      );
    }
  }

  Future<void> _onVocab(BuildContext context, String inputWord) async {
    if (inputWord.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入單字！')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final info = await globalJpVocabService.lookup(inputWord);

      if (!context.mounted) return;
      Navigator.pop(context);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          bool isSpeaking = false;
          return StatefulBuilder(
            builder: (context, setModalState) {
              Future<void> onSpeak(String text) async {
                try {
                  if (isSpeaking) {
                    await globalJpTtsService.stop();
                    setModalState(() => isSpeaking = false);
                  } else {
                    setModalState(() => isSpeaking = true);
                    await globalJpTtsService.speak(text);
                    setModalState(() => isSpeaking = false);
                  }
                } catch (e) {
                  setModalState(() => isSpeaking = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('語音播放失敗，請檢查裝置設定。')),
                    );
                  }
                }
              }

              final loc = AppLocalizations.of(context);
              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                    left: 24,
                    right: 24,
                    top: 24,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.spellcheck, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              inputWord,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                isSpeaking ? Icons.stop_circle : Icons.volume_up,
                                color: isSpeaking ? Colors.red : Colors.blue,
                                size: 28,
                              ),
                              tooltip: isSpeaking ? loc.stopSpeaking : loc.speakPronunciation,
                              onPressed: () => onSpeak(inputWord),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        Text(
                          info,
                          style: const TextStyle(fontSize: 16, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).vocabAnalysisFailed)),
      );
    }
  }

  Future<void> _onSentence(BuildContext context, String inputWord) async {
    if (inputWord.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入單字！')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final sentences = await globalJpSentenceService.makeSentences(inputWord);

      if (!context.mounted) return;
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) {
          bool isSpeaking = false;
          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> onSpeak(String text) async {
                try {
                  if (isSpeaking) {
                    await globalJpTtsService.stop();
                    setDialogState(() => isSpeaking = false);
                  } else {
                    setDialogState(() => isSpeaking = true);
                    await globalJpTtsService.speak(text);
                    setDialogState(() => isSpeaking = false);
                  }
                } catch (e) {
                  setDialogState(() => isSpeaking = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('語音播放失敗，請檢查裝置設定。')),
                    );
                  }
                }
              }

              final loc = AppLocalizations.of(context);
              return AlertDialog(
                title: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Text(loc.aiSentence),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        isSpeaking ? Icons.stop_circle : Icons.volume_up,
                        color: isSpeaking ? Colors.red : Colors.blue,
                        size: 28,
                      ),
                      tooltip: isSpeaking ? loc.stopSpeaking : loc.speakPronunciation,
                      onPressed: () => onSpeak(sentences),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Text(
                    sentences,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      if (isSpeaking) {
                        globalJpTtsService.stop();
                      }
                      Navigator.pop(context);
                    },
                    child: Text(loc.close),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).sentenceGenerationFailed)),
      );
    }
  }

  Future<void> _addToListeningHistory(String text, String subtitle) async {
    try {
      final existingId = 'ListeningHistory:${text.hashCode}';
      await globalStore.deleteById(existingId);

      final chunk = DocChunk(
        id: existingId,
        collectionName: 'ListeningHistory',
        docName: 'history_item',
        chunkIndex: 0,
        text: text,
        metadata: {
          'text': text,
          'subtitle': subtitle,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      await globalStore.addToCollection('ListeningHistory', chunk);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Failed to save to listening history: $e');
    }
  }

  // English Handlers
  Future<void> _onEnGrammar(BuildContext context, String inputSentence) async {
    if (inputSentence.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入句子！')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await globalEnGrammarService.analyze(inputSentence);

      if (!context.mounted) return;
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) {
          bool isSpeaking = false;
          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> onSpeak(String text) async {
                try {
                  if (isSpeaking) {
                    await globalEnTtsService.stop();
                    setDialogState(() => isSpeaking = false);
                  } else {
                    setDialogState(() => isSpeaking = true);
                    _addToListeningHistory(text, '句型文法檢查');
                    await globalEnTtsService.speak(text);
                    setDialogState(() => isSpeaking = false);
                  }
                } catch (e) {
                  setDialogState(() => isSpeaking = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('語音播放失敗，請檢查裝置設定。')),
                    );
                  }
                }
              }

              final loc = AppLocalizations.of(context);
              return AlertDialog(
                title: Row(
                  children: [
                    const Icon(Icons.language, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(loc.enGrammarAnalysis),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        isSpeaking ? Icons.stop_circle : Icons.volume_up,
                        color: isSpeaking ? Colors.red : Colors.blue,
                        size: 28,
                      ),
                      tooltip: isSpeaking ? loc.stopSpeaking : loc.speakPronunciation,
                      onPressed: () => onSpeak(inputSentence),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDetailItem('中文意思', (result['translation'] as String?) ?? ''),
                      const Divider(),
                      _buildDetailItem('句型結構', (result['structure'] as String?) ?? ''),
                      const Divider(),
                      _buildDetailItem('詞性標註', (result['pos_tags'] as String?) ?? ''),
                      const Divider(),
                      _buildDetailItem('文法重點', (result['grammar_focus'] as String?) ?? ''),
                      const Divider(),
                      _buildDetailItem('常見錯誤', (result['common_mistakes'] as String?) ?? ''),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      if (isSpeaking) {
                        globalEnTtsService.stop();
                      }
                      Navigator.pop(context);
                    },
                    child: Text(loc.close),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).generateFailed)),
      );
    }
  }

  Future<void> _onEnVocab(BuildContext context, String inputWord) async {
    if (inputWord.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入單字！')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await globalEnVocabService.lookup(inputWord);

      if (!context.mounted) return;
      Navigator.pop(context);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          int activeSpeakingIndex = -1; // -1: none, 0: word, 1+: example at index-1
          bool isSaved = false;

          return StatefulBuilder(
            builder: (context, setModalState) {
              final loc = AppLocalizations.of(context);
              final String wordStr = (result['word'] as String?) ?? inputWord;
              final String pos = (result['part_of_speech'] as String?) ?? '';
              final String cefr = (result['cefr_level'] as String?) ?? '';
              final String meaning = (result['meaning'] as String?) ?? (result['definition'] as String?) ?? '';
              final List<dynamic> collocations = (result['collocations'] as List<dynamic>?) ?? <dynamic>[];
              final List<dynamic> examples = (result['examples'] as List<dynamic>?) ?? <dynamic>[];
              final String synonymsAntonyms = (result['synonyms_antonyms'] as String?) ?? (result['synonyms'] as String?) ?? '';

              Future<void> onSpeak(String text, int index) async {
                try {
                  if (activeSpeakingIndex == index) {
                    await globalEnTtsService.stop();
                    setModalState(() => activeSpeakingIndex = -1);
                  } else {
                    if (activeSpeakingIndex != -1) {
                      await globalEnTtsService.stop();
                    }
                    setModalState(() => activeSpeakingIndex = index);
                    final subtitle = index == 0
                        ? '${pos.isNotEmpty ? "$pos · " : ""}$meaning'
                        : '例句 · $wordStr';
                    _addToListeningHistory(text, subtitle);
                    await globalEnTtsService.speak(text);
                    setModalState(() => activeSpeakingIndex = -1);
                  }
                } catch (e) {
                  setModalState(() => activeSpeakingIndex = -1);
                }
              }

              Future<void> onSaveWord(String w, String p, String m, String c, String sa, List<dynamic> colls) async {
                try {
                  final chunk = DocChunk(
                    collectionName: 'Vocabulary',
                    docName: w,
                    chunkIndex: 0,
                    text: '$w ($p) - $m',
                    metadata: {
                      'word': w,
                      'part_of_speech': p,
                      'meaning': m,
                      'cefr_level': c,
                      'synonyms_antonyms': sa,
                      'collocations': colls,
                      'savedAt': DateTime.now().toIso8601String(),
                    },
                  );
                  await globalStore.addToCollection('Vocabulary', chunk);
                  setModalState(() => isSaved = true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已存入單字本！')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('儲存失敗: $e')),
                    );
                  }
                }
              }

              return DraggableScrollableSheet(
                initialChildSize: 0.6, // 預設佔螢幕 60%
                minChildSize: 0.4,
                maxChildSize: 0.9,
                expand: false,
                builder: (_, scrollController) {
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 頂部：單字 + 詞性 + CEFR + 朗讀按鈕
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  wordStr,
                                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ),
                              if (cefr.isNotEmpty)
                                Chip(
                                  label: Text(cefr, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  backgroundColor: Colors.amber.shade100,
                                ),
                              const SizedBox(width: 8),
                              // TTS 朗讀按鈕 (結合 StatefulBuilder 管理播放狀態)
                              IconButton(
                                icon: Icon(
                                  activeSpeakingIndex == 0 ? Icons.stop_circle : Icons.volume_up,
                                ),
                                color: activeSpeakingIndex == 0 ? Colors.red : Colors.blue,
                                iconSize: 32,
                                tooltip: activeSpeakingIndex == 0 ? loc.stopSpeaking : loc.speakPronunciation,
                                onPressed: () => onSpeak(wordStr, 0),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // 詞性與中文意思
                          Row(
                            children: [
                              if (pos.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    pos,
                                    style: TextStyle(color: Colors.grey.shade800, fontStyle: FontStyle.italic),
                                  ),
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  meaning,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                            ],
                          ),

                          const Divider(height: 32, thickness: 1),

                          // 例句區塊 (Examples)
                          if (examples.isNotEmpty) ...[
                            const Text("📝 例句 (Examples)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            ...List.generate(examples.length, (i) {
                              final ex = examples[i] as Map<String, dynamic>;
                              final String en = (ex['en'] as String?) ?? '';
                              final String zh = (ex['zh'] as String?) ?? '';
                              final idx = i + 1;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              en,
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              activeSpeakingIndex == idx ? Icons.stop_circle : Icons.volume_up,
                                              color: activeSpeakingIndex == idx ? Colors.red : Colors.blueGrey,
                                              size: 20,
                                            ),
                                            onPressed: () => onSpeak(en, idx),
                                            constraints: const BoxConstraints(),
                                            padding: EdgeInsets.zero,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(zh, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],

                          const SizedBox(height: 16),

                          // 常見搭配詞 (Collocations)
                          if (collocations.isNotEmpty) ...[
                            const Text("🔗 常見搭配 (Collocations)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: collocations.map((c) => Chip(
                                label: Text(c.toString()),
                                backgroundColor: Colors.green.shade50,
                              )).toList(),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // 同義詞/反義詞
                          if (synonymsAntonyms.isNotEmpty) ...[
                            const Text("🔄 同義詞 / 反義詞", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(synonymsAntonyms, style: const TextStyle(fontSize: 16)),
                          ],
                          
                          const SizedBox(height: 32),
                          
                          // 底部儲存按鈕
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: Icon(isSaved ? Icons.check : Icons.bookmark_add),
                              label: Text(isSaved ? '已存入單字本' : '存入單字本'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isSaved ? Colors.grey[300] : Colors.blue.shade800,
                                foregroundColor: isSaved ? Colors.grey[600] : Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: isSaved ? null : () => onSaveWord(wordStr, pos, meaning, cefr, synonymsAntonyms, collocations),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).enVocabAnalysisFailed)),
      );
    }
  }

  Future<void> _onEnSentence(BuildContext context, String inputWord) async {
    if (inputWord.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入單字！')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final results = await Future.wait([
        globalEnSentenceService.makeSentences(inputWord),
        globalEnSentenceService.makeQuiz(inputWord),
      ]);
      final sentenceResult = results[0];
      final quizResult = results[1];

      if (!context.mounted) return;
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) {
          final List<dynamic> questionsList = (quizResult['questions'] as List<dynamic>?) ?? <dynamic>[];
          List<int?> selectedOptionIndices = List.filled(questionsList.length, null);
          int activeSpeakingIndex = -1; // -1: none, 0: beginner, 1: intermediate, 2: advanced, 3: slang, 4+: quiz questions (4+qIdx)

          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> onSpeak(String text, int index) async {
                try {
                  if (activeSpeakingIndex == index) {
                    await globalEnTtsService.stop();
                    setDialogState(() => activeSpeakingIndex = -1);
                  } else {
                    if (activeSpeakingIndex != -1) {
                      await globalEnTtsService.stop();
                    }
                    setDialogState(() => activeSpeakingIndex = index);
                    String subtitle;
                    if (index == 0) {
                      subtitle = '初級例句 · $inputWord';
                    } else if (index == 1) {
                      subtitle = '中級例句 · $inputWord';
                    } else if (index == 2) {
                      subtitle = '高級例句 · $inputWord';
                    } else if (index == 3) {
                      subtitle = '口語/流行語 · $inputWord';
                    } else {
                      subtitle = '隨堂測驗 · $inputWord';
                    }
                    _addToListeningHistory(text, subtitle);
                    await globalEnTtsService.speak(text);
                    setDialogState(() => activeSpeakingIndex = -1);
                  }
                } catch (e) {
                  setDialogState(() => activeSpeakingIndex = -1);
                }
              }

              final loc = AppLocalizations.of(context);
              final Map beginnerMap = (sentenceResult['beginner'] as Map?) ?? const {};
              final Map intermediateMap = (sentenceResult['intermediate'] as Map?) ?? const {};
              final Map advancedMap = (sentenceResult['advanced'] as Map?) ?? const {};
              final Map slangMap = (sentenceResult['slang_or_spoken'] as Map?) ?? const {};
              final String beginnerEn = (beginnerMap['en'] as String?) ?? '';
              final String beginnerZh = (beginnerMap['zh'] as String?) ?? '';
              final String intermediateEn = (intermediateMap['en'] as String?) ?? '';
              final String intermediateZh = (intermediateMap['zh'] as String?) ?? '';
              final String advancedEn = (advancedMap['en'] as String?) ?? '';
              final String advancedZh = (advancedMap['zh'] as String?) ?? '';
              final String slangEn = (slangMap['en'] as String?) ?? '';
              final String slangZh = (slangMap['zh'] as String?) ?? '';

              return AlertDialog(
                title: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Text(loc.enAiSentence),
                  ],
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '例句生成',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent),
                        ),
                        const SizedBox(height: 8),
                        if (beginnerEn.isNotEmpty)
                          _buildSentenceTile(
                            '初級 (Beginner)',
                            beginnerEn,
                            beginnerZh,
                            activeSpeakingIndex == 0,
                            () => onSpeak(beginnerEn, 0),
                          ),
                        if (intermediateEn.isNotEmpty)
                          _buildSentenceTile(
                            '中級 (Intermediate)',
                            intermediateEn,
                            intermediateZh,
                            activeSpeakingIndex == 1,
                            () => onSpeak(intermediateEn, 1),
                          ),
                        if (advancedEn.isNotEmpty)
                          _buildSentenceTile(
                            '高級 (Advanced)',
                            advancedEn,
                            advancedZh,
                            activeSpeakingIndex == 2,
                            () => onSpeak(advancedEn, 2),
                          ),
                        if (slangEn.isNotEmpty)
                          _buildSentenceTile(
                            '口語/流行語 (Spoken/Slang)',
                            slangEn,
                            slangZh,
                            activeSpeakingIndex == 3,
                            () => onSpeak(slangEn, 3),
                          ),
                        if (questionsList.isNotEmpty) ...[
                          const Divider(height: 32),
                          const Text(
                            '隨堂測驗 (Mini Quiz)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orangeAccent),
                          ),
                          const SizedBox(height: 12),
                          Column(
                            children: List.generate(questionsList.length, (qIdx) {
                              final q = questionsList[qIdx] as Map<String, dynamic>;
                              final String quizQuestion = (q['question'] as String?) ?? '';
                              final List<dynamic> quizOptions = (q['options'] as List<dynamic>?) ?? <dynamic>[];
                              final int quizCorrectIndex = (q['correct_answer_index'] as int?) ?? 0;
                              final String quizExplanation = (q['explanation'] as String?) ?? '';
                              final selectedOptionIndex = selectedOptionIndices[qIdx];
                              final hasAnswered = selectedOptionIndex != null;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '題目 ${qIdx + 1}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blueGrey),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            quizQuestion,
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            activeSpeakingIndex == 4 + qIdx ? Icons.stop_circle : Icons.volume_up,
                                            color: activeSpeakingIndex == 4 + qIdx ? Colors.red : Colors.blueGrey,
                                            size: 20,
                                          ),
                                          onPressed: () => onSpeak(quizQuestion, 4 + qIdx),
                                          constraints: const BoxConstraints(),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Column(
                                      children: List.generate(quizOptions.length, (optIdx) {
                                        final optionText = quizOptions[optIdx].toString();
                                        final isSelected = selectedOptionIndex == optIdx;
                                        final isCorrectOption = optIdx == quizCorrectIndex;

                                        Color? buttonBgColor;
                                        Color? buttonTextColor;
                                        BorderSide? borderSide;

                                        if (hasAnswered) {
                                          if (isCorrectOption) {
                                            buttonBgColor = Colors.green[100];
                                            buttonTextColor = Colors.green[900];
                                            borderSide = BorderSide(color: Colors.green[400]!, width: 2);
                                          } else if (isSelected) {
                                            buttonBgColor = Colors.red[100];
                                            buttonTextColor = Colors.red[900];
                                            borderSide = BorderSide(color: Colors.red[400]!, width: 2);
                                          } else {
                                            buttonBgColor = Colors.grey[50];
                                            buttonTextColor = Colors.grey[500];
                                            borderSide = BorderSide(color: Colors.grey[300]!);
                                          }
                                        } else {
                                          buttonBgColor = Colors.grey[50];
                                          buttonTextColor = Colors.blueGrey[800];
                                          borderSide = BorderSide(color: Colors.grey[300]!);
                                        }

                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 6.0),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                backgroundColor: buttonBgColor,
                                                foregroundColor: buttonTextColor,
                                                side: borderSide,
                                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                                alignment: Alignment.centerLeft,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              onPressed: hasAnswered
                                                  ? null
                                                  : () {
                                                      setDialogState(() {
                                                        selectedOptionIndices[qIdx] = optIdx;
                                                      });
                                                    },
                                              child: Text(
                                                optionText,
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                    if (hasAnswered) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.orange[50],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.orange[200]!),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  selectedOptionIndex == quizCorrectIndex
                                                      ? Icons.check_circle
                                                      : Icons.cancel,
                                                  color: selectedOptionIndex == quizCorrectIndex
                                                      ? Colors.green
                                                      : Colors.red,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  selectedOptionIndex == quizCorrectIndex ? '答對了！' : '答錯了，再接再厲！',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              quizExplanation,
                                              style: const TextStyle(fontSize: 13, height: 1.4),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      if (activeSpeakingIndex != -1) {
                        globalEnTtsService.stop();
                      }
                      Navigator.pop(context);
                    },
                    child: Text(loc.close),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).enSentenceGenerationFailed)),
      );
    }
  }

  // Helper widgets for structured details
  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSentenceTile(
    String label,
    String sentence,
    String translation,
    bool isSpeaking,
    VoidCallback onSpeak,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, fontSize: 13),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    isSpeaking ? Icons.stop_circle : Icons.volume_up,
                    color: isSpeaking ? Colors.red : Colors.blueGrey,
                    size: 18,
                  ),
                  onPressed: onSpeak,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              sentence,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              translation,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListeningHistoryCard(BuildContext context) {
    final history = globalStore.chunks
        .where((c) => c.collectionName == 'ListeningHistory')
        .toList();
    history.sort((a, b) {
      final String tA = (a.metadata['timestamp'] as String?) ?? '';
      final String tB = (b.metadata['timestamp'] as String?) ?? '';
      return tB.compareTo(tA);
    });

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '聽力歷史紀錄 (Listening History)',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                ),
                if (history.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.delete_sweep, size: 18),
                    label: const Text('清除'),
                    onPressed: () async {
                      await globalStore.clear(null, 'ListeningHistory');
                      setState(() {});
                    },
                  ),
              ],
            ),
            const Divider(),
            if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    '尚無聽力紀錄，請在上方點擊語音播放！',
                    style: TextStyle(color: Colors.grey[500], fontSize: 15),
                  ),
                ),
              )
            else
              StatefulBuilder(
                builder: (context, setHistoryState) {
                  int activeSpeakingIndex = -1;
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final String text = (item.metadata['text'] as String?) ?? '';
                      final String subtitle = (item.metadata['subtitle'] as String?) ?? '';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          text,
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                        ),
                        subtitle: Text(
                          subtitle,
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            activeSpeakingIndex == index ? Icons.stop_circle : Icons.volume_up,
                            color: activeSpeakingIndex == index ? Colors.red : Colors.blueAccent,
                          ),
                          onPressed: () async {
                            try {
                              if (activeSpeakingIndex == index) {
                                await globalEnTtsService.stop();
                                setHistoryState(() => activeSpeakingIndex = -1);
                              } else {
                                if (activeSpeakingIndex != -1) {
                                  await globalEnTtsService.stop();
                                }
                                setHistoryState(() => activeSpeakingIndex = index);
                                await globalEnTtsService.speak(text);
                                setHistoryState(() => activeSpeakingIndex = -1);
                              }
                            } catch (e) {
                              setHistoryState(() => activeSpeakingIndex = -1);
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // Builder for Japanese Learning Tab
  Widget _buildJapaneseTab(BuildContext context, AppLocalizations loc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    loc.grammarAnalysis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: loc.inputSentenceHint,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _controller.clear(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AiButton(
                    label: loc.grammarAnalysis,
                    icon: Icons.language,
                    onPressed: () => _onGrammar(context, _controller.text),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    loc.vocabAnalysis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _vocabController,
                    maxLines: 1,
                    decoration: InputDecoration(
                      hintText: loc.inputWordHint,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _vocabController.clear(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AiButton(
                    label: loc.vocabAnalysis,
                    icon: Icons.spellcheck,
                    onPressed: () => _onVocab(context, _vocabController.text),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    loc.sentenceGeneration,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _sentenceController,
                    maxLines: 1,
                    decoration: InputDecoration(
                      hintText: loc.inputSentenceWordHint,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _sentenceController.clear(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AiButton(
                    label: loc.sentenceGeneration,
                    icon: Icons.chat_bubble_outline,
                    onPressed: () => _onSentence(context, _sentenceController.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onStartLesson(BuildContext context, String topic) async {
    if (topic.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入課堂主題！')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final results = await Future.wait([
        globalEnGrammarLessonService.generateLesson(topic),
        globalEnVocabLessonService.generateVocabSet(topic),
        globalEnQuizService.generateQuiz(topic),
      ]);

      if (!context.mounted) return;
      Navigator.pop(context); // dismiss loading

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LessonScreen(
            topic: topic,
            grammarLesson: results[0],
            vocabLesson: results[1],
            quiz: results[2],
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('生成課堂失敗，請稍後再試：$e')),
      );
    }
  }

  // Builder for English Learning Tab
  Widget _buildEnglishTab(BuildContext context, AppLocalizations loc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'AI 英文課堂 (AI English Classroom)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _enLessonController,
                    maxLines: 1,
                    decoration: InputDecoration(
                      hintText: '請輸入課堂主題（例如 Restaurant English）...',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _enLessonController.clear(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AiButton(
                    label: '開始課堂',
                    icon: Icons.school,
                    onPressed: () => _onStartLesson(context, _enLessonController.text),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    loc.enGrammarAnalysis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _enGrammarController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: loc.enInputSentenceHint,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _enGrammarController.clear(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AiButton(
                    label: loc.enGrammarAnalysis,
                    icon: Icons.language,
                    onPressed: () => _onEnGrammar(context, _enGrammarController.text),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    loc.enVocabAnalysis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[700],
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _enVocabController,
                    maxLines: 1,
                    decoration: InputDecoration(
                      hintText: loc.enInputWordHint,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _enVocabController.clear(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AiButton(
                    label: loc.enVocabAnalysis,
                    icon: Icons.spellcheck,
                    onPressed: () => _onEnVocab(context, _enVocabController.text),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    loc.enSentenceGeneration,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _enSentenceController,
                    maxLines: 1,
                    decoration: InputDecoration(
                      hintText: loc.enInputSentenceWordHint,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _enSentenceController.clear(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AiButton(
                    label: loc.enSentenceGeneration,
                    icon: Icons.chat_bubble_outline,
                    onPressed: () => _onEnSentence(context, _enSentenceController.text),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildListeningHistoryCard(context),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _vocabController.dispose();
    _sentenceController.dispose();
    _enGrammarController.dispose();
    _enVocabController.dispose();
    _enSentenceController.dispose();
    _enLessonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.learningHub),
          bottom: TabBar(
            tabs: [
              Tab(text: loc.japaneseLab),
              Tab(text: loc.englishLab),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildJapaneseTab(context, loc),
            _buildEnglishTab(context, loc),
          ],
        ),
      ),
    );
  }
}


