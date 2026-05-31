import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/models/app_settings.dart';
import 'package:local_ai_chat/screens/settings_screen.dart';
import '../helpers/test_app.dart';

void main() {
  testWidgets('SettingsScreen displays ttsMode dropdown and defaults to initial value', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    const settings = AppSettings(
      embeddingModel: 'nomic-embed-text',
      ttsMode: TtsMode.auto,
    );

    await tester.pumpWidget(const TestApp(
      child: SettingsScreen(currentSettings: settings),
    ));
    await tester.pumpAndSettle();

    expect(find.text('語音合成模式'), findsAtLeastNWidgets(1));
    expect(find.text('自動決策（推薦）'), findsOneWidget);
  });

  testWidgets('SettingsScreen can change ttsMode dropdown and submit new settings', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    const settings = AppSettings(
      embeddingModel: 'nomic-embed-text',
      ttsMode: TtsMode.auto,
    );

    AppSettings? submittedSettings;

    await tester.pumpWidget(
      TestApp(
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                submittedSettings = await Navigator.of(context).push<AppSettings>(
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(currentSettings: settings),
                  ),
                );
              },
              child: const Text('Open Settings'),
            );
          },
        ),
      ),
    );

    // Open settings screen
    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();

    // Verify initial dropdown selection is displayed
    expect(find.text('自動決策（推薦）'), findsOneWidget);

    // Open the dropdown menu
    await tester.tap(find.text('自動決策（推薦）'));
    await tester.pumpAndSettle();

    // Select "僅本地（節省流量）"
    await tester.tap(find.text('僅本地（節省流量）').last);
    await tester.pumpAndSettle();

    // Submit changes by pressing applySettings button
    await tester.tap(find.text('套用設定'));
    await tester.pumpAndSettle();

    // Verify settings were returned and updated
    expect(submittedSettings, isNotNull);
    expect(submittedSettings!.ttsMode, TtsMode.localOnly);
  });

  testWidgets('SettingsScreen displays Office Bridge settings and allows modifications', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    const settings = AppSettings(
      embeddingModel: 'nomic-embed-text',
      enableOfficeBridge: true,
      officeBridgePort: 61670,
      officeBridgeToken: 'YOUR_LOCAL_TOKEN',
      officeBridgeLanguage: 'zh-TW',
      officeBridgeModel: 'local',
      officeBridgeAllowedApps: ['word', 'excel'],
    );

    AppSettings? submittedSettings;

    await tester.pumpWidget(
      TestApp(
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                submittedSettings = await Navigator.of(context).push<AppSettings>(
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(currentSettings: settings),
                  ),
                );
              },
              child: const Text('Open Settings'),
            );
          },
        ),
      ),
    );

    // Open settings screen
    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();

    // Verify fields are present
    expect(find.text('啟用 Office Bridge'), findsOneWidget);
    expect(find.text('本機 API 連接埠 (Port)'), findsOneWidget);
    expect(find.text('API 安全認證 Token'), findsOneWidget);
    expect(find.text('預設本機模型 (Ollama)'), findsOneWidget);

    // Modify Port
    final portFinder = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == '本機 API 連接埠 (Port)',
    );
    await tester.enterText(portFinder, '70000');

    // Modify Token
    final tokenFinder = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == 'API 安全認證 Token',
    );
    await tester.enterText(tokenFinder, 'NEW_TOKEN');

    // Modify Model
    final modelFinder = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == '預設本機模型 (Ollama)',
    );
    await tester.enterText(modelFinder, 'llama3');

    // Toggle Allowed Apps: deselect word, select ppt
    await tester.tap(find.text('WORD'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PPT'));
    await tester.pumpAndSettle();

    // Submit changes
    await tester.tap(find.text('套用設定'));
    await tester.pumpAndSettle();

    expect(submittedSettings, isNotNull);
    expect(submittedSettings!.officeBridgePort, 70000);
    expect(submittedSettings!.officeBridgeToken, 'NEW_TOKEN');
    expect(submittedSettings!.officeBridgeModel, 'llama3');
    // Allowed apps should have had 'word' removed, 'ppt' added, and 'excel' remained
    expect(submittedSettings!.officeBridgeAllowedApps, contains('excel'));
    expect(submittedSettings!.officeBridgeAllowedApps, contains('ppt'));
    expect(submittedSettings!.officeBridgeAllowedApps, isNot(contains('word')));
  });
}


