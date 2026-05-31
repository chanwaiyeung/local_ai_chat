import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/controllers/church/care_controller.dart';
import 'package:local_ai_chat/screens/church/care_dashboard_screen.dart';
import 'package:local_ai_chat/screens/church/case_detail_screen.dart';
import 'package:local_ai_chat/screens/church/person_history_screen.dart';
import 'package:local_ai_chat/services/vector_store.dart';
import 'package:local_ai_chat/widgets/church/case_form_dialog.dart';
import 'package:local_ai_chat/widgets/church/visit_log_dialog.dart';
import '../helpers/test_app.dart';

void main() {
  late VectorStore store;
  late CareController controller;
  late Directory tempDir;

  Widget hostFor() => TestApp(
        child: CareDashboardScreen(controller: controller),
      );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'local_ai_chat_church_flow_test_',
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return tempDir.path;
      },
    );

    store = VectorStore();
    controller = CareController(store);
    await controller.loadAll();
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

  testWidgets('E2E Care Dashboard Flow (Case Creation, Visit Logging, History, Closing)', (tester) async {
    // Set viewport size and text scale factor so buttons are fully visible/tappable and no overflow occurs
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    tester.platformDispatcher.textScaleFactorTestValue = 0.8;
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    // 1. Initial render - should show Care Dashboard with empty tabs
    await tester.pumpWidget(hostFor());
    await tester.pumpAndSettle();

    expect(find.text('教會關懷中央看版'), findsOneWidget);
    expect(find.text('會友 (0)'), findsOneWidget);
    expect(find.text('新朋友 (0)'), findsOneWidget);
    expect(find.text('已探訪者 (0)'), findsOneWidget);

    // 2. Open CaseFormDialog using FAB
    expect(find.byType(FloatingActionButton), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.byType(CaseFormDialog), findsOneWidget);
    expect(find.text('新增關懷案件'), findsOneWidget);

    // 3. Fill in Case details and Save
    final Finder nameField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == '會友 / Member 姓名 *');
    final Finder reasonField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == '緣由 *(例:住院、喪父、非會友追蹤)');
    final Finder notesField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == '備註(可空)');

    await tester.enterText(nameField, '李四');
    await tester.enterText(reasonField, '開刀住院');
    await tester.enterText(notesField, '需要關懷與禱告');

    await tester.runAsync(() async {
      await tester.tap(find.text('儲存'));
      int elapsed = 0;
      while ((controller.allCases.isEmpty ||
              find.byType(CaseFormDialog).evaluate().isNotEmpty) &&
          elapsed < 5000) {
        await tester.pump(const Duration(milliseconds: 50));
        await Future.delayed(const Duration(milliseconds: 50));
        elapsed += 100;
      }
    });
    await tester.pumpAndSettle();

    // Verify dialog is closed and case is rendered in the active list
    expect(find.byType(CaseFormDialog), findsNothing);
    expect(find.text('會友 (1)'), findsOneWidget);
    expect(find.text('李四'), findsOneWidget);
    expect(find.text('開刀住院  ·  中優先'), findsOneWidget);
    expect(find.text('尚未探訪過'), findsOneWidget);

    // 4. Log a visit using "記探訪" button
    await tester.tap(find.text('記探訪'));
    await tester.pumpAndSettle();

    expect(find.byType(VisitLogDialog), findsOneWidget);
    expect(find.text('Log Visit - 李四'), findsOneWidget);

    final Finder visitedByField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == 'Visited By *');
    final Finder summaryField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == 'Notes / Summary *');

    await tester.enterText(visitedByField, '陳傳道');
    await tester.enterText(summaryField, '手術順利，精神良好');

    // Tap ChoiceChip for "Home Visit" (label is Home Visit, value is inperson)
    await tester.tap(find.text('Home Visit'));
    await tester.pumpAndSettle();

    // Save visit log
    await tester.runAsync(() async {
      await tester.tap(find.text('Save'));
      int elapsed = 0;
      while ((controller.allVisits.isEmpty ||
              find.byType(VisitLogDialog).evaluate().isNotEmpty) &&
          elapsed < 5000) {
        await tester.pump(const Duration(milliseconds: 50));
        await Future.delayed(const Duration(milliseconds: 50));
        elapsed += 100;
      }
    });
    await tester.pumpAndSettle();

    // Verify dialog closed and case card updated (last visit info is displayed)
    expect(find.byType(VisitLogDialog), findsNothing);
    expect(find.textContaining('陳傳道'), findsOneWidget);
    expect(find.text('李四'), findsOneWidget);

    // 5. Navigate to Details (CaseDetailScreen)
    await tester.tap(find.text('詳情'));
    await tester.pumpAndSettle();

    expect(find.byType(CaseDetailScreen), findsOneWidget);
    expect(find.text('手術順利，精神良好'), findsOneWidget);

    // Navigate back to Dashboard using the BackButton
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // 6. Go to "已探訪者" tab
    await tester.tap(find.text('已探訪者 (1)'));
    await tester.pumpAndSettle();

    expect(find.text('李四'), findsOneWidget);
    
    expect(find.textContaining('陳傳道'), findsOneWidget);
    expect(find.text('共 1 次探訪 · 1 個案件'), findsOneWidget);

    // 7. Drill down to Person History from "已探訪者" tab
    await tester.tap(find.text('李四'));
    await tester.pumpAndSettle();

    expect(find.byType(PersonHistoryScreen), findsOneWidget);
    expect(find.text('李四'), findsNWidgets(2));
    expect(find.textContaining('關懷案件'), findsOneWidget);
    expect(find.textContaining('探訪時間軸'), findsOneWidget);
    expect(find.text('手術順利，精神良好'), findsOneWidget);

    // Navigate back to Dashboard
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // 8. Close Case
    // Tap "會友 (1)" tab to return to the active case
    await tester.tap(find.text('會友 (1)'));
    await tester.pumpAndSettle();

    // Tap close case button
    await tester.tap(find.byTooltip('結案'));
    await tester.pumpAndSettle();

    expect(find.text('將「李四」這個案件標記為已結案?'), findsOneWidget);
    final confirmDialog = find.ancestor(
      of: find.textContaining('將「李四」這個案件標記為已結案'),
      matching: find.byType(AlertDialog),
    );
    final buttonFinder = find.descendant(
      of: confirmDialog,
      matching: find.byType(FilledButton),
    );

    await tester.runAsync(() async {
      await tester.tap(buttonFinder);
      int elapsed = 0;
      while ((controller.activeCases.isNotEmpty ||
              find.byType(AlertDialog).evaluate().isNotEmpty) &&
          elapsed < 5000) {
        await tester.pump(const Duration(milliseconds: 50));
        await Future.delayed(const Duration(milliseconds: 50));
        elapsed += 100;
      }
    });
    await tester.pumpAndSettle();

    // Verify case is moved out of active member list
    expect(find.text('會友 (0)'), findsOneWidget);
    expect(find.text('李四'), findsNothing);
  });
}


