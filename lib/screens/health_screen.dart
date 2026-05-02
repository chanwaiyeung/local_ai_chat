// lib/screens/health_screen.dart
//
// Phase 6.7 (v2.3) — Health module UI.
// Layout:
//   AppBar [健康紀錄]
//   Body
//     ├─ HealthStatsCard (last 30 days summary)
//     ├─ Search bar
//     └─ ListView of HealthRecordCard (newest first)
//   FAB [+] → HealthRecordFormDialog (modal bottom sheet)
//
// Stats card auto-updates whenever the controller fires notifyListeners.

import 'package:flutter/material.dart';

import '../controllers/health_controller.dart';
import '../models/health_record.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key, required this.controller});
  final HealthController controller;

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refresh() async {
    if (mounted) setState(() {});
  }

  Future<void> _openForm({HealthRecord? existing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: HealthRecordFormDialog(
          existing: existing,
          onSave: (r) async {
            await widget.controller.saveRecord(r);
            if (ctx.mounted) Navigator.of(ctx).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.controller.getStats(lastNDays: 30);
    final records = _query.trim().isEmpty
        ? widget.controller.getAllRecords()
        : widget.controller.searchRecords(_query);

    return Scaffold(
      appBar: AppBar(title: const Text('健康紀錄')),
      body: Column(
        children: [
          HealthStatsCard(stats: stats),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: '搜尋備註 / 標籤...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: records.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height:
                              MediaQuery.of(context).size.height * 0.3,
                          child: const Center(
                            child: Text('尚無健康紀錄'),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: records.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, i) => HealthRecordCard(
                        record: records[i],
                        onTap: () => _openForm(existing: records[i]),
                        onDismissed: () =>
                            widget.controller.deleteRecord(records[i].id),
                      ),
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ============================================================================
// HealthStatsCard
// ============================================================================

class HealthStatsCard extends StatelessWidget {
  const HealthStatsCard({super.key, required this.stats});
  final HealthStats stats;

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('最近 30 天暫無紀錄'),
        ),
      );
    }
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite_outline),
                const SizedBox(width: 8),
                Text(
                  '最近 30 天概況',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${stats.recordCount} 筆',
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
              ],
            ),
            const Divider(),
            if (stats.avgWeight != null)
              _StatRow(
                label: '體重',
                value:
                    '平均 ${stats.avgWeight!.toStringAsFixed(1)} kg '
                    '(${stats.weightCount} 次)',
              ),
            if (stats.avgSystolic != null && stats.avgDiastolic != null)
              _StatRow(
                label: '血壓',
                value:
                    '平均 ${stats.avgSystolic!.toStringAsFixed(0)} / '
                    '${stats.avgDiastolic!.toStringAsFixed(0)} mmHg '
                    '(${stats.bloodPressureCount} 次)',
              ),
            if (stats.avgHeartRate != null)
              _StatRow(
                label: '心率',
                value:
                    '平均 ${stats.avgHeartRate!.toStringAsFixed(0)} bpm '
                    '(${stats.heartRateCount} 次)',
              ),
            if (stats.totalSteps > 0)
              _StatRow(
                label: '步數',
                value:
                    '總計 ${stats.totalSteps} 步 (${stats.stepsCount} 天)',
              ),
            if (stats.avgSleepHours != null)
              _StatRow(
                label: '睡眠',
                value:
                    '平均 ${stats.avgSleepHours!.toStringAsFixed(1)} 小時 '
                    '(${stats.sleepCount} 次)',
              ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// ============================================================================
// HealthRecordCard
// ============================================================================

class HealthRecordCard extends StatelessWidget {
  const HealthRecordCard({
    super.key,
    required this.record,
    required this.onTap,
    required this.onDismissed,
  });
  final HealthRecord record;
  final VoidCallback onTap;
  final Future<bool> Function() onDismissed;

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${record.date.year}/${record.date.month}/${record.date.day}';
    final summary = <String>[];
    if (record.weight != null) {
      summary.add('${record.weight!.toStringAsFixed(1)}kg');
    }
    if (record.systolic != null && record.diastolic != null) {
      summary.add('${record.systolic}/${record.diastolic}');
    }
    if (record.heartRate != null) summary.add('${record.heartRate}bpm');
    if (record.steps != null) summary.add('${record.steps}步');
    if (record.sleepHours != null) {
      summary.add('${record.sleepHours!.toStringAsFixed(1)}h睡眠');
    }

    return Dismissible(
      key: ValueKey('health_card_${record.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        onDismissed();
      },
      child: ListTile(
        title: Text(dateText),
        subtitle: Text(
          summary.isEmpty
              ? (record.notes.isEmpty ? '(無資料)' : record.notes)
              : summary.join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: onTap,
      ),
    );
  }
}

// ============================================================================
// HealthRecordFormDialog
// ============================================================================

class HealthRecordFormDialog extends StatefulWidget {
  const HealthRecordFormDialog({
    super.key,
    this.existing,
    required this.onSave,
  });
  final HealthRecord? existing;
  final Future<void> Function(HealthRecord) onSave;

  @override
  State<HealthRecordFormDialog> createState() =>
      _HealthRecordFormDialogState();
}

class _HealthRecordFormDialogState extends State<HealthRecordFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weightCtrl;
  late final TextEditingController _systolicCtrl;
  late final TextEditingController _diastolicCtrl;
  late final TextEditingController _heartRateCtrl;
  late final TextEditingController _stepsCtrl;
  late final TextEditingController _sleepCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _tagsCtrl;
  late DateTime _date;

  String? _topError;

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    _weightCtrl = TextEditingController(
      text: r?.weight?.toString() ?? '',
    );
    _systolicCtrl = TextEditingController(
      text: r?.systolic?.toString() ?? '',
    );
    _diastolicCtrl = TextEditingController(
      text: r?.diastolic?.toString() ?? '',
    );
    _heartRateCtrl = TextEditingController(
      text: r?.heartRate?.toString() ?? '',
    );
    _stepsCtrl = TextEditingController(text: r?.steps?.toString() ?? '');
    _sleepCtrl = TextEditingController(
      text: r?.sleepHours?.toString() ?? '',
    );
    _notesCtrl = TextEditingController(text: r?.notes ?? '');
    _tagsCtrl = TextEditingController(text: (r?.tags ?? const []).join(', '));
    _date = r?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _systolicCtrl.dispose();
    _diastolicCtrl.dispose();
    _heartRateCtrl.dispose();
    _stepsCtrl.dispose();
    _sleepCtrl.dispose();
    _notesCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    double? parseDouble(String s) =>
        s.trim().isEmpty ? null : double.tryParse(s.trim());
    int? parseInt(String s) =>
        s.trim().isEmpty ? null : int.tryParse(s.trim());

    final draft = HealthRecord(
      id: widget.existing?.id ?? '',
      date: _date,
      weight: parseDouble(_weightCtrl.text),
      systolic: parseInt(_systolicCtrl.text),
      diastolic: parseInt(_diastolicCtrl.text),
      heartRate: parseInt(_heartRateCtrl.text),
      steps: parseInt(_stepsCtrl.text),
      sleepHours: parseDouble(_sleepCtrl.text),
      notes: _notesCtrl.text.trim(),
      tags: _tagsCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      dateAdded: widget.existing?.dateAdded ?? DateTime.now(),
      source: widget.existing?.source ?? 'manual',
    );

    if (!draft.hasAnyMeasurement && draft.notes.isEmpty) {
      setState(() => _topError = '請至少填寫一項測量值或備註');
      return;
    }

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
              widget.existing == null ? '新增健康紀錄' : '編輯健康紀錄',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('測量日期'),
              subtitle: Text('${_date.year}/${_date.month}/${_date.day}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _weightCtrl,
              decoration: const InputDecoration(labelText: '體重 (kg)'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _systolicCtrl,
                    decoration:
                        const InputDecoration(labelText: '收縮壓 (mmHg)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _diastolicCtrl,
                    decoration:
                        const InputDecoration(labelText: '舒張壓 (mmHg)'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _heartRateCtrl,
              decoration: const InputDecoration(labelText: '心率 (bpm)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _stepsCtrl,
              decoration: const InputDecoration(labelText: '步數'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _sleepCtrl,
              decoration:
                  const InputDecoration(labelText: '睡眠時數 (小時)'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: '備註'),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _tagsCtrl,
              decoration: const InputDecoration(
                labelText: '標籤（逗號分隔）',
              ),
            ),
            if (_topError != null) ...[
              const SizedBox(height: 12),
              Text(
                _topError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              child: const Text('儲存'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
