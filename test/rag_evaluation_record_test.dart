import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/models/rag_evaluation_record.dart';

void main() {
  test('serializes to json', () {
    final createdAt = DateTime.parse('2026-04-26T12:00:00.000');

    final record = RagEvaluationRecord(
      id: '1',
      question: 'What is the deadline?',
      answer: 'Friday.',
      citationText: 'deadline',
      citationTarget: 'chunk:?doc=test.pdf&i=3',
      expectedStatus: RagExpectedStatus.exists,
      verdict: RagVerdict.pass,
      notes: 'Correct.',
      chatModel: 'llama3.2',
      embeddingModel: 'nomic-embed-text',
      createdAt: createdAt,
    );

    final json = record.toJson();

    expect(json['id'], '1');
    expect(json['citationTarget'], 'chunk:?doc=test.pdf&i=3');
    expect(json['expectedStatus'], 'exists');
    expect(json['verdict'], 'pass');
    expect(json['chatModel'], 'llama3.2');
    expect(json['embeddingModel'], 'nomic-embed-text');
    expect(json['createdAt'], createdAt.toIso8601String());
  });

  test('deserializes with safe defaults', () {
    final record = RagEvaluationRecord.fromJson({
      'question': 'Unknown?',
      'expectedStatus': 'invalid',
      'verdict': 'invalid',
    });

    expect(record.question, 'Unknown?');
    expect(record.answer, '');
    expect(record.expectedStatus, RagExpectedStatus.exists);
    expect(record.verdict, RagVerdict.unsure);
  });

  test('deserializes enum values case-insensitively', () {
    final record = RagEvaluationRecord.fromJson({
      'expectedStatus': 'FOLLOW_UP',
      'verdict': 'PASS',
    });

    expect(record.expectedStatus, RagExpectedStatus.followUp);
    expect(record.verdict, RagVerdict.pass);
  });

  test('round trip preserves values', () {
    final record = RagEvaluationRecord(
      id: '2',
      question: 'Q',
      answer: 'A',
      citationText: 'C',
      citationTarget: 'chunk:?doc=demo.pdf&i=5',
      expectedStatus: RagExpectedStatus.synonym,
      verdict: RagVerdict.unsure,
      notes: 'N',
      chatModel: 'gemma2:2b',
      embeddingModel: 'bge-m3',
      createdAt: DateTime.parse('2026-04-26T13:00:00.000'),
    );

    final restored = RagEvaluationRecord.fromJson(record.toJson());

    expect(restored.id, record.id);
    expect(restored.question, record.question);
    expect(restored.citationTarget, record.citationTarget);
    expect(restored.expectedStatus, record.expectedStatus);
    expect(restored.verdict, record.verdict);
    expect(restored.chatModel, record.chatModel);
    expect(restored.embeddingModel, record.embeddingModel);
  });

  test('round trip preserves missing and fail enums', () {
    final record = RagEvaluationRecord(
      id: 'missing-fail',
      question: 'Q',
      answer: '',
      citationText: '',
      citationTarget: '',
      expectedStatus: RagExpectedStatus.missing,
      verdict: RagVerdict.fail,
      notes: '',
      chatModel: 'model',
      embeddingModel: 'embed',
      createdAt: DateTime.parse('2026-04-26T13:30:00.000'),
    );

    final restored = RagEvaluationRecord.fromJson(record.toJson());

    expect(restored.expectedStatus, RagExpectedStatus.missing);
    expect(restored.verdict, RagVerdict.fail);
  });

  test('createRagEvaluationRecord uses provided enum state', () {
    final record = createRagEvaluationRecord(
      id: 'state-test',
      question: 'test missing',
      answer: '',
      citationText: '',
      citationTarget: '',
      expectedStatus: RagExpectedStatus.missing,
      verdict: RagVerdict.fail,
      notes: '',
      chatModel: 'gemma2:2b',
      embeddingModel: 'bge-m3',
      createdAt: DateTime.parse('2026-04-26T13:45:00.000'),
    );

    expect(record.expectedStatus, RagExpectedStatus.missing);
    expect(record.verdict, RagVerdict.fail);
  });

  test('summary counts pass fail unsure correctly', () {
    final records = [
      _makeRecord(verdict: RagVerdict.pass),
      _makeRecord(verdict: RagVerdict.fail),
    ];

    final summary = summarizeRagEvaluationRecords(records);

    expect(summary.total, 2);
    expect(summary.pass, 1);
    expect(summary.fail, 1);
    expect(summary.unsure, 0);
    expect(summary.passRate, 0.5);
    expect(summary.toJson()['passRate'], 0.5);
  });

  test('empty summary uses zero pass rate', () {
    final summary = summarizeRagEvaluationRecords([]);

    expect(summary.total, 0);
    expect(summary.passRate, 0.0);
  });

  test('summary deserializes from json', () {
    final summary = RagEvaluationSummary.fromJson({
      'count': 3,
      'pass': 1,
      'fail': 1,
      'unsure': 1,
      'passRate': 1 / 3,
    });

    expect(summary.total, 3);
    expect(summary.pass, 1);
    expect(summary.passRate, closeTo(1 / 3, 0.0001));
  });

  test('copyWith updates selected fields', () {
    final record = RagEvaluationRecord(
      id: '3',
      question: 'Q',
      answer: 'A',
      citationText: '',
      citationTarget: '',
      expectedStatus: RagExpectedStatus.exists,
      verdict: RagVerdict.unsure,
      notes: '',
      chatModel: 'model-a',
      embeddingModel: 'embed-a',
      createdAt: DateTime.parse('2026-04-26T14:00:00.000'),
    );

    final updated = record.copyWith(
      verdict: RagVerdict.pass,
      notes: 'ok',
    );

    expect(updated.question, 'Q');
    expect(updated.verdict, RagVerdict.pass);
    expect(updated.notes, 'ok');
  });

  test('copyWithJson patches selected fields safely', () {
    final record = _makeRecord(verdict: RagVerdict.unsure);

    final updated = record.copyWithJson({
      'verdict': 'fail',
      'expectedStatus': 'synonym',
      'notes': 'patched',
    });

    expect(updated.id, record.id);
    expect(updated.verdict, RagVerdict.fail);
    expect(updated.expectedStatus, RagExpectedStatus.synonym);
    expect(updated.notes, 'patched');
  });

  test('verdict convenience getters reflect verdict', () {
    expect(_makeRecord(verdict: RagVerdict.pass).isPass, isTrue);
    expect(_makeRecord(verdict: RagVerdict.fail).isFail, isTrue);
    expect(_makeRecord(verdict: RagVerdict.unsure).isUnsure, isTrue);
  });
}

RagEvaluationRecord _makeRecord({required RagVerdict verdict}) {
  return RagEvaluationRecord(
    id: verdict.name,
    question: 'Q',
    answer: '',
    citationText: '',
    citationTarget: '',
    expectedStatus: RagExpectedStatus.exists,
    verdict: verdict,
    notes: '',
    chatModel: 'model',
    embeddingModel: 'embed',
    createdAt: DateTime.parse('2026-04-26T14:30:00.000'),
  );
}


