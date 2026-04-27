import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/rag_evaluation_record.dart';

class RagEvaluationService {
  static const _fileName = 'rag_evaluations.json';

  Future<File> _stateFile() async {
    final dir = await getApplicationSupportDirectory();
    final appDir =
        Directory('${dir.path}${Platform.pathSeparator}local_ai_chat');
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return File('${appDir.path}${Platform.pathSeparator}$_fileName');
  }

  Future<List<RagEvaluationRecord>> loadRecords() async {
    final file = await _stateFile();
    if (!await file.exists()) return [];

    try {
      final text = await file.readAsString();
      final json = jsonDecode(text) as Map<String, dynamic>;
      final records = json['records'] as List<dynamic>? ?? const [];
      return records
          .whereType<Map<String, dynamic>>()
          .map(RagEvaluationRecord.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveRecords(List<RagEvaluationRecord> records) async {
    final file = await _stateFile();
    final temp = File('${file.path}.tmp');

    final payload = {
      'schemaVersion': 1,
      'updatedAt': DateTime.now().toIso8601String(),
      'count': records.length,
      'records': records.map((record) => record.toJson()).toList(),
    };

    const encoder = JsonEncoder.withIndent('  ');
    await temp.writeAsString(encoder.convert(payload));
    if (await file.exists()) {
      await file.delete();
    }
    await temp.rename(file.path);
  }

  Future<File> exportSnapshot(List<RagEvaluationRecord> records) async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = _timestamp(DateTime.now());

    final file = File(
      '${dir.path}${Platform.pathSeparator}rag_evaluation_$timestamp.json',
    );

    final payload = buildExportPayload(records);

    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(payload));
    return file;
  }

  Map<String, dynamic> buildExportPayload(List<RagEvaluationRecord> records) {
    final summary = summarizeRagEvaluationRecords(records);

    final chatModels = records
        .map((r) => r.chatModel)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final embeddingModels = records
        .map((r) => r.embeddingModel)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return {
      'schemaVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'summary': {
        'count': summary.total,
        'pass': summary.pass,
        'fail': summary.fail,
        'unsure': summary.unsure,
        'passRate': summary.passRate,
        'chatModels': chatModels,
        'embeddingModels': embeddingModels,
      },
      'records': records.map((record) => record.toJson()).toList(),
    };
  }

  String _timestamp(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}'
        '${two(value.month)}'
        '${two(value.day)}_'
        '${two(value.hour)}'
        '${two(value.minute)}'
        '${two(value.second)}';
  }
}
