// lib/screens/personal_hub_screen.dart
import 'package:flutter/material.dart';

import '../controllers/contact_controller.dart';
import '../controllers/expense_controller.dart';
import '../controllers/health_controller.dart';
import '../controllers/wealth_controller.dart';
import '../services/personal_rag_service.dart';
import 'expense_screen.dart';
import 'health_screen.dart';
import 'personal_query_screen.dart';
import 'wealth_screen.dart';

class PersonalHubScreen extends StatefulWidget {
  const PersonalHubScreen({
    super.key,
    required this.expenseController,
    required this.contactController,
    required this.healthController,
    required this.wealthController,
    this.personalRagService,
  });
  
  final ExpenseController expenseController;
  final ContactController contactController;
  final HealthController healthController;
  final WealthController wealthController;
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
    widget.healthController.addListener(_onChanged);
    widget.wealthController.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.expenseController.removeListener(_onChanged);
    widget.contactController.removeListener(_onChanged);
    widget.healthController.removeListener(_onChanged);
    widget.wealthController.removeListener(_onChanged);
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
    final healthCount = widget.healthController.count;
    final wealthCount = widget.wealthController.count;
    final wealthTotalsByCcy =
        widget.wealthController.getCurrentTotalByCurrency();

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
              healthCount: healthCount,
              wealthCount: wealthCount,
              wealthTotalsByCcy: wealthTotalsByCcy,
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
              healthCount: healthCount,
              wealthCount: wealthCount,
              onExpenseTap: _openExpense,
              onContactsTap: _openContacts,
              healthController: widget.healthController,
              wealthController: widget.wealthController,
              ragService: widget.personalRagService,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.year,
    required this.month,
    required this.monthlySummary,
    required this.contactCount,
    required this.healthCount,
    required this.wealthCount,
    required this.wealthTotalsByCcy,
    required this.onAiQuery,
  });
  final int year;
  final int month;
  final Map<String, double> monthlySummary;
  final int contactCount;
  final int healthCount;
  final int wealthCount;
  final Map<String, double> wealthTotalsByCcy;
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

  String get _wealthText {
    if (wealthCount == 0) return '尚未加入資產';
    if (wealthTotalsByCcy.isEmpty) return '$wealthCount 筆資產';
    final parts = wealthTotalsByCcy.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return parts
        .take(2)
        .map((e) => '${e.value.toStringAsFixed(0)} ${e.key}')
        .join(' / ');
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
            const SizedBox(height: 8),
            _DashboardRow(
              icon: Icons.favorite_outline,
              label: '健康紀錄',
              value: healthCount == 0 ? '尚未加入紀錄' : '$healthCount 筆',
              muted: healthCount == 0,
            ),
            const SizedBox(height: 8),
            _DashboardRow(
              icon: Icons.account_balance_outlined,
              label: '投資淨值',
              value: _wealthText,
              muted: wealthCount == 0,
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
    required this.healthCount,
    required this.wealthCount,
    required this.onExpenseTap,
    required this.onContactsTap,
    required this.healthController,
    required this.wealthController,
    this.ragService,
  });
  
  final int expenseCount;
  final int contactCount;
  final int healthCount;
  final int wealthCount;
  final VoidCallback onExpenseTap;
  final VoidCallback onContactsTap;
  final HealthController healthController;
  final WealthController wealthController;
  final PersonalRagService? ragService;

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
      _ModuleData(
        icon: Icons.favorite_outline,
        label: '健康紀錄',
        subtitle: '$healthCount 筆紀錄',
        color: Colors.red,
        enabled: true,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HealthScreen(controller: healthController),
          ),
        ),
      ),
      _ModuleData(
        icon: Icons.account_balance_outlined,
        label: '投資理財',
        subtitle: '$wealthCount 筆資產',
        color: Colors.purple,
        enabled: true,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WealthScreen(
              controller: wealthController,
              ragService: ragService,
            ),
          ),
        ),
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
