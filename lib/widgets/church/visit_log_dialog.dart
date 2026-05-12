// lib/widgets/church/visit_log_dialog.dart
import 'package:flutter/material.dart';
import '../../models/church/care_case.dart';
import '../../models/church/visit_log.dart';

/// 30-second workflow at the heart of the pastoral care MVP — record one
/// sentence + condition + save. The demo moment: case turns red → green.
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
  bool _closeCase = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _visitedByCtrl = TextEditingController(text: e?.visitedBy ?? '');
    _summaryCtrl = TextEditingController(text: e?.summary ?? '');
    _visitDate = e?.visitDate ?? DateTime.now();
    _method = e?.method ?? VisitMethod.inPerson;
    _condition = e?.condition ?? MemberCondition.good;
  }

  @override
  void dispose() {
    _visitedByCtrl.dispose();
    _summaryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _visitDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final base = widget.existing ??
        VisitLog(caseId: widget.caseObj.id, visitedBy: '', summary: '');
    final visit = base.copyWith(
      caseId: widget.caseObj.id,
      visitDate: _visitDate,
      visitedBy: _visitedByCtrl.text.trim(),
      method: _method,
      summary: _summaryCtrl.text.trim(),
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
          SnackBar(content: Text('儲存失敗:$e')),
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
        title: const Text('確認刪除'),
        content: const Text('刪除此筆探訪記錄?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('刪除', style: TextStyle(color: Colors.red))),
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
    return AlertDialog(
      title: Text(
          '${isEditing ? "編輯" : "記錄"}探訪 — ${widget.caseObj.memberName}'),
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
                  decoration:
                      const InputDecoration(labelText: '探訪者(傳道人姓名)*'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '請輸入探訪者' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('日期:'),
                    const SizedBox(width: 8),
                    Text(_fmtDate(_visitDate)),
                    const Spacer(),
                    TextButton(
                        onPressed: _pickDate, child: const Text('Pick')),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('方式', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: VisitMethod.all
                      .map((m) => ChoiceChip(
                            label: Text(VisitMethod.label(m)),
                            selected: _method == m,
                            onSelected: (sel) {
                              if (sel) setState(() => _method = m);
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _summaryCtrl,
                  decoration: const InputDecoration(
                    labelText: '摘要 *(1-2 句話,讓其他傳道人知道情況)',
                  ),
                  maxLines: 3,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '請寫一句摘要' : null,
                ),
                const SizedBox(height: 12),
                const Text('狀況', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: MemberCondition.all
                      .map((c) => ChoiceChip(
                            label: Text(MemberCondition.label(c)),
                            selected: _condition == c,
                            onSelected: (sel) {
                              if (sel) setState(() => _condition = c);
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
                    title: const Text('此案件可以結案'),
                    subtitle: const Text('儲存後自動移到「已結案」'),
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
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed:
              _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? '儲存中...' : '儲存'),
        ),
      ],
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
