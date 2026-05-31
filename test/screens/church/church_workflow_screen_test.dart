// test/screens/church/church_workflow_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/main.dart' as main_app;
import 'package:local_ai_chat/screens/church/church_workflow_screen.dart';
import 'package:local_ai_chat/server/ollama_client.dart';

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
  setUp(() {
    main_app.globalOllama = FakeOllamaClient(responseTokens: []);
  });

  Widget hostFor() {
    return const TestApp(
      child: ChurchWorkflowScreen(),
    );
  }

  testWidgets('renders ChurchWorkflowScreen tabs', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(hostFor());
    await tester.pumpAndSettle();

    expect(find.text('工作流沙盒測試'), findsOneWidget);
    expect(find.text('教會 VBA 巨集工具箱'), findsOneWidget);
  });

  testWidgets('can select workflow scenario and run AI simulation', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    main_app.globalOllama = FakeOllamaClient(responseTokens: ['講道', '分段結果：', '\n1. 前言']);

    await tester.pumpWidget(hostFor());
    await tester.pumpAndSettle();

    // In sandbox tab, verify elements
    expect(find.text('選擇教會 Office 工作流場景'), findsOneWidget);
    expect(find.text('執行 AI 工作流'), findsOneWidget);

    // Tap generate
    await tester.tap(find.text('執行 AI 工作流'));
    await tester.pumpAndSettle();

    expect(find.textContaining('講道分段結果'), findsOneWidget);
  });

  testWidgets('renders VBA macro toolbox cards', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(hostFor());
    await tester.pumpAndSettle();

    // Tap Tab 2
    await tester.tap(find.text('教會 VBA 巨集工具箱'));
    await tester.pumpAndSettle();

    // Verify macro titles are rendered
    expect(find.text('講道整理 (Word VBA)'), findsOneWidget);
    expect(find.text('查經教材 (Word / PPT VBA)'), findsOneWidget);
    expect(find.text('奉獻報表 (Excel VBA)'), findsOneWidget);
  });
}


