// lib/screens/personal_hub_screen.dart
//
// Phase 6.3'a + 6.4'b + 6.5 — Personal Hub entry + Dashboard UI.
//
// 6.5 changes vs 6.4'b:
//   * Optional personalRagService parameter. When provided, the "快速 AI 查詢"
//     button navigates to PersonalQueryScreen. When null (default), it still
//     shows the legacy stub snackbar — keeps backwards compatibility for any
//     wiring that hasn't been updated yet.
//
// === Wiring (Albert: do this once at app start) ===
//
//   final expenseController  = ExpenseController(yourExistingVectorStore);
//   final contactController  = ContactController(yourExistingVectorStore);
//   final personalRagService = PersonalRagService(
//     embedder: yourEmbeddingService,
//     store:    yourVectorStore,
//     llmComplete: ({required systemPrompt, required userPrompt}) =>
//       yourOllamaService.chat([
//         ChatMessage(role: 'system', content: systemPrompt),
//         ChatMessage(role: 'user',   content: userPrompt),
//       ]),
//     llmCompleteStream: ({required systemPrompt, required userPrompt}) =>
//       yourOllamaService.chatStream([
//         ChatMessage(role: 'system', content: systemPrompt),
//         ChatMessage(role: 'user',   content: userPrompt),
//       ]),
//   );
//
//   PersonalHubScreen(
//     expenseController:    expenseController,
//     contactController:    contactController,
//     personalRagService:   personalRagService,
//   )

import 'package:flutter/material.dart';

import '../controllers/contact_controller.dart';
import '../controllers/expense_controller.dart';
import '../services/personal_rag_service.dart';
import 'expense_screen.dart';
import 'personal_query_screen.dart';

class PersonalHubScreen extends StatefulWidget {
  const PersonalHubScreen({
    super.key,
    required this.expenseController,
    required this.contactController,
    this.personalRagService,
  });
  final ExpenseController expenseController;
  final ContactController contactController;

  /// Optional. When provided, the AI quick-query button opens
  /// [PersonalQueryScreen]. When null, the button shows a stub snackbar.
  final PersonalRagService? personalRagService;

  @override
  State<PersonalHubScreen> createState() => _PersonalHubScreenState();
}

class _PersonalHubScreenState extends State<PersonalHubScreen> {
  @override
  void initState() {
    super.initState();
    widget.expenseController.addListener(_onChanged);
    widget.contactController.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.expenseController.removeListener(_onChanged);
    widget.contactController.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _openExpense() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ExpenseScreen(controller: widget.expenseController),
      ),
    );
  }

  void _openContacts() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _ContactListScreen(controller: widget.contactController),
      ),
    );
  }

  void _onAiQueryPressed() {
    final svc = widget.personalRagService;
    if (svc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("AI 跨模組查詢將於 Phase 6.3'b 推出"),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonalQueryScreen(ragService: svc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final summary =
        widget.expenseController.getMonthlySummary(now.year, now.month);
    final expenseCount = widget.expenseController.expenses.length;
    final contactCount = widget.contactController.contactCount;

    return Scaffold(
      appBar: AppBar(title: const Text('Personal Hub')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DashboardCard(
              year: now.year,
              month: now.month,
              monthlySummary: summary,
              contactCount: contactCount,
              onAiQuery: _onAiQueryPressed,
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '模組',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            _ModulesGrid(
              expenseCount: expenseCount,
              contactCount: contactCount,
              onExpenseTap: _openExpense,
              onContactsTap: _openContacts,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Dashboard summary card
// ============================================================================

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.year,
    required this.month,
    required this.monthlySummary,
    required this.contactCount,
    required this.onAiQuery,
  });
  final int year;
  final int month;
  final Map<String, double> monthlySummary;
  final int contactCount;
  final VoidCallback onAiQuery;

  String get _summaryText {
    if (monthlySummary.isEmpty) return '本月暫無開支';
    return monthlySummary.entries
        .map((e) => '${e.value.toStringAsFixed(2)} ${e.key}')
        .join(' / ');
  }

  String get _contactText {
    if (contactCount == 0) return '尚未加入名片';
    return '$contactCount 張';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dashboard_outlined),
                const SizedBox(width: 8),
                Text(
                  '$year 年 $month 月總覽',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(height: 24),
            _DashboardRow(
              icon: Icons.payments_outlined,
              label: '本月總開支',
              value: _summaryText,
            ),
            const SizedBox(height: 8),
            _DashboardRow(
              icon: Icons.contacts_outlined,
              label: '名片總數',
              value: _contactText,
              muted: contactCount == 0,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onAiQuery,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('快速 AI 查詢'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardRow extends StatelessWidget {
  const _DashboardRow({
    required this.icon,
    required this.label,
    required this.value,
    this.muted = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = muted
        ? Theme.of(context).disabledColor
        : Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Modules grid
// ============================================================================

class _ModuleData {
  const _ModuleData({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.enabled,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;
}

class _ModulesGrid extends StatelessWidget {
  const _ModulesGrid({
    required this.expenseCount,
    required this.contactCount,
    required this.onExpenseTap,
    required this.onContactsTap,
  });
  final int expenseCount;
  final int contactCount;
  final VoidCallback onExpenseTap;
  final VoidCallback onContactsTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 600 ? 3 : 2;

    final modules = <_ModuleData>[
      _ModuleData(
        icon: Icons.payments_outlined,
        label: '日常開支',
        subtitle: '$expenseCount 筆紀錄',
        color: Colors.green,
        enabled: true,
        onTap: onExpenseTap,
      ),
      _ModuleData(
        icon: Icons.contacts_outlined,
        label: '名片管理',
        subtitle: '$contactCount 張名片',
        color: Colors.blue,
        enabled: true,
        onTap: onContactsTap,
      ),
      const _ModuleData(
        icon: Icons.favorite_outline,
        label: '健康紀錄',
        subtitle: '即將推出',
        color: Colors.red,
        enabled: false,
      ),
      const _ModuleData(
        icon: Icons.show_chart,
        label: '投資理財',
        subtitle: '即將推出',
        color: Colors.purple,
        enabled: false,
      ),
      const _ModuleData(
        icon: Icons.dashboard_customize_outlined,
        label: '完整儀表板',
        subtitle: '即將推出',
        color: Colors.orange,
        enabled: false,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.05,
        children: [
          for (final m in modules) _ModuleCard(data: m),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.data});
  final _ModuleData data;

  void _showDisabledNotice(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${data.label}：尚未啟用，請等待後續 Phase'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconColor =
        data.enabled ? data.color : Theme.of(context).disabledColor;
    final labelColor = data.enabled
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).disabledColor;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: data.enabled ? data.onTap : () => _showDisabledNotice(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(data.icon, size: 32, color: iconColor),
              const SizedBox(height: 8),
              Text(
                data.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.subtitle,
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


class _ContactListScreen extends StatelessWidget {
  const _ContactListScreen({required this.controller});

  final ContactController controller;

  @override
  Widget build(BuildContext context) {
    final contacts = controller.contacts;
    return Scaffold(
      appBar: AppBar(title: const Text('名片管理')),
      body: contacts.isEmpty
          ? const Center(child: Text('尚未加入名片'))
          : ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                final subtitle = [contact.title, contact.company]
                    .where((value) => value.trim().isNotEmpty)
                    .join(' · ');
                return ListTile(
                  leading: const Icon(Icons.contacts_outlined),
                  title: Text(contact.name),
                  subtitle: subtitle.isEmpty ? null : Text(subtitle),
                );
              },
            ),
    );
  }
}
