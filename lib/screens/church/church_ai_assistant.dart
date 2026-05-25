// lib/screens/church/church_ai_assistant.dart
//
// ChurchAiAssistant v2.1 — 8 quick AI functions for pastoral team.
//
// v1 (4 cards): 生成探訪摘要 / 整理代禱事項 / 講道PPT大綱 / 會友近況查詢
// v2.1 (+ 4 cards): 小組討論問題 / 活動文案海報 / 財務報告草稿 / 牧養行動建議
//
// Each card builds a context-aware prompt from live controller data and
// opens PersonalQueryScreen with that pre-filled query.
//
// WRITE: only this file.
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

  // ── v2.1 prompt builders ─────────────────────────────────────────────────

  String _buildGroupDiscussionPrompt(String topic) {
    return '請為小組查經或小組聚會設計一套討論問題，主題／經文：「$topic」。\n'
        '要求：\n'
        '(1) 破冰問題 1 條（輕鬆、生活化）；\n'
        '(2) 深入查經問題 4 條（引導小組思考經文意義與應用）；\n'
        '(3) 生活應用問題 2 條（促進個人行動）；\n'
        '(4) 結束禱告重點 1 條。\n'
        '請用繁體中文，每條問題後附上簡短「引導提示」供帶領者參考。';
  }

  String _buildEventCopyPrompt(String eventName) {
    return '請為教會活動「$eventName」生成完整宣傳文案套件，包括：\n'
        '(1) 活動主題句（15 字以內，吸引人）；\n'
        '(2) 海報副標題（25 字以內）；\n'
        '(3) 活動介紹段落（3-4 句，說明活動內容與對象）；\n'
        '(4) WhatsApp／Line 分享短文（100 字以內）；\n'
        '(5) 三個可用的 hashtag 建議；\n'
        '(6) 呼召行動句（Call to Action，例：立即報名、歡迎帶朋友參加）。\n'
        '請用繁體中文，風格溫暖親切，適合教會社群。';
  }

  String _buildFinanceReportPrompt(String period) {
    final care = globalCareController;
    final people = globalPersonController;
    return '請為教會生成「$period」財務報告草稿範本，包括：\n'
        '(1) 報告標題與日期欄位；\n'
        '(2) 收入項目清單（奉獻、什一、特別奉獻、其他）及合計欄；\n'
        '(3) 支出項目清單（人事、房租/場地、事工、行政、其他）及合計欄；\n'
        '(4) 結餘計算欄；\n'
        '(5) 重點摘要段落（給長執會閱讀）；\n'
        '(6) 財務健康指標建議（例：緊急備用金≥3個月支出）。\n\n'
        '教會目前概況（供參考）：\n'
        '- 會友人數：${people.totalCount} 人（定期出席 ${people.regularCount} 人）\n'
        '- 活躍關懷案件：${care.activeCount} 件\n\n'
        '請用繁體中文，表格部分用文字列出欄位名稱，方便貼入 Excel。';
  }

  String _buildPastoralActionPrompt(String name) {
    final care = globalCareController;
    final people = globalPersonController;
    final buf = StringBuffer();
    buf.writeln('請為會友「$name」制定具體的牧養行動計劃，'
        '包含短期（本週）、中期（本月）和長期（3 個月）的跟進步驟。\n');

    final person = people.findByName(name);
    if (person != null) {
      buf.writeln('【會友基本資料】');
      buf.writeln('姓名：${person.name} ／ 類型：${person.personType}');
      buf.writeln('出席狀況：${person.attendance}');
      if (person.notes.isNotEmpty) buf.writeln('備註：${person.notes}');
    } else {
      buf.writeln('（通訊錄中未找到「$name」，請根據以下關懷記錄判斷）');
    }

    final related = care.allCases
        .where((c) => c.memberName.contains(name) || name.contains(c.memberName))
        .toList();
    if (related.isNotEmpty) {
      buf.writeln('\n【關懷案件歷史（${related.length} 件）】');
      for (final c in related.take(10)) {
        buf.writeln('- [${c.status}] ${c.reason}（緊急度：${c.urgency}）');
        final visits = care.visitsForCase(c.id);
        for (final v in visits.take(3)) {
          buf.writeln('  探訪 ${v.visitDate.year}/${v.visitDate.month}/${v.visitDate.day}'
              '：${v.summary}（狀況：${v.condition}）');
        }
      }
    }

    buf.writeln('\n請根據以上資料，生成：\n'
        '(1) 當前屬靈需要評估；\n'
        '(2) 本週具體跟進行動（1-2 項）；\n'
        '(3) 本月牧養目標；\n'
        '(4) 3 個月長期培育方向；\n'
        '(5) 可邀請參與的教會活動或事工建議。\n'
        '請用繁體中文，具體可執行，避免空泛。');
    return buf.toString();
  }

  // ── input dialogs ────────────────────────────────────────────────────────

  /// Generic single-field input dialog — avoids duplicating dialog code.
  Future<void> _askInput({
    required String title,
    required String hint,
    required String confirmLabel,
    required String Function(String) buildPrompt,
  }) async {
    final ctrl = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
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
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (value == null || value.isEmpty) return;
    _run(buildPrompt(value));
  }

  Future<void> _askSermonTopic() => _askInput(
        title: '講道題目',
        hint: '例：盼望、悔改、恩典…',
        confirmLabel: '生成',
        buildPrompt: _buildSermonPrompt,
      );

  Future<void> _askMemberName() => _askInput(
        title: '會友姓名',
        hint: '請輸入會友姓名',
        confirmLabel: '查詢',
        buildPrompt: _buildMemberStatusPrompt,
      );

  // ── v2.1 dialog triggers ─────────────────────────────────────────────────

  Future<void> _askGroupTopic() => _askInput(
        title: '小組主題 ／ 聖經章節',
        hint: '例：約翰福音 3:16、寬恕、信心…',
        confirmLabel: '生成',
        buildPrompt: _buildGroupDiscussionPrompt,
      );

  Future<void> _askEventName() => _askInput(
        title: '活動名稱',
        hint: '例：2026 青年退修會、感恩節晚宴…',
        confirmLabel: '生成文案',
        buildPrompt: _buildEventCopyPrompt,
      );

  Future<void> _askFinancePeriod() => _askInput(
        title: '報告期間',
        hint: '例：2026 年 5 月、2026 年第二季…',
        confirmLabel: '生成草稿',
        buildPrompt: _buildFinanceReportPrompt,
      );

  Future<void> _askPastoralName() => _askInput(
        title: '會友姓名',
        hint: '請輸入需要牧養建議的會友姓名',
        confirmLabel: '生成建議',
        buildPrompt: _buildPastoralActionPrompt,
      );

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
          _SectionDivider(label: '事工輔助'),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.groups_2_outlined,
            color: Colors.orange,
            title: '小組討論問題',
            subtitle: '輸入查經主題或經文，生成破冰、深入與應用問題套組',
            onTap: _askGroupTopic,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.campaign_outlined,
            color: Colors.pink,
            title: '活動文案與海報提示',
            subtitle: '輸入活動名稱，AI 生成海報標題、介紹段落與分享短文',
            onTap: _askEventName,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.receipt_long_outlined,
            color: Colors.green,
            title: '財務報告草稿',
            subtitle: '輸入報告期間，自動生成財務報告範本與健康指標建議',
            onTap: _askFinancePeriod,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.edit_note_outlined,
            color: Colors.deepOrange,
            title: '牧養行動建議',
            subtitle: '輸入會友姓名，生成短中長期具體牧養行動計劃',
            onTap: _askPastoralName,
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
// Section divider
// ============================================================================

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
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
