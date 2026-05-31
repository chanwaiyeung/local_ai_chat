// lib/screens/church/case_detail_screen.dart
import 'package:flutter/material.dart';
import '../../controllers/church/care_controller.dart';
import '../../models/church/care_case.dart';
import '../../models/church/visit_log.dart';
import '../../widgets/church/case_form_dialog.dart';
import '../../widgets/church/visit_log_dialog.dart';

/// Detail view for a single [CareCase]: full case info card + visit timeline.
class CaseDetailScreen extends StatefulWidget {
  const CaseDetailScreen({
    super.key,
    required this.controller,
    required this.caseId,
  });

  final CareController controller;
  final String caseId;

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
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

  Future<void> _editCase(CareCase c) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CaseFormDialog(
        existing: c,
        onSave: (caseObj) => widget.controller.saveCase(caseObj),
        onDelete: () async {
          await widget.controller.deleteCase(c.id);
          if (mounted) Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _addVisit(CareCase c) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => VisitLogDialog(
        caseObj: c,
        onSave: (v) => widget.controller.saveVisit(v),
        onCloseCase: () => widget.controller.closeCase(c.id),
      ),
    );
  }

  Future<void> _editVisit(CareCase c, VisitLog v) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => VisitLogDialog(
        caseObj: c,
        existing: v,
        onSave: (vl) => widget.controller.saveVisit(vl),
        onDelete: () => widget.controller.deleteVisit(v.id),
      ),
    );
  }

  Future<void> _toggleClose(CareCase c) async {
    if (c.status == CareStatus.closed) {
      await widget.controller.reopenCase(c.id);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('結案'),
        content: Text('將「${c.memberName}」這個案件標記為已結案?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('結案')),
        ],
      ),
    );
    if (ok == true) {
      await widget.controller.closeCase(c.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller.findCase(widget.caseId);
    if (c == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('找不到此案件(可能已刪除)')),
      );
    }
    final visits = widget.controller.visitsForCase(c.id);
    final alert = widget.controller.alertLevel(c);
    final isClosed = c.status == CareStatus.closed;

    return Scaffold(
      appBar: AppBar(
        title: Text(c.memberName),
        actions: [
          IconButton(
            tooltip: '編輯案件',
            icon: const Icon(Icons.edit),
            onPressed: () => _editCase(c),
          ),
          IconButton(
            tooltip: isClosed ? '重新開啟' : '結案',
            icon: Icon(isClosed ? Icons.refresh : Icons.archive_outlined),
            onPressed: () => _toggleClose(c),
          ),
        ],
      ),
      floatingActionButton: isClosed
          ? null
          : FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('記探訪'),
              onPressed: () => _addVisit(c),
            ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _CaseInfoCard(caseObj: c, alert: alert, controller: widget.controller),
          const SizedBox(height: 16),
          Text('探訪記錄 (${visits.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (visits.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.history, size: 40, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text('尚未有探訪記錄',
                        style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            )
          else
            ...visits.map((v) => _VisitCard(
                  visit: v,
                  onTap: () => _editVisit(c, v),
                )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _CaseInfoCard extends StatelessWidget {
  const _CaseInfoCard({
    required this.caseObj,
    required this.alert,
    required this.controller,
  });

  final CareCase caseObj;
  final CareAlertLevel alert;
  final CareController controller;

  Color _alertColor() {
    switch (alert) {
      case CareAlertLevel.red:
        return Colors.red.shade700;
      case CareAlertLevel.yellow:
        return Colors.orange.shade800;
      case CareAlertLevel.green:
        return Colors.green.shade700;
      case CareAlertLevel.closed:
        return Colors.grey.shade600;
    }
  }

  String _alertEmoji() {
    switch (alert) {
      case CareAlertLevel.red:
        return '🔴';
      case CareAlertLevel.yellow:
        return '🟡';
      case CareAlertLevel.green:
        return '🟢';
      case CareAlertLevel.closed:
        return '📁';
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = controller.daysSinceLastTouch(caseObj);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(_alertEmoji(), style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(caseObj.reason,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _alertColor().withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${CareUrgency.label(caseObj.urgency)}優先',
                    style: TextStyle(
                        color: _alertColor(), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (caseObj.memberPhone.isNotEmpty)
              _infoRow(Icons.phone, '電話', caseObj.memberPhone),
            if (caseObj.createdBy.isNotEmpty)
              _infoRow(Icons.person_outline, '開立者', caseObj.createdBy),
            _infoRow(Icons.event_outlined, '開立日期',
                _fmtDate(caseObj.createdAt)),
            if (days != null)
              _infoRow(
                Icons.access_time,
                '上次探訪',
                days == 0 ? '今天' : '$days 天前',
                valueColor: _alertColor(),
              ),
            if (caseObj.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('備註', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(caseObj.notes, style: TextStyle(color: Colors.grey[700])),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          SizedBox(
              width: 70,
              child:
                  Text(label, style: TextStyle(color: Colors.grey[700]))),
          Expanded(
            child: Text(value,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                )),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.visit, required this.onTap});

  final VisitLog visit;
  final VoidCallback onTap;

  Color _conditionColor() {
    switch (visit.condition) {
      case MemberCondition.worsening:
        return Colors.red.shade700;
      case MemberCondition.concern:
        return Colors.orange.shade800;
      case MemberCondition.good:
      default:
        return Colors.green.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(_fmtDate(visit.visitDate),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text(VisitMethod.label(visit.method),
                      style:
                          TextStyle(color: Colors.grey[700], fontSize: 12)),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _conditionColor().withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      MemberCondition.label(visit.condition),
                      style: TextStyle(
                          color: _conditionColor(),
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(visit.visitedBy,
                  style: TextStyle(color: Colors.grey[800], fontSize: 13)),
              const SizedBox(height: 4),
              Text(visit.summary),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}


