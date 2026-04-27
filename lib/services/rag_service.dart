// lib/services/rag_service.dart
import 'dart:math' as math;

import 'embedding_service.dart';
import 'vector_store.dart';

class RagService {
  final EmbeddingService embedder;
  final VectorStore store;

  RagService({required this.embedder, required this.store});

  /// 智能切塊：依段落 / 句子分隔，再合併成接近 [maxChars] 嘅塊，
  /// 相鄰塊之間有 [overlap] 字元重疊，保留上下文。
  static List<String> chunk(
    String text, {
    int maxChars = 800,
    int overlap = 120,
  }) {
    final clean = text.replaceAll('\r', '').trim();
    if (clean.isEmpty) return [];

    // 先按空行（段落）切，再按句號 / 問號 / 驚嘆號切細段
    final paras = clean.split(RegExp(r'\n\s*\n'));
    final segments = <String>[];
    for (final p in paras) {
      final sents = p.split(RegExp(r'(?<=[。！？.!?])\s+|(?<=[。！？])(?=\S)'));
      segments.addAll(sents.where((s) => s.trim().isNotEmpty));
    }

    final chunks = <String>[];
    final buf = StringBuffer();
    for (final seg in segments) {
      if (buf.length + seg.length + 1 > maxChars && buf.isNotEmpty) {
        chunks.add(buf.toString().trim());
        // 留 overlap 部分作為下一塊嘅開頭
        final tail = buf.toString();
        final start = tail.length > overlap ? tail.length - overlap : 0;
        buf
          ..clear()
          ..write(tail.substring(start))
          ..write(' ');
      }
      buf
        ..write(seg.trim())
        ..write(' ');
    }
    if (buf.toString().trim().isNotEmpty) chunks.add(buf.toString().trim());
    return chunks;
  }

  /// 將文件加入向量庫
  Future<int> ingest({
    required String docName,
    required String text,
    int maxChars = 800,
    int overlap = 120,
    void Function(int done, int total)? onProgress,
  }) async {
    // 同名文件先剷走
    store.removeDoc(docName);

    final pieces = chunk(text, maxChars: maxChars, overlap: overlap);
    for (var i = 0; i < pieces.length; i++) {
      final emb = await embedder.embed(pieces[i]);
      store.add(DocChunk(
        id: '${docName}_$i',
        docName: docName,
        chunkIndex: i,
        text: pieces[i],
        embedding: emb,
      ));
      onProgress?.call(i + 1, pieces.length);
    }
    await store.save();
    return pieces.length;
  }

  /// 為一條查詢取相關段落
  Future<List<ScoredChunk>> retrieve(
    String query, {
    int k = 4,
    String? docName,
    double minScore = 0.0,
  }) async {
    if (store.length == 0) return [];
    final qv = await embedder.embed(query);
    final candidateK = math.max(k, math.min(store.length, k * 4));
    final queryKeywords = keywords(query);
    final candidates = store
        .topK(qv, k: candidateK, docName: docName)
        .where((s) => s.score >= minScore)
        .toList();

    candidates.sort((a, b) {
      final boostedA = a.score + _keywordBoost(queryKeywords, a.chunk.text);
      final boostedB = b.score + _keywordBoost(queryKeywords, b.chunk.text);
      return boostedB.compareTo(boostedA);
    });

    return candidates.take(k).toList();
  }

  /// 粗略確認檢索結果至少有一個實詞對得上問題，避免低質量
  /// embedding 將完全無關片段送入模型後誘發幻覺。
  static bool hasKeywordGrounding(String query, List<ScoredChunk> hits) {
    if (hits.isEmpty) return false;
    final queryKeywords = keywords(query);
    if (queryKeywords.isEmpty) return true;

    return hits.any((hit) {
      final chunkKeywords = keywords(hit.chunk.text);
      final overlap = chunkKeywords.intersection(queryKeywords);
      if (overlap.isNotEmpty) return true;

      final queryAliases = expandedKeywords(queryKeywords);
      final chunkAliases = expandedKeywords(chunkKeywords);
      return chunkAliases.intersection(queryAliases).isNotEmpty;
    });
  }

  static double _keywordBoost(Set<String> queryKeywords, String text) {
    if (queryKeywords.isEmpty) return 0;
    final queryAliases = expandedKeywords(queryKeywords);
    final chunkAliases = expandedKeywords(keywords(text));
    final overlap = chunkAliases.intersection(queryAliases).length;
    return math.min(overlap, 4) * 0.04;
  }

  static Set<String> keywords(String text) {
    final stopwords = {
      'a',
      'an',
      'and',
      'any',
      'are',
      'about',
      'according',
      'doc',
      'document',
      'does',
      'do',
      'did',
      'file',
      'for',
      'from',
      'has',
      'have',
      'in',
      'is',
      'it',
      'loaded',
      'me',
      'mention',
      'mentioned',
      'of',
      'on',
      'or',
      'pdf',
      'please',
      'tell',
      'that',
      'the',
      'there',
      'this',
      'to',
      'what',
      'where',
      'which',
      'who',
      'why',
      'with',
      '中',
      '有',
      '沒有',
      '文件',
      '是否',
      '的',
      '是',
      '請',
      '問',
    };

    final out = <String>{};
    final matches = RegExp(r'[A-Za-z0-9]+|[一-龥]+').allMatches(
      text.toLowerCase(),
    );

    for (final match in matches) {
      final token = match.group(0) ?? '';
      if (token.isEmpty || stopwords.contains(token)) continue;

      final isLatin = RegExp(r'^[a-z0-9]+$').hasMatch(token);
      if (isLatin) {
        if (token.length >= 3 || RegExp(r'\d').hasMatch(token)) {
          out.add(token);
        }
        continue;
      }

      if (token.length <= 2) {
        out.add(token);
      } else {
        for (var size = 2; size <= 3; size++) {
          for (var i = 0; i <= token.length - size; i++) {
            final gram = token.substring(i, i + size);
            if (!stopwords.contains(gram)) out.add(gram);
          }
        }
      }
    }

    return out;
  }

  static Set<String> expandedKeywords(Set<String> terms) {
    final out = <String>{...terms};
    const groups = [
      {'deadline', 'due', 'date', 'schedule', '期限', '截止', '日期'},
      {
        'risk',
        'danger',
        'issue',
        'problem',
        'limitation',
        'limit',
        '風險',
        '問題',
        '限制'
      },
      {
        'mitigation',
        'mitigate',
        'solution',
        'fix',
        'workaround',
        'remedy',
        '緩解',
        '解決',
        '方案',
        '處理'
      },
      {'owner', 'responsible', 'lead', '負責', '擁有人', '負責人'},
      {'budget', 'cost', 'price', 'spend', 'expense', '預算', '成本', '費用'},
      {'security', 'safe', 'safety', 'secure', '安全'},
      {'feature', 'function', 'capability', '功能', '能力'},
    ];

    for (final group in groups) {
      if (terms.intersection(group).isNotEmpty) {
        out.addAll(group);
      }
    }

    return out;
  }

  /// 將檢索結果格式化成 system prompt
  static String buildContext(List<ScoredChunk> hits) {
    if (hits.isEmpty) return '';
    final sb = StringBuffer()
      ..writeln('以下係從用戶上載文件中檢索到嘅相關段落，請優先根據呢啲資料作答。')
      ..writeln('只可根據以下段落回答文件相關問題；如果段落唔夠資料答問題，請直接講「在文件中沒有找到相關資訊」，不要猜測或編造。')
      ..writeln();
    for (var i = 0; i < hits.length; i++) {
      final h = hits[i];
      sb
        ..writeln(
            '--- 片段 ${i + 1}（來源：${h.chunk.docName}，相似度 ${h.score.toStringAsFixed(2)}）---')
        ..writeln(h.chunk.text)
        ..writeln();
    }
    return sb.toString();
  }
}
