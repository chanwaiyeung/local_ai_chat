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

// Stats card auto-updates whenever the controller fires notifyListeners.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../controllers/health_controller.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/health_record.dart';
import 'personal_query_screen.dart';

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
      appBar: AppBar(title: Text(AppLocalizations.of(context).healthRecords)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  HealthStatsCard(stats: stats),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.auto_awesome),
                        label: Text(AppLocalizations.of(context).aiHealthAdvisor),
                        onPressed: () {
                          String prompt = '請根據我過去 30 天的健康數據總結，給我一些生活與飲食上的建議：\n';
                          if (stats.avgWeight != null) prompt += '- 平均體重：${stats.avgWeight!.toStringAsFixed(1)} kg\n';
                          if (stats.avgSystolic != null) prompt += '- 平均血壓：${stats.avgSystolic!.toStringAsFixed(0)}/${stats.avgDiastolic?.toStringAsFixed(0) ?? '?'} mmHg\n';
                          if (stats.totalSteps > 0) prompt += '- 近期總步數：${stats.totalSteps} 步\n';
                          if (stats.avgSleepHours != null) prompt += '- 平均睡眠：${stats.avgSleepHours!.toStringAsFixed(1)} 小時\n';
                          prompt += '\n請告訴我目前的健康狀態如何，以及需要注意什麼？';

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PersonalQueryScreen(
                                ragService: globalPersonalRagService,
                                initialQuery: prompt,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  _HealthTrendsCard(records: widget.controller.getAllRecords()),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).searchHealthHint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: const OutlineInputBorder(),
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
                          height: MediaQuery.of(context).size.height * 0.3,
                          child: Center(
                            child: Text(AppLocalizations.of(context).noHealthRecords),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(AppLocalizations.of(context).noRecordsLast30Days),
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
                  AppLocalizations.of(context).last30DaysOverview,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  AppLocalizations.of(context).recordCountUnit(stats.recordCount),
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
              ],
            ),
            const Divider(),
            if (stats.avgWeight != null)
              _StatRow(
                label: AppLocalizations.of(context).weight,
                value: AppLocalizations.of(context).avgWeightStat(stats.avgWeight!.toStringAsFixed(1), stats.weightCount),
              ),
            if (stats.avgSystolic != null && stats.avgDiastolic != null)
              _StatRow(
                label: AppLocalizations.of(context).bloodPressure,
                value: AppLocalizations.of(context).avgBpStat(stats.avgSystolic!.toStringAsFixed(0), stats.avgDiastolic!.toStringAsFixed(0), stats.bloodPressureCount),
              ),
            if (stats.avgHeartRate != null)
              _StatRow(
                label: AppLocalizations.of(context).heartRate,
                value: AppLocalizations.of(context).avgHeartRateStat(stats.avgHeartRate!.toStringAsFixed(0), stats.heartRateCount),
              ),
            if (stats.totalSteps > 0)
              _StatRow(
                label: AppLocalizations.of(context).steps,
                value: AppLocalizations.of(context).totalStepsStat(stats.totalSteps.toString(), stats.stepsCount),
              ),
            if (stats.avgSleepHours != null)
              _StatRow(
                label: AppLocalizations.of(context).sleep,
                value: AppLocalizations.of(context).avgSleepStat(stats.avgSleepHours!.toStringAsFixed(1), stats.sleepCount),
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
              ? (record.notes.isEmpty ? AppLocalizations.of(context).noDataLabel : record.notes)
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
  State<HealthRecordFormDialog> createState() => _HealthRecordFormDialogState();
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
    int? parseInt(String s) => s.trim().isEmpty ? null : int.tryParse(s.trim());

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
      setState(() => _topError = AppLocalizations.of(context).fillAtLeastOneMeasurement);
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
              widget.existing == null ? AppLocalizations.of(context).addHealthRecord : AppLocalizations.of(context).editHealthRecord,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppLocalizations.of(context).measurementDate),
              subtitle: Text('${_date.year}/${_date.month}/${_date.day}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _weightCtrl,
              decoration: InputDecoration(labelText: AppLocalizations.of(context).weightKg),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _systolicCtrl,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context).systolicMmHg),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _diastolicCtrl,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context).diastolicMmHg),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _heartRateCtrl,
              decoration: InputDecoration(labelText: AppLocalizations.of(context).heartRateBpm),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _stepsCtrl,
              decoration: InputDecoration(labelText: AppLocalizations.of(context).steps),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _sleepCtrl,
              decoration: InputDecoration(labelText: AppLocalizations.of(context).sleepHours),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              decoration: InputDecoration(labelText: AppLocalizations.of(context).notes),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _tagsCtrl,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).tagsCommaSeparated,
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
              child: Text(AppLocalizations.of(context).saveButton),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Trend Charts
// ============================================================================

class _HealthTrendsCard extends StatelessWidget {
  const _HealthTrendsCard({required this.records});
  final List<HealthRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();

    // Sort records by date ascending for trend
    final sorted = List<HealthRecord>.from(records)
      ..sort((a, b) => a.date.compareTo(b.date));

    final weights = sorted.map((e) => e.weight).whereType<double>().toList();
    final steps = sorted.map((e) => e.steps).whereType<int>().toList();
    final systolic = sorted.map((e) => e.systolic).whereType<int>().toList();
    final sleep = sorted.map((e) => e.sleepHours).whereType<double>().toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).trendCharts, style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            if (weights.isNotEmpty) ...[
              Text(AppLocalizations.of(context).weightTrend, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              SizedBox(
                height: 80,
                width: double.infinity,
                child: _buildLineChart(weights, Colors.blue),
              ),
              const SizedBox(height: 12),
            ],
            if (systolic.isNotEmpty) ...[
              Text(AppLocalizations.of(context).systolicTrend, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              SizedBox(
                height: 80,
                width: double.infinity,
                child: _buildLineChart(systolic.map((e) => e.toDouble()).toList(), Colors.redAccent),
              ),
              const SizedBox(height: 12),
            ],
            if (steps.isNotEmpty) ...[
              Text(AppLocalizations.of(context).steps, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              SizedBox(
                height: 80,
                width: double.infinity,
                child: _buildBarChart(steps.map((e) => e.toDouble()).toList(), Colors.green),
              ),
              const SizedBox(height: 12),
            ],
            if (sleep.isNotEmpty) ...[
              Text(AppLocalizations.of(context).sleepHoursLabel, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              SizedBox(
                height: 80,
                width: double.infinity,
                child: _buildBarChart(sleep, Colors.purpleAccent),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List<double> data, Color color) {
    if (data.isEmpty) return const SizedBox.shrink();

    double minVal = data.reduce((a, b) => a < b ? a : b);
    double maxVal = data.reduce((a, b) => a > b ? a : b);
    if (maxVal == minVal) {
      minVal -= 1;
      maxVal += 1;
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (data.length - 1 < 1) ? 1 : (data.length - 1).toDouble(),
        minY: minVal - (maxVal - minVal) * 0.1,
        maxY: maxVal + (maxVal - minVal) * 0.1,
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) => LineTooltipItem(
                    spot.y.toStringAsFixed(1),
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  )).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i])),
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: data.length == 1),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.2),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildBarChart(List<double> data, Color color) {
    if (data.isEmpty) return const SizedBox.shrink();

    double maxVal = data.reduce((a, b) => a > b ? a : b);
    if (maxVal <= 0) maxVal = 1;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal * 1.1,
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY.toInt().toString(),
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        barGroups: List.generate(
          data.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data[i],
                color: color,
                width: 12,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          ),
        ),
      ),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }
}

