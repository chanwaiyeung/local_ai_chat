import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/models/rag_evaluation_record.dart';
import 'package:local_ai_chat/services/rag_evaluation_service.dart';

void main() {
  test('buildExportPayload uses expected JSON schema', () {
    final service = RagEvaluationService();

    final records = [
      RagEvaluationRecord(
        id: '1',
        question: 'test exists',
        answer: '',
        citationText: '',
        citationTarget: 'chunk:?doc=test.pdf&i=1',
        expectedStatus: RagExpectedStatus.exists,
        verdict: RagVerdict.pass,
        notes: '',
        chatModel: 'qwen2.5:7b',
        embeddingModel: 'nomic-embed-text',
        createdAt: DateTime.parse('2026-04-26T12:00:00.000'),
      ),
      RagEvaluationRecord(
        id: '2',
        question: 'test missing',
        answer: '',
        citationText: '',
        citationTarget: '',
        expectedStatus: RagExpectedStatus.missing,
        verdict: RagVerdict.fail,
        notes: '',
        chatModel: 'qwen2.5:7b',
        embeddingModel: 'nomic-embed-text',
        createdAt: DateTime.parse('2026-04-26T12:01:00.000'),
      ),
    ];

    final payload = service.buildExportPayload(records);
    final summary = payload['summary'] as Map<String, dynamic>;

    expect(payload.containsKey('count'), isFalse);
    expect(payload['schemaVersion'], 1);
    expect(payload.containsKey('records'), isTrue);

    expect(summary['count'], 2);
    expect(summary['pass'], 1);
    expect(summary['fail'], 1);
    expect(summary['unsure'], 0);
    expect(summary['passRate'], 0.5);
    expect(summary['chatModels'], ['qwen2.5:7b']);
    expect(summary['embeddingModels'], ['nomic-embed-text']);
    expect(summary.containsKey('chatModelsUsed'), isFalse);
    expect(summary.containsKey('embeddingModelsUsed'), isFalse);
  });

  test('buildExportPayload sorts and filters model metadata', () {
    final service = RagEvaluationService();

    final records = [
      _record('1', RagVerdict.pass, chatModel: 'z-chat', embedModel: ''),
      _record('2', RagVerdict.unsure, chatModel: '', embedModel: 'b-embed'),
      _record('3', RagVerdict.fail, chatModel: 'a-chat', embedModel: 'a-embed'),
      _record('4', RagVerdict.pass, chatModel: 'a-chat', embedModel: 'a-embed'),
    ];

    final payload = service.buildExportPayload(records);
    final summary = payload['summary'] as Map<String, dynamic>;

    expect(summary['count'], 4);
    expect(summary['pass'], 2);
    expect(summary['fail'], 1);
    expect(summary['unsure'], 1);
    expect(summary['passRate'], 0.5);
    expect(summary['chatModels'], ['a-chat', 'z-chat']);
    expect(summary['embeddingModels'], ['a-embed', 'b-embed']);
  });
}

RagEvaluationRecord _record(
  String id,
  RagVerdict verdict, {
  required String chatModel,
  required String embedModel,
}) {
  return RagEvaluationRecord(
    id: id,
    question: 'Q$id',
    answer: '',
    citationText: '',
    citationTarget: '',
    expectedStatus: RagExpectedStatus.exists,
    verdict: verdict,
    notes: '',
    chatModel: chatModel,
    embeddingModel: embedModel,
    createdAt: DateTime.parse('2026-04-26T12:00:00.000'),
  );
}
