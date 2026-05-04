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
import '../controllers/health_controller.dart';
import '../controllers/wealth_controller.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/app_settings.dart';
import '../services/app_settings_service.dart';
import '../services/personal_rag_service.dart';
import '../widgets/wealth/wealth_monthly_report_card.dart';
import '../widgets/wealth/wealth_report_card.dart';
import 'expense_screen.dart';
import 'health_screen.dart';
import 'my_skills_screen.dart';
import 'personal_query_screen.dart';
import 'settings_screen.dart';
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
        SnackBar(
          content: Text(AppLocalizations.of(context).aiQueryFeatureComingSoon),
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

  void _openLifeInsights() {
    final svc = widget.personalRagService;
    if (svc == null) return;
    
    final hStats = widget.healthController.getStats(lastNDays: 30);
    
    String ccy = 'TWD';
    final totals = widget.wealthController.getCurrentTotalByCurrency();
    if (totals.isNotEmpty) {
      ccy = totals.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }
    final wStats = widget.wealthController.getStats(currency: ccy);

    String prompt = '請根據我近期的健康與財務狀況，給我一份「生活與財務總分析」：\n\n';
    prompt += '[健康狀態 (近30天)]\n';
    if (hStats.avgWeight != null) prompt += '- 平均體重：${hStats.avgWeight!.toStringAsFixed(1)} kg\n';
    if (hStats.avgSystolic != null) prompt += '- 平均血壓：${hStats.avgSystolic!.toStringAsFixed(0)}/${hStats.avgDiastolic?.toStringAsFixed(0) ?? '?'} mmHg\n';
    if (hStats.totalSteps != null && hStats.totalSteps! > 0) prompt += '- 近期總步數：${hStats.totalSteps} 步\n';
    if (hStats.avgSleepHours != null) prompt += '- 平均睡眠：${hStats.avgSleepHours!.toStringAsFixed(1)} 小時\n';
    
    prompt += '\n[財務狀態 ($ccy)]\n';
    prompt += '- 總淨值：${wStats.totalNetWorth.toStringAsFixed(0)} $ccy\n';
    if (wStats.allocationByType.isNotEmpty) {
      prompt += '- 資產分佈：\n';
      for (final e in wStats.allocationByType.entries) {
        prompt += '  * ${e.key}: ${e.value.toStringAsFixed(0)}\n';
      }
    }
    
    prompt += '\n請綜合以上數據，評估我目前的生活品質與財務健康，並給出 3 點具體建議。';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonalQueryScreen(
          ragService: svc,
          initialQuery: prompt,
        ),
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

    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.personalHubTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final current = await AppSettingsService().load();
              if (!context.mounted) return;
              final updated = await Navigator.of(context).push<AppSettings>(
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(currentSettings: current),
                ),
              );
              if (updated != null) {
                await AppSettingsService().save(updated);
                restartTelegramBot(updated.telegramBotToken);
              }
            },
          ),
        ],
      ),
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
            // === 新增：Wealth 月報卡（Personal Hub 首頁重點強化） ===
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: WealthMonthlyReportCard(
                controller: widget.wealthController,
                currency: widget.wealthController.getCurrencies().isNotEmpty
                    ? widget.wealthController.getCurrencies().first
                    : 'TWD',
              ),
            ),
            if (widget.personalRagService != null)
              _LifeInsightsCard(onTap: _openLifeInsights),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                loc.modules,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

// ============================================================================
// Dashboard summary card
// ============================================================================

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

  String _wealthText(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (wealthCount == 0) return loc.noRecordsYet;
    if (wealthTotalsByCcy.isEmpty) return loc.recordCountPlural(wealthCount);
    final parts = wealthTotalsByCcy.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return parts
        .take(2)
        .map((e) => '${e.value.toStringAsFixed(0)} ${e.key}')
        .join(' / ');
  }

  String _summaryText(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (monthlySummary.isEmpty) return loc.noExpensesThisMonth;
    return monthlySummary.entries
        .map((e) => '${e.value.toStringAsFixed(2)} ${e.key}')
        .join(' / ');
  }

  String _contactText(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (contactCount == 0) return loc.noContactsYet;
    return loc.contactCountPlural(contactCount);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
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
                  loc.dashboardTitle(year, month),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(height: 24),
            _DashboardRow(
              icon: Icons.payments_outlined,
              label: loc.totalExpensesThisMonth,
              value: _summaryText(context),
            ),
            const SizedBox(height: 8),
            _DashboardRow(
              icon: Icons.contacts_outlined,
              label: loc.totalContacts,
              value: _contactText(context),
              muted: contactCount == 0,
            ),
            const SizedBox(height: 8),
            _DashboardRow(
              icon: Icons.favorite_outline,
              label: loc.healthRecords,
              value: healthCount == 0 ? loc.noRecordsYet : loc.recordCountPlural(healthCount),
              muted: healthCount == 0,
            ),
            const SizedBox(height: 8),
            _DashboardRow(
              icon: Icons.account_balance_outlined,
              label: loc.investmentNetWorth,
              value: _wealthText(context),
              muted: wealthCount == 0,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onAiQuery,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: Text(loc.quickAiQuery),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LifeInsightsCard extends StatelessWidget {
  const _LifeInsightsCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade400, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.psychology, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🧠 一鍵生活洞察',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '結合 Health 與 Wealth 雙核分析，打造您的專屬生活指南。',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
              ],
            ),
          ),
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
    final loc = AppLocalizations.of(context);
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 600 ? 3 : 2;

    final modules = <_ModuleData>[
      _ModuleData(
        icon: Icons.payments_outlined,
        label: loc.moduleExpense,
        subtitle: loc.recordCountPlural(expenseCount),
        color: Colors.green,
        enabled: true,
        onTap: onExpenseTap,
      ),
      _ModuleData(
        icon: Icons.contacts_outlined,
        label: loc.moduleContacts,
        subtitle: loc.contactCountPlural(contactCount),
        color: Colors.blue,
        enabled: true,
        onTap: onContactsTap,
      ),
      _ModuleData(
        icon: Icons.favorite_outline,
        label: loc.healthRecords,
        subtitle: loc.recordCountPlural(healthCount),
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
        label: loc.investmentFinance,
        subtitle: wealthCount == 0
            ? loc.noRecordsYet
            : loc.recordCountPlural(wealthCount),
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
      _ModuleData(
        icon: Icons.dashboard_customize_outlined,
        label: loc.moduleDashboardSoon,
        subtitle: loc.comingSoon,
        color: Colors.orange,
        enabled: false,
      ),
      _ModuleData(
        icon: Icons.psychology_outlined,
        label: loc.mySkills,
        subtitle: 'AI 學習記憶庫',
        color: Colors.teal,
        enabled: ragService?.skillsService != null,
        onTap: () {
          if (ragService?.skillsService != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MySkillsScreen(
                  ragService: ragService!,
                ),
              ),
            );
          }
        },
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
    final loc = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.featureNotEnabled(data.label)),
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
    final loc = AppLocalizations.of(context);
    final contacts = controller.contacts;
    return Scaffold(
      appBar: AppBar(title: Text(loc.moduleContacts)),
      body: contacts.isEmpty
          ? Center(child: Text(loc.noContactsYet))
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
