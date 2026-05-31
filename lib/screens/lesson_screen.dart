import 'package:flutter/material.dart';

import '../main.dart';
import '../services/vector_store.dart';

class LessonScreen extends StatefulWidget {
  final String topic;
  final Map<String, dynamic> grammarLesson;
  final Map<String, dynamic> vocabLesson;
  final Map<String, dynamic> quiz;

  const LessonScreen({
    super.key,
    required this.topic,
    required this.grammarLesson,
    required this.vocabLesson,
    required this.quiz,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  String? activeSpeakingId;
  final Set<String> savedWordIndices = {};
  late List<int?> selectedOptionIndices;

  @override
  void initState() {
    super.initState();
    final List<dynamic> questions = (widget.quiz['questions'] as List<dynamic>?) ?? <dynamic>[];
    selectedOptionIndices = List.filled(questions.length, null);
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
    } catch (e) {
      debugPrint('Failed to save to listening history: $e');
    }
  }

  Future<void> _onSpeak(String text, String id, String subtitle) async {
    try {
      if (activeSpeakingId == id) {
        await globalEnTtsService.stop();
        if (mounted) {
          setState(() {
            activeSpeakingId = null;
          });
        }
      } else {
        if (activeSpeakingId != null) {
          await globalEnTtsService.stop();
        }
        if (mounted) {
          setState(() {
            activeSpeakingId = id;
          });
        }
        await _addToListeningHistory(text, subtitle);
        await globalEnTtsService.speak(text);
        if (mounted) {
          setState(() {
            activeSpeakingId = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          activeSpeakingId = null;
        });
      }
    }
  }

  Future<void> _onSaveWord(int index, String w, String p, String m, List<dynamic> syns, List<dynamic> ants) async {
    try {
      final sa = '同義詞: ${syns.join(', ')} / 反義詞: ${ants.join(', ')}';
      final chunk = DocChunk(
        collectionName: 'Vocabulary',
        docName: w,
        chunkIndex: 0,
        text: '$w ($p) - $m',
        metadata: {
          'word': w,
          'part_of_speech': p,
          'meaning': m,
          'cefr_level': '',
          'synonyms_antonyms': sa,
          'collocations': <dynamic>[],
          'savedAt': DateTime.now().toIso8601String(),
        },
      );
      await globalStore.addToCollection('Vocabulary', chunk);
      setState(() {
        savedWordIndices.add(w);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已存入單字本！')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('儲存失敗: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    if (activeSpeakingId != null) {
      globalEnTtsService.stop();
    }
    super.dispose();
  }

  Widget _buildGrammarTab(BuildContext context) {
    final String explanation = (widget.grammarLesson['explanation'] as String?) ?? '';
    final List<dynamic> examples = (widget.grammarLesson['examples'] as List<dynamic>?) ?? <dynamic>[];
    final String commonMistakes = (widget.grammarLesson['common_mistakes'] as String?) ?? '';
    final List<dynamic> ttsSentences = (widget.grammarLesson['tts_sentences'] as List<dynamic>?) ?? <dynamic>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.menu_book, color: Colors.blue.shade800),
                      const SizedBox(width: 8),
                      Text(
                        '文法要點說明',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Text(
                    explanation,
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (examples.isNotEmpty) ...[
            Text(
              '📝 實用文法例句',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Column(
              children: List.generate(examples.length, (i) {
                final ex = examples[i] as Map<String, dynamic>;
                final String en = (ex['en'] as String?) ?? '';
                final String zh = (ex['zh'] as String?) ?? '';
                final id = 'grammar_ex_$i';
                final isSpeaking = activeSpeakingId == id;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                en,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.4),
                              ),
                            ),
                            IconButton(
                              icon: Icon(isSpeaking ? Icons.stop_circle : Icons.volume_up),
                              color: isSpeaking ? Colors.red : Colors.blue,
                              onPressed: () => _onSpeak(en, id, '文法例句 · ${widget.topic}'),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          zh,
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
          ],
          if (commonMistakes.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                      SizedBox(width: 8),
                      Text(
                        '💡 常見錯誤與提示',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    commonMistakes,
                    style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey.shade800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (ttsSentences.isNotEmpty) ...[
            Text(
              '🗣️ 朗讀口說練習',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Column(
              children: List.generate(ttsSentences.length, (i) {
                final sentence = ttsSentences[i].toString();
                final id = 'grammar_tts_$i';
                final isSpeaking = activeSpeakingId == id;

                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(
                      sentence,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    trailing: IconButton(
                      icon: Icon(isSpeaking ? Icons.stop_circle : Icons.volume_up),
                      color: isSpeaking ? Colors.red : Colors.blueAccent,
                      onPressed: () => _onSpeak(sentence, id, '口說練習 · ${widget.topic}'),
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVocabTab(BuildContext context) {
    final List<dynamic> vocabulary = (widget.vocabLesson['vocabulary'] as List<dynamic>?) ?? <dynamic>[];

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: vocabulary.length,
      itemBuilder: (context, i) {
        final item = vocabulary[i] as Map<String, dynamic>;
        final String word = (item['word'] as String?) ?? '';
        final String pos = (item['part_of_speech'] as String?) ?? '';
        final String meaning = (item['meaning'] as String?) ?? '';
        final Map example = (item['example'] as Map?) ?? const {};
        final String exEn = (example['en'] as String?) ?? '';
        final String exZh = (example['zh'] as String?) ?? '';
        final List<dynamic> syns = (item['synonyms'] as List<dynamic>?) ?? <dynamic>[];
        final List<dynamic> ants = (item['antonyms'] as List<dynamic>?) ?? <dynamic>[];
        
        final wordId = 'vocab_word_$i';
        final exId = 'vocab_ex_$i';
        final isWordSpeaking = activeSpeakingId == wordId;
        final isExSpeaking = activeSpeakingId == exId;
        final isSaved = savedWordIndices.contains(word);

        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            word,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                          ),
                          const SizedBox(width: 8),
                          if (pos.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                pos,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontStyle: FontStyle.italic),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(isWordSpeaking ? Icons.stop_circle : Icons.volume_up),
                      color: isWordSpeaking ? Colors.red : Colors.blue,
                      onPressed: () => _onSpeak(word, wordId, '單字發音 · ${widget.topic}'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  meaning,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const Divider(height: 24),
                if (exEn.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                exEn,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(isExSpeaking ? Icons.stop_circle : Icons.volume_up),
                              color: isExSpeaking ? Colors.red : Colors.blueGrey,
                              iconSize: 18,
                              onPressed: () => _onSpeak(exEn, exId, '單字例句 · ${widget.topic}'),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          exZh,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (syns.isNotEmpty || ants.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...syns.map((s) => Chip(
                        label: Text('同義: $s', style: const TextStyle(fontSize: 11)),
                        backgroundColor: Colors.green.shade50,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      )),
                      ...ants.map((a) => Chip(
                        label: Text('反義: $a', style: const TextStyle(fontSize: 11)),
                        backgroundColor: Colors.purple.shade50,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isSaved ? Colors.grey[200] : Colors.white,
                      foregroundColor: isSaved ? Colors.grey[600] : Colors.blue.shade800,
                      side: BorderSide(color: isSaved ? Colors.transparent : Colors.blue.shade800),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: isSaved ? null : () => _onSaveWord(i, word, pos, meaning, syns, ants),
                    icon: Icon(isSaved ? Icons.check : Icons.bookmark_add),
                    label: Text(isSaved ? '已存入單字本' : '存入單字本'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuizTab(BuildContext context) {
    final List<dynamic> questions = (widget.quiz['questions'] as List<dynamic>?) ?? <dynamic>[];
    if (questions.isEmpty) {
      return const Center(child: Text('無測驗內容'));
    }

    int answeredCount = selectedOptionIndices.where((idx) => idx != null).length;
    int correctCount = 0;
    for (int qIdx = 0; qIdx < questions.length; qIdx++) {
      final q = questions[qIdx] as Map<String, dynamic>;
      final int correctIdx = (q['correct_answer_index'] as int?) ?? 0;
      if (selectedOptionIndices[qIdx] == correctIdx) {
        correctCount++;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...List.generate(questions.length, (qIdx) {
            final q = questions[qIdx] as Map<String, dynamic>;
            final String questionText = (q['question'] as String?) ?? '';
            final List<dynamic> options = (q['options'] as List<dynamic>?) ?? <dynamic>[];
            final int correctIdx = (q['correct_answer_index'] as int?) ?? 0;
            final String explanation = (q['explanation'] as String?) ?? '';
            final selectedIdx = selectedOptionIndices[qIdx];
            final hasAnswered = selectedIdx != null;

            final id = 'quiz_question_$qIdx';
            final isSpeaking = activeSpeakingId == id;

            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '問題 ${qIdx + 1}: $questionText',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.4),
                          ),
                        ),
                        IconButton(
                          icon: Icon(isSpeaking ? Icons.stop_circle : Icons.volume_up),
                          color: isSpeaking ? Colors.red : Colors.blueGrey,
                          onPressed: () => _onSpeak(questionText, id, '測驗題目 · ${widget.topic}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: List.generate(options.length, (oIdx) {
                        final optionText = options[oIdx].toString();
                        final isCorrectOption = oIdx == correctIdx;
                        final isSelectedOption = oIdx == selectedIdx;

                        Color? bgColor;
                        Color? textColor;
                        BorderSide? border;

                        if (hasAnswered) {
                          if (isCorrectOption) {
                            bgColor = Colors.green[50];
                            textColor = Colors.green[900];
                            border = BorderSide(color: Colors.green[400]!, width: 2);
                          } else if (isSelectedOption) {
                            bgColor = Colors.red[50];
                            textColor = Colors.red[900];
                            border = BorderSide(color: Colors.red[400]!, width: 2);
                          } else {
                            bgColor = Colors.grey[50];
                            textColor = Colors.grey[400];
                            border = BorderSide(color: Colors.grey[200]!);
                          }
                        } else {
                          bgColor = Colors.white;
                          textColor = Colors.blueGrey[800];
                          border = BorderSide(color: Colors.grey[300]!);
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: bgColor,
                                foregroundColor: textColor,
                                side: border,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                alignment: Alignment.centerLeft,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: hasAnswered
                                  ? null
                                  : () {
                                      setState(() {
                                        selectedOptionIndices[qIdx] = oIdx;
                                      });
                                    },
                              child: Text(
                                optionText,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    if (hasAnswered) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  selectedIdx == correctIdx ? Icons.check_circle : Icons.cancel,
                                  color: selectedIdx == correctIdx ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  selectedIdx == correctIdx ? '答對了！' : '答錯了，請看解析！',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              explanation,
                              style: const TextStyle(fontSize: 14, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          if (answeredCount == questions.length) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.blue.shade50,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      '🏆 課堂測驗完成！',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '答對題數: $correctCount / ${questions.length}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      correctCount == questions.length
                          ? '太棒了！您拿到了滿分！💯'
                          : '做得好！請繼續保持努力！💪',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.topic),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.class_outlined), text: '文法課堂'),
              Tab(icon: Icon(Icons.spellcheck_outlined), text: '核心單字'),
              Tab(icon: Icon(Icons.quiz_outlined), text: '課堂測驗'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGrammarTab(context),
            _buildVocabTab(context),
            _buildQuizTab(context),
          ],
        ),
      ),
    );
  }
}


