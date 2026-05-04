

import 'dart:math';

import '../models/skill_card.dart';
import 'embedding_service.dart';
import 'vector_store.dart';

class SkillsService {
  static const String collectionName = 'skills';

  final VectorStore _store;
  final EmbeddingService _embedder;
  SkillsService({
    required VectorStore store,
    required EmbeddingService embedder,
  })  : _store = store,
        _embedder = embedder;

  /// Saves a new skill or updates an existing one.
  Future<void> saveSkill(SkillCard card) async {
    final embedding = await _embedder.embed(card.query);
    final doc = DocChunk(
      id: card.id,
      docName: 'skill_${card.id}',
      chunkIndex: 0,
      text: card.query,
      embedding: embedding,
      collectionName: collectionName,
      metadata: card.toMap(),
    );
    
    // In our VectorStore, adding a document with an existing ID doesn't automatically replace it unless we delete first.
    await _store.deleteById(card.id);
    await _store.add(doc);
  }

  /// Extracts and saves a skill automatically.
  Future<SkillCard> extractAndSaveSkill({
    required String query,
    required String answer,
    String reasoningPath = '',
    String domain = 'general',
  }) async {
    final rand = Random().nextInt(1000000);
    final card = SkillCard(
      id: 'skill_${DateTime.now().microsecondsSinceEpoch}_$rand',
      query: query,
      reasoningPath: reasoningPath,
      answer: answer,
      domain: domain,
      createdAt: DateTime.now(),
    );
    await saveSkill(card);
    return card;
  }

  /// Retrieves skills that are semantically similar to the [query].
  Future<List<SkillCard>> getRelevantSkills(
    String query, {
    int topK = 3,
    double threshold = 0.82,
    List<double>? precomputedEmbedding,
  }) async {
    final embedding = precomputedEmbedding ?? await _embedder.embed(query);
    
    final candidates = _store.searchInCollection(
      collectionName,
      embedding,
      topK: topK * 2, // Fetch more to allow threshold filtering
    );

    final results = <SkillCard>[];
    for (final hit in candidates) {
      if (hit.score >= threshold) {
        try {
          results.add(SkillCard.fromMap(hit.chunk.metadata));
          if (results.length >= topK) break;
        } catch (e) {
          // Ignore malformed skill cards
        }
      }
    }
    return results;
  }

  /// Retrieves all stored skills.
  List<SkillCard> getAllSkills() {
    final chunks = _store.chunksInCollection(collectionName);
    return chunks.map((c) {
      try {
        return SkillCard.fromMap(c.metadata);
      } catch (e) {
        return null;
      }
    }).whereType<SkillCard>().toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Updates the success count of a skill. If delta makes it <= 0, deletes the skill.
  Future<void> updateSuccessCount(String id, int delta) async {
    final chunks = _store.chunksInCollection(collectionName);
    final target = chunks.where((c) => c.id == id).firstOrNull;
    if (target != null) {
      try {
        final card = SkillCard.fromMap(target.metadata);
        final newCount = card.successCount + delta;
        if (newCount <= 0) {
          await deleteSkill(id);
        } else {
          final updatedCard = card.copyWith(successCount: newCount);
          await saveSkill(updatedCard);
        }
      } catch (e) {
        // Ignore
      }
    }
  }

  /// Increments the success count of a skill, indicating user satisfaction or repeated use.
  Future<void> incrementSuccessCount(String id) async {
    await updateSuccessCount(id, 1);
  }

  Future<void> deleteSkill(String id) async {
    await _store.deleteById(id);
  }
}
