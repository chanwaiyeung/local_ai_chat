// lib/screens/church/care_dashboard_screen.dart
import 'package:flutter/material.dart';
import '../../controllers/church/care_controller.dart';
import '../../models/church/care_case.dart';
import '../../models/church/visit_log.dart';
import '../../widgets/church/case_form_dialog.dart';
import '../../widgets/church/visit_log_dialog.dart';
import 'case_detail_screen.dart';
import 'person_history_screen.dart';

/// Pastoral Care Coordination Dashboard.
/// Top tabs split active cases by [CaseType] (member / newcomer);
/// a third tab shows closed cases (will become person-centric history in B3).
class CareDashboardScreen extends StatefulWidget {
  const CareDashboardScreen({super.key, required this.controller});

  final CareController controller;

  @override
  State<CareDashboardScreen> createState() => _CareDashboardScreenState();
}

class _CareDashboardScreenState extends State<CareDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _searchCtrl;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChange);
    _searchCtrl = TextEditingController();
    widget.controller.addListener(_onChange);
    if (!widget.controller.isLoaded) {
      widget.controller.loadAll();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChange);
    _tabController.dispose();
    widget.controller.removeListener(_onChange);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  void _onTabChange() {
    // Rebuild so FAB context (label / visibility) updates on tab switch.
    if (mounted) setState(() {});
  }

  // ---------- form / dialog wrappers ----------

  Future<void> _openCaseForm(
      {CareCase? existing, String? defaultType}) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CaseFormDialog(
        existing: existing,
        defaultType: defaultType,
        onSave: (caseObj) => widget.controller.saveCase(caseObj),
        onDelete: existing == null
            ? null
            : () => widget.controller.deleteCase(existing.id),
      ),
    );
  }

  void _logVisit(CareCase c) {
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => VisitLogDialog(
        caseObj: c,
        onSave: (v) => widget.controller.saveVisit(v),
        onCloseCase: () => widget.controller.closeCase(c.id),
      ),
    );
  }

  void _openCaseDetail(CareCase c) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => CaseDetailScreen(
        controller: widget.controller,
        caseId: c.id,
      ),
    ));
  }

  Future<void> _confirmClose(CareCase c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(/* l10n: closeCaseConfirmTitle */ '結案'),
        content: Text(/* l10n: closeCaseConfirmContent */ '將「${c.memberName}」這個案件標記為已結案?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(/* l10n: commonCancel */ '取消')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(/* l10n: closeCase */ '結案')),
        ],
      ),
    );
    if (ok == true) {
      await widget.controller.closeCase(c.id);
    }
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    final ctl = widget.controller;
    final searching = _searchQuery.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(/* l10n: careDashboardTitle */ '教會關懷中央看版'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: /* l10n: tabMemberActive */ '會友 (${ctl.activeCountByType(CaseType.member)})'),
            Tab(text: /* l10n: tabNewcomerActive */ '新朋友 (${ctl.activeCountByType(CaseType.newcomer)})'),
            Tab(text: /* l10n: tabVisitedHistory */ '已探訪者 (${ctl.personHistorySorted().length})'),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
      body: !ctl.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: /* l10n: careSearchHint */ '搜尋會友姓名 / 緣由 / 備註',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTypeTab(ctl, CaseType.member,
                          searching: searching),
                      _buildTypeTab(ctl, CaseType.newcomer,
                          searching: searching),
                      _buildPersonHistoryTab(ctl, searching: searching),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget? _buildFab() {
    if (_tabController.index == 2) return null;
    final type =
        _tabController.index == 0 ? CaseType.member : CaseType.newcomer;
    return FloatingActionButton.extended(
      icon: const Icon(Icons.add),
      label: Text(/* l10n: addNewCaseLabel */ '新增${CaseType.label(type)}案件'),
      onPressed: () => _openCaseForm(defaultType: type),
    );
  }

  Widget _buildTypeTab(CareController ctl, String caseType,
      {required bool searching}) {
    if (searching) {
      final matches = ctl
          .searchCases(_searchQuery)
          .where((c) =>
              c.caseType == caseType && c.status == CareStatus.active)
          .toList();
      return _searchList(matches, ctl);
    }

    final red = ctl.casesByAlertAndType(CareAlertLevel.red, caseType);
    final yellow = ctl.casesByAlertAndType(CareAlertLevel.yellow, caseType);
    final green = ctl.casesByAlertAndType(CareAlertLevel.green, caseType);

    if (red.isEmpty && yellow.isEmpty && green.isEmpty) {
      return _emptyState(caseType);
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: [
        if (red.isNotEmpty)
          _AlertSection(
            emoji: '🔴',
            title: /* l10n: alertRedTitle */ '需要立刻處理',
            color: Colors.red.shade700,
            cases: red,
            controller: ctl,
            initiallyExpanded: true,
            onEdit: (c) => _openCaseForm(existing: c),
            onVisit: _logVisit,
            onDetail: _openCaseDetail,
            onClose: _confirmClose,
          ),
        if (yellow.isNotEmpty)
          _AlertSection(
            emoji: '🟡',
            title: /* l10n: alertYellowTitle */ '即將需要安排',
            color: Colors.orange.shade800,
            cases: yellow,
            controller: ctl,
            initiallyExpanded: true,
            onEdit: (c) => _openCaseForm(existing: c),
            onVisit: _logVisit,
            onDetail: _openCaseDetail,
            onClose: _confirmClose,
          ),
        if (green.isNotEmpty)
          _AlertSection(
            emoji: '🟢',
            title: /* l10n: alertGreenTitle */ '在追蹤中',
            color: Colors.green.shade700,
            cases: green,
            controller: ctl,
            initiallyExpanded: red.isEmpty && yellow.isEmpty,
            onEdit: (c) => _openCaseForm(existing: c),
            onVisit: _logVisit,
            onDetail: _openCaseDetail,
            onClose: _confirmClose,
          ),
      ],
    );
  }

  Widget _buildPersonHistoryTab(CareController ctl, {required bool searching}) {
    var persons = ctl.personHistorySorted();

    if (searching) {
      final q = _searchQuery.toLowerCase();
      persons = persons
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.phone.toLowerCase().contains(q))
          .toList();
    }

    if (persons.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              searching ? /* l10n: historyNoResults */ '沒有符合的人' : /* l10n: historyEmpty */ '暫無探訪歷史',
              style: const TextStyle(fontSize: 16),
            ),
            if (!searching) ...[
              const SizedBox(height: 4),
              Text(/* l10n: historyEmptyHint */ '在會友 / 新朋友 tab 開新案件並記錄探訪後,會出現喺度',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: persons.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
      itemBuilder: (ctx, i) => _PersonRow(
        person: persons[i],
        onTap: () => _openPersonHistory(persons[i].name),
      ),
    );
  }

  void _openPersonHistory(String name) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => PersonHistoryScreen(
        controller: widget.controller,
        personName: name,
      ),
    ));
  }

  Widget _searchList(List<CareCase> matches, CareController ctl) {
    if (matches.isEmpty) {
      return const Center(child: Text(/* l10n: searchNoCaseResults */ '沒有符合的案件'));
    }
    return ListView.builder(
      itemCount: matches.length,
      itemBuilder: (ctx, i) {
        final c = matches[i];
        return _CaseRow(
          caseObj: c,
          controller: ctl,
          onEdit: () => _openCaseForm(existing: c),
          onVisit: () => _logVisit(c),
          onDetail: () => _openCaseDetail(c),
          onClose: c.status == CareStatus.closed
              ? null
              : () => _confirmClose(c),
        );
      },
    );
  }

  Widget _emptyState(String caseType) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            caseType == CaseType.member
                ? Icons.people_outline
                : Icons.person_add_alt_1,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(/* l10n: tabEmptyCaseState */ '目前沒有${CaseType.label(caseType)}案件',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: Text(/* l10n: addNewCaseButton */ '新增${CaseType.label(caseType)}案件'),
            onPressed: () => _openCaseForm(defaultType: caseType),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Helper widgets (structure unchanged from pre-B2)
// ============================================================================

class _AlertSection extends StatelessWidget {
  const _AlertSection({
    required this.emoji,
    required this.title,
    required this.color,
    required this.cases,
    required this.controller,
    required this.initiallyExpanded,
    required this.onEdit,
    required this.onVisit,
    required this.onDetail,
    this.onClose,
  });

  final String emoji;
  final String title;
  final Color color;
  final List<CareCase> cases;
  final CareController controller;
  final bool initiallyExpanded;
  final void Function(CareCase) onEdit;
  final void Function(CareCase) onVisit;
  final void Function(CareCase) onDetail;
  final void Function(CareCase)? onClose;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      title: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(width: 8),
          Text('(${cases.length})',
              style: TextStyle(color: color, fontSize: 14)),
        ],
      ),
      childrenPadding: EdgeInsets.zero,
      children: cases
          .map((c) => _CaseRow(
                caseObj: c,
                controller: controller,
                onEdit: () => onEdit(c),
                onVisit: () => onVisit(c),
                onDetail: () => onDetail(c),
                onClose: onClose != null ? () => onClose!(c) : null,
              ))
          .toList(),
    );
  }
}

class _CaseRow extends StatelessWidget {
  const _CaseRow({
    required this.caseObj,
    required this.controller,
    required this.onEdit,
    required this.onVisit,
    required this.onDetail,
    this.onClose,
  });

  final CareCase caseObj;
  final CareController controller;
  final VoidCallback onEdit;
  final VoidCallback onVisit;
  final VoidCallback onDetail;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final lastVisit = controller.lastVisitFor(caseObj.id);
    final days = controller.daysSinceLastTouch(caseObj);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    caseObj.memberName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (days != null)
                  Text(
                    days == 0 ? /* l10n: today */ '今天' : /* l10n: daysNoVisit */ '🕐 $days 天沒探訪',
                    style:
                        TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              /* l10n: caseRowSummary */ '${caseObj.reason}  ·  ${CareUrgency.label(caseObj.urgency)}優先',
              style: TextStyle(color: Colors.grey[800], fontSize: 13),
            ),
            const SizedBox(height: 4),
            if (lastVisit != null)
              Text(
                /* l10n: caseRowLastVisitPrefix */ '上次:${lastVisit.visitedBy} ${_fmtDate(lastVisit.visitDate)} '
                '${VisitMethod.label(lastVisit.method)} '
                '「${_truncate(lastVisit.summary, 30)}」',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            else
              Text(
                /* l10n: noVisitRecorded */ /* l10n: historyNoVisitRecorded */ '尚未探訪過',
                style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic),
              ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 4,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text(/* l10n: detailsButton */ '詳情'),
                  onPressed: onDetail,
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text(/* l10n: logVisitButton */ '記探訪'),
                  onPressed: onVisit,
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  tooltip: /* l10n: editCaseTooltip */ '編輯案件',
                  onPressed: onEdit,
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.archive_outlined, size: 18),
                    tooltip: /* l10n: closeCaseTooltip */ '結案',
                    onPressed: onClose,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.month}/${d.day.toString().padLeft(2, '0')}';

  static String _truncate(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}...';
}

// ============================================================================
// Person row for the 已探訪者 (history) tab
// ============================================================================

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.person, required this.onTap});

  final PersonSummary person;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lastVisit = person.lastVisit;
    final daysSince = lastVisit == null
        ? null
        : DateTime.now().difference(lastVisit.visitDate).inDays;

    return ListTile(
      title: Row(
        children: [
          Flexible(
            child: Text(person.name,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 6),
          if (person.hasActiveCase)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                /* l10n: statusActiveBadge */ '進行中',
                style: TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 10),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lastVisit != null)
            Text(
              /* l10n: historyRowLastVisit */ '上次:${lastVisit.visitedBy} · ${VisitMethod.label(lastVisit.method)} · ${_fmtShort(lastVisit.visitDate)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            )
          else
            Text(
              /* l10n: noVisitRecorded */ /* l10n: historyNoVisitRecorded */ '尚未探訪過',
              style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontStyle: FontStyle.italic),
            ),
          const SizedBox(height: 2),
          Text(
            /* l10n: historyRowStats */ '共 ${person.totalVisits} 次探訪 · ${person.caseIds.length} 個案件',
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (daysSince != null)
            Text(
              _agoLabel(daysSince),
              style: TextStyle(
                color: daysSince > 30
                    ? Colors.red.shade400
                    : Colors.grey[700],
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
      onTap: onTap,
    );
  }

  static String _fmtShort(DateTime d) =>
      '${d.month}/${d.day.toString().padLeft(2, '0')}';

  static String _agoLabel(int days) {
    if (days == 0) return /* l10n: today */ '今天';
    if (days < 7) return /* l10n: daysAgo */ '$days 天前';
    if (days < 30) return /* l10n: weeksAgo */ '${(days / 7).floor()} 週前';
    if (days < 365) return /* l10n: monthsAgo */ '${(days / 30).floor()} 個月前';
    return /* l10n: yearsAgo */ '${(days / 365).floor()} 年前';
  }
}


