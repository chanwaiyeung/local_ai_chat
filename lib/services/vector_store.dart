// lib/services/vector_store.dart
//
// File-backed vector store with in-memory cosine search.
//
//   final store = VectorStore(storagePath: 'data/vectors.ndjson');
//   await store.load();                 // reads existing index, if any
//   await store.add(chunk, embedding);  // appends to disk + memory
//   final hits = store.search(qVec, topK: 6);
//
// Tests can pass storagePath: null for an in-memory-only store.
//
// Persistence format: NDJSON, one chunk + embedding per line:
//   {"docName":"a.txt","chunkIndex":0,"text":"...","embedding":[0.1,0.2,...]}
//
// Adding the same chunk multiple times duplicates it; call clear(docName)
// before re-indexing a file to avoid that.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

class Chunk {
  Chunk({
    required this.docName,
    required this.chunkIndex,
    required this.text,
  });

  final String docName;
  final int chunkIndex;
  final String text;
}

class _StoredVector {
  _StoredVector({required this.chunk, required this.embedding});
  final Chunk chunk;
  final List<double> embedding;
}

class VectorStore {
  VectorStore({this.storagePath});

  /// NDJSON path. null = in-memory only (no persistence).
  final String? storagePath;
  final List<_StoredVector> _vectors = [];

  int get totalChunks => _vectors.length;

  /// Sorted, deduplicated list of doc names currently indexed.
  List<String> get docNames {
    final s = <String>{for (final v in _vectors) v.chunk.docName};
    final l = s.toList()..sort();
    return l;
  }

  /// Returns every chunk belonging to [docName], sorted by chunkIndex.
  /// Useful for read-mode UI and the `/docs/<docName>/chunks` endpoint
  /// (so the mobile client can show the source text without re-running
  /// retrieval). Empty list if the doc isn't indexed.
  List<Chunk> chunksOf(String docName) {
    return _vectors
        .where((v) => v.chunk.docName == docName)
        .map((v) => v.chunk)
        .toList()
      ..sort((a, b) => a.chunkIndex.compareTo(b.chunkIndex));
  }

  Future<void> load() async {
    if (storagePath == null) return;
    final file = File(storagePath!);
    if (!await file.exists()) return;

    final lines = await file.readAsLines();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      try {
        final j = jsonDecode(line) as Map<String, dynamic>;
        _vectors.add(_StoredVector(
          chunk: Chunk(
            docName: j['docName'] as String,
            chunkIndex: j['chunkIndex'] as int,
            text: j['text'] as String,
          ),
          embedding: (j['embedding'] as List)
              .cast<num>()
              .map((n) => n.toDouble())
              .toList(),
        ));
      } catch (e) {
        stderr.writeln('VectorStore: skipping bad line $i: $e');
      }
    }
  }

  Future<void> add(Chunk chunk, List<double> embedding) async {
    _vectors.add(_StoredVector(chunk: chunk, embedding: embedding));
    if (storagePath == null) return;

    final file = File(storagePath!);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      '${jsonEncode({
        'docName': chunk.docName,
        'chunkIndex': chunk.chunkIndex,
        'text': chunk.text,
        'embedding': embedding,
      })}\n',
      mode: FileMode.append,
    );
  }

  /// Removes all chunks belonging to [docName] from memory and disk.
  /// Call this before re-indexing a file to avoid duplicate entries.
  Future<void> clear(String docName) async {
    _vectors.removeWhere((v) => v.chunk.docName == docName);
    if (storagePath == null) return;

    final dst = File(storagePath!);
    if (!await dst.exists()) return;
    final tmp = File('${storagePath!}.tmp');
    final sink = tmp.openWrite();
    try {
      for (final v in _vectors) {
        sink.writeln(jsonEncode({
          'docName': v.chunk.docName,
          'chunkIndex': v.chunk.chunkIndex,
          'text': v.chunk.text,
          'embedding': v.embedding,
        }));
      }
    } finally {
      await sink.close();
    }
    await tmp.rename(storagePath!);
  }

  /// Top-K cosine similarity search. Optionally restrict to a single doc.
  List<({Chunk chunk, double score})> search(
    List<double> query, {
    int topK = 6,
    String? docName,
  }) {
    final candidates = docName == null
        ? _vectors
        : _vectors.where((v) => v.chunk.docName == docName);
    final scored = candidates
        .map((v) =>
            (chunk: v.chunk, score: _cosine(query, v.embedding)))
        .toList();
    scored.sort((a, b) => b.score.compareTo(a.score));
    if (scored.length <= topK) return scored;
    return scored.sublist(0, topK);
  }

  /// Top-K with Maximal Marginal Relevance re-ranking. Pulls a wider
  /// [candidatePool] by cosine, then iteratively picks the chunk that
  /// maximises:
  ///
  ///     lambda * relevance(query, chunk)
  ///       - (1 - lambda) * max_redundancy(chunk, already-selected)
  ///
  /// `lambda = 1.0` is identical to [search]. `lambda = 0.0` is pure
  /// diversity (always picks the chunk most different from what's already
  /// been chosen). Default 0.7 leans toward relevance but cuts redundancy.
  ///
  /// The returned `score` is the original cosine relevance, not the MMR
  /// objective — what callers usually want to display.
  List<({Chunk chunk, double score})> searchMmr(
    List<double> query, {
    int topK = 6,
    int candidatePool = 30,
    double lambda = 0.7,
    String? docName,
  }) {
    if (lambda < 0 || lambda > 1) {
      throw ArgumentError.value(lambda, 'lambda', 'must be in [0, 1]');
    }
    if (topK <= 0) return const [];

    // 1. Build the candidate pool, keeping embeddings around for redundancy.
    final filtered = docName == null
        ? _vectors
        : _vectors.where((v) => v.chunk.docName == docName);
    final pool = filtered
        .map((v) => (
              chunk: v.chunk,
              score: _cosine(query, v.embedding),
              embedding: v.embedding,
            ))
        .toList();
    pool.sort((a, b) => b.score.compareTo(a.score));
    final trimmed = pool.length <= candidatePool
        ? pool
        : pool.sublist(0, candidatePool);

    if (trimmed.length <= topK || lambda >= 0.999) {
      return trimmed
          .take(topK)
          .map((p) => (chunk: p.chunk, score: p.score))
          .toList();
    }

    // 2. Iteratively pick the candidate that maximises the MMR objective.
    final selected =
        <({Chunk chunk, double score, List<double> embedding})>[];
    final remaining = List.of(trimmed);

    while (selected.length < topK && remaining.isNotEmpty) {
      var bestObjective = double.negativeInfinity;
      var bestIdx = 0;
      for (var i = 0; i < remaining.length; i++) {
        final cand = remaining[i];
        var maxRedundancy = 0.0;
        for (final s in selected) {
          final sim = _cosine(cand.embedding, s.embedding);
          if (sim > maxRedundancy) maxRedundancy = sim;
        }
        final objective =
            lambda * cand.score - (1 - lambda) * maxRedundancy;
        if (objective > bestObjective) {
          bestObjective = objective;
          bestIdx = i;
        }
      }
      selected.add(remaining.removeAt(bestIdx));
    }

    return selected
        .map((s) => (chunk: s.chunk, score: s.score))
        .toList();
  }
}

double _cosine(List<double> a, List<double> b) {
  if (a.length != b.length) {
    throw ArgumentError(
        'Vector dimension mismatch: ${a.length} vs ${b.length}');
  }
  var dot = 0.0;
  var normA = 0.0;
  var normB = 0.0;
  for (var i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  if (normA == 0 || normB == 0) return 0;
  return dot / (math.sqrt(normA) * math.sqrt(normB));
}
