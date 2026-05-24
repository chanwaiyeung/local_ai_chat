// lib/models/church/care_case.dart

/// A pastoral care case — an active person/situation needing follow-up from
/// the pastoral team.
///
/// Persisted via VectorStore (Pattern A) under collection 'ChurchCareCases'.
class CareCase {
  CareCase({
    this.id = '',
    required this.memberName,
    this.memberPhone = '',
    required this.reason,
    this.caseType = CaseType.member,
    this.urgency = CareUrgency.medium,
    this.status = CareStatus.active,
    DateTime? createdAt,
    this.createdBy = '',
    this.notes = '',
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String memberName;
  final String memberPhone;
  final String reason;
  final String caseType; // member / newcomer
  final String urgency;
  final String status;
  final DateTime createdAt;
  final String createdBy;
  final String notes;

  CareCase copyWith({
    String? id,
    String? memberName,
    String? memberPhone,
    String? reason,
    String? caseType,
    String? urgency,
    String? status,
    DateTime? createdAt,
    String? createdBy,
    String? notes,
  }) {
    return CareCase(
      id: id ?? this.id,
      memberName: memberName ?? this.memberName,
      memberPhone: memberPhone ?? this.memberPhone,
      reason: reason ?? this.reason,
      caseType: caseType ?? this.caseType,
      urgency: urgency ?? this.urgency,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberName': memberName,
        'memberPhone': memberPhone,
        'reason': reason,
        'caseType': caseType,
        'urgency': urgency,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'createdBy': createdBy,
        'notes': notes,
      };

  factory CareCase.fromJson(Map<String, dynamic> json) {
    return CareCase(
      id: json['id'] as String? ?? '',
      memberName: json['memberName'] as String? ?? '',
      memberPhone: json['memberPhone'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      caseType: json['caseType'] as String? ?? CaseType.member,
      urgency: json['urgency'] as String? ?? CareUrgency.medium,
      status: json['status'] as String? ?? CareStatus.active,
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      createdBy: json['createdBy'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }

  String toSearchText() => [
        memberName,
        memberPhone,
        reason,
        notes,
      ].where((s) => s.isNotEmpty).join(' ');
}

/// Whether this case is for an existing member or a newcomer being followed up.
class CaseType {
  static const String member = 'member';     // 會友
  static const String newcomer = 'newcomer'; // 新朋友

  static const List<String> all = [member, newcomer];

  static String label(String type) {
    switch (type) {
      case member:
        return '會友 / Member';
      case newcomer:
        return '非會友 / Non-Member';
      default:
        return type;
    }
  }
}

class CareUrgency {
  static const String high = 'high';
  static const String medium = 'medium';
  static const String low = 'low';

  static const List<String> all = [high, medium, low];

  static int slaDays(String urgency) {
    switch (urgency) {
      case high:
        return 3;
      case low:
        return 14;
      case medium:
      default:
        return 7;
    }
  }

  static String label(String urgency) {
    switch (urgency) {
      case high:
        return '高';
      case medium:
        return '中';
      case low:
        return '低';
      default:
        return urgency;
    }
  }
}

class CareStatus {
  static const String active = 'active';
  static const String closed = 'closed';

  static const List<String> all = [active, closed];

  static String label(String status) {
    switch (status) {
      case active:
        return '進行中';
      case closed:
        return '已結案';
      default:
        return status;
    }
  }
}
