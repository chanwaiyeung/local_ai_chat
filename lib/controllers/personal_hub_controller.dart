// lib/controllers/personal_hub_controller.dart
import 'package:flutter/foundation.dart';

import '../models/contact.dart';
import '../models/expense.dart';
import '../services/vector_store.dart';
import 'contact_controller.dart';
import 'expense_controller.dart';

enum PersonalHubItemType { contact, expense }

enum PersonalHubSearchScope { all, contacts, expenses }

class PersonalHubSearchResult {
  const PersonalHubSearchResult({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.searchText,
    this.amount,
    this.date,
  });

  final PersonalHubItemType type;
  final String id;
  final String title;
  final String subtitle;
  final String searchText;
  final double? amount;
  final DateTime? date;

  bool get isContact => type == PersonalHubItemType.contact;
  bool get isExpense => type == PersonalHubItemType.expense;
}

class PersonalHubSummary {
  const PersonalHubSummary({
    this.contactCount = 0,
    this.expenseCount = 0,
    this.totalExpenseCount = 0,
    this.monthlyTotalsByCurrency = const {},
    this.topExpenseCategory = '',
  });

  final int contactCount;
  final int expenseCount;
  final int totalExpenseCount;
  final Map<String, double> monthlyTotalsByCurrency;
  final String topExpenseCategory;

  double totalForCurrency(String currency) {
    return monthlyTotalsByCurrency[currency] ?? 0.0;
  }
}

class PersonalHubController extends ChangeNotifier {
  PersonalHubController({
    required this.contactController,
    required this.expenseController,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  factory PersonalHubController.fromStore(
    VectorStore store, {
    DateTime Function()? now,
  }) {
    return PersonalHubController(
      contactController: ContactController(store: store),
      expenseController: ExpenseController(store),
      now: now,
    );
  }

  final ContactController contactController;
  final ExpenseController expenseController;
  final DateTime Function() _now;

  bool _isLoading = false;
  String? _errorMessage;
  PersonalHubSummary _summary = const PersonalHubSummary();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  PersonalHubSummary get summary => _summary;

  List<Contact> get contacts => contactController.contacts;
  List<Expense> get expenses => expenseController.expenses;
  int get contactCount => contacts.length;
  int get expenseCount => expenses.length;
  bool get isEmpty => contactCount == 0 && expenseCount == 0;

  Future<void> loadAll() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await contactController.loadAll();
      await expenseController.getAllExpenses();
      _refreshSummary();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> saveContact(Contact contact) async {
    await _runAndRefresh(() => contactController.saveContact(contact));
  }

  Future<void> deleteContact(String id) async {
    await _runAndRefresh(() => contactController.deleteContact(id));
  }

  Future<void> saveExpense(Expense expense) async {
    await _runAndRefresh(() => expenseController.saveExpense(expense));
  }

  Future<void> deleteExpense(String id) async {
    await _runAndRefresh(() => expenseController.deleteExpense(id));
  }

  Future<List<PersonalHubSearchResult>> search(
    String query, {
    PersonalHubSearchScope scope = PersonalHubSearchScope.all,
  }) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const [];

    final results = <PersonalHubSearchResult>[];
    if (scope != PersonalHubSearchScope.expenses) {
      results.addAll(_searchContacts(normalized));
    }
    if (scope != PersonalHubSearchScope.contacts) {
      results.addAll(_searchExpenses(normalized));
    }

    results.sort((a, b) {
      final byType = a.type.index.compareTo(b.type.index);
      if (byType != 0) return byType;
      return a.title.compareTo(b.title);
    });
    return results;
  }

  Map<String, double> monthlySummary(int year, int month) {
    return expenseController.getMonthlySummary(year, month);
  }

  List<Expense> expensesForMonth(int year, int month) {
    return expenses
        .where((expense) =>
            expense.date.year == year && expense.date.month == month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Expense> recentExpenses({int limit = 5}) {
    if (limit <= 0) return const [];
    final sorted = expenses.toList()..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(limit).toList();
  }

  List<Contact> recentContacts({int limit = 5}) {
    if (limit <= 0) return const [];
    final sorted = contacts.toList()
      ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return sorted.take(limit).toList();
  }

  Map<String, int> expenseCategoryCounts() {
    final counts = <String, int>{};
    for (final expense in expenses) {
      final category = expense.category.trim().isEmpty
          ? 'Uncategorized'
          : expense.category.trim();
      counts.update(category, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  Future<void> _runAndRefresh(Future<void> Function() action) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await action();
      await contactController.loadAll();
      await expenseController.getAllExpenses();
      _refreshSummary();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Iterable<PersonalHubSearchResult> _searchContacts(String normalized) sync* {
    for (final contact in contacts) {
      final text = contact.toSearchText();
      if (!text.toLowerCase().contains(normalized)) continue;
      yield PersonalHubSearchResult(
        type: PersonalHubItemType.contact,
        id: contact.id,
        title: contact.name,
        subtitle: [contact.title, contact.company]
            .where((value) => value.trim().isNotEmpty)
            .join(' · '),
        searchText: text,
      );
    }
  }

  Iterable<PersonalHubSearchResult> _searchExpenses(String normalized) sync* {
    for (final expense in expenses) {
      final text = expense.toSearchText();
      if (!text.toLowerCase().contains(normalized)) continue;
      yield PersonalHubSearchResult(
        type: PersonalHubItemType.expense,
        id: expense.id,
        title: expense.category.trim().isEmpty
            ? 'Uncategorized'
            : expense.category,
        subtitle: expense.description,
        searchText: text,
        amount: expense.amount,
        date: expense.date,
      );
    }
  }

  void _refreshSummary() {
    final now = _now();
    final monthlyTotals =
        expenseController.getMonthlySummary(now.year, now.month);
    final counts = expenseCategoryCounts();
    final topCategory = counts.entries.isEmpty
        ? ''
        : (counts.entries.toList()
              ..sort((a, b) {
                final byCount = b.value.compareTo(a.value);
                if (byCount != 0) return byCount;
                return a.key.compareTo(b.key);
              }))
            .first
            .key;

    _summary = PersonalHubSummary(
      contactCount: contactCount,
      expenseCount: expensesForMonth(now.year, now.month).length,
      totalExpenseCount: expenseCount,
      monthlyTotalsByCurrency: Map.unmodifiable(monthlyTotals),
      topExpenseCategory: topCategory,
    );
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }
}
