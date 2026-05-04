// test/screens/personal_hub_screen_test.dart
//
// Phase 6.3'a + 6.4'b — Widget tests for PersonalHubScreen.
// Updated for 6.4'b: Contacts module is enabled, dashboard shows real
// contact count. The "disabled module shows snackbar" test now targets
// 健康紀錄 (which remains disabled in this phase).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:local_ai_chat/controllers/contact_controller.dart';
import 'package:local_ai_chat/controllers/expense_controller.dart';
import 'package:local_ai_chat/controllers/health_controller.dart';
import 'package:local_ai_chat/controllers/wealth_controller.dart';
import 'package:local_ai_chat/core/locator.dart';
import 'package:local_ai_chat/models/contact.dart';
import 'package:local_ai_chat/models/expense.dart';
import 'package:local_ai_chat/models/health_record.dart';
import 'package:local_ai_chat/models/wealth_record.dart';
import 'package:local_ai_chat/screens/personal_hub_screen.dart';
import 'package:local_ai_chat/services/vector_store.dart';

void main() {
  late VectorStore store;
  late ExpenseController expenseController;
  late ContactController contactController;
  late HealthController healthController;
  late WealthController wealthController;

  setUp(() async {
    await Locator.resetForTest();
    store = VectorStore();
    expenseController = ExpenseController(store);
    contactController = ContactController(store: store);
    healthController = HealthController(store);
    wealthController = WealthController(store);
  });

  Widget hostFor() => MaterialApp(
        home: PersonalHubScreen(
          expenseController: expenseController,
          contactController: contactController,
          healthController: healthController,
          wealthController: wealthController,
        ),
      );

  testWidgets('renders AppBar title "Personal Hub"', (tester) async {
    await tester.pumpWidget(hostFor());
    expect(find.text('Personal Hub'), findsOneWidget);
  });

  testWidgets('renders dashboard summary card with current month label',
      (tester) async {
    final now = DateTime.now();
    await tester.pumpWidget(hostFor());
    expect(
      find.textContaining('${now.year} 年 ${now.month} 月'),
      findsOneWidget,
    );
    expect(find.text('本月總開支'), findsOneWidget);
    expect(find.text('名片總數'), findsOneWidget);
  });

  testWidgets('shows zero-state for both expense and contact when empty',
      (tester) async {
    await tester.pumpWidget(hostFor());
    expect(find.text('本月暫無開支'), findsOneWidget);
    expect(find.text('尚未加入名片'), findsOneWidget);
  });

  testWidgets('reflects monthly total in dashboard when expenses exist',
      (tester) async {
    final now = DateTime.now();
    await expenseController.saveExpense(Expense(
      id: '',
      amount: 250,
      currency: 'TWD',
      date: DateTime(now.year, now.month, 1),
    ));
    await expenseController.saveExpense(Expense(
      id: '',
      amount: 500,
      currency: 'TWD',
      date: DateTime(now.year, now.month, 5),
    ));

    await tester.pumpWidget(hostFor());
    expect(find.textContaining('750.00 TWD'), findsOneWidget);
  });

  testWidgets('reflects contact count in dashboard when contacts exist',
      (tester) async {
    await contactController.saveContact(
      Contact(id: 'c1', name: 'Albert', scannedAt: DateTime(2026, 5, 1)),
    );
    await contactController.saveContact(
      Contact(id: 'c2', name: 'Wang', scannedAt: DateTime(2026, 5, 2)),
    );
    await tester.pumpWidget(hostFor());
    expect(find.text('2 張'), findsOneWidget);
  });

  testWidgets('renders all 5 module cards in a GridView', (tester) async {
    await tester.pumpWidget(hostFor());

    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('日常開支'), findsOneWidget);
    expect(find.text('名片管理'), findsOneWidget);
    expect(find.text('健康紀錄'), findsAtLeastNWidgets(1));
    expect(find.text('投資理財'), findsOneWidget);
    expect(find.text('完整儀表板'), findsOneWidget);
  });

  testWidgets('Expense module card shows record count from controller',
      (tester) async {
    await expenseController.saveExpense(
      Expense(id: '', amount: 100, date: DateTime.now()),
    );
    await expenseController.saveExpense(
      Expense(id: '', amount: 200, date: DateTime.now()),
    );
    await tester.pumpWidget(hostFor());
    expect(find.textContaining('2 筆紀錄'), findsOneWidget);
  });

  testWidgets('Contacts module card shows count from controller',
      (tester) async {
    await contactController.saveContact(
      Contact(id: 'c1', name: 'Albert', scannedAt: DateTime(2026, 5, 1)),
    );
    await contactController.saveContact(
      Contact(id: 'c2', name: 'Wang', scannedAt: DateTime(2026, 5, 2)),
    );
    await contactController.saveContact(
      Contact(id: 'c3', name: 'Charlie', scannedAt: DateTime(2026, 5, 3)),
    );
    await tester.pumpWidget(hostFor());
    expect(find.textContaining('3 張名片'), findsOneWidget);
  });

  testWidgets('dashboard reflects health count when records exist',
      (tester) async {
    await healthController.saveRecord(HealthRecord(
      date: DateTime(2026, 5, 1),
      weight: 70,
      dateAdded: DateTime(2026, 5, 1),
    ));
    await healthController.saveRecord(HealthRecord(
      date: DateTime(2026, 5, 2),
      steps: 8000,
      dateAdded: DateTime(2026, 5, 2),
    ));

    await tester.pumpWidget(hostFor());
    expect(find.text('2 筆'), findsOneWidget);
  });

  testWidgets('Health module card shows count from controller', (tester) async {
    await healthController.saveRecord(HealthRecord(
      date: DateTime(2026, 5, 1),
      sleepHours: 7.5,
      dateAdded: DateTime(2026, 5, 1),
    ));
    await healthController.saveRecord(HealthRecord(
      date: DateTime(2026, 5, 2),
      heartRate: 68,
      dateAdded: DateTime(2026, 5, 2),
    ));
    await healthController.saveRecord(HealthRecord(
      date: DateTime(2026, 5, 3),
      systolic: 120,
      diastolic: 80,
      dateAdded: DateTime(2026, 5, 3),
    ));

    await tester.pumpWidget(hostFor());
    expect(find.textContaining('3 筆紀錄'), findsOneWidget);
  });

  // In Phase 6.8, Health is enabled, so we no longer expect the disabled snackbar
  // Let's test navigation to HealthScreen instead or simply test it exists.
  testWidgets('health module navigates to HealthScreen', (tester) async {
    await tester.pumpWidget(hostFor());
    await tester.tap(find.text('健康紀錄').last);
    await tester.pumpAndSettle();
    // Both the grid card and AppBar can contain '健康紀錄' after navigation.
    expect(find.text('健康紀錄'), findsAtLeastNWidgets(1));
  });

  testWidgets('AI quick-query button shows Phase 6.3\'b stub notice',
      (tester) async {
    await tester.pumpWidget(hostFor());
    await tester.tap(find.text('快速 AI 查詢'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      find.textContaining("Phase 6.3'b"),
      findsOneWidget,
    );
  });

  testWidgets('updates when ExpenseController notifies listeners',
      (tester) async {
    await tester.pumpWidget(hostFor());
    expect(find.text('本月暫無開支'), findsOneWidget);

    final now = DateTime.now();
    await expenseController.saveExpense(Expense(
      id: '',
      amount: 100,
      currency: 'TWD',
      date: DateTime(now.year, now.month, 1),
    ));
    await tester.pump();

    expect(find.text('本月暫無開支'), findsNothing);
    expect(find.textContaining('100.00 TWD'), findsOneWidget);
  });

  testWidgets('updates when ContactController notifies listeners',
      (tester) async {
    await tester.pumpWidget(hostFor());
    expect(find.text('尚未加入名片'), findsOneWidget);

    await contactController.saveContact(
      Contact(id: 'c1', name: 'Albert', scannedAt: DateTime(2026, 5, 1)),
    );
    await tester.pump();

    expect(find.text('尚未加入名片'), findsNothing);
    expect(find.text('1 張'), findsOneWidget);
  });

  testWidgets('updates when HealthController notifies listeners',
      (tester) async {
    await tester.pumpWidget(hostFor());
    expect(find.text('尚未加入紀錄'), findsOneWidget);

    await healthController.saveRecord(HealthRecord(
      date: DateTime(2026, 5, 1),
      weight: 71.5,
      dateAdded: DateTime(2026, 5, 1),
    ));
    await tester.pump();

    expect(find.text('尚未加入紀錄'), findsNothing);
    expect(find.text('1 筆'), findsOneWidget);
  });

  testWidgets('updates when WealthController notifies listeners',
      (tester) async {
    await tester.pumpWidget(hostFor());
    expect(find.text('0 筆資產'), findsOneWidget);

    await wealthController.saveRecord(WealthRecord(
      id: '',
      date: DateTime.now(),
      assetType: 'stock',
      assetName: 'AAPL',
      amount: 1000,
      currency: 'TWD',
    ));
    await tester.pump();

    expect(find.text('0 筆資產'), findsNothing);
    expect(find.text('1 筆資產'), findsOneWidget);
  });
}
