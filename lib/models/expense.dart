// lib/models/expense.dart

class Expense {
  final String id;
  final double amount;
  final String currency;
  final String category;
  final String merchant;
  final String notes;
  final String paymentMethod;
  final DateTime date;
  final List<String> tags;

  const Expense({
    this.id = '',
    required this.amount,
    this.currency = 'TWD',
    this.category = '餐飲',
    this.merchant = '',
    this.notes = '',
    this.paymentMethod = 'cash',
    required this.date,
    this.tags = const [],
  });

  Expense copyWith({
    String? id,
    double? amount,
    String? currency,
    String? category,
    String? merchant,
    String? notes,
    String? paymentMethod,
    DateTime? date,
    List<String>? tags,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      merchant: merchant ?? this.merchant,
      notes: notes ?? this.notes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'currency': currency,
        'category': category,
        'merchant': merchant,
        'notes': notes,
        'paymentMethod': paymentMethod,
        'date': date.toIso8601String(),
        'tags': tags,
      };

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'TWD',
      category: json['category'] as String? ?? '',
      merchant: json['merchant'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      paymentMethod: json['paymentMethod'] as String? ?? 'cash',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  String toSearchText() {
    final buffer = StringBuffer();
    buffer.write('$category $merchant $notes $amount $currency $paymentMethod');
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
        merchant == other.merchant &&
        notes == other.notes &&
        paymentMethod == other.paymentMethod &&
        date.isAtSameMomentAs(other.date) &&
        _listEquals(tags, other.tags);
  }

  @override
  int get hashCode => Object.hash(
        id,
        amount,
        currency,
        category,
        merchant,
        notes,
        paymentMethod,
        date,
        Object.hashAll(tags),
      );
}


