// test/screens/life_documents_screen_test.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/controllers/book_controller.dart';
import 'package:local_ai_chat/controllers/expense_controller.dart';
import 'package:local_ai_chat/controllers/health_controller.dart';
import 'package:local_ai_chat/controllers/wealth_controller.dart';
import 'package:local_ai_chat/main.dart' as main_app;
import 'package:local_ai_chat/screens/life_documents_screen.dart';
import 'package:local_ai_chat/server/ollama_client.dart';
import 'package:local_ai_chat/services/vector_store.dart';
import '../helpers/test_app.dart';

class FakeOllamaClient extends OllamaClient {
  FakeOllamaClient({required this.responseTokens});

  final List<String> responseTokens;

  @override
  Stream<String> generate(String prompt) async* {
    for (final token in responseTokens) {
      yield token;
    }
  }
}

void main() {
  late Directory tempDir;
  late VectorStore store;
  late ExpenseController expenseController;
  late WealthController wealthController;
  late HealthController healthController;
  late BookController bookController;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('life_docs_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return tempDir.path;
      },
    );
    main_app.globalOllama = FakeOllamaClient(responseTokens: []);
    store = VectorStore(storagePath: '${tempDir.path}/test_store.json');
    expenseController = ExpenseController(store);
    wealthController = WealthController(store);
    healthController = HealthController(store);
    bookController = BookController(store);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget hostFor() {
    return TestApp(
      child: LifeDocumentsScreen(
        expenseController: expenseController,
        wealthController: wealthController,
        healthController: healthController,
        bookController: bookController,
      ),
    );
  }

  testWidgets('renders all 6 Life Document Apps cards', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(hostFor());
    await tester.pumpAndSettle();

    expect(find.text('生活文件應用 (Life Document Apps)'), findsOneWidget);
    expect(find.text('家庭財務月報'), findsOneWidget);
    expect(find.text('健康紀錄摘要'), findsOneWidget);
    expect(find.text('讀書筆記整理'), findsOneWidget);
    expect(find.text('收據 OCR 匯入'), findsOneWidget);
    expect(find.text('個人年度回顧'), findsOneWidget);
    expect(find.text('旅遊計畫書'), findsOneWidget);
  });

  testWidgets('can configure and run Family Finance report generator', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    main_app.globalOllama = FakeOllamaClient(responseTokens: ['# ', '財務', '報告', '\n', '本月支出正常。']);

    await tester.pumpWidget(hostFor());
    await tester.pumpAndSettle();

    // Click on Family Finance Report card
    await tester.tap(find.text('家庭財務月報'));
    await tester.pumpAndSettle();

    // Verify config headers are displayed
    expect(find.text('開始產生文件'), findsOneWidget);
    expect(find.text('額外指示/要求 (可留空)'), findsOneWidget);

    // Enter extra instructions
    await tester.enterText(find.byType(TextField), '請分析交通費');
    await tester.pumpAndSettle();

    // Tap generate
    await tester.tap(find.text('開始產生文件'));
    await tester.pumpAndSettle();

    // Verify streamed output renders
    expect(find.textContaining('財務報告'), findsOneWidget);
    expect(find.textContaining('本月支出正常'), findsOneWidget);
  });

  testWidgets('can parse OCR output JSON and import it to Expense database', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // LLM outputs markdown formatting containing a structured JSON array block
    final llmOcrOutput = '''
這裡是由 OCR 原始文字結構化後的結果：

| 日期 | 品項 | 金額 |
|---|---|---|
| 2026/05/29 | 咖啡 | 75 |

```json
[
  {
    "amount": 75.0,
    "currency": "TWD",
    "category": "餐飲",
    "merchant": "全家便利商店",
    "notes": "咖啡",
    "paymentMethod": "cash"
  }
]
```
已完成結構化。
''';

    main_app.globalOllama = FakeOllamaClient(responseTokens: [llmOcrOutput]);

    await tester.pumpWidget(hostFor());
    await tester.pumpAndSettle();

    // Click OCR card
    await tester.tap(find.text('收據 OCR 匯入'));
    await tester.pumpAndSettle();

    // Fill in OCR input text
    final ocrInputFinder = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == '貼上收據/發票 OCR 原始文字',
    );
    expect(ocrInputFinder, findsOneWidget);
    await tester.enterText(ocrInputFinder, '全家 2026/05/29 咖啡 75');
    await tester.pumpAndSettle();

    // Generate structure
    await tester.tap(find.text('開始產生文件'));
    await tester.pumpAndSettle();

    // Verify it generated and contains the import button
    expect(find.text('一鍵匯入記帳'), findsOneWidget);

    // Tap import
    await tester.tap(find.text('一鍵匯入記帳'));
    await tester.pump(); // Trigger saveExpense future

    // Let the expenseController notify listeners
    await tester.runAsync(() async {
      await expenseController.getAllExpenses();
    });
    await tester.pumpAndSettle();

    // Check if the record is successfully imported
    expect(expenseController.expenses.length, 1);
    expect(expenseController.expenses.first.amount, 75.0);
    expect(expenseController.expenses.first.merchant, '全家便利商店');
    expect(expenseController.expenses.first.category, '餐飲');
  });
}


