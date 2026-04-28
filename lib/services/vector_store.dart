// lib/services/vector_store.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';

import 'debug_log_service.dart';

/// 一段被切碎並向量化嘅文字片段
class DocChunk {
  final String id;
  final String docName;
  final int chunkIndex;
  final String text;
  final List<double> embedding;

  DocChunk({
    required this.id,
    required this.docName,
    required this.chunkIndex,
    required this.text,
    required this.embedding,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'docName': docName,
        'chunkIndex': chunkIndex,
        'text': text,
        'embedding': embedding,
      };

  factory DocChunk.fromJson(Map<String, dynamic> j) => DocChunk(
        id: j['id'] as String,
        docName: j['docName'] as String,
        chunkIndex: j['chunkIndex'] as int,
        text: j['text'] as String,
        embedding: (j['embedding'] as List)
            .cast<num>()
            .map((e) => e.toDouble())
            .toList(),
      );
}

class ScoredChunk {
  final DocChunk chunk;
  final double score; // cosine similarity, 1.0 = 完全相同
  ScoredChunk(this.chunk, this.score);
}

class SparseIndexSnapshot {
  const SparseIndexSnapshot({
    required this.docCount,
    required this.avgDocLength,
    required this.chunkLengths,
    required this.documentFrequency,
    required this.termFrequency,
  });

  final int docCount;
  final double avgDocLength;
  final Map<String, int> chunkLengths;
  final Map<String, int> documentFrequency;
  final Map<String, Map<String, int>> termFrequency;

  Map<String, dynamic> toJson() => {
        'docCount': docCount,
        'avgDocLength': avgDocLength,
        'chunkLengths': chunkLengths,
        'documentFrequency': documentFrequency,
        'termFrequency': termFrequency,
      };

  factory SparseIndexSnapshot.fromJson(Map<String, dynamic> json) {
    return SparseIndexSnapshot(
      docCount: (json['docCount'] as num?)?.toInt() ?? 0,
      avgDocLength: (json['avgDocLength'] as num?)?.toDouble() ?? 0.0,
      chunkLengths: _intMap(json['chunkLengths']),
      documentFrequency: _intMap(json['documentFrequency']),
      termFrequency: (json['termFrequency'] as Map? ?? {}).map(
        (key, value) => MapEntry(
          key.toString(),
          _intMap(value),
        ),
      ),
    );
  }

  static Map<String, int> _intMap(Object? raw) {
    return (raw as Map? ?? {}).map(
      (key, value) => MapEntry(
        key.toString(),
        (value as num?)?.toInt() ?? 0,
      ),
    );
  }
}

typedef SparseIndexBuilder = SparseIndexSnapshot Function(
    List<DocChunk> chunks);

class VectorStoreSnapshot {
  const VectorStoreSnapshot({
    required this.embeddingModel,
    required this.chunks,
    this.sparseIndex,
    this.needsSparseIndexMigration = false,
    this.migratedFromLegacy = false,
  });

  final String? embeddingModel;
  final List<DocChunk> chunks;
  final SparseIndexSnapshot? sparseIndex;
  final bool needsSparseIndexMigration;
  final bool migratedFromLegacy;
}

/// 簡單嘅 in-memory 向量庫，支援 JSON 持久化
class VectorStore {
  final List<DocChunk> _chunks = [];
  String? _embeddingModel;
  SparseIndexSnapshot? _sparseIndex;

  int get length => _chunks.length;
  String? get embeddingModel => _embeddingModel;
  SparseIndexSnapshot? get sparseIndex => _sparseIndex;
  List<String> get docNames => _chunks.map((c) => c.docName).toSet().toList();
  List<DocChunk> get chunks => List.unmodifiable(_chunks);

  void add(DocChunk c) {
    _chunks.add(c);
    _sparseIndex = null;
  }

  void addAll(Iterable<DocChunk> cs) {
    _chunks.addAll(cs);
    _sparseIndex = null;
  }

  void clear() {
    _chunks.clear();
    _embeddingModel = null;
    _sparseIndex = null;
  }

  void setEmbeddingModel(String model) {
    _embeddingModel = model;
  }

  void setSparseIndex(SparseIndexSnapshot? index) {
    _sparseIndex = index;
  }

  void removeDoc(String docName) {
    _chunks.removeWhere((c) => c.docName == docName);
    _sparseIndex = null;
  }

  Future<void> replaceDoc(
    String docName,
    Iterable<DocChunk> chunks, {
    SparseIndexSnapshot? sparseIndex,
  }) async {
    final previousChunks = List<DocChunk>.of(_chunks);
    final previousSparseIndex = _sparseIndex;
    try {
      _chunks
        ..removeWhere((c) => c.docName == docName)
        ..addAll(chunks);
      _sparseIndex = sparseIndex;
      await save();
    } catch (_) {
      _chunks
        ..clear()
        ..addAll(previousChunks);
      _sparseIndex = previousSparseIndex;
      rethrow;
    }
  }

  /// 取某份文件嘅所有片段（按 chunkIndex 排序）— 文件預覽會用到
  List<DocChunk> chunksOf(String docName) {
    final list = _chunks.where((c) => c.docName == docName).toList()
      ..sort((a, b) => a.chunkIndex.compareTo(b.chunkIndex));
    return list;
  }

  /// 取最相近嘅 k 個片段
  List<ScoredChunk> topK(List<double> query, {int k = 4, String? docName}) {
    final pool = docName == null
        ? _chunks
        : _chunks.where((c) => c.docName == docName).toList();
    final scored = pool
        .map((c) => ScoredChunk(c, _cosine(query, c.embedding)))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return scored.take(k).toList();
  }

  static double _cosine(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0.0;
    double dot = 0, na = 0, nb = 0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      na += a[i] * a[i];
      nb += b[i] * b[i];
    }
    final denom = math.sqrt(na) * math.sqrt(nb);
    return denom == 0 ? 0.0 : dot / denom;
  }

  // -------- 持久化 --------
  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    final out = Directory('${dir.path}${Platform.pathSeparator}local_ai_chat');
    if (!await out.exists()) await out.create(recursive: true);
    return File('${out.path}${Platform.pathSeparator}vector_store.json');
  }

  Future<void> save() async {
    final f = await _file();
    final tmp = File('${f.path}.tmp');
    final payload = {
      'schemaVersion': 3,
      'embeddingModel': _embeddingModel,
      'chunks': _chunks.map((c) => c.toJson()).toList(),
      if (_sparseIndex != null) 'sparseIndex': _sparseIndex!.toJson(),
    };
    final data = jsonEncode(payload);
    await tmp.writeAsString(data, flush: true);
    if (await f.exists()) {
      await f.delete();
    }
    await tmp.rename(f.path);
  }

  Future<void> load({SparseIndexBuilder? sparseIndexBuilder}) async {
    final f = await _file();
    if (!await f.exists()) return;
    try {
      final raw = await f.readAsString();
      final snapshot = decodeSnapshot(jsonDecode(raw));
      _embeddingModel = snapshot.embeddingModel;
      _chunks
        ..clear()
        ..addAll(snapshot.chunks);
      _sparseIndex = snapshot.sparseIndex;
      if (snapshot.needsSparseIndexMigration &&
          _chunks.isNotEmpty &&
          sparseIndexBuilder != null) {
        _sparseIndex = sparseIndexBuilder(chunks);
      }
      if (snapshot.migratedFromLegacy || snapshot.needsSparseIndexMigration) {
        await DebugLogService.append(
          'VectorStore: migrated vector_store.json to schemaVersion=3 '
          'chunks=${_chunks.length} '
          'sparseIndex=${_sparseIndex == null ? 'missing' : 'present'}',
        );
        await save();
      }
    } catch (_) {
      // 檔案損壞就當冇
    }
  }

  static VectorStoreSnapshot decodeSnapshot(Object? decoded) {
    final List list;
    final String? embeddingModel;
    SparseIndexSnapshot? sparseIndex;
    var needsSparseIndexMigration = false;

    if (decoded is List) {
      embeddingModel = null;
      list = decoded;
      return VectorStoreSnapshot(
        embeddingModel: embeddingModel,
        chunks: _decodeChunks(list),
        needsSparseIndexMigration: true,
        migratedFromLegacy: true,
      );
    } else if (decoded is Map<String, dynamic>) {
      embeddingModel = decoded['embeddingModel'] as String?;
      final schemaVersion = (decoded['schemaVersion'] as num?)?.toInt() ?? 1;
      final rawSparseIndex = decoded['sparseIndex'];
      if (rawSparseIndex is Map<String, dynamic>) {
        sparseIndex = SparseIndexSnapshot.fromJson(rawSparseIndex);
      }
      needsSparseIndexMigration = schemaVersion < 3 || sparseIndex == null;
      final rawChunks = decoded['chunks'];
      if (rawChunks is List) {
        list = rawChunks;
      } else if (rawChunks is Map<String, dynamic> &&
          rawChunks['value'] is List) {
        list = rawChunks['value'] as List;
        return VectorStoreSnapshot(
          embeddingModel: embeddingModel,
          chunks: _decodeChunks(list),
          sparseIndex: sparseIndex,
          needsSparseIndexMigration: true,
          migratedFromLegacy: true,
        );
      } else {
        list = const [];
      }
    } else {
      return const VectorStoreSnapshot(
        embeddingModel: null,
        chunks: [],
      );
    }

    return VectorStoreSnapshot(
      embeddingModel: embeddingModel,
      chunks: _decodeChunks(list),
      sparseIndex: sparseIndex,
      needsSparseIndexMigration: needsSparseIndexMigration,
    );
  }

  static List<DocChunk> _decodeChunks(List list) {
    final chunks = <DocChunk>[];

    for (final item in list) {
      if (item is! Map) continue;

      try {
        chunks.add(DocChunk.fromJson(Map<String, dynamic>.from(item)));
      } catch (_) {
        // Skip malformed chunk instead of failing whole vector store load.
      }
    }

    return chunks;
  }
}
