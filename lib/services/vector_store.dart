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

class VectorStoreSnapshot {
  const VectorStoreSnapshot({
    required this.embeddingModel,
    required this.chunks,
    this.migratedFromLegacy = false,
  });

  final String? embeddingModel;
  final List<DocChunk> chunks;
  final bool migratedFromLegacy;
}

/// 簡單嘅 in-memory 向量庫，支援 JSON 持久化
class VectorStore {
  final List<DocChunk> _chunks = [];
  String? _embeddingModel;

  int get length => _chunks.length;
  String? get embeddingModel => _embeddingModel;
  List<String> get docNames => _chunks.map((c) => c.docName).toSet().toList();
  List<DocChunk> get chunks => List.unmodifiable(_chunks);

  void add(DocChunk c) => _chunks.add(c);
  void addAll(Iterable<DocChunk> cs) => _chunks.addAll(cs);

  void clear() {
    _chunks.clear();
    _embeddingModel = null;
  }

  void setEmbeddingModel(String model) {
    _embeddingModel = model;
  }

  void removeDoc(String docName) =>
      _chunks.removeWhere((c) => c.docName == docName);

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
      'schemaVersion': 2,
      'embeddingModel': _embeddingModel,
      'chunks': _chunks.map((c) => c.toJson()).toList(),
    };
    final data = jsonEncode(payload);
    await tmp.writeAsString(data, flush: true);
    if (await f.exists()) {
      await f.delete();
    }
    await tmp.rename(f.path);
  }

  Future<void> load() async {
    final f = await _file();
    if (!await f.exists()) return;
    try {
      final raw = await f.readAsString();
      final snapshot = decodeSnapshot(jsonDecode(raw));
      _embeddingModel = snapshot.embeddingModel;
      _chunks
        ..clear()
        ..addAll(snapshot.chunks);
      if (snapshot.migratedFromLegacy) {
        await DebugLogService.append(
          'VectorStore: loaded legacy vector_store.json format; '
          'next save will write schemaVersion=2 chunks=${_chunks.length}',
        );
      }
    } catch (_) {
      // 檔案損壞就當冇
    }
  }

  static VectorStoreSnapshot decodeSnapshot(Object? decoded) {
    final List list;
    final String? embeddingModel;

    if (decoded is List) {
      embeddingModel = null;
      list = decoded;
      return VectorStoreSnapshot(
        embeddingModel: embeddingModel,
        chunks: _decodeChunks(list),
        migratedFromLegacy: true,
      );
    } else if (decoded is Map<String, dynamic>) {
      embeddingModel = decoded['embeddingModel'] as String?;
      final rawChunks = decoded['chunks'];
      if (rawChunks is List) {
        list = rawChunks;
      } else if (rawChunks is Map<String, dynamic> &&
          rawChunks['value'] is List) {
        list = rawChunks['value'] as List;
        return VectorStoreSnapshot(
          embeddingModel: embeddingModel,
          chunks: _decodeChunks(list),
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
    );
  }

  static List<DocChunk> _decodeChunks(List list) {
    return list
        .whereType<Map<String, dynamic>>()
        .map(DocChunk.fromJson)
        .toList();
  }
}
