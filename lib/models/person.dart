
class Person {
  final String id;
  final String name;
  final String? nickname;
  final String? phone;
  final String? email;
  final DateTime? birthday;
  final String? baptismDate;
  final String? spiritualStage; // 慕道、初信、成長、服事...
  final String? address;
  final String? notes;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Person({
    required this.id,
    required this.name,
    this.nickname,
    this.phone,
    this.email,
    this.birthday,
    this.baptismDate,
    this.spiritualStage,
    this.address,
    this.notes,
    this.tags = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // toJson / fromJson 稍後補
}
