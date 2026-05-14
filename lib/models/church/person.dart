// lib/models/church/person.dart

/// A church directory entry — member, attender, or contact.
/// Persisted via VectorStore under collection 'ChurchPersons'.
class Person {
  Person({
    this.id = '',
    required this.name,
    this.phone = '',
    this.birthday,
    this.baptismDate,
    this.joinDate,
    this.attendance = AttendanceStatus.regular,
    this.smallGroup = '',
    this.sundaySchool = '',
    this.notes = '',
    DateTime? createdAt,
    this.createdBy = '',
    this.personType = PersonType.member,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String name;
  final String phone;
  final DateTime? birthday;
  final DateTime? baptismDate;
  final DateTime? joinDate;
  final String attendance;
  final String smallGroup;
  final String sundaySchool;
  final String notes;
  final DateTime createdAt;
  final String createdBy;
  final String personType;

  Person copyWith({
    String? id,
    String? name,
    String? phone,
    DateTime? birthday,
    DateTime? baptismDate,
    DateTime? joinDate,
    String? attendance,
    String? smallGroup,
    String? sundaySchool,
    String? notes,
    DateTime? createdAt,
    String? createdBy,
    String? personType,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      birthday: birthday ?? this.birthday,
      baptismDate: baptismDate ?? this.baptismDate,
      joinDate: joinDate ?? this.joinDate,
      attendance: attendance ?? this.attendance,
      smallGroup: smallGroup ?? this.smallGroup,
      sundaySchool: sundaySchool ?? this.sundaySchool,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      personType: personType ?? this.personType,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'birthday': birthday?.toIso8601String(),
        'baptismDate': baptismDate?.toIso8601String(),
        'joinDate': joinDate?.toIso8601String(),
        'attendance': attendance,
        'smallGroup': smallGroup,
        'sundaySchool': sundaySchool,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'createdBy': createdBy,
        'personType': personType,
      };

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      birthday: _parseDate(json['birthday']),
      baptismDate: _parseDate(json['baptismDate']),
      joinDate: _parseDate(json['joinDate']),
      attendance: json['attendance'] as String? ?? AttendanceStatus.regular,
      smallGroup: json['smallGroup'] as String? ?? '',
      sundaySchool: json['sundaySchool'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      createdBy: json['createdBy'] as String? ?? '',
      personType: json['personType'] as String? ?? PersonType.member,
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v is! String) return null;
    return DateTime.tryParse(v);
  }

  String toSearchText() => [
        name,
        phone,
        smallGroup,
        sundaySchool,
        notes,
      ].where((s) => s.isNotEmpty).join(' ');
}

class AttendanceStatus {
  static const String regular = 'regular';
  static const String occasional = 'occasional';
  static const String inactive = 'inactive';

  static const List<String> all = [regular, occasional, inactive];

  static String label(String s) {
    switch (s) {
      case regular: return '經常出席';
      case occasional: return '偶爾出席';
      case inactive: return '久未出席';
      default: return s;
    }
  }
}

class PersonType {
  static const String member = 'member';
  static const String seeker = 'seeker';

  static const List<String> all = [member, seeker];

  static String label(String s) {
    switch (s) {
      case member: return '會友';
      case seeker: return '非會友';
      default: return s;
    }
  }
}