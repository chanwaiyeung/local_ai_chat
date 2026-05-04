// lib/controllers/wealth_controller.dart
//
// Phase 7.0'a (v2.4) — Investment / wealth controller.
// VectorStore API: Pattern A (matches ExpenseController):
//   - store.add(chunk, embedding)
//   - store.deleteById(id)
//   - store.chunks (filter by collectionName)
//
// Diff vs Antigravity local v0:
//   * collection name 'wealth' -> 'Wealth' (consistent with
//     'Contacts' / 'Expenses' / 'Health')
//   * latestPerAsset() — group successive valuations of same asset, take latest
//   * getCurrentTotalByCurrency() — never sums across currencies
//   * getAllocationByType({currency}) — only sums latest-per-asset
//   * getStats({currency}) — bundle for UI
//   * getNetWorthHistory({currency, lastNDays}) — step-function timeseries
//   * getCurrencies() — distinct currencies for picker
//   * count getter, deleteAllRecords()
//   * loadAll() public + NOT called from constructor
//     (caller does `await ctl.loadAll()` once, mirroring ExpenseController)

import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/wealth_record.dart';
import '../services/vector_store.dart';

class WealthController extends ChangeNotifier {
  WealthController(this._store);

  static const String kWealthCollection = 'Wealth';
  static const String kWealthTypeTag = 'personal_hub_wealth';

  final VectorStore _store;
  final math.Random _rng = math.Random();
  List<WealthRecord> _records = const [];
  bool _loaded = false;

  // ---------------------------------------------------------- lifecycle

  /// Reads all wealth chunks from the store. Call once after construction.
  /// Subsequent saves/deletes refresh the cache automatically.
  Future<void> loadAll() async {
    final out = <WealthRecord>[];
    for (final c in _store.chunks) {
      if (c.collectionName != kWealthCollection) continue;
      if (c.metadata['type'] != kWealthTypeTag) continue;
      final data = c.metadata['data'];
      if (data is! Map) continue;
      try {
        out.add(WealthRecord.fromJson(Map<String, dynamic>.from(data)));
      } catch (_) {
        // Skip a malformed row rather than throwing.
      }
    }
    out.sort((a, b) => b.date.compareTo(a.date));
    _records = List.unmodifiable(out);
    _loaded = true;
    notifyListeners();
  }

  bool get isLoaded => _loaded;

  // -------------------------------------------------------------- reads

  /// All records, newest-first. Returns the cached list (call [loadAll] first).
  List<WealthRecord> getAllRecords() => _records;

  int get count => _records.length;

  WealthRecord? findById(String id) {
    for (final r in _records) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// Substring search over [WealthRecord.toSearchText]. Empty query → all.
  List<WealthRecord> searchRecords(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _records;
    return _records
        .where((r) => r.toSearchText().toLowerCase().contains(q))
        .toList();
  }

  /// Distinct currencies present, sorted.
  List<String> getCurrencies() {
    final set = <String>{for (final r in _records) r.currency};
    final list = set.toList()..sort();
    return list;
  }

  /// For each [WealthRecord.assetKey] keep only the record with the
  /// greatest [date]. This is what "current value" means.
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

  /// Sum of latest values, grouped by currency. Never mixes currencies.
  Map<String, double> getCurrentTotalByCurrency() {
    final out = <String, double>{};
    for (final r in latestPerAsset().values) {
      out.update(r.currency, (v) => v + r.amount, ifAbsent: () => r.amount);
    }
    return out;
  }

  /// Allocation by [assetType] within a single [currency], using latest
  /// valuation per asset.
  Map<String, double> getAllocationByType({required String currency}) {
    final out = <String, double>{};
    for (final r in latestPerAsset().values) {
      if (r.currency != currency) continue;
      out.update(r.assetType, (v) => v + r.amount, ifAbsent: () => r.amount);
    }
    return out;
  }

  /// Bundle for the screen.
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

  /// Net-worth time series for [currency]. For each distinct date d in the
  /// records, total(d) = sum over assets of "latest value as of d".
  /// Optionally restrict to last N days.
  List<NetWorthSnapshot> getNetWorthHistory({
    required String currency,
    int? lastNDays,
  }) {
    final inCurrency = _records.where((r) => r.currency == currency).toList();
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
      // For each asset, find latest valuation up to and including d.
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

  /// Insert or update. Generates id when input id is empty. Refreshes cache.
  Future<WealthRecord> saveRecord(WealthRecord record) async {
    final isNew = record.id.isEmpty;
    final finalRecord = isNew ? record.copyWith(id: _generateId()) : record;

    if (!isNew) {
      // Replace prior chunk with this id (if any).
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

  /// Wipes every record in this collection. Returns how many were removed.
  Future<int> deleteAllRecords() async {
    final ids = _records.map((r) => r.id).toList();
    for (final id in ids) {
      await _store.deleteById(id);
    }
    await loadAll();
    return ids.length;
  }

  // ---------------------------------------------------------- internals

  String _generateId() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final rand = _rng.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0');
    return 'wealth_${ts}_$rand';
  }

  /// Phase 7 has no real Wealth embeddings; matches ExpenseController's
  /// `_generateDummyEmbedding`. When real embeddings ship later we'll plug
  /// EmbeddingService here without changing the API surface.
  List<double> _emptyEmbedding(String _) => List.filled(384, 0.0);
}
