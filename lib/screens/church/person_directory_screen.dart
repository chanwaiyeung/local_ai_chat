// lib/screens/church/person_directory_screen.dart
import 'package:flutter/material.dart';
import '../../controllers/church/person_controller.dart';
import '../../models/church/person.dart';
import '../../widgets/church/person_form_dialog.dart';

class PersonDirectoryScreen extends StatefulWidget {
  const PersonDirectoryScreen({super.key, required this.controller});

  final PersonController controller;

  @override
  State<PersonDirectoryScreen> createState() =>
      _PersonDirectoryScreenState();
}

class _PersonDirectoryScreenState extends State<PersonDirectoryScreen> {
  late final TextEditingController _searchCtrl;
  String _searchQuery = '';
  String? _attendanceFilter;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    widget.controller.addListener(_onChange);
    if (!widget.controller.isLoaded) {
      widget.controller.loadAll();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _openForm({Person? existing, String? defaultType}) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PersonFormDialog(
        existing: existing,
        defaultType: defaultType,
        onSave: (p) => widget.controller.savePerson(p),
        onDelete: existing == null
            ? null
            : () => widget.controller.deletePerson(existing.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctl = widget.controller;
    var persons = _searchQuery.trim().isEmpty
        ? ctl.allPersons
        : ctl.searchPersons(_searchQuery);
    if (_attendanceFilter != null) {
      persons =
          persons.where((p) {
            final f = _attendanceFilter!;
            if (f == PersonType.member || f == PersonType.seeker) {
              return p.personType == f;
            }
            final parts = f.split('_');
            if (parts.length == 2) {
              return p.attendance == parts[0] && p.personType == parts[1];
            }
            return p.attendance == f;
          }).toList();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('會友通訊錄')),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'memberFab',
            icon: const Icon(Icons.person_add),
            label: const Text('新增會友'),
            onPressed: () => _openForm(defaultType: PersonType.member),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'seekerFab',
            icon: const Icon(Icons.person_search_outlined),
            label: const Text('新增非會友'),
            onPressed: () => _openForm(defaultType: PersonType.seeker),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        ],
      ),
      body: !ctl.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: '搜尋姓名 / 電話 / 小組 / 主日學 / 備註',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _Filter(
                          label: '會友 (${ctl.memberCount})',
                          selected: _attendanceFilter == PersonType.member,
                          onTap: () => setState(
                              () => _attendanceFilter = PersonType.member),
                        ),
                        _Filter(
                          label: '非會友 (${ctl.seekerCount})',
                          selected: _attendanceFilter == PersonType.seeker,
                          onTap: () => setState(
                              () => _attendanceFilter = PersonType.seeker),
                        ),
                        _Filter(
                          label: '全部 (${ctl.totalCount})',
                          selected: _attendanceFilter == null,
                          onTap: () =>
                              setState(() => _attendanceFilter = null),
                        ),
                        const SizedBox(width: 6),
                        _Filter(
                          label: '經常參加崇拜的會友 (${ctl.memberRegularCount})',
                          selected: _attendanceFilter == 'regular_member',
                          color: Colors.green,
                          onTap: () => setState(
                              () => _attendanceFilter = 'regular_member'),
                        ),
                        _Filter(
                          label: '經常參加崇拜的非會友 (${ctl.seekerRegularCount})',
                          selected: _attendanceFilter == 'regular_seeker',
                          color: Colors.green,
                          onTap: () => setState(
                              () => _attendanceFilter = 'regular_seeker'),
                        ),
                        const SizedBox(width: 6),
                        _Filter(
                          label: '偶爾參加崇拜的會友 (${ctl.memberOccasionalCount})',
                          selected: _attendanceFilter == 'occasional_member',
                          color: Colors.orange,
                          onTap: () => setState(
                              () => _attendanceFilter = 'occasional_member'),
                        ),
                        _Filter(
                          label: '偶爾參加崇拜的非會友 (${ctl.seekerOccasionalCount})',
                          selected: _attendanceFilter == 'occasional_seeker',
                          color: Colors.orange,
                          onTap: () => setState(
                              () => _attendanceFilter = 'occasional_seeker'),
                        ),
                        const SizedBox(width: 6),
                        _Filter(
                          label: '久未參加崇拜的會友 (${ctl.memberInactiveCount})',
                          selected: _attendanceFilter == 'inactive_member',
                          color: Colors.red,
                          onTap: () => setState(
                              () => _attendanceFilter = 'inactive_member'),
                        ),
                        _Filter(
                          label: '久未參加崇拜的非會友 (${ctl.seekerInactiveCount})',
                          selected: _attendanceFilter == 'inactive_seeker',
                          color: Colors.red,
                          onTap: () => setState(
                              () => _attendanceFilter = 'inactive_seeker'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: persons.isEmpty
                      ? _emptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: persons.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, indent: 16),
                          itemBuilder: (ctx, i) => _PersonRow(
                            person: persons[i],
                            onTap: () =>
                                _openForm(existing: persons[i]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _emptyState() {
    final filtered =
        _searchQuery.isNotEmpty || _attendanceFilter != null;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.contacts_outlined,
              size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            filtered ? '無符合搜尋條件嘅會友' : '通訊錄空白',
            style: const TextStyle(fontSize: 16),
          ),
          if (!filtered) ...[
            const SizedBox(height: 4),
            Text('撳右下角加第一個會友',
                style: TextStyle(
                    color: Colors.grey[600], fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

class _Filter extends StatelessWidget {
  const _Filter({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: color?.withValues(alpha: 0.2),
      checkmarkColor: color,
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.person, required this.onTap});
  final Person person;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final infoLine = [
      if (person.smallGroup.isNotEmpty) '小組:${person.smallGroup}',
      if (person.sundaySchool.isNotEmpty)
        '主日學:${person.sundaySchool}',
    ].join(' · ');

    return ListTile(
      title: Row(
        children: [
          Flexible(
            child: Text(person.name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 6),
          _AttendanceBadge(status: person.attendance),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (person.phone.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  Icon(Icons.phone,
                      size: 11, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(person.phone,
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          if (infoLine.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                infoLine,
                style: TextStyle(
                    fontSize: 11, color: Colors.grey[700]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}

class _AttendanceBadge extends StatelessWidget {
  const _AttendanceBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      AttendanceStatus.regular => Colors.green,
      AttendanceStatus.occasional => Colors.orange,
      AttendanceStatus.inactive => Colors.red,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        AttendanceStatus.label(status),
        style: TextStyle(
            color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }
}