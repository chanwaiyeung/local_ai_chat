// lib/screens/church/person_history_screen.dart
import 'package:flutter/material.dart';
import '../../controllers/church/care_controller.dart';
import '../../models/church/care_case.dart';
import '../../models/church/visit_log.dart';

/// Person-centric drill-down: shows ALL visits + ALL cases (active and
/// closed) for one person across their entire pastoral care history.
class PersonHistoryScreen extends StatefulWidget {
  const PersonHistoryScreen({
    super.key,
    required this.controller,
    required this.personName,
  });

  final CareController controller;
  final String personName;

  @override
  State<PersonHistoryScreen> createState() => _PersonHistoryScreenState();
}

class _PersonHistoryScreenState extends State<PersonHistoryScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ctl = widget.controller;
    final visits = ctl.visitsForPerson(widget.personName);
    final cases = ctl.casesForPerson(widget.personName);

    final phone = cases
        .map((c) => c.memberPhone)
        .firstWhere((p) => p.isNotEmpty, orElse: () => '');

    final activeCases =
        cases.where((c) => c.status == CareStatus.active).toList();
    final closedCases =
        cases.where((c) => c.status == CareStatus.closed).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.personName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _HeaderCard(
            name: widget.personName,
            phone: phone,
            visitCount: visits.length,
            activeCount: activeCases.length,
            closedCount: closedCases.length,
          ),
          if (cases.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionLabel(label: '關懷案件', count: cases.length),
            const SizedBox(height: 4),
            ...cases.map((c) => _CaseSummaryTile(c: c)),
          ],
          const SizedBox(height: 16),
          _SectionLabel(label: '探訪時間軸', count: visits.length),
          const SizedBox(height: 4),
          if (visits.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '尚未有任何探訪紀錄',
                style: TextStyle(
                    color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
            )
          else
            ...visits.map((v) => _VisitTile(visit: v, controller: ctl)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.name,
    required this.phone,
    required this.visitCount,
    required this.activeCount,
    required this.closedCount,
  });

  final String name;
  final String phone;
  final int visitCount;
  final int activeCount;
  final int closedCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      Colors.deepPurple.withValues(alpha: 0.15),
                  child: const Icon(Icons.person, color: Colors.deepPurple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      if (phone.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.phone,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(phone,
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[700])),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _StatChip(
                  icon: Icons.event_note,
                  label: '$visitCount 次探訪',
                  color: Colors.indigo,
                ),
                if (activeCount > 0)
                  _StatChip(
                    icon: Icons.local_fire_department,
                    label: '$activeCount 個進行中',
                    color: Colors.orange,
                  ),
                if (closedCount > 0)
                  _StatChip(
                    icon: Icons.archive_outlined,
                    label: '$closedCount 個已結案',
                    color: Colors.grey,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Text(
        '$label ($count)',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _CaseSummaryTile extends StatelessWidget {
  const _CaseSummaryTile({required this.c});
  final CareCase c;

  @override
  Widget build(BuildContext context) {
    final isClosed = c.status == CareStatus.closed;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        dense: true,
        leading: Icon(
          isClosed ? Icons.archive_outlined : Icons.local_fire_department,
          color: isClosed ? Colors.grey : Colors.orange,
        ),
        title: Text(c.reason),
        subtitle: Text(
          '${CaseType.label(c.caseType)} · ${CareUrgency.label(c.urgency)}優先 · 開立 ${_fmt(c.createdAt)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          isClosed ? '已結案' : '進行中',
          style: TextStyle(
            color: isClosed ? Colors.grey : Colors.orange,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.year}/${d.month}/${d.day.toString().padLeft(2, '0')}';
}

class _VisitTile extends StatelessWidget {
  const _VisitTile({required this.visit, required this.controller});
  final VisitLog visit;
  final CareController controller;

  @override
  Widget build(BuildContext context) {
    final relatedCase = controller.findCase(visit.caseId);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _conditionIcon(visit.condition),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${visit.visitedBy} · ${VisitMethod.label(visit.method)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Text(
                  _fmt(visit.visitDate),
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(visit.summary, style: const TextStyle(fontSize: 13)),
            if (relatedCase != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.folder_outlined,
                      size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      relatedCase.reason +
                          (relatedCase.status == CareStatus.closed
                              ? '(已結案)'
                              : ''),
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _conditionIcon(String condition) {
    switch (condition) {
      case MemberCondition.good:
        return const Icon(Icons.sentiment_satisfied,
            color: Colors.green, size: 22);
      case MemberCondition.worsening:
        return const Icon(Icons.sentiment_dissatisfied,
            color: Colors.red, size: 22);
      case MemberCondition.concern:
      default:
        return const Icon(Icons.sentiment_neutral,
            color: Colors.orange, size: 22);
    }
  }

  static String _fmt(DateTime d) =>
      '${d.year}/${d.month}/${d.day.toString().padLeft(2, '0')}';
}

