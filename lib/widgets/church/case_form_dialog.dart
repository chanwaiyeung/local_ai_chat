// lib/widgets/church/case_form_dialog.dart
import 'package:flutter/material.dart';
import '../../models/church/care_case.dart';

/// Add / Edit / Delete a [CareCase]. Status is NOT exposed here — new cases
/// always start active, and closing is done via dashboard action buttons.
class CaseFormDialog extends StatefulWidget {
  const CaseFormDialog({
    super.key,
    this.existing,
    this.defaultType,
    required this.onSave,
    this.onDelete,
  });

  final CareCase? existing;
  final String? defaultType;
  final Future<void> Function(CareCase) onSave;
  final Future<void> Function()? onDelete;

  @override
  State<CaseFormDialog> createState() => _CaseFormDialogState();
}

class _CaseFormDialogState extends State<CaseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _reasonCtrl;
  late final TextEditingController _createdByCtrl;
  late final TextEditingController _notesCtrl;
  late String _urgency;
  late String _caseType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.memberName ?? '');
    _phoneCtrl = TextEditingController(text: e?.memberPhone ?? '');
    _reasonCtrl = TextEditingController(text: e?.reason ?? '');
    _createdByCtrl = TextEditingController(text: e?.createdBy ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _urgency = e?.urgency ?? CareUrgency.medium;
    _caseType = e?.caseType ?? widget.defaultType ?? CaseType.member;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _reasonCtrl.dispose();
    _createdByCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final base = widget.existing ?? CareCase(memberName: '', reason: '');
    final caseObj = base.copyWith(
      memberName: _nameCtrl.text.trim(),
      memberPhone: _phoneCtrl.text.trim(),
      reason: _reasonCtrl.text.trim(),
      caseType: _caseType,
      urgency: _urgency,
      createdBy: _createdByCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );
    try {
      await widget.onSave(caseObj);
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
        content: const Text('此案件和所有相關探訪記錄都會被永久刪除。'),
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
    return AlertDialog(
      title: Text(isEditing ? '編輯案件' : '新增關懷案件'),
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
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: '會友姓名 *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '請輸入姓名' : null,
                ),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(labelText: '電話(可空)'),
                  keyboardType: TextInputType.phone,
                ),
                TextFormField(
                  controller: _reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: '緣由 *(例:住院、喪父、新朋友追蹤)',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '請輸入緣由' : null,
                ),
                const SizedBox(height: 16),
                const Text('身分', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: CaseType.all
                      .map((t) => ChoiceChip(
                            label: Text(CaseType.label(t)),
                            selected: _caseType == t,
                            onSelected: (sel) {
                              if (sel) setState(() => _caseType = t);
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                const Text('優先程度', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: CareUrgency.all
                      .map((u) => ChoiceChip(
                            label: Text(CareUrgency.label(u)),
                            selected: _urgency == u,
                            onSelected: (sel) {
                              if (sel) setState(() => _urgency = u);
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 4),
                Text(
                  '高 = 3 天紅燈 / 中 = 7 天紅燈 / 低 = 14 天紅燈',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _createdByCtrl,
                  decoration: const InputDecoration(labelText: '開立者(傳道人姓名)'),
                ),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(labelText: '備註(可空)'),
                  maxLines: 2,
                ),
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
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? '儲存中...' : '儲存'),
        ),
      ],
    );
  }
}
