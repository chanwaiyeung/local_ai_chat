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

import '../models/contact.dart';
import '../models/expense.dart';
import '../models/health_record.dart';
import '../models/wealth_record.dart';
import 'embedding_service.dart';
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
    this.llmComplete,
    this.llmCompleteStream,
    this.collections = const [
      kExpensesCollection,
      kContactsCollection,
      kHealthCollection,
      kWealthCollection,
    ],
    String? defaultSystemPrompt,
  }) : defaultSystemPrompt = defaultSystemPrompt ?? _defaultSystemPromptText;

  /// Default Personal Hub collection names. Aligned with the constants used
  /// by ExpenseController / ContactController.
  static const String kExpensesCollection = 'Expenses';
  static const String kContactsCollection = 'Contacts';
  static const String kHealthCollection = 'Health';
  static const String kWealthCollection = 'Wealth';

  final EmbeddingService embedder;
  final VectorStore store;

  /// Optional: required for [answer] / [answerStream]. Retrieval-only callers
  /// can leave this null.
  final LlmCompletion? llmComplete;
  final LlmCompletionStream? llmCompleteStream;

  /// Collections this service searches by default. Defaults to
  /// Expenses + Contacts; callers can pass an override per call.
  final List<String> collections;

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
    if (embeddings.length != chunks.length) {
      _debugLog(
        '[PersonalRagService] embedAll returned ${embeddings.length} results '
        'for ${chunks.length} inputs in collection $collectionName. '
        'Skipping collection reindex.',
      );
      return 0;
    }
    assert(
      embeddings.length == chunks.length,
      'embedAll length mismatch: got ${embeddings.length}, '
      'expected ${chunks.length}',
    );

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
      if (embeddings.length != missingChunks.length) {
        _debugLog(
          '[PersonalRagService] embedAll returned ${embeddings.length} results '
          'for ${missingChunks.length} inputs in collection $col. '
          'Skipping batch.',
        );
        continue;
      }
      assert(
        embeddings.length == missingChunks.length,
        'embedAll length mismatch: got ${embeddings.length}, '
        'expected ${missingChunks.length}',
      );

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

  /// Decode a Personal Hub chunk's text into a search-friendly representation
  /// that the embedder will index well. Returns the chunk's own text when the
  /// chunk has no parseable JSON (e.g. Wealth records store toRagString —
  /// already searchable).
  static String extractSearchTextForTest(DocChunk c) => _extractSearchText(c);

  static void _debugLog(String message) {
    // Keep this service usable from pure Dart CLIs such as bin/telegram_bot.dart.
    // ignore: avoid_print
    print(message);
  }

  static String _extractSearchText(DocChunk c) {
    // Metadata-first path. Newer Personal Hub modules store structured JSON in
    // metadata['data'] while keeping chunk.text as the already searchable text.
    // Prefer the structured payload when available so re-embedding stays stable
    // if display text changes.
    final type = c.metadata['type']?.toString().toLowerCase();
    final data = c.metadata['data'];
    try {
      switch (type) {
        case 'personal_hub_expense':
        case 'expense':
        case 'expenses':
          if (data is Map) {
            return Expense.fromJson(Map<String, dynamic>.from(data))
                .toSearchText();
          }
          break;
        case 'personal_hub_contact':
        case 'contact':
        case 'contacts':
          if (data is Map) {
            return Contact.fromJson(Map<String, dynamic>.from(data))
                .toSearchText();
          }
          return Contact.fromJson(c.metadata).toSearchText();
        case 'personal_hub_health':
        case 'health':
        case 'healthrecord':
          if (data is Map) {
            return HealthRecord.fromJson(Map<String, dynamic>.from(data))
                .toSearchText();
          }
          break;
        case 'personal_hub_wealth':
        case 'wealth':
          if (data is Map) {
            return WealthRecord.fromJson(Map<String, dynamic>.from(data))
                .toSearchText();
          }
          // Wealth chunks usually store a rich RAG/search string in chunk.text.
          return c.text;
      }
    } catch (_) {
      // Fall through to text decoding/fallback below. This keeps one malformed
      // Personal Hub record from breaking a full collection reindex.
    }

    Map<String, dynamic>? parsed;
    try {
      final decoded = jsonDecode(c.text);
      if (decoded is Map<String, dynamic>) parsed = decoded;
    } catch (_) {
      // Not JSON — return the raw text. Expenses + Contacts already store
      // toSearchText() in chunk.text, so this is the desired output for them.
      return c.text;
    }
    if (parsed == null) return c.text;

    // HealthRecord stores its encoded JSON in chunk.text.
    try {
      final hr = HealthRecord.fromJson(parsed);
      return hr.toSearchText();
    } catch (_) {
      // not a Health record
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
    // Last resort: stringify any non-null values.
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

    final queryVec = await embedder.embed(query);

    final pooled = <ScoredChunk>[];
    for (final col in cols) {
      final hits = store.searchInCollection(
        col,
        queryVec,
        topK: perCollectionPool,
      );
      pooled.addAll(hits);
    }

    pooled.sort((a, b) => b.score.compareTo(a.score));
    final filtered =
        pooled.where((h) => h.score >= minScore).toList(growable: false);
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

    final reply = await llm(
      systemPrompt: systemPromptOverride ?? defaultSystemPrompt,
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

    yield* stream(
      systemPrompt: systemPromptOverride ?? defaultSystemPrompt,
      userPrompt: _buildUserPrompt(query, hits),
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
參考資料來自他們本機的開支(Expenses)、名片(Contacts)、健康(Health)、投資(Wealth)紀錄；
每筆已標註 collectionName 與 score。
規則：
1. 只回答能從參考資料中推導的內容；無法推導時直接說「資料不足」並說明缺什麼。
2. 引用時用括號註明來源序號，例如「(1)」「(2)」。
3. 用繁體中文，簡潔，不要重複參考資料原文。
4. 涉及金額時保留原始幣別，不自動換算。
5. 涉及健康指標(體重/血壓/心率)時保留原始單位。
6. 涉及投資淨值時，最新日期那筆即代表現值，較舊日期的紀錄不要當「另一筆資產」相加。
''';
}
