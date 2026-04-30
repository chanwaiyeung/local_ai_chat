// lib/services/rag_service.dart
//
// Retrieval-Augmented Generation glue. Owns:
//   - Indexing: read a file -> chunk (with optional overlap) -> embed -> store
//   - Retrieval: embed query -> cosine search (or MMR re-rank) -> top-K
//
// Public types (Chunk, ScoredChunk, RagService.retrieve) match the previous
// stub, so api_server.dart and the mobile API client need no changes.

import 'dart:io';

import 'package:path/path.dart' as p;

import 'document_loader.dart';
import 'embedding_service.dart';
import 'text_chunker.dart';
import 'vector_store.dart';

/// Re-export so callers don't need a separate import.
export 'vector_store.dart' show Chunk;

class ScoredChunk {
  ScoredChunk({required this.chunk, required this.score});

  final Chunk chunk;
  final double score;
}

class RagService {
  RagService({
    required this.embedder,
    required this.store,
    this.topK = 6,
    this.maxChunkChars = 500,
    this.chunkOverlap = 100,
    this.mmrLambda = 0.7,
    this.mmrCandidatePool = 30,
  });

  final EmbeddingService embedder;
  final VectorStore store;

  /// Final number of chunks returned to the LLM.
  final int topK;

  /// Target body size per chunk (chars).
  final int maxChunkChars;

  /// Characters of the previous chunk's tail to prepend to the next chunk.
  /// Helps when sentences / concepts straddle a chunk boundary. Set to 0
  /// to disable.
  final int chunkOverlap;

  /// Maximal Marginal Relevance balance:
  ///   1.0 → pure cosine relevance (no re-ranking, identical to old behaviour).
  ///   0.7 → leans toward relevance but penalises near-duplicate chunks.
  ///   0.0 → pure diversity (rarely useful; for ablation tests).
  /// Setting 1.0 also short-circuits past the MMR candidate-pool fetch,
  /// so it costs the same as plain `store.search()`.
  final double mmrLambda;

  /// How many cosine top-N candidates to feed into MMR before picking
  /// the final [topK]. Bigger pool = more diversity, marginally slower.
  final int mmrCandidatePool;

  /// Indexes a single document file: clears any existing chunks for the
  /// same docName, then chunks (with [chunkOverlap]), embeds, and stores.
  /// Returns the number of chunks added.
  Future<int> indexFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw FileSystemException('File not found', path);
    }
    // Dispatch by extension: .txt/.md/.epub/.pdf/.cbz/.png/... all funnel
    // to plain text via document_loader.
    final raw = await loadDocument(path);
    final docName = p.basename(path);

    await store.clear(docName);

    final chunks = TextChunker.split(
      raw,
      docName: docName,
      maxChars: maxChunkChars,
      overlap: chunkOverlap,
    );
    for (final chunk in chunks) {
      final embedding = await embedder.embed(chunk.text);
      await store.add(chunk, embedding);
    }
    return chunks.length;
  }

  /// Embeds [query], retrieves top-K via MMR (or plain cosine if
  /// [mmrLambda] >= 0.999), returns scored chunks.
  Future<List<ScoredChunk>> retrieve(
    String query, {
    String? docName,
  }) async {
    final qVec = await embedder.embed(query);
    final hits = mmrLambda >= 0.999
        ? store.search(qVec, topK: topK, docName: docName)
        : store.searchMmr(
            qVec,
            topK: topK,
            candidatePool: mmrCandidatePool,
            lambda: mmrLambda,
            docName: docName,
          );
    return hits
        .map((h) => ScoredChunk(chunk: h.chunk, score: h.score))
        .toList();
  }
}
