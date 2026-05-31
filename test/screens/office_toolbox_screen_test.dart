import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/screens/office_toolbox_screen.dart';

import '../helpers/test_app.dart';

void main() {
  group('OfficeToolboxScreen Widget Tests', () {
    final List<String> clipboardLogs = [];

    setUp(() {
      clipboardLogs.clear();
      // Mock Clipboard channels
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            clipboardLogs.add(methodCall.arguments['text'] as String);
            return true;
          }
          return null;
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    testWidgets('renders all tabs and status header correctly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      await tester.pumpWidget(const TestApp(
        child: OfficeToolboxScreen(),
      ));
      await tester.pump(); // Start health check
      await tester.pumpAndSettle(); // Resolve health check and render

      // Verify title is rendered
      expect(find.text('Office AI 工具箱'), findsOneWidget);

      // Verify status header
      expect(find.text('Local Office Bridge API'), findsOneWidget);
      expect(find.text('伺服器未啟動'), findsOneWidget); // Default offline status in widget test
      expect(find.text('連接埠: 61670'), findsOneWidget);

      // Verify tabs are rendered
      expect(find.text('助理工具'), findsOneWidget);
      expect(find.text('巨集與指令碼'), findsOneWidget);
      expect(find.text('整合指南'), findsOneWidget);

      // We should be on the Assistants tab first
      expect(find.text('Word / Writer 助理'), findsOneWidget);
      expect(find.text('Excel / Sheets 助理'), findsOneWidget);
      expect(find.text('教會文書助理'), findsOneWidget);
    });

    testWidgets('taps on VBA tab, renders macro list and copies macro successfully', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      await tester.pumpWidget(const TestApp(
        child: OfficeToolboxScreen(),
      ));
      await tester.pumpAndSettle();

      // Switch to VBA Macros tab
      await tester.tap(find.text('巨集與指令碼'));
      await tester.pumpAndSettle();

      // Check macro lists are rendered
      expect(find.text('Word / WPS Writer (文筆潤飾)'), findsOneWidget);
      expect(find.text('Excel / WPS Spreadsheets (公式生成)'), findsOneWidget);

      // Tap copy macro button for Word (first one)
      final copyButtons = find.widgetWithText(ElevatedButton, '複製程式碼');
      expect(copyButtons, findsWidgets); // Should find several copy buttons

      await tester.ensureVisible(copyButtons.first);
      await tester.tap(copyButtons.first);
      await tester.pumpAndSettle();

      // Verify it was copied to clipboard
      expect(clipboardLogs, isNotEmpty);
      expect(clipboardLogs.first, contains('Sub PolishSelectedText()'));
    });

    testWidgets('taps on Setup Guide tab and renders step items', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      await tester.pumpWidget(const TestApp(
        child: OfficeToolboxScreen(),
      ));
      await tester.pumpAndSettle();

      // Switch to Guide tab
      await tester.tap(find.text('整合指南'));
      await tester.pumpAndSettle();

      // Verify guide titles
      expect(find.text('🚀 快速整合指南 (Setup Guide)'), findsOneWidget);
      expect(find.text('步驟 1'), findsNWidgets(2));
      expect(find.text('步驟 5'), findsNWidgets(2));
      expect(find.text('提示'), findsOneWidget); 
    });
  });
}


