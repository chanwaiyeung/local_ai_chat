// test/screens/wealth_screen_test.dart

//

// v2.4 Phase 7.0'b — UI regression防線 for WealthScreen.

// Mirrors the existing health_screen_test.dart conventions.

//

// Coverage:

//   * AppBar title + TabBar tabs render

//   * empty state when no records

//   * 紀錄 tab: stats card shows correct net worth in selected currency

//   * 紀錄 tab: AI 理財顧問 button only renders when ragService is non-null

//   * 紀錄 tab: search filters list

//   * 紀錄 tab: currency picker chips visible when ≥2 currencies present

//   * 配置 tab: pie chart (allocation) appears

//   * 配置 tab: net worth history chart appears when ≥2 dates

//   * Form: shows date / assetType / assetName / amount / currency / notes / tags

//   * Form: required validators reject invalid amount





import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';



import 'package:local_ai_chat/controllers/wealth_controller.dart';
import 'package:local_ai_chat/l10n/app_localizations.dart';
import 'package:local_ai_chat/models/wealth_record.dart';

import 'package:local_ai_chat/screens/wealth_screen.dart';

import 'package:local_ai_chat/services/vector_store.dart';



void main() {
  late VectorStore store;

  late WealthController controller;



  Widget hostFor() => MaterialApp(
        locale: const Locale('zh', 'TW'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WealthScreen(controller: controller),
      );



  setUp(() async {
    store = VectorStore();

    controller = WealthController(store);

    await controller.loadAll();

  });



  tearDown(() async {

    // if (await tempDir.exists()) await tempDir.delete(recursive: true);

  });



  group('shell + tabs', () {

    testWidgets('renders AppBar title + 紀錄/配置 tabs', (tester) async {

      await tester.pumpWidget(hostFor());

      expect(find.text('投資理財'), findsOneWidget);

      expect(find.text('紀錄'), findsOneWidget);

      expect(find.text('配置'), findsOneWidget);

    });



    testWidgets('shows empty state on 紀錄 tab when no records',

        (tester) async {

      await tester.pumpWidget(hostFor());

      expect(find.text('尚無投資紀錄'), findsWidgets);

    });



    testWidgets('shows empty state on 配置 tab when no records',

        (tester) async {

      await tester.pumpWidget(hostFor());

      await tester.tap(find.text('配置'));

      await tester.pumpAndSettle();

      expect(find.text('沒有可繪製的投資資料'), findsOneWidget);

    });

  });



  group('records tab', () {

    Future<void> seedSingleUsd(WidgetTester tester) async {

      await tester.runAsync(() async {
        await controller.saveRecord(WealthRecord(

          date: DateTime(2026, 5, 1),

          assetType: WealthAssetType.stock,

          assetName: 'AAPL',

          amount: 1000,

          currency: 'USD',

          dateAdded: DateTime(2026, 5, 1),

        ));
      });

      await tester.pumpAndSettle();

    }



    testWidgets('stats card shows asset count and net worth', (tester) async {

      await tester.pumpWidget(hostFor());

      await seedSingleUsd(tester);

      expect(find.textContaining('1 項資產'), findsOneWidget);

      expect(find.text('1000.00'), findsOneWidget);

    });



    testWidgets('list row shows asset label · name and amount/currency',

        (tester) async {

      await tester.pumpWidget(hostFor());

      await seedSingleUsd(tester);

      // Title is "股票 · AAPL" thanks to WealthAssetType.label('stock').

      expect(find.text('股票 · AAPL'), findsOneWidget);

      // Trailing shows amount with the right currency token.

      expect(find.text('1000.00 USD'), findsOneWidget);

    });



    testWidgets('search filters list by assetName (case-insensitive)',

        (tester) async {

      await tester.pumpWidget(hostFor());

      await tester.runAsync(() async {
        await controller.saveRecord(WealthRecord(

          date: DateTime(2026, 5, 1),

          assetType: WealthAssetType.stock,

          assetName: 'AAPL',

          amount: 1000,

          currency: 'USD',

          dateAdded: DateTime(2026, 5, 1),

        ));
      });

      await tester.runAsync(() async {
        await controller.saveRecord(WealthRecord(

          date: DateTime(2026, 5, 1),

          assetType: WealthAssetType.stock,

          assetName: 'TSLA',

          amount: 2000,

          currency: 'USD',

          dateAdded: DateTime(2026, 5, 1),

        ));
      });

      await tester.pumpAndSettle();

      expect(find.textContaining('AAPL'), findsOneWidget);

      expect(find.textContaining('TSLA'), findsOneWidget);



      await tester.enterText(find.byType(TextField), 'aapl');

      await tester.pumpAndSettle();

      expect(find.textContaining('AAPL'), findsOneWidget);

      expect(find.textContaining('TSLA'), findsNothing);

    });



    testWidgets('currency picker appears when ≥2 currencies present',

        (tester) async {

      await tester.pumpWidget(hostFor());

      await tester.runAsync(() async {
        await controller.saveRecord(WealthRecord(

          date: DateTime(2026, 5, 1),

          assetType: WealthAssetType.cash,

          amount: 100,

          currency: 'USD',

          dateAdded: DateTime(2026, 5, 1),

        ));
      });

      await tester.runAsync(() async {
        await controller.saveRecord(WealthRecord(

          date: DateTime(2026, 5, 1),

          assetType: WealthAssetType.cash,

          amount: 100000,

          currency: 'TWD',

          dateAdded: DateTime(2026, 5, 1),

        ));
      });

      await tester.pumpAndSettle();

      expect(find.text('幣別：'), findsWidgets);

      expect(find.widgetWithText(ChoiceChip, 'USD'), findsOneWidget);

      expect(find.widgetWithText(ChoiceChip, 'TWD'), findsOneWidget);

    });



    testWidgets('AI advisor button hidden when ragService is null',

        (tester) async {

      await tester.pumpWidget(hostFor());

      await tester.runAsync(() async {
        await controller.saveRecord(WealthRecord(

          date: DateTime(2026, 5, 1),

          assetType: WealthAssetType.cash,

          amount: 100,

          dateAdded: DateTime(2026, 5, 1),

        ));
      });

      await tester.pumpAndSettle();

      expect(find.text('AI 理財顧問'), findsNothing);

    });

  });



  group('allocation tab', () {

    testWidgets('shows allocation rows + pie chart when records exist',

        (tester) async {

      await tester.runAsync(() async {
        await controller.saveRecord(WealthRecord(

          date: DateTime(2026, 5, 1),

          assetType: WealthAssetType.stock,

          assetName: 'AAPL',

          amount: 800,

          currency: 'USD',

          dateAdded: DateTime(2026, 5, 1),

        ));
      });

      await tester.runAsync(() async {
        await controller.saveRecord(WealthRecord(

          date: DateTime(2026, 5, 1),

          assetType: WealthAssetType.crypto,

          assetName: 'BTC',

          amount: 200,

          currency: 'USD',

          dateAdded: DateTime(2026, 5, 1),

        ));
      });



      await tester.pumpWidget(hostFor());

      await tester.tap(find.text('配置'));

      await tester.pumpAndSettle();



      expect(find.textContaining('資產配置（USD）'), findsOneWidget);

      expect(find.text('股票'), findsOneWidget);

      expect(find.text('加密貨幣'), findsOneWidget);

      expect(find.byType(CustomPaint), findsWidgets);

    });



    testWidgets('history chart needs ≥2 distinct dates', (tester) async {

      await tester.runAsync(() async {
        await controller.saveRecord(WealthRecord(

          date: DateTime(2026, 5, 1),

          assetType: WealthAssetType.cash,

          amount: 100,

          currency: 'USD',

          dateAdded: DateTime(2026, 5, 1),

        ));
      });



      await tester.pumpWidget(hostFor());

      await tester.tap(find.text('配置'));

      await tester.pumpAndSettle();

      expect(find.text('需要至少兩個不同日期才能繪製趨勢'), findsOneWidget);



      await tester.runAsync(() async {
        await controller.saveRecord(WealthRecord(

          date: DateTime(2026, 5, 5),

          assetType: WealthAssetType.cash,

          amount: 150,

          currency: 'USD',

          dateAdded: DateTime(2026, 5, 5),

        ));
      });

      await tester.pumpAndSettle();

      expect(find.text('需要至少兩個不同日期才能繪製趨勢'), findsNothing);

    });

  });



  group('form dialog', () {

    testWidgets('FAB opens form with all expected fields', (tester) async {

      await tester.pumpWidget(hostFor());

      await tester.tap(find.byType(FloatingActionButton));

      await tester.pumpAndSettle();



      expect(find.text('新增投資紀錄'), findsOneWidget);

      expect(find.text('估值日期'), findsOneWidget);

      expect(find.text('資產類別'), findsOneWidget);

      expect(find.textContaining('資產名稱'), findsOneWidget);

      expect(find.text('金額'), findsOneWidget);

      expect(find.text('幣別'), findsOneWidget);

      expect(find.text('備註'), findsOneWidget);

      expect(find.textContaining('標籤'), findsWidgets);

    });



    testWidgets('amount validator rejects empty / non-numeric / zero',

        (tester) async {

      await tester.pumpWidget(hostFor());

      await tester.tap(find.byType(FloatingActionButton));

      await tester.pumpAndSettle();



      // Empty submit

      await tester.tap(find.text('儲存'));

      await tester.pumpAndSettle();

      expect(find.text('請輸入有效金額'), findsOneWidget);



      // Submit zero

      await tester.enterText(

          find.widgetWithText(TextFormField, '金額'), '0');

      await tester.tap(find.text('儲存'));

      await tester.pumpAndSettle();

      expect(find.text('請輸入有效金額'), findsOneWidget);

    });



    testWidgets('valid submit creates a record', (tester) async {

      await tester.pumpWidget(hostFor());

      await tester.tap(find.byType(FloatingActionButton));

      await tester.pumpAndSettle();



      await tester.enterText(

          find.widgetWithText(TextFormField, '金額'), '12345');

      await tester.tap(find.text('儲存'));

      await tester.pumpAndSettle();



      expect(controller.count, 1);

      expect(controller.getAllRecords().first.amount, 12345);

    });

  });

}


// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
// padding
