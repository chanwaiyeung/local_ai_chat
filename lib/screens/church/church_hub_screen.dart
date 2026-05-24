// lib/screens/church/church_hub_screen.dart
//
// Unified entry point for the Church module.
// Displays a stats overview card and a 2-entry grid leading to:
//   • Care Dashboard (pastoral care case tracking)
//   • Member Directory (member contact list)
//
// Both sub-screens are accessible via their existing screens; this hub
// consolidates the two separate PersonalHub cards into one cohesive module.

import 'package:flutter/material.dart';

import '../../main.dart';
import 'care_dashboard_screen.dart';
import 'person_directory_screen.dart';

class ChurchHubScreen extends StatefulWidget {
  const ChurchHubScreen({super.key});

  @override
  State<ChurchHubScreen> createState() => _ChurchHubScreenState();
}

class _ChurchHubScreenState extends State<ChurchHubScreen> {
  @override
  void initState() {
    super.initState();
    globalCareController.addListener(_onChanged);
    globalPersonController.addListener(_onChanged);
  }

  @override
  void dispose() {
    globalCareController.removeListener(_onChanged);
    globalPersonController.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final care = globalCareController;
    final people = globalPersonController;

    return Scaffold(
      appBar: AppBar(title: const Text('教會')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ChurchStatsCard(
              activeCount: care.activeCount,
              redCount: care.redCount,
              memberCount: people.totalCount,
              inactiveCount: people.inactiveCount,
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              children: [
                _ChurchEntryCard(
                  icon: Icons.volunteer_activism_outlined,
                  label: '關懷追蹤',
                  subtitle: '${care.activeCount} 案件 · ${care.redCount} 紅燈',
                  color: Colors.deepPurple,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          CareDashboardScreen(controller: care),
                    ),
                  ),
                ),
                _ChurchEntryCard(
                  icon: Icons.groups_outlined,
                  label: '會友通訊錄',
                  subtitle: '${people.totalCount} 位 · ${people.inactiveCount} 久未出席',
                  color: Colors.blueGrey,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          PersonDirectoryScreen(controller: people),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Stats card
// ============================================================================

class _ChurchStatsCard extends StatelessWidget {
  const _ChurchStatsCard({
    required this.activeCount,
    required this.redCount,
    required this.memberCount,
    required this.inactiveCount,
  });

  final int activeCount;
  final int redCount;
  final int memberCount;
  final int inactiveCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.church_outlined),
                const SizedBox(width: 8),
                Text(
                  '教會概況',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.volunteer_activism_outlined,
                    label: '進行中案件',
                    value: '$activeCount',
                    color: Colors.deepPurple,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.warning_amber_rounded,
                    label: '需立即跟進',
                    value: '$redCount',
                    color: redCount > 0 ? Colors.red : Colors.grey,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.groups_outlined,
                    label: '會友人數',
                    value: '$memberCount',
                    color: Colors.blueGrey,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.person_off_outlined,
                    label: '久未出席',
                    value: '$inactiveCount',
                    color: inactiveCount > 0 ? Colors.orange : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).hintColor,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Entry card
// ============================================================================

class _ChurchEntryCard extends StatelessWidget {
  const _ChurchEntryCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
