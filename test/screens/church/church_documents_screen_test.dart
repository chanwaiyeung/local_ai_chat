// test/screens/church/church_documents_screen_test.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/controllers/church/care_controller.dart';
import 'package:local_ai_chat/controllers/church/person_controller.dart';
import 'package:local_ai_chat/main.dart' as main_app;
import 'package:local_ai_chat/models/church/care_case.dart';
import 'package:local_ai_chat/screens/church/church_documents_screen.dart';
import 'package:local_ai_chat/server/ollama_client.dart';
import 'package:local_ai_chat/services/vector_store.dart';

import '../../helpers/test_app.dart';

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
  late CareController careController;
  late PersonController personController;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('church_docs_test');
    store = VectorStore(storagePath: '${tempDir.path}/test_store.json');
    careController = CareController(store);
    personController = PersonController(store);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget hostFor() {
    return TestApp(
      child: ChurchDocumentsScreen(
        careController: careController,
        personController: personController,
      ),
    );
  }

  testWidgets('renders all 8 Church Document cards', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(hostFor());
    await tester.pumpAndSettle();

    expect(find.text('教會文書助理'), findsWidgets);
    expect(find.text('講道逐字稿摘要'), findsOneWidget);
    expect(find.text('小組查經問題生成'), findsOneWidget);
    expect(find.text('關懷紀錄整理'), findsOneWidget);
    expect(find.text('會友資料摘要'), findsOneWidget);
    expect(find.text('教會週報草稿'), findsOneWidget);
    expect(find.text('活動企劃書'), findsOneWidget);
    expect(find.text('PPT 敬拜/查經大綱'), findsOneWidget);
    expect(find.text('Outlook 關懷郵件草稿'), findsOneWidget);
  });

  testWidgets('can run Sermon transcript summarizer', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    main_app.globalOllama = FakeOllamaClient(responseTokens: ['# ', '講道', '大綱', '\n', '本週宣講信心。']);

    await tester.pumpWidget(hostFor());
    await tester.pumpAndSettle();

    await tester.tap(find.text('講道逐字稿摘要'));
    await tester.pumpAndSettle();

    final inputFinder = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == '貼上講道逐字稿或筆記',
    );
    expect(inputFinder, findsOneWidget);
    await tester.enterText(inputFinder, '主日講道：活出有信心的生命。');
    await tester.pumpAndSettle();

    await tester.tap(find.text('開始產生文件'));
    await tester.pumpAndSettle();

    expect(find.textContaining('講道大綱'), findsOneWidget);
    expect(find.textContaining('本週宣講信心'), findsOneWidget);
  });

  testWidgets('loads active care cases in dropdown and runs Care Summary', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.runAsync(() async {
      await careController.saveCase(CareCase(
        id: 'case_1',
        memberName: '王小美',
        reason: '開刀住院',
        status: CareStatus.active,
      ));
    });

    main_app.globalOllama = FakeOllamaClient(responseTokens: ['王小美', '關懷狀況穩定。']);

    await tester.pumpWidget(hostFor());
    await tester.pumpAndSettle();

    await tester.tap(find.text('關懷紀錄整理'));
    await tester.pumpAndSettle();

    // Find and tap dropdown
    final dropdownFinder = find.byType(DropdownButtonFormField<String>);
    expect(dropdownFinder, findsOneWidget);
    await tester.tap(dropdownFinder);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Select the option
    final dropdownItemFinder = find.text('王小美 (開刀住院)').last;
    await tester.tap(dropdownItemFinder);
    await tester.pumpAndSettle();

    await tester.tap(find.text('開始產生文件'));
    await tester.pumpAndSettle();

    expect(find.textContaining('王小美關懷狀況穩定'), findsOneWidget);
  });
}


