// lib/screens/expense_screen.dart
//
// Phase 6.2' (base) + Phase 6.6 enhancements.
//
// 6.6 changes vs 6.2':
//   * _MonthSummary now shows total + per-category breakdown.
//   * The list is wrapped in RefreshIndicator (pull-to-refresh).
//   * The category field in _ExpenseForm now suggests user's past categories
//     in addition to the predefined list (即時分類建議).
//
// Everything else from 6.2' is preserved verbatim:
//   * Month switcher (prev / next / current label)
//   * Search bar
//   * ListView with Dismissible swipe-to-delete and tap-to-edit
//   * FAB → modal bottom sheet form (amount, currency, merchant, category,
//     payment method, date, notes)

import 'package:flutter/material.dart';

import '../controllers/expense_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/expense.dart';
import '../services/currency_service.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key, required this.controller});
  final ExpenseController controller;

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  late int _year;
  late int _month;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _stepMonth(int delta) {
    setState(() {
      var y = _year;
      var m = _month + delta;
      while (m < 1) {
        m += 12;
        y -= 1;
      }
      while (m > 12) {
        m -= 12;
        y += 1;
      }
      _year = y;
      _month = m;
    });
  }

  Future<void> _onRefresh() async {
    // No remote source — controller already exposes the latest in-memory
    // state. Just force a rebuild so the user gets the affordance.
    if (mounted) setState(() {});
  }

  Future<void> _openForm({Expense? existing}) async {
    final pastCategories = widget.controller.expenses
        .map((e) => e.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: _ExpenseForm(
            existing: existing,
            pastCategories: pastCategories,
            onSave: (e) async {
              await widget.controller.saveExpense(e);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthly = widget.controller.getMonthlyExpenses(_year, _month);
    final filtered = _query.trim().isEmpty
        ? monthly
        : monthly
            .where((e) =>
                e.toSearchText().toLowerCase().contains(_query.toLowerCase()))
            .toList();
    final summary = widget.controller.getMonthlySummary(_year, _month);
    final byCategory = widget.controller.getMonthlyByCategory(_year, _month);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).moduleExpense)),
      body: Column(
        children: [
          _MonthSwitcher(
            year: _year,
            month: _month,
            onPrev: () => _stepMonth(-1),
            onNext: () => _stepMonth(1),
          ),
          _MonthSummary(summary: summary, byCategory: byCategory),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).searchExpenseHint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: filtered.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: Center(
                            child: Text(AppLocalizations.of(context).noMatchingExpenses),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, i) {
                        final e = filtered[i];
                        return _ExpenseTile(
                          expense: e,
                          onDelete: () async {
                            await widget.controller.deleteExpense(e.id);
                            return true;
                          },
                          onTap: () => _openForm(existing: e),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ============================================================================
// Sub-widgets
// ============================================================================

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.year,
    required this.month,
    required this.onPrev,
    required this.onNext,
  });
  final int year;
  final int month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
          tooltip: AppLocalizations.of(context).previousMonth,
        ),
        Text(
          AppLocalizations.of(context).yearMonthTitle(year, month),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
          tooltip: AppLocalizations.of(context).nextMonth,
        ),
      ],
    );
  }
}

class _MonthSummary extends StatelessWidget {
  const _MonthSummary({
    required this.summary,
    required this.byCategory,
  });
  final Map<String, double> summary;
  final Map<String, double> byCategory;

  @override
  Widget build(BuildContext context) {
    if (summary.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(AppLocalizations.of(context).noExpensesThisMonth),
        ),
      );
    }

    final totalText = summary.entries
        .map((e) => '${e.value.toStringAsFixed(2)} ${e.key}')
        .join(' / ');

    final sortedCategories = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(5).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppLocalizations.of(context).monthlyTotal(totalText),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          if (topCategories.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final entry in topCategories)
                  _CategoryChip(
                    label: entry.key,
                    amount: entry.value,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.amount});
  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        AppLocalizations.of(context).categoryAmountChip(label, amount.toStringAsFixed(0)),
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.onDelete,
    required this.onTap,
  });
  final Expense expense;
  final Future<bool> Function() onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        onDelete();
      },
      child: ListTile(
        title: Text(
          expense.merchant.isEmpty ? AppLocalizations.of(context).noMerchant : expense.merchant,
        ),
        subtitle: Text(
          [
            expense.category,
            '${expense.date.year}/${expense.date.month}/${expense.date.day}',
            if (expense.notes.isNotEmpty) expense.notes,
          ].join(' · '),
        ),
        trailing: Text(
          '${expense.amount.toStringAsFixed(2)} ${expense.currency}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _ExpenseForm extends StatefulWidget {
  const _ExpenseForm({
    this.existing,
    required this.pastCategories,
    required this.onSave,
  });
  final Expense? existing;
  final List<String> pastCategories;
  final Future<void> Function(Expense) onSave;

  @override
  State<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<_ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  late final TextEditingController _merchantCtrl;
  late final TextEditingController _notesCtrl;
  late String _currency;
  late String _category;
  late String _paymentMethod;
  late DateTime _date;

  static const List<String> _currencies = ['USD', 'EUR', 'GBP', 'HKD', 'TWD', 'CAD', 'JPY', 'CNY', 'AUD'];
  static const List<String> _defaultCategories = [
    '餐飲',
    '交通',
    '購物',
    '娛樂',
    '住房',
    '醫療',
    '教育',
    '其他',
  ];
  static const List<String> _payments = [
    'cash',
    'credit_card',
    'apple_pay',
    'line_pay',
    'other',
  ];

  /// Predefined categories merged with the user's actual past categories,
  /// deduplicated and sorted. Powers the 即時分類建議 dropdown.
  List<String> get _categoryOptions {
    final s = <String>{..._defaultCategories, ...widget.pastCategories};
    final list = s.toList()..sort();
    return list;
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _amountCtrl =
        TextEditingController(text: e == null ? '' : e.amount.toString());
    _merchantCtrl = TextEditingController(text: e?.merchant ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _currency = e?.currency ?? CurrencyService.instance.code;
    _category = e?.category ?? '餐飲';
    // If existing.category isn't in the predefined list (e.g. user typed a
    // custom one), still show it as the selected value via _categoryOptions.
    _paymentMethod = e?.paymentMethod ?? 'cash';
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _merchantCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final base = widget.existing ?? Expense(amount: 0, date: DateTime.now());
    final updated = base.copyWith(
      amount: double.parse(_amountCtrl.text),
      currency: _currency,
      date: _date,
      merchant: _merchantCtrl.text.trim(),
      category: _category,
      paymentMethod: _paymentMethod,
      notes: _notesCtrl.text.trim(),
    );
    widget.onSave(updated);
  }

  @override
  Widget build(BuildContext context) {
    final categoryOptions = _categoryOptions;
    // Ensure currently-selected category is in options (defensive — covers
    // the case where existing category was deleted from defaults).
    final categoryItems = {
      ..._defaultCategories,
      ...widget.pastCategories,
      _category
    }.toList()
      ..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? AppLocalizations.of(context).addExpense : AppLocalizations.of(context).editExpense,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _amountCtrl,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context).amount),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return AppLocalizations.of(context).invalidAmountError;
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    initialValue: _currency,
                    decoration: InputDecoration(labelText: AppLocalizations.of(context).currency),
                    items: [
                      for (final c in _currencies)
                        DropdownMenuItem(value: c, child: Text(c))
                    ],
                    onChanged: (v) => setState(() => _currency = v ?? CurrencyService.instance.code),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _merchantCtrl,
              decoration: InputDecoration(labelText: AppLocalizations.of(context).merchant),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue:
                  categoryItems.contains(_category) ? _category : '其他',
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).category,
                helperText: widget.pastCategories.isEmpty
                    ? AppLocalizations.of(context).defaultCategoriesLabel
                    : AppLocalizations.of(context).customCategoriesCount(widget.pastCategories.length),
              ),
              items: [
                for (final c in categoryOptions)
                  DropdownMenuItem(value: c, child: Text(c))
              ],
              onChanged: (v) => setState(() => _category = v ?? '其他'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              decoration: InputDecoration(labelText: AppLocalizations.of(context).paymentMethod),
              items: [
                for (final p in _payments)
                  DropdownMenuItem(value: p, child: Text(p))
              ],
              onChanged: (v) => setState(() => _paymentMethod = v ?? 'cash'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppLocalizations.of(context).date),
              subtitle: Text('${_date.year}/${_date.month}/${_date.day}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration: InputDecoration(labelText: AppLocalizations.of(context).notes),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              child: Text(AppLocalizations.of(context).saveButton),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}



