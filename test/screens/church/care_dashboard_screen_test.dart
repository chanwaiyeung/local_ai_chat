import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/controllers/church/care_controller.dart';
import 'package:local_ai_chat/models/church/care_case.dart';
import 'package:local_ai_chat/screens/church/care_dashboard_screen.dart';
import 'package:local_ai_chat/services/vector_store.dart';
import 'package:local_ai_chat/widgets/church/visit_log_dialog.dart';

void main() {
  late Directory tempDir;
  late VectorStore store;
  late CareController controller;

  Widget hostFor() => MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(0.7),
          ),
          child: child!,
        ),
        home: CareDashboardScreen(controller: controller),
      );

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync();
    store = VectorStore(storagePath: '${tempDir.path}/test_store.json');
    controller = CareController(store);
    await controller.loadAll();
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('renders AppBar and tabs', (tester) async {
    await tester.pumpWidget(hostFor());
    await tester.pumpAndSettle();

    expect(find.text('教會關懷中央看版'), findsOneWidget);
    expect(find.text('會友 (0)'), findsOneWidget);
    expect(find.text('新朋友 (0)'), findsOneWidget);
    expect(find.text('已探訪者 (0)'), findsOneWidget);
  });

  testWidgets('renders case card and opens log visit dialog', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final caseObj = CareCase(
      id: 'c1',
      memberName: '李四',
      reason: 'Need follow-up after surgery',
      status: CareStatus.active,
      createdAt: DateTime.now(),
    );

    // Save a case
    await tester.runAsync(() async {
      await controller.saveCase(caseObj);
    });

    await tester.pumpWidget(hostFor());
    await tester.pumpAndSettle();

    // Verify case is listed
    expect(find.text('李四'), findsOneWidget);

    // Tap on "記探訪" button
    final visitBtn = find.text('記探訪');
    expect(visitBtn, findsOneWidget);
    await tester.tap(visitBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify VisitLogDialog is displayed
    expect(find.byType(VisitLogDialog), findsOneWidget);
    expect(find.text('Log Visit - 李四'), findsOneWidget);
  });
}


