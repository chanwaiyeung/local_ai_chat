import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../controllers/expense_controller.dart';
import '../../l10n/app_localizations.dart';

class ExpenseSummaryCard extends StatelessWidget {
  final ExpenseController controller;

  const ExpenseSummaryCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final summary = controller.getMonthlySummary(now.year, now.month);
    final total = summary.values.fold<double>(0, (sum, v) => sum + v);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.personalHubThisMonthExpense, 
                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              NumberFormat("#,###.##").format(total),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(
              l10n.totalExpensesThisMonth,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
