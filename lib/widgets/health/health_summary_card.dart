import 'package:flutter/material.dart';
import '../../controllers/health_controller.dart';
import '../../l10n/app_localizations.dart';

class HealthSummaryCard extends StatelessWidget {
  final HealthController controller;

  const HealthSummaryCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final count = controller.count;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.personalHubHealthRecords, 
                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(count.toString(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text(l10n.records, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


