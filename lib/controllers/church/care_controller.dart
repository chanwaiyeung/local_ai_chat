// lib/controllers/church/care_controller.dart
import 'package:flutter/foundation.dart';
import '../../models/church/care_case.dart';
import '../../models/church/visit_log.dart';
import '../../services/vector_store.dart';

/// Alert color for a [CareCase] based on time since last touch + urgency SLA.
/// Computed on the fly, not persisted.
enum CareAlertLevel {
  red,    // overdue: days since last touch >= SLA days
  yellow, // approaching: >= half SLA
  green,  // recently visited
  closed, // case is closed
}

/// Single controller managing both [CareCase] and [VisitLog]. They are tightly
/// coupled (visits FK to cases, dashboard needs both) so splitting adds friction
/// without benefit.
///
/// Follows the same Pattern A (delete + add) as [BookController].
class CareController extends ChangeNotifier {
  CareController(this._store);

  static const String kCaseCollection = 'ChurchCareCases';
  static const String kCaseTypeTag = 'church_care_case';
  static const String kVisitCollection = 'ChurchVisitLogs';
  static const String kVisitTypeTag = 'church_visit_log';

  final VectorStore _store;
  List<CareCase> _cases = const [];
  List<VisitLog> _visits = const [];
  bool _loaded = false;

  // ---------- lifecycle ----------
  Future<void> loadAll() async {
    final cases = <CareCase>[];
    final visits = <VisitLog>[];
    for (final c in _store.chunks) {
      if (c.collectionName == kCaseCollection &&
          c.metadata['type'] == kCaseTypeTag) {
        final data = c.metadata['data'];
        if (data is! Map) continue;
        try {
          cases.add(CareCase.fromJson(Map<String, dynamic>.from(data)));
        } catch (_) {}
      } else if (c.collectionName == kVisitCollection &&
          c.metadata['type'] == kVisitTypeTag) {
        final data = c.metadata['data'];
        if (data is! Map) continue;
        try {
          visits.add(VisitLog.fromJson(Map<String, dynamic>.from(data)));
        } catch (_) {}
      }
    }

    // Active cases first, then by createdAt desc within each group
    cases.sort((a, b) {
      if (a.status != b.status) {
        return a.status == CareStatus.active ? -1 : 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    // Visits newest first
    visits.sort((a, b) => b.visitDate.compareTo(a.visitDate));

    _cases = List.unmodifiable(cases);
    _visits = List.unmodifiable(visits);
    _loaded = true;
    notifyListeners();
  }

  bool get isLoaded => _loaded;

  // ---------- reads: cases ----------
  List<CareCase> get allCases => _cases;
  List<CareCase> get activeCases =>
      _cases.where((c) => c.status == CareStatus.active).toList();
  List<CareCase> get closedCases =>
      _cases.where((c) => c.status == CareStatus.closed).toList();

  CareCase? findCase(String id) {
    for (final c in _cases) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<CareCase> searchCases(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _cases;
    return _cases
        .where((c) => c.toSearchText().toLowerCase().contains(q))
        .toList();
  }

  // ---------- reads: visits ----------
  List<VisitLog> get allVisits => _visits;

  List<VisitLog> visitsForCase(String caseId) =>
      _visits.where((v) => v.caseId == caseId).toList();

  /// Most recent visit for a case, or null if no visits yet.
  VisitLog? lastVisitFor(String caseId) {
    VisitLog? latest;
    for (final v in _visits) {
      if (v.caseId != caseId) continue;
      if (latest == null || v.visitDate.isAfter(latest.visitDate)) {
        latest = v;
      }
    }
    return latest;
  }

  // ---------- derived: SLA / alert level ----------

  /// Alert color for the case dashboard.
  /// red if overdue, yellow if approaching, green otherwise.
  CareAlertLevel alertLevel(CareCase c) {
    if (c.status == CareStatus.closed) return CareAlertLevel.closed;
    final reference = lastVisitFor(c.id)?.visitDate ?? c.createdAt;
    final daysSince = DateTime.now().difference(reference).inDays;
    final sla = CareUrgency.slaDays(c.urgency);
    if (daysSince >= sla) return CareAlertLevel.red;
    if (daysSince * 2 >= sla) return CareAlertLevel.yellow;
    return CareAlertLevel.green;
  }

  /// Days since last visit (or case creation if never visited).
  /// Null if case is closed.
  int? daysSinceLastTouch(CareCase c) {
    if (c.status == CareStatus.closed) return null;
    final reference = lastVisitFor(c.id)?.visitDate ?? c.createdAt;
    return DateTime.now().difference(reference).inDays;
  }

  List<CareCase> casesByAlert(CareAlertLevel level) {
    if (level == CareAlertLevel.closed) return closedCases;
    return activeCases.where((c) => alertLevel(c) == level).toList();
  }

  int get redCount => casesByAlert(CareAlertLevel.red).length;
  int get yellowCount => casesByAlert(CareAlertLevel.yellow).length;
  int get greenCount => casesByAlert(CareAlertLevel.green).length;
  int get closedCount => closedCases.length;
  int get activeCount => activeCases.length;

  // ---------- type-based filters (B2 dashboard tabs) ----------
  List<CareCase> activeCasesByType(String caseType) =>
      activeCases.where((c) => c.caseType == caseType).toList();

  int activeCountByType(String caseType) =>
      activeCasesByType(caseType).length;

  int redCountByType(String caseType) => activeCasesByType(caseType)
      .where((c) => alertLevel(c) == CareAlertLevel.red)
      .length;

  List<CareCase> casesByAlertAndType(CareAlertLevel level, String caseType) {
    if (level == CareAlertLevel.closed) {
      return closedCases.where((c) => c.caseType == caseType).toList();
    }
    return activeCasesByType(caseType)
        .where((c) => alertLevel(c) == level)
        .toList();
  }

  // ---------- writes: case (Pattern A: delete + add) ----------
  Future<CareCase> saveCase(CareCase caseObj) async {
    final isNew = caseObj.id.isEmpty;
    final finalCase =
        isNew ? caseObj.copyWith(id: _generateCaseId()) : caseObj;

    if (!isNew) {
      await _store.deleteById(finalCase.id);
    }

    final chunk = DocChunk(
      id: finalCase.id,
      docName: 'care_case_${finalCase.id}',
      chunkIndex: 0,
      text: finalCase.toSearchText(),
      embedding: const [],
      collectionName: kCaseCollection,
      metadata: {
        'type': kCaseTypeTag,
        'data': finalCase.toJson(),
      },
    );

    await _store.add(chunk);
    await _store.save();
    await loadAll();
    return finalCase;
  }

  /// Close a case without changing other fields.
  Future<void> closeCase(String caseId) async {
    final existing = findCase(caseId);
    if (existing == null) return;
    await saveCase(existing.copyWith(status: CareStatus.closed));
  }

  /// Reopen a closed case.
  Future<void> reopenCase(String caseId) async {
    final existing = findCase(caseId);
    if (existing == null) return;
    await saveCase(existing.copyWith(status: CareStatus.active));
  }

  /// Delete a case AND all its associated visits (cascade).
  Future<void> deleteCase(String caseId) async {
    for (final v in visitsForCase(caseId)) {
      await _store.deleteById(v.id);
    }
    await _store.deleteById(caseId);
    await _store.save();
    await loadAll();
  }

  // ---------- writes: visit (Pattern A: delete + add) ----------
  Future<VisitLog> saveVisit(VisitLog visit) async {
    final isNew = visit.id.isEmpty;
    final finalVisit =
        isNew ? visit.copyWith(id: _generateVisitId()) : visit;

    if (!isNew) {
      await _store.deleteById(finalVisit.id);
    }

    final chunk = DocChunk(
      id: finalVisit.id,
      docName: 'visit_log_${finalVisit.id}',
      chunkIndex: 0,
      text: finalVisit.toSearchText(),
      embedding: const [],
      collectionName: kVisitCollection,
      metadata: {
        'type': kVisitTypeTag,
        'data': finalVisit.toJson(),
      },
    );

    await _store.add(chunk);
    await _store.save();
    await loadAll();
    return finalVisit;
  }

  Future<void> deleteVisit(String visitId) async {
    await _store.deleteById(visitId);
    await _store.save();
    await loadAll();
  }

  // ---------- id generation ----------
  String _generateCaseId() =>
      'care_case_${DateTime.now().microsecondsSinceEpoch}';
  String _generateVisitId() =>
      'visit_log_${DateTime.now().microsecondsSinceEpoch}';
}
