// lib/screens/church/church_hub_screen.dart
//
// ChurchHubScreen v2.0 — Unified Church Module Entry Point
//
// Layout:
//   AppBar  「教會」
//   ├─ _ChurchStatsCard   (4 live counters: cases / red / members / inactive)
//   └─ GridView 2-col
//       ├─ 關懷追蹤    → CareDashboardScreen
//       ├─ 會友通訊錄  → PersonDirectoryScreen
//       └─ 探訪歷史    → _PersonHistoryListScreen (inline, picks a person)
//
// All data comes from globalCareController / globalPersonController (main.dart).
// No controllers or models are modified.

import 'package:flutter/material.dart';

import '../../controllers/church/care_controller.dart';
import '../../main.dart';
import 'care_dashboard_screen.dart';
import 'church_ai_assistant.dart';
import 'church_documents_screen.dart';
import 'church_workflow_screen.dart';
import 'person_directory_screen.dart';
import 'person_history_screen.dart';

// ============================================================================
// Entry screen
// ============================================================================

class ChurchHubScreen extends StatefulWidget {
  const ChurchHubScreen({super.key});

  @override
  State<ChurchHubScreen> createState() => _ChurchHubScreenState();
}

class _ChurchHubScreenState extends State<ChurchHubScreen> {
  @override
  void initState() {
    super.initState();
    globalCareController.addListener(_onChanged);
    globalPersonController.addListener(_onChanged);
  }

  @override
  void dispose() {
    globalCareController.removeListener(_onChanged);
    globalPersonController.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _openCare() => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CareDashboardScreen(controller: globalCareController),
      ));

  void _openDirectory() => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            PersonDirectoryScreen(controller: globalPersonController),
      ));

  void _openHistory() => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            _PersonHistoryListScreen(controller: globalCareController),
      ));

  @override
  Widget build(BuildContext context) {
    final care = globalCareController;
    final people = globalPersonController;

    return Scaffold(
      appBar: AppBar(title: const Text('教會')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ChurchAiAssistant()),
        ),
        icon: const Icon(Icons.smart_toy_outlined),
        label: const Text('AI 助手'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ChurchStatsCard(
              activeCount: care.activeCount,
              redCount: care.redCount,
              memberCount: people.totalCount,
              inactiveCount: people.inactiveCount,
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                _ChurchEntryCard(
                  icon: Icons.volunteer_activism_outlined,
                  label: '關懷追蹤',
                  subtitle: '${care.activeCount} 案件 · ${care.redCount} 紅燈',
                  color: Colors.deepPurple,
                  onTap: _openCare,
                ),
                _ChurchEntryCard(
                  icon: Icons.groups_outlined,
                  label: '會友通訊錄',
                  subtitle:
                      '${people.totalCount} 位 · ${people.inactiveCount} 久未出席',
                  color: Colors.blueGrey,
                  onTap: _openDirectory,
                ),
                _ChurchEntryCard(
                  icon: Icons.history_outlined,
                  label: '探訪歷史',
                  subtitle: '${care.personHistoryCount} 位有記錄',
                  color: Colors.teal,
                  onTap: _openHistory,
                ),
                _ChurchEntryCard(
                  icon: Icons.article_outlined,
                  label: '教會文書助理',
                  subtitle: '講道 · 查經 · 關懷紀錄',
                  color: Colors.teal,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChurchDocumentsScreen(
                        careController: care,
                        personController: people,
                      ),
                    ),
                  ),
                ),
                _ChurchEntryCard(
                  icon: Icons.integration_instructions_outlined,
                  label: '教會 Office 工作流',
                  subtitle: 'Word · Excel · PPT 巨集',
                  color: Colors.indigo,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ChurchWorkflowScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Person-history list screen (person picker → PersonHistoryScreen)
// ============================================================================

class _PersonHistoryListScreen extends StatefulWidget {
  const _PersonHistoryListScreen({required this.controller});

  final CareController controller;

  @override
  State<_PersonHistoryListScreen> createState() =>
      _PersonHistoryListScreenState();
}

class _PersonHistoryListScreenState extends State<_PersonHistoryListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.controller.personHistorySorted();
    final filtered = _query.trim().isEmpty
        ? all
        : all
            .where((p) =>
                p.name.toLowerCase().contains(_query.toLowerCase()) ||
                p.phone.contains(_query))
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('探訪歷史')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: '搜尋姓名 / 電話...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      all.isEmpty ? '尚無探訪記錄' : '沒有符合的人',
                      style: TextStyle(color: Theme.of(context).hintColor),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      final lastVisitText = p.lastVisit == null
                          ? '尚未探訪'
                          : '上次：${p.lastVisit!.visitDate.year}/${p.lastVisit!.visitDate.month}/${p.lastVisit!.visitDate.day}';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondaryContainer,
                          child: Text(
                            p.name.isNotEmpty ? p.name[0] : '?',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                            ),
                          ),
                        ),
                        title: Text(p.name),
                        subtitle: Text(
                          '${p.totalVisits} 次探訪 · $lastVisitText',
                          style: TextStyle(
                              fontSize: 12, color: Theme.of(context).hintColor),
                        ),
                        trailing: p.activeCaseCount > 0
                            ? Badge(
                                label: Text('${p.activeCaseCount}'),
                                child: const Icon(
                                    Icons.volunteer_activism_outlined),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PersonHistoryScreen(
                              controller: widget.controller,
                              personName: p.name,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Stats card
// ============================================================================

class _ChurchStatsCard extends StatelessWidget {
  const _ChurchStatsCard({
    required this.activeCount,
    required this.redCount,
    required this.memberCount,
    required this.inactiveCount,
  });

  final int activeCount;
  final int redCount;
  final int memberCount;
  final int inactiveCount;

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
                const Icon(Icons.church_outlined),
                const SizedBox(width: 8),
                Text(
                  '教會概況',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.volunteer_activism_outlined,
                    label: '進行中案件',
                    value: '$activeCount',
                    color: Colors.deepPurple,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.warning_amber_rounded,
                    label: '需立即跟進',
                    value: '$redCount',
                    color: redCount > 0 ? Colors.red : Colors.grey,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.groups_outlined,
                    label: '會友人數',
                    value: '$memberCount',
                    color: Colors.blueGrey,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.person_off_outlined,
                    label: '久未出席',
                    value: '$inactiveCount',
                    color: inactiveCount > 0 ? Colors.orange : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).hintColor,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Entry card
// ============================================================================

class _ChurchEntryCard extends StatelessWidget {
  const _ChurchEntryCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
