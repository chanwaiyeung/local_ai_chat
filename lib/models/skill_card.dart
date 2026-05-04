import 'dart:convert';

class SkillCard {
  final String id;
  final String query;
  final String reasoningPath;
  final String answer;
  final String domain;
  final DateTime createdAt;
  final int successCount;

  SkillCard({
    required this.id,
    required this.query,
    required this.reasoningPath,
    required this.answer,
    required this.domain,
    required this.createdAt,
    this.successCount = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'query': query,
      'reasoningPath': reasoningPath,
      'answer': answer,
      'domain': domain,
      'createdAt': createdAt.toIso8601String(),
      'successCount': successCount,
    };
  }

  factory SkillCard.fromMap(Map<String, dynamic> map) {
    return SkillCard(
      id: map['id'] as String? ?? '',
      query: map['query'] as String? ?? '',
      reasoningPath: map['reasoningPath'] as String? ?? '',
      answer: map['answer'] as String? ?? '',
      domain: map['domain'] as String? ?? 'general',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      successCount: (map['successCount'] as num?)?.toInt() ?? 1,
    );
  }

  String toJson() => json.encode(toMap());

  factory SkillCard.fromJson(String source) =>
      SkillCard.fromMap(json.decode(source) as Map<String, dynamic>);
      
  SkillCard copyWith({
    String? id,
    String? query,
    String? reasoningPath,
    String? answer,
    String? domain,
    DateTime? createdAt,
    int? successCount,
  }) {
    return SkillCard(
      id: id ?? this.id,
      query: query ?? this.query,
      reasoningPath: reasoningPath ?? this.reasoningPath,
      answer: answer ?? this.answer,
      domain: domain ?? this.domain,
      createdAt: createdAt ?? this.createdAt,
      successCount: successCount ?? this.successCount,
    );
  }
}
