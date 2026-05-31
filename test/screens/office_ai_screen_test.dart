// test/screens/office_ai_screen_test.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/main.dart' as main_app;
import 'package:local_ai_chat/screens/office_ai_screen.dart';
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

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('office_ai_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return tempDir.path;
      },
    );
    main_app.globalOllama = FakeOllamaClient(responseTokens: []);
    main_app.globalStore = VectorStore();
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

  Widget hostFor({String? initialApp, String? initialTask}) {
    return TestApp(
      child: OfficeAiScreen(
        initialApp: initialApp,
        initialTask: initialTask,
      ),
    );
  }

  testWidgets('renders sidebar navigation menu and main workspace', (WidgetTester tester) async {
    // Desktop size to trigger split layout
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(hostFor());
    await tester.pumpAndSettle();

    expect(find.text('Office AI 工具箱'), findsWidgets);
    expect(find.text('Word 助理'), findsOneWidget);
    expect(find.text('Excel 助理'), findsOneWidget);
    expect(find.text('PowerPoint 助理'), findsOneWidget);
    expect(find.text('Outlook 助理'), findsOneWidget);
    expect(find.text('Office Bridge 設定'), findsOneWidget);
  });

  testWidgets('can toggle office bridge settings and save', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(hostFor());
    await tester.pumpAndSettle();

    // Select Office Bridge Settings
    await tester.tap(find.text('Office Bridge 設定'));
    await tester.pumpAndSettle();

    // Verify settings fields are rendered
    expect(find.text('啟用 Office Bridge 伺服器'), findsOneWidget);
    expect(find.widgetWithText(TextField, '本機 API Port'), findsOneWidget);

    // Click save
    await tester.runAsync(() async {
      await tester.tap(find.text('儲存並套用設定'));
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();

    expect(find.textContaining('Office Bridge 設定已儲存'), findsOneWidget);
  });

  testWidgets('can enter sandbox text and generate AI response', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    main_app.globalOllama = FakeOllamaClient(responseTokens: ['已', '完成', '摘要']);

    await tester.pumpWidget(hostFor(initialApp: 'word', initialTask: 'summarize_doc'));
    await tester.pumpAndSettle();

    // Verify task title is rendered
    expect(find.textContaining('任務設定：摘要文件'), findsOneWidget);

    // Input some text
    final inputFinder = find.byType(TextFormField);
    expect(inputFinder, findsOneWidget);
    await tester.enterText(inputFinder, '這是要被摘要的文字。');
    await tester.pumpAndSettle();

    // Run AI
    await tester.tap(find.text('執行 AI 處理'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('已完成摘要'), findsOneWidget);
  });
}


