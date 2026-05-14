// lib/widgets/church/person_form_dialog.dart
import 'package:flutter/material.dart';
import '../../models/church/person.dart';

class PersonFormDialog extends StatefulWidget {
  const PersonFormDialog({
    super.key,
    this.existing,
    this.defaultType,
    required this.onSave,
    this.onDelete,
  });

  final Person? existing;
  final String? defaultType;
  final Future<void> Function(Person) onSave;
  final Future<void> Function()? onDelete;

  @override
  State<PersonFormDialog> createState() => _PersonFormDialogState();
}

class _PersonFormDialogState extends State<PersonFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _smallGroupCtrl;
  late final TextEditingController _sundaySchoolCtrl;
  late final TextEditingController _createdByCtrl;
  late final TextEditingController _notesCtrl;
  DateTime? _birthday;
  DateTime? _baptismDate;
  DateTime? _joinDate;
  late String _attendance;
  late String _personType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _personType = widget.existing?.personType ?? widget.defaultType ?? PersonType.member;
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _phoneCtrl = TextEditingController(text: e?.phone ?? '');
    _smallGroupCtrl = TextEditingController(text: e?.smallGroup ?? '');
    _sundaySchoolCtrl =
        TextEditingController(text: e?.sundaySchool ?? '');
    _createdByCtrl = TextEditingController(text: e?.createdBy ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _birthday = e?.birthday;
    _baptismDate = e?.baptismDate;
    _joinDate = e?.joinDate;
    _attendance = e?.attendance ?? AttendanceStatus.regular;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _smallGroupCtrl.dispose();
    _sundaySchoolCtrl.dispose();
    _createdByCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext ctx, DateTime? current,
      ValueChanged<DateTime?> onChanged) async {
    final picked = await showDatePicker(
      context: ctx,
      initialDate: current ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) onChanged(picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final personObj = Person(
      id: widget.existing?.id ?? '',
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      birthday: _birthday,
      baptismDate: _baptismDate,
      joinDate: _joinDate,
      attendance: _attendance,
      personType: _personType,
      smallGroup: _smallGroupCtrl.text.trim(),
      sundaySchool: _sundaySchoolCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      createdAt: widget.existing?.createdAt,
      createdBy: widget.existing != null
          ? widget.existing!.createdBy
          : _createdByCtrl.text.trim(),
    );
    try {
      await widget.onSave(personObj);
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
        content: const Text('此會友嘅通訊錄資料會被永久刪除(相關探訪案件不會刪除)。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('刪除',
                  style: TextStyle(color: Colors.red))),
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
      title: Text(isEditing ? '編輯${PersonType.label(_personType)}' : '新增${PersonType.label(_personType)}'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: '姓名 *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '請輸入姓名' : null,
                ),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration:
                      const InputDecoration(labelText: '電話(可空)'),
                  keyboardType: TextInputType.phone,
                ),
                _DateField(
                  label: '生日',
                  value: _birthday,
                  onPick: () => _pickDate(context, _birthday,
                      (d) => setState(() => _birthday = d)),
                  onClear: () => setState(() => _birthday = null),
                ),
                const SizedBox(height: 14),
                const _SectionHeader('教會生命'),
                _DateField(
                  label: '洗禮日期',
                  value: _baptismDate,
                  onPick: () => _pickDate(context, _baptismDate,
                      (d) => setState(() => _baptismDate = d)),
                  onClear: () => setState(() => _baptismDate = null),
                ),
                _DateField(
                  label: '轉會 / 加入日期',
                  value: _joinDate,
                  onPick: () => _pickDate(context, _joinDate,
                      (d) => setState(() => _joinDate = d)),
                  onClear: () => setState(() => _joinDate = null),
                ),
                const SizedBox(height: 8),
                const Text('出席崇拜',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: AttendanceStatus.all
                      .map((s) => ChoiceChip(
                            label: Text(AttendanceStatus.label(s)),
                            selected: _attendance == s,
                            onSelected: (sel) {
                              if (sel) setState(() => _attendance = s);
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 14),
                const _SectionHeader('參與'),
                TextFormField(
                  controller: _smallGroupCtrl,
                  decoration: const InputDecoration(
                    labelText: '所屬小組 / 團契',
                    hintText: '例:週三長者團、夫婦團契 B 組',
                  ),
                ),
                TextFormField(
                  controller: _sundaySchoolCtrl,
                  decoration: const InputDecoration(
                    labelText: '主日學參與',
                    hintText: '例:成人 B 班 - 學生、兒童老師',
                  ),
                ),
                const SizedBox(height: 14),
                const _SectionHeader('其他'),
                if (!isEditing)
                  TextFormField(
                    controller: _createdByCtrl,
                    decoration: const InputDecoration(
                        labelText: '建立者(傳道人姓名)'),
                  ),
                TextFormField(
                  controller: _notesCtrl,
                  decoration:
                      const InputDecoration(labelText: '備註(可空)'),
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
            child: const Text('刪除',
                style: TextStyle(color: Colors.red)),
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
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.indigo,
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
  });
  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          ),
          Expanded(
            child: TextButton.icon(
              icon: const Icon(Icons.calendar_today, size: 14),
              label: Text(
                value != null ? _fmt(value!) : '未設定',
                style: value != null
                    ? null
                    : const TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic),
              ),
              onPressed: onPick,
              style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft),
            ),
          ),
          if (value != null)
            TextButton.icon(
              icon: const Icon(Icons.clear, size: 14),
              label: const Text('清除', style: TextStyle(fontSize: 12)),
              onPressed: onClear,
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade400,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
            ),
        ],
      ),
    );
  }

  static String _fmt(DateTime d) =>
      '${d.year}/${d.month}/${d.day.toString().padLeft(2, '0')}';
}