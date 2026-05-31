// lib/widgets/wealth/wealth_monthly_report_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/wealth_controller.dart';
import '../../l10n/app_localizations.dart';
import '../currency_picker_button.dart';

class WealthMonthlyReportCard extends StatelessWidget {
  final WealthController controller;
  final String currency;

  const WealthMonthlyReportCard({
    super.key,
    required this.controller,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final report = controller.getMonthlyReport(
      currency: currency,
      year: now.year,
      month: now.month,
    );

    final thisMonth = report['thisMonthTotal'] as double;
    final lastMonth = report['lastMonthTotal'] as double;
    final change = thisMonth - lastMonth;
    final changePercent =
        lastMonth != 0 ? (change / lastMonth) * 100 : 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ 用 l10n
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.wealthMonthlyReport,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const CurrencyPickerButton(),
              ],
            ),
            const SizedBox(height: 16),
            _buildRow(l10n.wealthThisMonthTotal, thisMonth, currency),
            _buildRow(l10n.wealthLastMonthTotal, lastMonth, currency),
            const Divider(height: 24),
            _buildRow(
              l10n.wealthChange,
              change,
              currency,
              color: change >= 0 ? Colors.green : Colors.red,
              percent: changePercent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    double value,
    String currency, {
    Color? color,
    double? percent,
  }) {
    final formatter = NumberFormat('#,###.##');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '${formatter.format(value)} $currency'
            '${percent != null ? ' (${percent.toStringAsFixed(1)}%)' : ''}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}




