// lib/screens/wealth_screen.dart

//

// Phase 7.0'a (v2.4) — Investment / wealth UI.

// Layout:  AppBar [投資理財] + TabBar [紀錄][配置]

//          Tab 紀錄: stats card + currency picker + search + list

//          Tab 配置: pie chart of allocation + line chart of net worth

//

// Diff vs Antigravity local v0:

//   * REMOVED `import '../main.dart'` (was reaching into globalPersonalRagService).

//     Optional [ragService] is now a constructor param — testable, no globals.

//   * Form actually shows currency dropdown, tags input, AND a date picker.

//     (Local version declared the controllers but never put them in the UI.)

//   * Required validators on amount and assetType.

//   * Net-worth chart drawn from controller.getNetWorthHistory() — no more

//     "naive cumulative sum of all amounts" bug.

//   * Pie chart shouldRepaint compares the allocation map.

//   * Currency picker (ChoiceChip row) when ≥2 currencies present.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/wealth_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/wealth_record.dart';
import '../services/app_settings_service.dart';
import '../services/currency_service.dart';
import '../services/personal_rag_service.dart';
import '../services/vision_llm_service.dart';
import '../widgets/wealth/wealth_monthly_report_card.dart';
import 'personal_query_screen.dart';

class WealthScreen extends StatefulWidget {
  const WealthScreen({
    super.key,
    required this.controller,
    this.ragService,
  });

  final WealthController controller;

  /// When non-null, the "AI 理財顧問" button opens [PersonalQueryScreen].

  /// When null, the button is hidden.

  final PersonalRagService? ragService;

  @override
  State<WealthScreen> createState() => _WealthScreenState();
}

class _WealthScreenState extends State<WealthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  String _query = '';

  String? _selectedCurrency;

  @override
  void initState() {
    super.initState();

    _tabCtrl = TabController(length: 2, vsync: this);

    widget.controller.addListener(_onChanged);
    CurrencyService.instance.addListener(_onCurrencyChanged);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();

    widget.controller.removeListener(_onChanged);
    CurrencyService.instance.removeListener(_onCurrencyChanged);

    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _onCurrencyChanged() {
    if (!mounted) return;
    setState(() => _selectedCurrency = null);
  }

  String _resolveCurrency() {
    final available = widget.controller.getCurrencies();

    if (_selectedCurrency != null && available.contains(_selectedCurrency)) {
      return _selectedCurrency!;
    }
    return CurrencyService.instance.code;
  }

  Future<void> _openForm({WealthRecord? existing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: WealthRecordFormDialog(
          existing: existing,
          onSave: (r) async {
            await widget.controller.saveRecord(r);

            if (ctx.mounted) Navigator.of(ctx).pop();
          },
        ),
      ),
    );
  }

  void _openAiAdvisor() {
    final svc = widget.ragService;

    if (svc == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonalQueryScreen(ragService: svc),
      ),
    );
  }

  Future<void> _scanAsset() async {
    final settings = await AppSettingsService().load();
    final apiKey = settings.geminiApiKey?.trim();

    if (apiKey == null || apiKey.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先前往 Settings 設定 Gemini API Key')),
      );
      return;
    }

    final picker = ImagePicker();
    if (!mounted) return;
    final image = await showDialog<XFile?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('掃描資產'),
        content: const Text('請選擇圖片來源'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: const Text('拍照'),
            onPressed: () async {
              final img = await picker.pickImage(
                source: ImageSource.camera,
                imageQuality: 90,
              );
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext, img);
              }
            },
          ),
          TextButton.icon(
            icon: const Icon(Icons.photo_library),
            label: const Text('從相簿選擇'),
            onPressed: () async {
              final img = await picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 90,
              );
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext, img);
              }
            },
          ),
        ],
      ),
    );

    if (image == null || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('AI 正在分析圖片...\n這可能需要幾秒鐘'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    try {
      final visionService = VisionLLMService();
      final record = await visionService.scanWealthFromImage(
        image.path,
        apiKey: apiKey,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (record != null) {
        _openForm(existing: record);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI 已成功辨識資產，請確認後儲存')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI 無法辨識清晰資產，請換張更清楚的圖片或手動輸入')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '掃描失敗：${e.toString().replaceAll('VisionLlmException: ', '')}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currency = _resolveCurrency();

    final currencies = widget.controller.getCurrencies();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).wealth),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: [
            Tab(
                text: AppLocalizations.of(context).tabRecords,
                icon: const Icon(Icons.list)),
            Tab(
                text: AppLocalizations.of(context).tabAllocation,
                icon: const Icon(Icons.pie_chart_outline)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _RecordsTab(
            controller: widget.controller,
            currency: currency,
            currencies: currencies,
            query: _query,
            onQueryChanged: (v) => setState(() => _query = v),
            onCurrencyChanged: (c) => setState(() => _selectedCurrency = c),
            onEdit: (r) => _openForm(existing: r),
            onAiAdvisor: widget.ragService == null ? null : _openAiAdvisor,
          ),
          _AllocationTab(
            controller: widget.controller,
            currency: currency,
            currencies: currencies,
            onCurrencyChanged: (c) => setState(() => _selectedCurrency = c),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: Text(l10n.addManually),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton.filled(
              tooltip: '掃描資產',
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
              ),
              onPressed: _scanAsset,
              icon: const Icon(Icons.camera_alt),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================

// Records tab

// ============================================================================

class _RecordsTab extends StatelessWidget {
  const _RecordsTab({
    required this.controller,
    required this.currency,
    required this.currencies,
    required this.query,
    required this.onQueryChanged,
    required this.onCurrencyChanged,
    required this.onEdit,
    this.onAiAdvisor,
  });

  final WealthController controller;

  final String currency;

  final List<String> currencies;

  final String query;

  final ValueChanged<String> onQueryChanged;

  final ValueChanged<String> onCurrencyChanged;

  final void Function(WealthRecord) onEdit;

  final VoidCallback? onAiAdvisor;

  @override
  Widget build(BuildContext context) {
    final records = query.trim().isEmpty
        ? controller.getAllRecords()
        : controller.searchRecords(query);

    final stats = controller.getStats(currency: currency);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 96),
      child: Column(
        children: [
          WealthStatsCard(stats: stats),
          WealthMonthlyReportCard(
            controller: controller,
            currency: currency,
          ),
          const SizedBox(height: 8),
          // === CSV 匯出按鈕 ===
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.download),
                label: Text(AppLocalizations.of(context).wealthExportCsv),
                onPressed: () {
                  final csv = controller.exportToCsv();
                  // 先複製到剪貼簿（最簡單跨平台）
                  Clipboard.setData(ClipboardData(text: csv));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text(AppLocalizations.of(context).wealthCsvCopied),
                    ),
                  );
                },
              ),
            ),
          ),
          if (onAiAdvisor != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(AppLocalizations.of(context).aiFinancialAdvisor),
                  onPressed: onAiAdvisor,
                ),
              ),
            ),
          if (currencies.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _CurrencyPicker(
                current: currency,
                available: currencies,
                onChanged: onCurrencyChanged,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).searchAssetHint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: onQueryChanged,
            ),
          ),
          if (records.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(AppLocalizations.of(context).noInvestmentRecords),
              ),
            )
          else
            for (var i = 0; i < records.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
              WealthRecordCard(
                record: records[i],
                onTap: () => onEdit(records[i]),
                onDelete: () => controller.deleteRecord(records[i].id),
              ),
            ],
        ],
      ),
    );
  }
}

// ============================================================================

// Allocation tab

// ============================================================================

class _AllocationTab extends StatelessWidget {
  const _AllocationTab({
    required this.controller,
    required this.currency,
    required this.currencies,
    required this.onCurrencyChanged,
  });

  final WealthController controller;

  final String currency;

  final List<String> currencies;

  final ValueChanged<String> onCurrencyChanged;

  @override
  Widget build(BuildContext context) {
    final stats = controller.getStats(currency: currency);

    final history = controller.getNetWorthHistory(currency: currency);

    if (stats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context).noDataToChart),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context).addFirstRecordHint,
                  style: TextStyle(color: Theme.of(context).hintColor)),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (currencies.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CurrencyPicker(
                current: currency,
                available: currencies,
                onChanged: onCurrencyChanged,
              ),
            ),
          AssetAllocationCard(
            allocation: stats.allocationByType,
            currency: currency,
            total: stats.totalNetWorth,
          ),
          const SizedBox(height: 12),
          NetWorthHistoryCard(history: history, currency: currency),
        ],
      ),
    );
  }
}

// ============================================================================

// Cards

// ============================================================================

class WealthStatsCard extends StatelessWidget {
  const WealthStatsCard({super.key, required this.stats});

  final WealthStats stats;

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(AppLocalizations.of(context).noInvestmentRecords)),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.account_balance_outlined),
              const SizedBox(width: 8),
              Text(
                  '${AppLocalizations.of(context).netWorthOverview}（${stats.currency}）',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(
                  AppLocalizations.of(context)
                      .assetCountLabel(stats.assetCount),
                  style: TextStyle(color: Theme.of(context).hintColor)),
            ]),
            const Divider(),
            Text(stats.totalNetWorth.toStringAsFixed(2),
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(AppLocalizations.of(context).valuationNote,
                style: TextStyle(
                    fontSize: 11, color: Theme.of(context).hintColor)),
          ],
        ),
      ),
    );
  }
}

class WealthRecordCard extends StatelessWidget {
  const WealthRecordCard({
    super.key,
    required this.record,
    required this.onTap,
    required this.onDelete,
  });

  final WealthRecord record;

  final VoidCallback onTap;

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${record.date.year}/${record.date.month}/${record.date.day}';

    final typeLabel = WealthAssetType.label(record.assetType);

    final assetTitle = record.assetName.isEmpty
        ? typeLabel
        : '$typeLabel · ${record.assetName}';

    return Dismissible(
      key: ValueKey('wealth_${record.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        title: Text(assetTitle),
        subtitle: Text([
          dateText,
          if (record.notes.isNotEmpty) record.notes,
        ].join(' · ')),
        trailing: Text(
          '${record.amount.toStringAsFixed(2)} ${record.currency}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _CurrencyPicker extends StatelessWidget {
  const _CurrencyPicker({
    required this.current,
    required this.available,
    required this.onChanged,
  });

  final String current;

  final List<String> available;

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(AppLocalizations.of(context).currencyLabel,
          style: TextStyle(color: Theme.of(context).hintColor)),
      const SizedBox(width: 8),
      Expanded(
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final c in available)
              ChoiceChip(
                label: Text(c),
                selected: c == current,
                onSelected: (_) => onChanged(c),
              ),
          ],
        ),
      ),
    ]);
  }
}

class AssetAllocationCard extends StatelessWidget {
  const AssetAllocationCard({
    super.key,
    required this.allocation,
    required this.currency,
    required this.total,
  });

  final Map<String, double> allocation;

  final String currency;

  final double total;

  static const List<Color> _palette = [
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.orange,
    Colors.red,
    Colors.teal,
    Colors.amber,
    Colors.indigo,
    Colors.pink,
    Colors.cyan,
  ];

  @override
  Widget build(BuildContext context) {
    final entries = allocation.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colorOf = <String, Color>{
      for (var i = 0; i < entries.length; i++)
        entries[i].key: _palette[i % _palette.length],
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${AppLocalizations.of(context).assetAllocation}（$currency）',
                style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            if (allocation.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text(AppLocalizations.of(context).noData)),
              )
            else ...[
              SizedBox(
                height: 180,
                child: CustomPaint(
                  painter:
                      _PieChartPainter(slices: allocation, colors: colorOf),
                  size: const Size(double.infinity, 180),
                ),
              ),
              const SizedBox(height: 12),
              for (final e in entries)
                _AllocationRow(
                  label: WealthAssetType.label(e.key),
                  amount: e.value,
                  fraction: total == 0 ? 0 : e.value / total,
                  color: colorOf[e.key]!,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AllocationRow extends StatelessWidget {
  const _AllocationRow({
    required this.label,
    required this.amount,
    required this.fraction,
    required this.color,
  });

  final String label;

  final double amount;

  final double fraction;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        Text(
          '${amount.toStringAsFixed(0)}  ${(fraction * 100).toStringAsFixed(1)}%',
          style: TextStyle(color: Theme.of(context).hintColor),
        ),
      ]),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  _PieChartPainter({required this.slices, required this.colors});

  final Map<String, double> slices;

  final Map<String, Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final entries = slices.entries.toList();

    final total = entries.fold<double>(0, (sum, e) => sum + e.value);

    if (total <= 0) return;

    final shorter = math.min(size.width, size.height);

    final radius = shorter / 2 * 0.95;

    final center = Offset(size.width / 2, size.height / 2);

    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -math.pi / 2;

    for (final e in entries) {
      final sweepAngle = (e.value / total) * 2 * math.pi;

      final paint = Paint()
        ..color = colors[e.key] ?? Colors.grey
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      startAngle += sweepAngle;
    }

    final innerPaint = Paint()..color = Colors.white;

    canvas.drawCircle(center, radius * 0.55, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter old) {
    if (old.slices.length != slices.length) return true;

    for (final e in slices.entries) {
      if (old.slices[e.key] != e.value) return true;
    }

    return false;
  }
}

class NetWorthHistoryCard extends StatelessWidget {
  const NetWorthHistoryCard({
    super.key,
    required this.history,
    required this.currency,
  });

  final List<NetWorthSnapshot> history;

  final String currency;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(AppLocalizations.of(context).netWorthTrend,
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(currency,
                  style: TextStyle(color: Theme.of(context).hintColor)),
            ]),
            const SizedBox(height: 12),
            if (history.length < 2)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                    child: Text(
                        AppLocalizations.of(context).needTwoDatesForChart)),
              )
            else
              SizedBox(
                height: 140,
                child: CustomPaint(
                  painter: _NetWorthLinePainter(history: history),
                  size: const Size(double.infinity, 140),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NetWorthLinePainter extends CustomPainter {
  _NetWorthLinePainter({required this.history});

  final List<NetWorthSnapshot> history;

  @override
  void paint(Canvas canvas, Size size) {
    if (history.length < 2) return;

    final values = history.map((h) => h.total).toList();

    final yMin = values.reduce(math.min);

    final yMax = values.reduce(math.max);

    final yRange = math.max(1.0, yMax - yMin);

    final earliest = history.first.date;

    final latest = history.last.date;

    final dateRangeDays =
        math.max(1, latest.difference(earliest).inDays).toDouble();

    const xPad = 4.0;

    const yPad = 12.0;

    final w = size.width - 2 * xPad;

    final h = size.height - 2 * yPad;

    final path = Path();

    final fillPath = Path()..moveTo(xPad, yPad + h);

    for (var i = 0; i < history.length; i++) {
      final h0 = history[i];

      final x =
          xPad + (h0.date.difference(earliest).inDays / dateRangeDays) * w;

      final y = yPad + h - ((h0.total - yMin) / yRange) * h;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      fillPath.lineTo(x, y);
    }

    fillPath.lineTo(xPad + w, yPad + h);

    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..color = Colors.blue.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    final dotPaint = Paint()..color = Colors.blue;

    for (final h0 in history) {
      final x =
          xPad + (h0.date.difference(earliest).inDays / dateRangeDays) * w;

      final y = yPad + h - ((h0.total - yMin) / yRange) * h;

      canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NetWorthLinePainter old) =>
      old.history != history;
}

// ============================================================================

// Form

// ============================================================================

class WealthRecordFormDialog extends StatefulWidget {
  const WealthRecordFormDialog({
    super.key,
    this.existing,
    required this.onSave,
  });

  final WealthRecord? existing;

  final Future<void> Function(WealthRecord) onSave;

  @override
  State<WealthRecordFormDialog> createState() => _WealthRecordFormDialogState();
}

class _WealthRecordFormDialogState extends State<WealthRecordFormDialog> {
  static const List<String> _currencies = [
    'TWD',
    'HKD',
    'USD',
    'CAD',
    'JPY',
    'CNY',
    'EUR',
  ];

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _amountCtrl;

  late final TextEditingController _assetNameCtrl;

  late final TextEditingController _notesCtrl;

  late final TextEditingController _tagsCtrl;

  late String _assetType;

  late String _currency;

  late DateTime _date;

  @override
  void initState() {
    super.initState();

    final r = widget.existing;

    _amountCtrl =
        TextEditingController(text: r == null ? '' : r.amount.toString());

    _assetNameCtrl = TextEditingController(text: r?.assetName ?? '');

    _notesCtrl = TextEditingController(text: r?.notes ?? '');

    _tagsCtrl = TextEditingController(text: (r?.tags ?? const []).join(', '));

    _assetType = r?.assetType ?? WealthAssetType.cash;

    _currency = r?.currency ?? 'TWD';

    _date = r?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();

    _assetNameCtrl.dispose();

    _notesCtrl.dispose();

    _tagsCtrl.dispose();

    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final draft = WealthRecord(
      id: widget.existing?.id ?? '',
      date: _date,
      assetType: _assetType,
      assetName: _assetNameCtrl.text.trim(),
      amount: double.tryParse(_amountCtrl.text.trim()) ?? 0.0,
      currency: _currency,
      notes: _notesCtrl.text.trim(),
      tags: _tagsCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      dateAdded: widget.existing?.dateAdded ?? DateTime.now(),
      source: widget.existing?.source ?? 'manual',
    );

    widget.onSave(draft);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
                widget.existing == null
                    ? AppLocalizations.of(context).addInvestmentRecord
                    : AppLocalizations.of(context).editInvestmentRecord,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppLocalizations.of(context).valuationDate),
              subtitle: Text('${_date.year}/${_date.month}/${_date.day}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _assetType,
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).assetClass),
              items: [
                for (final t in WealthAssetType.all)
                  DropdownMenuItem(
                      value: t, child: Text(WealthAssetType.label(t))),
              ],
              onChanged: (v) =>
                  setState(() => _assetType = v ?? WealthAssetType.other),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _assetNameCtrl,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).assetNameHint,
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _amountCtrl,
                  decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).amount),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    final trimmed = (v ?? '').trim();
                    final n = double.tryParse(trimmed);
                    if (n == null || n <= 0) {
                      return AppLocalizations.of(context).invalidAmountError;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _currency,
                  decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).currency),
                  items: [
                    for (final c in _currencies)
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (v) => setState(() => _currency = v ?? 'TWD'),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).notes),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _tagsCtrl,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).tagsCommaSeparated,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
                onPressed: _submit,
                child: Text(AppLocalizations.of(context).saveButton)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
