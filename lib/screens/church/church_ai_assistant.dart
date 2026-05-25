// lib/screens/church/church_ai_assistant.dart
//
// ChurchAiAssistant — 4 quick AI functions for pastoral team.
//
// Each card builds a context-aware prompt from live controller data and
// opens PersonalQueryScreen with that pre-filled query.
//
// WRITE: only this file + church_hub_screen.dart (FAB).
// NEVER TOUCH: controllers, models, services, l10n, main.dart.

import 'package:flutter/material.dart';

import '../../main.dart';
import '../personal_query_screen.dart';

// ============================================================================
// Screen
// ============================================================================

class ChurchAiAssistant extends StatefulWidget {
  const ChurchAiAssistant({super.key});

  @override
  State<ChurchAiAssistant> createState() => _ChurchAiAssistantState();
}

class _ChurchAiAssistantState extends State<ChurchAiAssistant> {
  // ── helpers ─────────────────────────────────────────────────────────────

  void _run(String prompt) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonalQueryScreen(
          ragService: globalPersonalRagService,
          initialQuery: prompt,
        ),
      ),
    );
  }

  // ── prompt builders ──────────────────────────────────────────────────────

  String _buildVisitSummaryPrompt() {
    final care = globalCareController;
    final buf = StringBuffer();
    buf.writeln('請根據以下教會關懷案件資料，生成本週探訪工作摘要報告，'
        '包括：(1) 緊急/需優先跟進的案件；(2) 本週已探訪情況；'
        '(3) 給牧者的行動建議。請用繁體中文，條列式回答。\n');

    final active = care.activeCases;
    if (active.isEmpty) {
      buf.writeln('目前無活躍關懷案件。');
    } else {
      buf.writeln('【活躍案件 ${active.length} 件】');
      for (final c in active.take(20)) {
        final level = care.alertLevel(c).name.toUpperCase();
        final days = care.daysSinceLastTouch(c);
        final daysStr = days == null ? '未知' : '$days 天未探訪';
        buf.writeln('- ${c.memberName}｜緣由：${c.reason}｜緊急度：${c.urgency}'
            '｜狀態：$level｜$daysStr');
        final last = care.lastVisitFor(c.id);
        if (last != null) {
          buf.writeln('  最近探訪：${last.visitDate.year}/${last.visitDate.month}/${last.visitDate.day}'
              ' 由 ${last.visitedBy}，${last.summary}');
        }
      }
    }

    buf.writeln('\n統計：紅燈 ${care.redCount} 件 / 黃燈 ${care.yellowCount} 件 / '
        '綠燈 ${care.greenCount} 件');
    return buf.toString();
  }

  String _buildPrayerPrompt() {
    final care = globalCareController;
    final buf = StringBuffer();
    buf.writeln('請根據以下教會關懷案件，整理成本週代禱清單，'
        '格式：姓名 + 簡短代禱事項（1 句話），按緊急度排序。請用繁體中文。\n');

    final active = care.activeCases;
    if (active.isEmpty) {
      buf.writeln('目前無活躍關懷案件。');
    } else {
      for (final c in active.take(30)) {
        final extra = c.notes.isNotEmpty ? '（備註：${c.notes}）' : '';
        buf.writeln('- ${c.memberName}：${c.reason}$extra');
      }
    }
    return buf.toString();
  }

  String _buildSermonPrompt(String topic) {
    return '請為題目「$topic」設計一份主日講道 PowerPoint 大綱，包括：'
        '(1) 主題經文（請引用具體章節）；'
        '(2) 講道結構（開場 / 主體 3 點 / 呼召）；'
        '(3) 每個段落的重點句與參考例子；'
        '(4) 適合會眾討論的反思問題 2 條。'
        '請用繁體中文，條列式回答。';
  }

  String _buildMemberStatusPrompt(String name) {
    final care = globalCareController;
    final people = globalPersonController;
    final buf = StringBuffer();
    buf.writeln('請查詢會友「$name」的近況，並給出牧關建議。\n');

    final person = people.findByName(name);
    if (person != null) {
      buf.writeln('【會友資料】');
      buf.writeln('姓名：${person.name}');
      buf.writeln('出席狀況：${person.attendance}');
      buf.writeln('類型：${person.personType}');
      if (person.phone.isNotEmpty) buf.writeln('電話：${person.phone}');
      if (person.notes.isNotEmpty) buf.writeln('備註：${person.notes}');
    } else {
      buf.writeln('（在會友通訊錄中找不到此姓名，將根據關懷記錄查詢）');
    }

    final related = care.activeCases
        .where((c) => c.memberName.contains(name) || name.contains(c.memberName))
        .toList();
    if (related.isNotEmpty) {
      buf.writeln('\n【相關關懷案件】');
      for (final c in related) {
        buf.writeln('- 緣由：${c.reason}｜緊急度：${c.urgency}');
        final last = care.lastVisitFor(c.id);
        if (last != null) {
          buf.writeln('  最近探訪：${last.visitDate.year}/${last.visitDate.month}/${last.visitDate.day}，${last.summary}');
        }
      }
    }

    buf.writeln('\n請根據以上資料分析此會友的近況，並建議牧者如何跟進。');
    return buf.toString();
  }

  // ── input dialogs ────────────────────────────────────────────────────────

  Future<void> _askSermonTopic() async {
    final ctrl = TextEditingController();
    final topic = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('講道題目'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '例：盼望、悔改、恩典…',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('生成'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (topic == null || topic.isEmpty) return;
    _run(_buildSermonPrompt(topic));
  }

  Future<void> _askMemberName() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('會友姓名'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '請輸入會友姓名',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('查詢'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null || name.isEmpty) return;
    _run(_buildMemberStatusPrompt(name));
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('AI 助手')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(context),
          const SizedBox(height: 16),
          _AiCard(
            icon: Icons.summarize_outlined,
            color: Colors.deepPurple,
            title: '生成探訪摘要',
            subtitle: '根據活躍案件自動整理本週探訪重點與行動建議',
            onTap: () => _run(_buildVisitSummaryPrompt()),
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.volunteer_activism_outlined,
            color: Colors.indigo,
            title: '整理代禱事項',
            subtitle: '將所有活躍關懷案件整合成本週代禱清單',
            onTap: () => _run(_buildPrayerPrompt()),
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.present_to_all_outlined,
            color: Colors.teal,
            title: '產生講道 PPT 大綱',
            subtitle: '輸入講道題目，AI 自動生成結構化 PPT 大綱與反思問題',
            onTap: _askSermonTopic,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.person_search_outlined,
            color: Colors.blueGrey,
            title: '會友近況查詢',
            subtitle: '輸入會友姓名，AI 整合關懷記錄並給出牧關建議',
            onTap: _askMemberName,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI 回應僅供參考，牧者請自行判斷與跟進。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final care = globalCareController;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.smart_toy_outlined,
                color: Theme.of(context).colorScheme.primary, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('教會 AI 助手',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                  Text(
                    '目前 ${care.activeCount} 個活躍案件 · ${care.redCount} 件需緊急跟進',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: care.redCount > 0 ? Colors.red : null,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Reusable card widget
// ============================================================================

class _AiCard extends StatelessWidget {
  const _AiCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            )),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
