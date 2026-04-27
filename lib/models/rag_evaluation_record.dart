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

  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();

  bool get isPass => verdict == RagVerdict.pass;
  bool get isFail => verdict == RagVerdict.fail;
  bool get isUnsure => verdict == RagVerdict.unsure;

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

  RagEvaluationRecord copyWithJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['createdAt'];

    return copyWith(
      id: json['id'] as String?,
      question: json['question'] as String?,
      answer: json['answer'] as String?,
      citationText: json['citationText'] as String?,
      citationTarget: json['citationTarget'] as String?,
      expectedStatus: json.containsKey('expectedStatus')
          ? _parseExpectedStatus(json['expectedStatus'])
          : null,
      verdict:
          json.containsKey('verdict') ? _parseVerdict(json['verdict']) : null,
      notes: json['notes'] as String?,
      chatModel: json['chatModel'] as String?,
      embeddingModel: json['embeddingModel'] as String?,
      createdAt: rawCreatedAt == null
          ? null
          : DateTime.tryParse(rawCreatedAt.toString()) ?? createdAt,
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
      expectedStatus: _parseExpectedStatus(json['expectedStatus']),
      verdict: _parseVerdict(json['verdict']),
      notes: json['notes'] as String? ?? '',
      chatModel: json['chatModel'] as String? ?? '',
      embeddingModel: json['embeddingModel'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

RagExpectedStatus _parseExpectedStatus(Object? raw) {
  switch (_normalizeEnumValue(raw)) {
    case 'exists':
      return RagExpectedStatus.exists;
    case 'missing':
      return RagExpectedStatus.missing;
    case 'followup':
      return RagExpectedStatus.followUp;
    case 'synonym':
      return RagExpectedStatus.synonym;
    default:
      return RagExpectedStatus.exists;
  }
}

RagVerdict _parseVerdict(Object? raw) {
  switch (_normalizeEnumValue(raw)) {
    case 'pass':
      return RagVerdict.pass;
    case 'fail':
      return RagVerdict.fail;
    case 'unsure':
      return RagVerdict.unsure;
    default:
      return RagVerdict.unsure;
  }
}

String _normalizeEnumValue(Object? raw) {
  return raw.toString().trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
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
  final double passRate;

  Map<String, dynamic> toJson() {
    return {
      'count': total,
      'pass': pass,
      'fail': fail,
      'unsure': unsure,
      'passRate': passRate,
    };
  }

  factory RagEvaluationSummary.fromJson(Map<String, dynamic> json) {
    return RagEvaluationSummary(
      total: json['count'] as int? ?? json['total'] as int? ?? 0,
      pass: json['pass'] as int? ?? 0,
      fail: json['fail'] as int? ?? 0,
      unsure: json['unsure'] as int? ?? 0,
      passRate: (json['passRate'] as num?)?.toDouble() ?? 0.0,
    );
  }
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
    passRate: records.isEmpty ? 0.0 : pass / records.length,
  );
}
