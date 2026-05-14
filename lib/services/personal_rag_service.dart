// lib/services/personal_rag_service.dart
//
// Phase 6.3'b — Cross-collection RAG for Personal Hub data.
//
// Wires Personal Hub (Expense + Contact) to the existing EmbeddingService and
// (optionally) OllamaService:
//
//   * Indexing: re-embeds Personal Hub chunks via the project's existing
//     EmbeddingService so their cosine vectors live in the same space as
//     book chunks. Replaces the stub/dummy/empty embeddings produced by
//     ContactController and ExpenseController in earlier phases.
//
//   * Retrieval: searches the requested collections using
//     VectorStore.searchInCollection, then merges and ranks across them.
//
//   * Answer synthesis (optional): builds a context block from the top hits
//     and asks an injected LlmCompletion function (production wiring:
//     OllamaService.chat) for a natural-language reply.
//
// === Wiring (Albert: do this once at app start) ===
//
//   final ragService = PersonalRagService(
//     embedder: yourEmbeddingService,                  // existing
//     store:    yourVectorStore,                       // existing
//     llmComplete: ({required systemPrompt, required userPrompt}) =>
//       yourOllamaService.chat([
//         ChatMessage(role: 'system', content: systemPrompt),
//         ChatMessage(role: 'user',   content: userPrompt),
//       ]),
//   );
//
// === Why a function instead of OllamaService directly? ===
//
// To stay testable without depending on ChatMessage's exact shape (which lives
// in message.dart and isn't this service's concern). Tests inject a fake
// llmComplete; production passes a 2-line lambda. Both work.

import 'dart:convert';

import '../models/app_settings.dart';
import '../models/contact.dart';
import '../models/expense.dart';
import '../models/skill_card.dart';
import 'app_settings_service.dart';
import 'embedding_service.dart';
import 'query_expansion.dart';
import 'rag_service.dart';
import 'skills_service.dart';
import 'vector_store.dart';

/// System prompt and user prompt → LLM reply. Production wiring builds
/// ChatMessage list and calls OllamaService.chat. Tests inject a fake.
typedef LlmCompletion = Future<String> Function({
  required String systemPrompt,
  required String userPrompt,
});

/// Streaming variant of [LlmCompletion].
typedef LlmCompletionStream = Stream<String> Function({
  required String systemPrompt,
  required String userPrompt,
});

class PersonalRagAnswer {
  const PersonalRagAnswer({required this.text, required this.hits});
  final String text;
  final List<ScoredChunk> hits;
}

class PersonalRagService {
  PersonalRagService({
    required this.embedder,
    required this.store,
    this.skillsService,
    this.llmComplete,
    this.llmCompleteStream,
    this.collections = const [kExpensesCollection, kContactsCollection],
    this.retrievalModeOverride,
    String? defaultSystemPrompt,
  }) : defaultSystemPrompt = defaultSystemPrompt ?? _defaultSystemPromptText;

  /// Default Personal Hub collection names. Aligned with the constants used
  /// by ExpenseController / ContactController.
  static const String kExpensesCollection = 'Expenses';
  static const String kContactsCollection = 'Contacts';

  final EmbeddingService embedder;
  final VectorStore store;
  final SkillsService? skillsService;

  /// Optional: required for [answer] / [answerStream]. Retrieval-only callers
  /// can leave this null.
  final LlmCompletion? llmComplete;
  final LlmCompletionStream? llmCompleteStream;

  /// Collections this service searches by default. Defaults to
  /// Expenses + Contacts; callers can pass an override per call.
  final List<String> collections;
  final RetrievalMode? retrievalModeOverride;

  final String defaultSystemPrompt;

  // ===========================================================================
  // Indexing — replaces stub/dummy embeddings with real ones from the
  // project's EmbeddingService so cross-collection cosine ranking works.
  // ===========================================================================

  /// Re-embed every chunk in [collectionName]. Returns count re-indexed.
  /// Uses a single batched embedAll() call + a single VectorStore.save().
  Future<int> reindexCollection(String collectionName) async {
    final chunks = store.chunksInCollection(collectionName);
    if (chunks.isEmpty) return 0;

    final texts = chunks.map(_extractSearchText).toList();
    final embeddings = await embedder.embedAll(texts);

    return _replaceCollectionInPlace(collectionName, chunks, embeddings);
  }

  /// Re-embed only chunks whose embedding is missing or all-zeros (a typical
  /// fingerprint of the dummy vectors written by Phase 6.2'/6.4'). This is
  /// the cheap incremental backfill — call it on app start to handle any
  /// rows added since the last reindex without redoing finished work.
  Future<int> reindexMissingEmbeddings({
    List<String>? collectionsOverride,
  }) async {
    final cols = collectionsOverride ?? collections;
    var total = 0;
    for (final col in cols) {
      final chunks = store.chunksInCollection(col);
      final missingChunks = chunks.where(_hasMissingEmbedding).toList();
      if (missingChunks.isEmpty) continue;

      final texts = missingChunks.map(_extractSearchText).toList();
      final embeddings = await embedder.embedAll(texts);

      // Build the full updated chunk list for the collection: missing ones
      // get new embeddings, the rest stay as-is (preserving prior real
      // embeddings if any).
      final missingById = <String, List<double>>{};
      for (var i = 0; i < missingChunks.length; i++) {
        missingById[missingChunks[i].id] = embeddings[i];
      }
      final updated = chunks
          .map((c) => missingById.containsKey(c.id)
              ? _copyChunk(c, embedding: missingById[c.id])
              : c)
          .toList();

      await store.deleteCollection(col);
      store.addAll(updated);
      await store.save();

      total += missingChunks.length;
    }
    return total;
  }

  /// Re-index every default collection. Convenience wrapper.
  Future<int> reindexAll() async {
    var total = 0;
    for (final c in collections) {
      total += await reindexCollection(c);
    }
    return total;
  }

  Future<int> _replaceCollectionInPlace(
    String collectionName,
    List<DocChunk> chunks,
    List<List<double>> embeddings,
  ) async {
    assert(chunks.length == embeddings.length);
    final updated = <DocChunk>[
      for (var i = 0; i < chunks.length; i++)
        _copyChunk(chunks[i], embedding: embeddings[i]),
    ];

    // Two-step: deleteCollection (1 save) → addAll (no save) → save (1 save).
    // Total: 2 disk writes instead of 2N.
    await store.deleteCollection(collectionName);
    store.addAll(updated);
    await store.save();
    return chunks.length;
  }

  /// True if a chunk's embedding looks like the placeholder Phase 6.2'/6.4'
  /// produced (empty list or all-zero vector).
  static bool _hasMissingEmbedding(DocChunk c) {
    if (c.embedding.isEmpty) return true;
    return c.embedding.every((v) => v == 0.0);
  }

  static DocChunk _copyChunk(
    DocChunk chunk, {
    List<double>? embedding,
  }) {
    return DocChunk(
      id: chunk.id,
      docName: chunk.docName,
      chunkIndex: chunk.chunkIndex,
      text: chunk.text,
      embedding: embedding ?? chunk.embedding,
      collectionName: chunk.collectionName,
      metadata: chunk.metadata,
    );
  }

  /// Decode a Personal Hub chunk's text back into Expense/Contact form and
  /// return its toSearchText() output. Falls back to raw text if the JSON
  /// is unrecognised (defensive against future schema additions).
  static String _extractSearchText(DocChunk c) {
    Map<String, dynamic> parsed;
    try {
      final decoded = jsonDecode(c.text);
      if (decoded is! Map<String, dynamic>) return c.text;
      parsed = decoded;
    } catch (_) {
      return c.text;
    }
    try {
      return Expense.fromJson(parsed).toSearchText();
    } catch (_) {
      // not an Expense
    }
    try {
      return Contact.fromJson(parsed).toSearchText();
    } catch (_) {
      // not a Contact
    }
    // Last-resort: concatenate any string-ish values so we still produce a
    // reasonable embedding source instead of empty text.
    return parsed.values
        .where((v) => v != null)
        .map((v) => v.toString())
        .join(' ');
  }

  // ===========================================================================
  // Retrieval — cross-collection cosine search.
  // ===========================================================================

  /// Embed [query] once, search each collection independently via
  /// [VectorStore.searchInCollection], then merge by cosine score and
  /// take the top [k] overall (subject to [minScore]).
  Future<List<ScoredChunk>> retrieveAcross({
    required String query,
    List<String>? collectionsOverride,
    int k = 4,
    double minScore = 0.0,
    int perCollectionPool = 16,
  }) async {
    if (query.trim().isEmpty) return const [];
    final cols = collectionsOverride ?? collections;

    final mode = retrievalModeOverride ??
        (await AppSettingsService().load()).retrievalMode;

    final semanticHits = <ScoredChunk>[];
    if (mode != RetrievalMode.sparse) {
      final queryVec = await embedder.embed(query);
      for (final col in cols) {
        final colHits = store.searchInCollection(
          col,
          queryVec,
          topK: perCollectionPool,
        );
        semanticHits.addAll(colHits);
      }
      semanticHits.sort((a, b) => b.score.compareTo(a.score));
    }

    final keywordHits = <ScoredChunk>[];
    if (mode != RetrievalMode.dense) {
      final sparseQuery = const QueryExpansion().sparseQueryForRetrieval(
        query,
        enabled: mode == RetrievalMode.hybrid,
      );
      for (final col in cols) {
        final pool = store.chunksInCollection(col);
        final colHits =
            RagService.bm25Rank(sparseQuery, pool, k: perCollectionPool);
        keywordHits.addAll(colHits);
      }
      keywordHits.sort((a, b) => b.score.compareTo(a.score));
    }

    final finalHits = switch (mode) {
      RetrievalMode.dense => semanticHits.take(k).toList(),
      RetrievalMode.sparse => keywordHits.take(k).toList(),
      RetrievalMode.hybrid => RagService.rrfFuse(
          semanticHits: semanticHits,
          keywordHits: keywordHits,
          k: k,
        ),
    };

    final filtered =
        finalHits.where((h) => h.score >= minScore).toList(growable: false);
    return filtered.take(k).toList();
  }

  // ===========================================================================
  // Answer synthesis — retrieval + LLM completion.
  // ===========================================================================

  /// Returns a natural-language reply plus the chunks it relied on.
  /// Throws [StateError] if no [llmComplete] was injected.
  Future<PersonalRagAnswer> answer({
    required String query,
    List<String>? collectionsOverride,
    int k = 4,
    double minScore = 0.0,
    String? systemPromptOverride,
  }) async {
    final llm = llmComplete;
    if (llm == null) {
      throw StateError(
        'PersonalRagService.answer requires llmComplete to be wired '
        '(production: OllamaService.chat).',
      );
    }

    final hits = await retrieveAcross(
      query: query,
      collectionsOverride: collectionsOverride,
      k: k,
      minScore: minScore,
    );
    if (hits.isEmpty) {
      return const PersonalRagAnswer(
        text: '抱歉，找不到相關資料。',
        hits: [],
      );
    }

    String finalSystemPrompt = systemPromptOverride ?? defaultSystemPrompt;
    if (skillsService != null) {
      final skills = await skillsService!.getRelevantSkills(query);
      if (skills.isNotEmpty) {
        final skillsText = skills.map((s) {
          if (s.reasoningPath.isNotEmpty) {
            return '- 類似問題: ${s.query}\n  推理: ${s.reasoningPath}\n  回答: ${s.answer}';
          }
          return '- 類似問題: ${s.query}\n  回答: ${s.answer}';
        }).join('\n\n');

        finalSystemPrompt +=
            '\n\n【技能卡 (過去成功的經驗)】\n你應該參考以下過去你曾經正確回答過的類似問題來保持一致性：\n$skillsText';
      }
    }

    final reply = await llm(
      systemPrompt: finalSystemPrompt,
      userPrompt: _buildUserPrompt(query, hits),
    );
    return PersonalRagAnswer(text: reply, hits: hits);
  }

  /// Streaming variant. Yields the system "no data" message synchronously
  /// when there are no hits; otherwise delegates to [llmCompleteStream].
  Stream<String> answerStream({
    required String query,
    List<String>? collectionsOverride,
    int k = 4,
    double minScore = 0.0,
    String? systemPromptOverride,
  }) async* {
    final stream = llmCompleteStream;
    if (stream == null) {
      throw StateError(
        'PersonalRagService.answerStream requires llmCompleteStream to be '
        'wired (production: OllamaService.chatStream).',
      );
    }

    final hits = await retrieveAcross(
      query: query,
      collectionsOverride: collectionsOverride,
      k: k,
      minScore: minScore,
    );
    if (hits.isEmpty) {
      yield '抱歉，找不到相關資料。';
      return;
    }

    String finalSystemPrompt = systemPromptOverride ?? defaultSystemPrompt;
    if (skillsService != null) {
      final skills = await skillsService!.getRelevantSkills(query);
      if (skills.isNotEmpty) {
        final skillsText = skills.map((s) {
          if (s.reasoningPath.isNotEmpty) {
            return '- 類似問題: ${s.query}\n  推理: ${s.reasoningPath}\n  回答: ${s.answer}';
          }
          return '- 類似問題: ${s.query}\n  回答: ${s.answer}';
        }).join('\n\n');

        finalSystemPrompt +=
            '\n\n【技能卡 (過去成功的經驗)】\n你應該參考以下過去你曾經正確回答過的類似問題來保持一致性：\n$skillsText';
      }
    }

    yield* stream(
      systemPrompt: finalSystemPrompt,
      userPrompt: _buildUserPrompt(query, hits),
    );
  }

  /// Extracts and saves a skill from a successful interaction.
  Future<SkillCard> extractAndSaveSkill({
    required String query,
    required String answer,
    String reasoningPath = '',
    String domain = 'general',
  }) async {
    if (skillsService == null) {
      throw StateError(
          'PersonalRagService.extractAndSaveSkill requires skillsService.');
    }

    String finalReasoningPath = reasoningPath;
    if (finalReasoningPath.isEmpty && llmComplete != null) {
      final prompt = '''
你是一個專業的知識萃取專家。
請根據以下使用者的問題與 AI 的回答，萃取出一段「思考路徑 (Reasoning Path)」。
這段路徑將作為未來回答類似問題時的指導原則。
請使用繁體中文，格式需結構化，包含：
1. 關鍵洞見 (Key Insight)
2. 適用情境 (Context)
3. 解決策略/步驟 (Strategy)
保持簡明扼要。
''';
      try {
        finalReasoningPath = await llmComplete!(
          systemPrompt: prompt,
          userPrompt: '問題：$query\n回答：$answer',
        );
      } catch (e) {
        // Fallback to empty if reflection fails
      }
    }

    return skillsService!.extractAndSaveSkill(
      query: query,
      answer: answer,
      reasoningPath: finalReasoningPath,
      domain: domain,
    );
  }

  static String _buildUserPrompt(String query, List<ScoredChunk> hits) {
    final buf = StringBuffer()
      ..writeln('使用者問題：$query')
      ..writeln()
      ..writeln('參考資料（依相關度排序）：');
    for (var i = 0; i < hits.length; i++) {
      final h = hits[i];
      buf.writeln(
        '[${i + 1}] (${h.chunk.collectionName}, score=${h.score.toStringAsFixed(3)}) '
        '${h.chunk.text}',
      );
    }
    buf
      ..writeln()
      ..writeln('請依參考資料回答；資料不足時直接說明，勿臆測。');
    return buf.toString();
  }

  static const String _defaultSystemPromptText = '''
你是 Personal Hub 的 AI 助理。使用者會給你一個問題與一組參考資料；
參考資料來自他們本機的開支與名片紀錄（每筆已標註 collectionName）。
規則：
1. 只回答能從參考資料中推導的內容；無法推導時直接說「資料不足」並說明缺什麼。
2. 引用時用括號註明來源序號，例如「(1)」「(2)」。
3. 用繁體中文，簡潔，不要重複參考資料原文。
4. 涉及金額時保留原始幣別，不自動換算。
''';
}
