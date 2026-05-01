// lib/models/expense.dart

class Expense {
  final String id;
  final double amount;
  final String currency;
  final String category;
  final String description;
  final DateTime date;
  final List<String> tags;

  const Expense({
    required this.id,
    required this.amount,
    this.currency = 'CAD',
    this.category = '',
    this.description = '',
    required this.date,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'currency': currency,
        'category': category,
        'description': description,
        'date': date.toIso8601String(),
        'tags': tags,
      };

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'CAD',
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  String toSearchText() {
    final buffer = StringBuffer();
    buffer.write('$category $description $amount $currency');
    if (tags.isNotEmpty) {
      buffer.write(' ${tags.join(' ')}');
    }
    return buffer.toString();
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Expense) return false;
    return id == other.id &&
        amount == other.amount &&
        currency == other.currency &&
        category == other.category &&
        description == other.description &&
        date.isAtSameMomentAs(other.date) &&
        _listEquals(tags, other.tags);
  }

  @override
  int get hashCode => Object.hash(
        id,
        amount,
        currency,
        category,
        description,
        date,
        Object.hashAll(tags),
      );
}
