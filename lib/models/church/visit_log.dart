// lib/models/church/visit_log.dart

/// A single pastoral visit logged against a [CareCase]. Multiple visits per
/// case build up the visit history shown on the case detail screen.
///
/// Persisted via VectorStore (Pattern A) under collection 'ChurchVisitLogs'.
class VisitLog {
  VisitLog({
    this.id = '',
    required this.caseId,
    DateTime? visitDate,
    required this.visitedBy,
    this.method = VisitMethod.inPerson,
    required this.summary,
    this.condition = MemberCondition.good,
  }) : visitDate = visitDate ?? DateTime.now();

  final String id;
  final String caseId; // FK -> CareCase.id
  final DateTime visitDate;
  final String visitedBy; // 探訪的傳道人名字
  final String method; // VisitMethod constants
  final String summary; // 1-2 sentence note, REQUIRED
  final String condition; // MemberCondition constants

  VisitLog copyWith({
    String? id,
    String? caseId,
    DateTime? visitDate,
    String? visitedBy,
    String? method,
    String? summary,
    String? condition,
  }) {
    return VisitLog(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      visitDate: visitDate ?? this.visitDate,
      visitedBy: visitedBy ?? this.visitedBy,
      method: method ?? this.method,
      summary: summary ?? this.summary,
      condition: condition ?? this.condition,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'caseId': caseId,
        'visitDate': visitDate.toIso8601String(),
        'visitedBy': visitedBy,
        'method': method,
        'summary': summary,
        'condition': condition,
      };

  factory VisitLog.fromJson(Map<String, dynamic> json) {
    return VisitLog(
      id: json['id'] as String? ?? '',
      caseId: json['caseId'] as String? ?? '',
      visitDate: json['visitDate'] is String
          ? DateTime.tryParse(json['visitDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      visitedBy: json['visitedBy'] as String? ?? '',
      method: json['method'] as String? ?? VisitMethod.inPerson,
      summary: json['summary'] as String? ?? '',
      condition: json['condition'] as String? ?? MemberCondition.good,
    );
  }

  String toSearchText() =>
      [visitedBy, summary].where((s) => s.isNotEmpty).join(' ');
}

class VisitMethod {
  static const String inPerson = 'inperson';
  static const String phone = 'phone';
  static const String message = 'message';

  static const List<String> all = [inPerson, phone, message];

  static String label(String method) {
    switch (method) {
      case inPerson:
        return '親訪';
      case phone:
        return '電話';
      case message:
        return '訊息';
      default:
        return method;
    }
  }
}

class MemberCondition {
  static const String good = 'good';
  static const String concern = 'concern';
  static const String worsening = 'worsening';

  static const List<String> all = [good, concern, worsening];

  static String label(String condition) {
    switch (condition) {
      case good:
        return '良好';
      case concern:
        return '需要關注';
      case worsening:
        return '惡化';
      default:
        return condition;
    }
  }
}
