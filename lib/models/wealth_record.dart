// lib/models/wealth_record.dart
//
// Phase 7.0'a (v2.4) — Investment / wealth record model.
// Pattern A storage (matches ExpenseController): record JSON lives in
// DocChunk.metadata['data']; chunk.text holds a search-friendly summary.
//
// Diff vs Antigravity local v0:
//   + assetName field (so AAPL vs TSLA can be tracked separately)
//   + source field ('manual' | 'imported' | 'ai_extracted')
//   + WealthAssetType constants + Chinese label() translator
//   + assetKey getter (assetType + assetName + currency)
//   + == / hashCode (List<String> tag equality respected)
//   + toSearchText() with rich token coverage
//   + null-safe fromJson with sane defaults

class WealthRecord {
  WealthRecord({
    this.id = '',
    required this.date,
    required this.assetType,
    this.assetName = '',
    required this.amount,
    this.currency = 'TWD',
    this.notes = '',
    this.tags = const [],
    DateTime? dateAdded,
    this.source = 'manual',
  }) : dateAdded = dateAdded ?? DateTime.now();

  final String id;
  final DateTime date;
  final String assetType; // see WealthAssetType
  final String assetName; // e.g. 'AAPL' / '0050.TW' / '' for cash
  final double amount;
  final String currency;
  final String notes;
  final List<String> tags;
  final DateTime dateAdded;
  final String source;

  /// Stable key used to group successive valuations of the same asset.
  String get assetKey =>
      '$assetType|${assetName.trim().toLowerCase()}|$currency';

  WealthRecord copyWith({
    String? id,
    DateTime? date,
    String? assetType,
    String? assetName,
    double? amount,
    String? currency,
    String? notes,
    List<String>? tags,
    DateTime? dateAdded,
    String? source,
  }) {
    return WealthRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      assetType: assetType ?? this.assetType,
      assetName: assetName ?? this.assetName,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      dateAdded: dateAdded ?? this.dateAdded,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'assetType': assetType,
        'assetName': assetName,
        'amount': amount,
        'currency': currency,
        'notes': notes,
        'tags': tags,
        'dateAdded': dateAdded.toIso8601String(),
        'source': source,
      };

  factory WealthRecord.fromMap(Map<String, dynamic> map) => WealthRecord(
        id: map['id']?.toString() ?? '',
        date: map['date'] != null
            ? DateTime.parse(map['date'].toString())
            : DateTime.now(),
        assetType:
            map['assetType']?.toString() ?? WealthAssetType.other,
        assetName: map['assetName']?.toString() ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        currency: map['currency']?.toString() ?? 'TWD',
        notes: map['notes']?.toString() ?? '',
        tags: (map['tags'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        dateAdded: map['dateAdded'] != null
            ? DateTime.parse(map['dateAdded'].toString())
            : DateTime.now(),
        source: map['source']?.toString() ?? 'manual',
      );

  Map<String, dynamic> toJson() => toMap();
  factory WealthRecord.fromJson(Map<String, dynamic> j) =>
      WealthRecord.fromMap(j);

  /// Free-text used to populate DocChunk.text (RAG-searchable).
  String toSearchText() {
    final parts = <String>[
      WealthAssetType.label(assetType),
      assetType,
      if (assetName.isNotEmpty) assetName,
      '${amount.toStringAsFixed(2)} $currency',
      if (notes.isNotEmpty) notes,
      ...tags,
      date.toIso8601String().split('T').first,
    ];
    return parts.join(' · ');
  }

  /// Long-form RAG snippet (mirrors HealthRecord.toRagString).
  String toRagString() {
    final dateStr = date.toIso8601String().split('T').first;
    final typeLabel = WealthAssetType.label(assetType);
    return [
      '【投資理財】$dateStr',
      '資產類型：$typeLabel${assetName.isEmpty ? '' : ' · $assetName'}',
      '金額：${amount.toStringAsFixed(2)} $currency',
      if (notes.isNotEmpty) '備註：$notes',
      if (tags.isNotEmpty) '標籤：${tags.join(', ')}',
    ].join('\n');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WealthRecord &&
          other.id == id &&
          other.date == date &&
          other.assetType == assetType &&
          other.assetName == assetName &&
          other.amount == amount &&
          other.currency == currency &&
          other.notes == notes &&
          _listEq(other.tags, tags) &&
          other.dateAdded == dateAdded &&
          other.source == source;

  @override
  int get hashCode => Object.hash(
        id,
        date,
        assetType,
        assetName,
        amount,
        currency,
        notes,
        Object.hashAll(tags),
        dateAdded,
        source,
      );

  static bool _listEq(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Asset type constants. Use these in code, not raw strings, to avoid
/// 'Stock' vs 'stock' silently creating different allocation buckets.
class WealthAssetType {
  WealthAssetType._();

  static const String cash = 'cash';
  static const String stock = 'stock';
  static const String fund = 'fund';
  static const String bond = 'bond';
  static const String crypto = 'crypto';
  static const String realEstate = 'real_estate';
  static const String insurance = 'insurance';
  static const String other = 'other';

  static const List<String> all = [
    cash, stock, fund, bond, crypto, realEstate, insurance, other,
  ];

  static const Map<String, String> _labels = {
    cash: '現金',
    stock: '股票',
    fund: '基金',
    bond: '債券',
    crypto: '加密貨幣',
    realEstate: '房地產',
    insurance: '保險',
    other: '其他',
  };

  /// Returns the Chinese label, or the input itself if unknown — so an
  /// out-of-vocabulary value still renders something sensible.
  static String label(String code) => _labels[code] ?? code;
}

/// Snapshot of total net-worth on a specific date (one currency).
class NetWorthSnapshot {
  const NetWorthSnapshot({required this.date, required this.total});
  final DateTime date;
  final double total;
}

/// Aggregated stats over the wealth collection for a chosen currency.
class WealthStats {
  const WealthStats({
    required this.currency,
    required this.totalNetWorth,
    required this.assetCount,
    required this.allocationByType,
  });

  final String currency;
  final double totalNetWorth;
  final int assetCount;
  final Map<String, double> allocationByType;

  bool get isEmpty => assetCount == 0;
}

// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
