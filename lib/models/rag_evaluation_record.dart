enum RagExpectedStatus {
  exists,
  missing,
  followUp,
  synonym,
}

enum RagVerdict {
  pass,
  fail,
  unsure,
}

class RagEvaluationRecord {
  const RagEvaluationRecord({
    required this.id,
    required this.question,
    required this.answer,
    required this.citationText,
    required this.citationTarget,
    required this.expectedStatus,
    required this.verdict,
    required this.notes,
    required this.chatModel,
    required this.embeddingModel,
    required this.createdAt,
  });

  final String id;
  final String question;
  final String answer;
  final String citationText;
  final String citationTarget;
  final RagExpectedStatus expectedStatus;
  final RagVerdict verdict;
  final String notes;
  final String chatModel;
  final String embeddingModel;
  final DateTime createdAt;

  RagEvaluationRecord copyWith({
    String? id,
    String? question,
    String? answer,
    String? citationText,
    String? citationTarget,
    RagExpectedStatus? expectedStatus,
    RagVerdict? verdict,
    String? notes,
    String? chatModel,
    String? embeddingModel,
    DateTime? createdAt,
  }) {
    return RagEvaluationRecord(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      citationText: citationText ?? this.citationText,
      citationTarget: citationTarget ?? this.citationTarget,
      expectedStatus: expectedStatus ?? this.expectedStatus,
      verdict: verdict ?? this.verdict,
      notes: notes ?? this.notes,
      chatModel: chatModel ?? this.chatModel,
      embeddingModel: embeddingModel ?? this.embeddingModel,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'citationText': citationText,
      'citationTarget': citationTarget,
      'expectedStatus': expectedStatus.name,
      'verdict': verdict.name,
      'notes': notes,
      'chatModel': chatModel,
      'embeddingModel': embeddingModel,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RagEvaluationRecord.fromJson(Map<String, dynamic> json) {
    return RagEvaluationRecord(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      citationText: json['citationText'] as String? ?? '',
      citationTarget: json['citationTarget'] as String? ?? '',
      expectedStatus: RagExpectedStatus.values.firstWhere(
        (value) => value.name == json['expectedStatus'],
        orElse: () => RagExpectedStatus.exists,
      ),
      verdict: RagVerdict.values.firstWhere(
        (value) => value.name == json['verdict'],
        orElse: () => RagVerdict.unsure,
      ),
      notes: json['notes'] as String? ?? '',
      chatModel: json['chatModel'] as String? ?? '',
      embeddingModel: json['embeddingModel'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

RagEvaluationRecord createRagEvaluationRecord({
  required String id,
  required String question,
  required String answer,
  required String citationText,
  required String citationTarget,
  required RagExpectedStatus expectedStatus,
  required RagVerdict verdict,
  required String notes,
  required String chatModel,
  required String embeddingModel,
  required DateTime createdAt,
}) {
  return RagEvaluationRecord(
    id: id,
    question: question,
    answer: answer,
    citationText: citationText,
    citationTarget: citationTarget,
    expectedStatus: expectedStatus,
    verdict: verdict,
    notes: notes,
    chatModel: chatModel,
    embeddingModel: embeddingModel,
    createdAt: createdAt,
  );
}

class RagEvaluationSummary {
  const RagEvaluationSummary({
    required this.total,
    required this.pass,
    required this.fail,
    required this.unsure,
    required this.passRate,
  });

  final int total;
  final int pass;
  final int fail;
  final int unsure;
  final double? passRate;
}

RagEvaluationSummary summarizeRagEvaluationRecords(
  List<RagEvaluationRecord> records,
) {
  final pass = records.where((r) => r.verdict == RagVerdict.pass).length;
  final fail = records.where((r) => r.verdict == RagVerdict.fail).length;
  final unsure = records.where((r) => r.verdict == RagVerdict.unsure).length;

  return RagEvaluationSummary(
    total: records.length,
    pass: pass,
    fail: fail,
    unsure: unsure,
    passRate: records.isEmpty ? null : pass / records.length,
  );
}
