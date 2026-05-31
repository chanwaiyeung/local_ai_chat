// lib/widgets/church/visit_log_dialog.dart
import 'package:flutter/material.dart';
import '../../models/church/care_case.dart';
import '../../models/church/visit_log.dart';

/// VisitLogDialog allows recording or editing pastoral care visit logs.
/// All labels are in English as per specification.
class VisitLogDialog extends StatefulWidget {
  const VisitLogDialog({
    super.key,
    required this.caseObj,
    this.existing,
    required this.onSave,
    this.onDelete,
    this.onCloseCase,
  });

  final CareCase caseObj;
  final VisitLog? existing;
  final Future<void> Function(VisitLog) onSave;
  final Future<void> Function()? onDelete;
  final Future<void> Function()? onCloseCase;

  @override
  State<VisitLogDialog> createState() => _VisitLogDialogState();
}

class _VisitLogDialogState extends State<VisitLogDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _visitedByCtrl;
  late final TextEditingController _summaryCtrl;
  late DateTime _visitDate;
  late String _method;
  late String _condition;
  DateTime? _nextFollowUpDate;
  bool _closeCase = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _visitedByCtrl = TextEditingController(text: e?.visitedBy ?? '');
    
    // Parse Next Follow-up Date if it exists in the summary
    String initialSummary = e?.summary ?? '';
    DateTime? parsedNextFollowUp;
    final regExp = RegExp(r'\n\[Next Follow-up: (\d{4}-\d{2}-\d{2})\]$');
    final match = regExp.firstMatch(initialSummary);
    if (match != null) {
      parsedNextFollowUp = DateTime.tryParse(match.group(1)!);
      initialSummary = initialSummary.replaceAll(regExp, '');
    }

    _summaryCtrl = TextEditingController(text: initialSummary);
    _visitDate = e?.visitDate ?? DateTime.now();
    _method = e?.method ?? VisitMethod.inPerson;
    _condition = e?.condition ?? MemberCondition.good;
    _nextFollowUpDate = parsedNextFollowUp;
  }

  @override
  void dispose() {
    _visitedByCtrl.dispose();
    _summaryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickVisitDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _visitDate = picked);
    }
  }

  Future<void> _pickNextFollowUpDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextFollowUpDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _nextFollowUpDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    String finalSummary = _summaryCtrl.text.trim();
    if (_nextFollowUpDate != null) {
      finalSummary += '\n[Next Follow-up: ${_fmtDate(_nextFollowUpDate!)}]';
    }

    final base = widget.existing ??
        VisitLog(caseId: widget.caseObj.id, visitedBy: '', summary: '');
    final visit = base.copyWith(
      caseId: widget.caseObj.id,
      visitDate: _visitDate,
      visitedBy: _visitedByCtrl.text.trim(),
      method: _method,
      summary: finalSummary,
      condition: _condition,
    );

    try {
      await widget.onSave(visit);
      if (_closeCase && widget.onCloseCase != null) {
        await widget.onCloseCase!();
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Delete this visit log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await widget.onDelete!();
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final canClose = !isEditing && widget.onCloseCase != null;

    final typeOptions = [
      {'label': 'Home Visit', 'value': 'inperson'},
      {'label': 'Hospital Visit', 'value': 'hospital'},
      {'label': 'Phone Call', 'value': 'phone'},
      {'label': 'Message', 'value': 'message'},
    ];

    final conditionOptions = [
      {'label': 'Good', 'value': 'good'},
      {'label': 'Concern', 'value': 'concern'},
      {'label': 'Worsening', 'value': 'worsening'},
    ];

    return AlertDialog(
      title: Text(
        '${isEditing ? "Edit" : "Log"} Visit - ${widget.caseObj.memberName}',
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _visitedByCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Visited By *',
                    hintText: 'Enter name of pastor/carer',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Please enter who visited' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Visit Date:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(_fmtDate(_visitDate)),
                    const Spacer(),
                    TextButton(
                      onPressed: _pickVisitDate,
                      child: const Text('Pick'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Visit Type',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: typeOptions
                      .map((opt) => ChoiceChip(
                            label: Text(opt['label']!),
                            selected: _method == opt['value'],
                            onSelected: (sel) {
                              if (sel) {
                                setState(() => _method = opt['value']!);
                              }
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _summaryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Summary *',
                    hintText: 'Enter a brief summary of the visit',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Please enter notes/summary' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Next Follow-up Date:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(_nextFollowUpDate == null
                        ? 'Optional'
                        : _fmtDate(_nextFollowUpDate!)),
                    const Spacer(),
                    if (_nextFollowUpDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _nextFollowUpDate = null),
                        tooltip: 'Clear Date',
                      ),
                    TextButton(
                      onPressed: _pickNextFollowUpDate,
                      child: const Text('Pick'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Condition',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: conditionOptions
                      .map((opt) => ChoiceChip(
                            label: Text(opt['label']!),
                            selected: _condition == opt['value'],
                            onSelected: (sel) {
                              if (sel) {
                                setState(() => _condition = opt['value']!);
                              }
                            },
                          ))
                      .toList(),
                ),
                if (canClose) ...[
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _closeCase,
                    onChanged: (v) =>
                        setState(() => _closeCase = v ?? false),
                    title: const Text('This case can be closed'),
                    subtitle: const Text('Automatically move to "Closed" after saving'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (widget.onDelete != null)
          TextButton(
            onPressed: _saving ? null : _confirmDelete,
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed:
              _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}


