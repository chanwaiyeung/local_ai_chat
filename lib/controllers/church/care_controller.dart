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

  // ---------- person-centric history (B3) ----------

  /// Unique persons across all cases (active + closed), sorted by last
  /// visit date desc; never-visited persons go to the end.
  List<PersonSummary> personHistorySorted() {
    final byName = <String, _PersonAccum>{};

    for (final c in _cases) {
      final name = c.memberName.trim();
      if (name.isEmpty) continue;

      final visits = visitsForCase(c.id);
      final caseLastVisit = visits.isEmpty
          ? null
          : visits.reduce(
              (a, b) => a.visitDate.isAfter(b.visitDate) ? a : b);

      final accum = byName.putIfAbsent(name, () => _PersonAccum(name: name));
      if (accum.phone.isEmpty && c.memberPhone.isNotEmpty) {
        accum.phone = c.memberPhone;
      }
      accum.caseIds.add(c.id);
      accum.caseTypes.add(c.caseType);
      accum.totalVisits += visits.length;
      if (c.status == CareStatus.active) accum.activeCaseCount++;
      if (caseLastVisit != null) {
        if (accum.lastVisit == null ||
            caseLastVisit.visitDate.isAfter(accum.lastVisit!.visitDate)) {
          accum.lastVisit = caseLastVisit;
        }
      }
      if (accum.earliestCaseAt == null ||
          c.createdAt.isBefore(accum.earliestCaseAt!)) {
        accum.earliestCaseAt = c.createdAt;
      }
    }

    final list = byName.values
        .map((a) => PersonSummary(
              name: a.name,
              phone: a.phone,
              caseIds: List.unmodifiable(a.caseIds),
              caseTypes: Set.unmodifiable(a.caseTypes),
              lastVisit: a.lastVisit,
              totalVisits: a.totalVisits,
              activeCaseCount: a.activeCaseCount,
              earliestCaseAt: a.earliestCaseAt ?? DateTime.now(),
            ))
        .toList();

    list.sort((a, b) {
      if (a.lastVisit == null && b.lastVisit == null) {
        return b.earliestCaseAt.compareTo(a.earliestCaseAt);
      }
      if (a.lastVisit == null) return 1;
      if (b.lastVisit == null) return -1;
      return b.lastVisit!.visitDate.compareTo(a.lastVisit!.visitDate);
    });

    return list;
  }

  /// All visits for a given person name (across all their cases).
  List<VisitLog> visitsForPerson(String name) {
    final trimmed = name.trim();
    final caseIds = _cases
        .where((c) => c.memberName.trim() == trimmed)
        .map((c) => c.id)
        .toSet();
    final result =
        _visits.where((v) => caseIds.contains(v.caseId)).toList();
    result.sort((a, b) => b.visitDate.compareTo(a.visitDate));
    return result;
  }

  /// All cases (active + closed) for a given person name.
  List<CareCase> casesForPerson(String name) {
    final trimmed = name.trim();
    return _cases.where((c) => c.memberName.trim() == trimmed).toList();
  }

  int get personHistoryCount => personHistorySorted().length;

  // ---------- id generation ----------
  String _generateCaseId() =>
      'care_case_${DateTime.now().microsecondsSinceEpoch}';
  String _generateVisitId() =>
      'visit_log_${DateTime.now().microsecondsSinceEpoch}';
}

// ============================================================================
// Person-centric history (B3) data classes
// ============================================================================

class _PersonAccum {
  _PersonAccum({required this.name});
  final String name;
  String phone = '';
  final List<String> caseIds = [];
  final Set<String> caseTypes = {};
  VisitLog? lastVisit;
  int totalVisits = 0;
  int activeCaseCount = 0;
  DateTime? earliestCaseAt;
}

/// Aggregate view of one person across all their cases (active + closed).
class PersonSummary {
  const PersonSummary({
    required this.name,
    required this.phone,
    required this.caseIds,
    required this.caseTypes,
    required this.lastVisit,
    required this.totalVisits,
    required this.activeCaseCount,
    required this.earliestCaseAt,
  });

  final String name;
  final String phone;
  final List<String> caseIds;
  final Set<String> caseTypes;
  final VisitLog? lastVisit;
  final int totalVisits;
  final int activeCaseCount;
  final DateTime earliestCaseAt;

  bool get hasActiveCase => activeCaseCount > 0;
  bool get hasMultipleTypes => caseTypes.length > 1;

  String get primaryCaseType {
    if (caseTypes.contains(CaseType.member)) return CaseType.member;
    if (caseTypes.contains(CaseType.newcomer)) return CaseType.newcomer;
    return CaseType.member;
  }
}
