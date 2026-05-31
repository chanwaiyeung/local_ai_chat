// lib/widgets/wealth/wealth_report_card.dart
import 'package:flutter/material.dart';
import '../../controllers/wealth_controller.dart';
import '../../l10n/app_localizations.dart';
import '../currency_picker_button.dart';

class WealthReportCard extends StatelessWidget {
  final WealthController controller;
  final String currency;

  const WealthReportCard({
    super.key,
    required this.controller,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final report = controller.getMonthlyReport(
      currency: currency,
      year: DateTime.now().year,
      month: DateTime.now().month,
    );

    final thisMonth = (report['thisMonthTotal'] as double?) ?? 0.0;
    final lastMonth = (report['lastMonthTotal'] as double?) ?? 0.0;
    final diff = thisMonth - lastMonth;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.wealthMonthlyReport,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const CurrencyPickerButton(),
              ],
            ),
            const SizedBox(height: 8),
            Text('${l10n.wealthThisMonthTotal}：$currency ${thisMonth.toStringAsFixed(2)}'),
            Text('${l10n.wealthLastMonthTotal}：$currency ${lastMonth.toStringAsFixed(2)}'),
            Text(
              '${l10n.wealthChange}：${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(2)}',
              style: TextStyle(
                color: diff >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}




