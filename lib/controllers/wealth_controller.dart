// lib/controllers/wealth_controller.dart
import 'package:flutter/foundation.dart';

import '../models/wealth_record.dart';
import '../services/vector_store.dart';

class WealthController extends ChangeNotifier {
  WealthController(this._store);

  static const String kWealthCollection = 'Wealth';
  static const String kWealthTypeTag = 'personal_hub_wealth';

  final VectorStore _store;
  List<WealthRecord> _records = const [];
  bool _loaded = false;

  // ---------------------------------------------------------- lifecycle

  Future<void> loadAll() async {
    final out = <WealthRecord>[];
    for (final c in _store.chunks) {
      if (c.collectionName != kWealthCollection) continue;
      if (c.metadata['type'] != kWealthTypeTag) continue;
      final data = c.metadata['data'];
      if (data is! Map) continue;
      try {
        out.add(WealthRecord.fromJson(Map<String, dynamic>.from(data)));
      } catch (_) {}
    }
    out.sort((a, b) => b.date.compareTo(a.date));
    _records = List.unmodifiable(out);
    _loaded = true;
    notifyListeners();
  }

  bool get isLoaded => _loaded;

  // -------------------------------------------------------------- reads

  List<WealthRecord> getAllRecords() => _records;

  int get count => _records.length;

  WealthRecord? findById(String id) {
    for (final r in _records) {
      if (r.id == id) return r;
    }
    return null;
  }

  List<WealthRecord> searchRecords(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _records;
    return _records
        .where((r) => r.toSearchText().toLowerCase().contains(q))
        .toList();
  }

  List<String> getCurrencies() {
    final set = <String>{for (final r in _records) r.currency};
    final list = set.toList()..sort();
    return list;
  }

  Map<String, WealthRecord> latestPerAsset() {
    final out = <String, WealthRecord>{};
    for (final r in _records) {
      final cur = out[r.assetKey];
      if (cur == null || r.date.isAfter(cur.date)) {
        out[r.assetKey] = r;
      }
    }
    return out;
  }

  Map<String, double> getCurrentTotalByCurrency() {
    final out = <String, double>{};
    for (final r in latestPerAsset().values) {
      out.update(r.currency, (v) => v + r.amount, ifAbsent: () => r.amount);
    }
    return out;
  }

  Map<String, double> getAllocationByType({required String currency}) {
    final out = <String, double>{};
    for (final r in latestPerAsset().values) {
      if (r.currency != currency) continue;
      out.update(r.assetType, (v) => v + r.amount, ifAbsent: () => r.amount);
    }
    return out;
  }

  WealthStats getStats({required String currency}) {
    final alloc = getAllocationByType(currency: currency);
    final total = alloc.values.fold<double>(0, (a, b) => a + b);
    final assetCount =
        latestPerAsset().values.where((r) => r.currency == currency).length;
    return WealthStats(
      currency: currency,
      totalNetWorth: total,
      assetCount: assetCount,
      allocationByType: alloc,
    );
  }

  List<NetWorthSnapshot> getNetWorthHistory({
    required String currency,
    int? lastNDays,
  }) {
    final inCurrency =
        _records.where((r) => r.currency == currency).toList();
    if (inCurrency.isEmpty) return const [];

    final dates = <DateTime>{};
    for (final r in inCurrency) {
      dates.add(DateTime(r.date.year, r.date.month, r.date.day));
    }
    final sortedDates = dates.toList()..sort();

    DateTime? cutoff;
    if (lastNDays != null) {
      final now = DateTime.now();
      cutoff = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: lastNDays - 1));
    }

    final out = <NetWorthSnapshot>[];
    for (final d in sortedDates) {
      if (cutoff != null && d.isBefore(cutoff)) continue;
      final latestUpTo = <String, WealthRecord>{};
      for (final r in inCurrency) {
        final rd = DateTime(r.date.year, r.date.month, r.date.day);
        if (rd.isAfter(d)) continue;
        final cur = latestUpTo[r.assetKey];
        if (cur == null || rd.isAfter(cur.date)) {
          latestUpTo[r.assetKey] = r;
        }
      }
      final total =
          latestUpTo.values.fold<double>(0, (sum, r) => sum + r.amount);
      out.add(NetWorthSnapshot(date: d, total: total));
    }
    return out;
  }

  // ------------------------------------------------------------- writes

  Future<WealthRecord> saveRecord(WealthRecord record) async {
    final isNew = record.id.isEmpty;
    final finalRecord =
        isNew ? record.copyWith(id: _generateId()) : record;

    if (!isNew) {
      await _store.deleteById(finalRecord.id);
    }

    final chunk = DocChunk(
      id: finalRecord.id,
      docName: 'wealth_${finalRecord.id}',
      chunkIndex: 0,
      text: finalRecord.toSearchText(),
      collectionName: kWealthCollection,
      metadata: {
        'type': kWealthTypeTag,
        'data': finalRecord.toJson(),
      },
    );

    await _store.add(chunk, _emptyEmbedding(chunk.text));
    await loadAll();
    return finalRecord;
  }

  Future<bool> deleteRecord(String id) async {
    final before = _records.length;
    await _store.deleteById(id);
    await loadAll();
    return _records.length < before;
  }

  // ✅ 修正：deleteAllRecords 的 for 迴圈正確關閉
  Future<int> deleteAllRecords() async {
    final ids = _records.map((r) => r.id).toList();
    for (final id in ids) {
      await _store.deleteById(id);
    }
    await loadAll();
    return ids.length;
  }

  // ---------------------------------------------------------- internals

  String _generateId() =>
      'wealth_${DateTime.now().microsecondsSinceEpoch}';

  Map<String, dynamic> getMonthlyReport({
    required String currency,
    required int year,
    required int month,
  }) {
    final inCurrency =
        _records.where((r) => r.currency == currency).toList();
    if (inCurrency.isEmpty) {
      return {'thisMonthTotal': 0.0, 'lastMonthTotal': 0.0};
    }

    final thisMonthStart = DateTime(year, month, 1);
    final thisMonthEnd = DateTime(year, month + 1, 0);
    final lastMonthStart = DateTime(year, month - 1, 1);
    final lastMonthEnd = DateTime(year, month, 0);

    double thisMonthTotal = 0.0;
    double lastMonthTotal = 0.0;

    for (final r in inCurrency) {
      if (!r.date.isBefore(thisMonthStart) &&
          !r.date.isAfter(thisMonthEnd)) {
        thisMonthTotal += r.amount;
      }
      if (!r.date.isBefore(lastMonthStart) &&
          !r.date.isAfter(lastMonthEnd)) {
        lastMonthTotal += r.amount;
      }
    }

    return {
      'thisMonthTotal': thisMonthTotal,
      'lastMonthTotal': lastMonthTotal,
    };
  }

  String exportToCsv() {
    if (_records.isEmpty) return 'No records';
    final buffer = StringBuffer();
    buffer.writeln('Date,AssetType,AssetName,Currency,Amount,Note');
    for (final r in _records) {
      buffer.writeln(
        '${r.date.toIso8601String().split('T')[0]},'
        '${r.assetType},'
        '${r.assetName.replaceAll(',', ' ')},'
        '${r.currency},'
        '${r.amount},'
        '${r.notes.replaceAll(',', ' ')}',
      );
    }
    return buffer.toString();
  }

  List<double> _emptyEmbedding(String _) => List.filled(384, 0.0);
}

