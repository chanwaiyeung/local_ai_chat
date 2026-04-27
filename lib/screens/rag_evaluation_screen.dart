import 'package:flutter/material.dart';

import '../models/rag_evaluation_record.dart';
import '../services/rag_evaluation_service.dart';

class RagEvaluationScreen extends StatefulWidget {
  const RagEvaluationScreen({
    super.key,
    required this.chatModel,
    required this.embeddingModel,
  });

  final String chatModel;
  final String embeddingModel;

  @override
  State<RagEvaluationScreen> createState() => _RagEvaluationScreenState();
}

class _RagEvaluationScreenState extends State<RagEvaluationScreen> {
  final _service = RagEvaluationService();
  final _records = <RagEvaluationRecord>[];

  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  final _citationTextController = TextEditingController();
  final _citationTargetController = TextEditingController();
  final _notesController = TextEditingController();
  final _editorController = ExpansibleController();

  RagExpectedStatus _expected = RagExpectedStatus.exists;
  RagVerdict _verdict = RagVerdict.unsure;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _citationTextController.dispose();
    _citationTargetController.dispose();
    _notesController.dispose();
    _editorController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    final records = await _service.loadRecords();
    if (!mounted) return;
    setState(() {
      _records
        ..clear()
        ..addAll(records);
      _loading = false;
    });
  }

  Future<void> _persist() async {
    setState(() => _saving = true);
    await _service.saveRecords(_records);
    if (!mounted) return;
    setState(() => _saving = false);
  }

  Future<void> _addRecord() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先輸入問題')),
      );
      return;
    }

    debugPrint('Saving expected=$_expected verdict=$_verdict');

    final record = createRagEvaluationRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      question: question,
      answer: _answerController.text.trim(),
      citationText: _citationTextController.text.trim(),
      citationTarget: _citationTargetController.text.trim(),
      expectedStatus: _expected,
      verdict: _verdict,
      notes: _notesController.text.trim(),
      chatModel: widget.chatModel,
      embeddingModel: widget.embeddingModel,
      createdAt: DateTime.now(),
    );

    debugPrint(
      'Record created expected=${record.expectedStatus} '
      'verdict=${record.verdict}',
    );

    setState(() {
      _records.insert(0, record);
      _questionController.clear();
      _answerController.clear();
      _citationTextController.clear();
      _citationTargetController.clear();
      _notesController.clear();
    });

    _editorController.collapse();

    await _persist();
  }

  Future<void> _deleteRecord(RagEvaluationRecord record) async {
    setState(() => _records.remove(record));
    await _persist();
  }

  Future<void> _clearRecords() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空所有記錄？'),
        content: const Text('此操作無法復原。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清空'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _records.clear());
    await _persist();
  }

  Future<void> _exportJson() async {
    if (_records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('沒有可匯出的記錄')),
      );
      return;
    }

    final file = await _service.exportSnapshot(_records);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已匯出：${file.path}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = summarizeRagEvaluationRecords(_records);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RAG 評測記錄'),
        actions: [
          IconButton(
            tooltip: '匯出 JSON',
            onPressed: _exportJson,
            icon: const Icon(Icons.file_download_outlined),
          ),
          IconButton(
            tooltip: '清空',
            onPressed: _records.isEmpty ? null : _clearRecords,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_saving) const LinearProgressIndicator(),
                _StatsCard(
                  total: summary.total,
                  pass: summary.pass,
                  fail: summary.fail,
                  unsure: summary.unsure,
                  passRate: summary.passRate,
                  chatModel: widget.chatModel,
                  embeddingModel: widget.embeddingModel,
                ),
                const SizedBox(height: 12),
                _buildEditor(),
                const SizedBox(height: 12),
                if (_records.isEmpty)
                  const _EmptyState()
                else
                  for (final record in _records)
                    _RecordCard(
                      record: record,
                      onDelete: () => _deleteRecord(record),
                    ),
              ],
            ),
    );
  }

  Widget _buildEditor() {
    return Card(
      child: ExpansionTile(
        controller: _editorController,
        title: const Text('新增評測記錄'),
        subtitle: Text(
          'Chat: ${widget.chatModel} · Embedding: ${widget.embeddingModel}',
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _questionController,
            decoration: const InputDecoration(
              labelText: 'Question',
              border: OutlineInputBorder(),
            ),
            minLines: 1,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _answerController,
            decoration: const InputDecoration(
              labelText: 'Answer',
              border: OutlineInputBorder(),
            ),
            minLines: 2,
            maxLines: 6,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _citationTextController,
            decoration: const InputDecoration(
              labelText: 'Citation text',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _citationTargetController,
            decoration: const InputDecoration(
              labelText: 'Citation target',
              hintText: 'chunk:?doc=<document>&i=<chunkIndex>',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Current enum: ${_expected.name} / ${_verdict.name}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Expected status',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: _buildExpectedChips(),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Verdict',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: _buildVerdictChips(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
            minLines: 1,
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _addRecord,
              icon: const Icon(Icons.add),
              label: const Text('儲存記錄'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpectedChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: RagExpectedStatus.values.map((value) {
        return FilterChip(
          label: Text(value.name),
          selected: _expected == value,
          onSelected: (_) {
            setState(() => _expected = value);
            debugPrint('Expected changed: $value');
          },
        );
      }).toList(),
    );
  }

  Widget _buildVerdictChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: RagVerdict.values.map((value) {
        return FilterChip(
          label: Text(value.name),
          selected: _verdict == value,
          onSelected: (_) {
            setState(() => _verdict = value);
            debugPrint('Verdict changed: $value');
          },
        );
      }).toList(),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.total,
    required this.pass,
    required this.fail,
    required this.unsure,
    required this.passRate,
    required this.chatModel,
    required this.embeddingModel,
  });

  final int total;
  final int pass;
  final int fail;
  final int unsure;
  final double? passRate;
  final String chatModel;
  final String embeddingModel;

  @override
  Widget build(BuildContext context) {
    final rateText =
        passRate == null ? '-' : '${(passRate! * 100).toStringAsFixed(1)}%';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            Chip(label: Text('Total: $total')),
            Chip(label: Text('Pass: $pass')),
            Chip(label: Text('Fail: $fail')),
            Chip(label: Text('Unsure: $unsure')),
            Chip(label: Text('Pass rate: $rateText')),
            Chip(label: Text('Chat: $chatModel')),
            Chip(label: Text('Embedding: $embeddingModel')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.fact_check_outlined, size: 48),
          SizedBox(height: 12),
          Text('尚未有 RAG 評測記錄'),
          SizedBox(height: 4),
          Text('點擊「新增評測記錄」開始保存人工驗收結果。'),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
    required this.onDelete,
  });

  final RagEvaluationRecord record;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(record.question),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Expected: ${record.expectedStatus.name}'),
            Text('Verdict: ${record.verdict.name}'),
            if (record.citationTarget.isNotEmpty)
              Text('Citation: ${record.citationTarget}'),
            if (record.notes.isNotEmpty) Text('Notes: ${record.notes}'),
            Text(
              'Chat: ${record.chatModel} · Embedding: ${record.embeddingModel}',
            ),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: '刪除',
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
