// test/controllers/personal_hub_controller_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/controllers/expense_controller.dart';
import 'package:local_ai_chat/controllers/personal_hub_controller.dart';
import 'package:local_ai_chat/models/contact.dart';
import 'package:local_ai_chat/models/expense.dart';
import 'package:local_ai_chat/services/vector_store.dart';

void main() {
  group('PersonalHubController', () {
    late VectorStore store;
    late PersonalHubController controller;

    Contact contact({
      String id = 'c1',
      String name = 'Ada Lovelace',
      String company = 'Analytical Engines',
      String title = 'Mathematician',
      DateTime? scannedAt,
    }) {
      return Contact(
        id: id,
        name: name,
        company: company,
        title: title,
        email: '$id@example.com',
        tags: const ['vip'],
        scannedAt: scannedAt ?? DateTime(2026, 1, 1),
      );
    }

    Expense expense({
      String id = 'e1',
      double amount = 42,
      String currency = 'CAD',
      String category = 'Books',
      String description = 'Flutter handbook',
      DateTime? date,
    }) {
      return Expense(
        id: id,
        amount: amount,
        currency: currency,
        category: category,
        description: description,
        date: date ?? DateTime(2026, 5, 1),
      );
    }

    setUp(() {
      store = VectorStore();
      controller = PersonalHubController.fromStore(
        store,
        now: () => DateTime(2026, 5, 20),
      );
    });

    test('initial state is empty and not loading', () {
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.isEmpty, isTrue);
      expect(controller.contactCount, 0);
      expect(controller.expenseCount, 0);
    });

    test('loadAll loads contacts and expenses from the shared store', () async {
      await controller.saveContact(contact());
      await controller.saveExpense(expense());

      final fresh = PersonalHubController.fromStore(
        store,
        now: () => DateTime(2026, 5, 20),
      );
      await fresh.loadAll();

      expect(fresh.contactCount, 1);
      expect(fresh.expenseCount, 1);
      expect(fresh.isEmpty, isFalse);
    });

    test('saveContact updates contacts and summary', () async {
      await controller.saveContact(contact());

      expect(controller.contactCount, 1);
      expect(controller.contacts.single.name, 'Ada Lovelace');
      expect(controller.summary.contactCount, 1);
    });

    test('saveExpense updates expenses and summary', () async {
      await controller.saveExpense(expense());

      expect(controller.expenseCount, 1);
      expect(controller.expenses.single.amount, 42);
      expect(controller.summary.totalExpenseCount, 1);
      expect(controller.summary.expenseCount, 1);
    });

    test('deleteContact removes a saved contact', () async {
      await controller.saveContact(contact());
      await controller.deleteContact('c1');

      expect(controller.contactCount, 0);
      expect(controller.summary.contactCount, 0);
    });

    test('deleteExpense removes a saved expense', () async {
      await controller.saveExpense(expense());
      await controller.deleteExpense('e1');

      expect(controller.expenseCount, 0);
      expect(controller.summary.totalExpenseCount, 0);
    });

    test('deleteContact propagates missing contact errors', () async {
      expect(
        () => controller.deleteContact('missing'),
        throwsA(isA<ContactNotFoundException>()),
      );
    });

    test('deleteContact records errorMessage on failure', () async {
      try {
        await controller.deleteContact('missing');
      } catch (_) {}

      expect(controller.errorMessage, contains('ContactNotFoundException'));
    });

    test('search returns empty list for blank query', () async {
      await controller.saveContact(contact());
      await controller.saveExpense(expense());

      expect(await controller.search('   '), isEmpty);
    });

    test('search finds contacts by name', () async {
      await controller.saveContact(contact());

      final results = await controller.search('ada');

      expect(results, hasLength(1));
      expect(results.single.isContact, isTrue);
      expect(results.single.title, 'Ada Lovelace');
    });

    test('search finds contacts by company', () async {
      await controller.saveContact(contact());

      final results = await controller.search('engines');

      expect(results.single.subtitle, contains('Analytical Engines'));
    });

    test('search finds contacts by email', () async {
      await controller.saveContact(contact(id: 'ada'));

      final results = await controller.search('ada@example.com');

      expect(results.single.id, 'ada');
    });

    test('search finds expenses by category', () async {
      await controller.saveExpense(expense(category: 'Groceries'));

      final results = await controller.search('groceries');

      expect(results.single.isExpense, isTrue);
      expect(results.single.title, 'Groceries');
    });

    test('search finds expenses by description', () async {
      await controller.saveExpense(expense(description: 'Weekly market run'));

      final results = await controller.search('market');

      expect(results.single.subtitle, 'Weekly market run');
    });

    test('search all can return mixed result types', () async {
      await controller.saveContact(contact(name: 'Market Partner'));
      await controller.saveExpense(expense(description: 'Market lunch'));

      final results = await controller.search('market');

      expect(results.length, 2);
      expect(results.any((result) => result.isContact), isTrue);
      expect(results.any((result) => result.isExpense), isTrue);
    });

    test('search can be scoped to contacts only', () async {
      await controller.saveContact(contact(name: 'Market Partner'));
      await controller.saveExpense(expense(description: 'Market lunch'));

      final results = await controller.search(
        'market',
        scope: PersonalHubSearchScope.contacts,
      );

      expect(results, hasLength(1));
      expect(results.single.isContact, isTrue);
    });

    test('search can be scoped to expenses only', () async {
      await controller.saveContact(contact(name: 'Market Partner'));
      await controller.saveExpense(expense(description: 'Market lunch'));

      final results = await controller.search(
        'market',
        scope: PersonalHubSearchScope.expenses,
      );

      expect(results, hasLength(1));
      expect(results.single.isExpense, isTrue);
    });

    test('search is case insensitive', () async {
      await controller.saveExpense(expense(category: 'Coffee'));

      final results = await controller.search('COFFEE');

      expect(results, hasLength(1));
    });

    test('search result exposes expense amount and date', () async {
      final date = DateTime(2026, 5, 2);
      await controller.saveExpense(expense(amount: 9.5, date: date));

      final result = (await controller.search('books')).single;

      expect(result.amount, 9.5);
      expect(result.date, date);
    });

    test('monthlySummary delegates expense totals by currency', () async {
      await controller.saveExpense(expense(amount: 10, currency: 'CAD'));
      await controller.saveExpense(
        expense(id: 'e2', amount: 20, currency: 'CAD'),
      );
      await controller.saveExpense(
        expense(id: 'e3', amount: 100, currency: 'JPY'),
      );

      final summary = controller.monthlySummary(2026, 5);

      expect(summary['CAD'], 30);
      expect(summary['JPY'], 100);
    });

    test('monthlySummary ignores other months', () async {
      await controller.saveExpense(expense(amount: 10));
      await controller.saveExpense(
        expense(id: 'old', amount: 90, date: DateTime(2026, 4, 1)),
      );

      final summary = controller.monthlySummary(2026, 5);

      expect(summary['CAD'], 10);
    });

    test('summary uses injected current month', () async {
      await controller.saveExpense(expense(amount: 10));
      await controller.saveExpense(
        expense(id: 'old', amount: 90, date: DateTime(2026, 4, 1)),
      );

      expect(controller.summary.expenseCount, 1);
      expect(controller.summary.totalExpenseCount, 2);
      expect(controller.summary.totalForCurrency('CAD'), 10);
    });

    test('summary totalForCurrency falls back to zero', () {
      expect(controller.summary.totalForCurrency('USD'), 0);
    });

    test('topExpenseCategory returns highest count', () async {
      await controller.saveExpense(expense(category: 'Food'));
      await controller.saveExpense(expense(id: 'e2', category: 'Food'));
      await controller.saveExpense(expense(id: 'e3', category: 'Books'));

      expect(controller.summary.topExpenseCategory, 'Food');
    });

    test('topExpenseCategory tie breaks alphabetically', () async {
      await controller.saveExpense(expense(category: 'Travel'));
      await controller.saveExpense(expense(id: 'e2', category: 'Books'));

      expect(controller.summary.topExpenseCategory, 'Books');
    });

    test('uncategorized expenses are counted', () async {
      await controller.saveExpense(expense(category: ''));

      expect(controller.expenseCategoryCounts()['Uncategorized'], 1);
    });

    test('expensesForMonth returns sorted expenses for the target month',
        () async {
      await controller
          .saveExpense(expense(id: 'early', date: DateTime(2026, 5, 1)));
      await controller
          .saveExpense(expense(id: 'late', date: DateTime(2026, 5, 9)));
      await controller
          .saveExpense(expense(id: 'other', date: DateTime(2026, 6, 1)));

      final expenses = controller.expensesForMonth(2026, 5);

      expect(expenses.map((expense) => expense.id), ['late', 'early']);
    });

    test('recentExpenses respects limit and date order', () async {
      await controller
          .saveExpense(expense(id: 'a', date: DateTime(2026, 5, 1)));
      await controller
          .saveExpense(expense(id: 'b', date: DateTime(2026, 5, 2)));
      await controller
          .saveExpense(expense(id: 'c', date: DateTime(2026, 5, 3)));

      final recent = controller.recentExpenses(limit: 2);

      expect(recent.map((expense) => expense.id), ['c', 'b']);
    });

    test('recentExpenses returns empty for non-positive limit', () async {
      await controller.saveExpense(expense());

      expect(controller.recentExpenses(limit: 0), isEmpty);
    });

    test('recentContacts respects limit and scannedAt order', () async {
      await controller.saveContact(
        contact(id: 'old', name: 'Old', scannedAt: DateTime(2026, 1, 1)),
      );
      await controller.saveContact(
        contact(id: 'new', name: 'New', scannedAt: DateTime(2026, 1, 3)),
      );

      final recent = controller.recentContacts(limit: 1);

      expect(recent.single.id, 'new');
    });

    test('recentContacts returns empty for non-positive limit', () async {
      await controller.saveContact(contact());

      expect(controller.recentContacts(limit: 0), isEmpty);
    });

    test('module collections remain isolated in VectorStore', () async {
      await controller.saveContact(contact());
      await controller.saveExpense(expense());

      expect(store.chunksInCollection(kContactsCollection), hasLength(1));
      expect(
        store.chunksInCollection(ExpenseController.kExpenseCollection),
        hasLength(1),
      );
      expect(store.chunksInCollection('default'), isEmpty);
    });

    test('notifies listeners during save flow', () async {
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.saveExpense(expense());

      expect(notifications, greaterThan(0));
    });
  });
}
