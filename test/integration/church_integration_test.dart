import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/controllers/church/person_controller.dart';
import 'package:local_ai_chat/models/church/person.dart';
import 'package:local_ai_chat/screens/church/person_directory_screen.dart';
import 'package:local_ai_chat/services/vector_store.dart';
import 'package:local_ai_chat/widgets/church/person_form_dialog.dart';
import '../helpers/test_app.dart';

void main() {
  late VectorStore store;
  late PersonController controller;
  late Directory tempDir;

  Widget hostFor() => TestApp(
        child: PersonDirectoryScreen(controller: controller),
      );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'local_ai_chat_church_integration_test_',
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return tempDir.path;
      },
    );

    store = VectorStore();
    controller = PersonController(store);
    await controller.loadAll();
  });

  test('does savePerson complete with mock path provider', () async {
    final person = Person(id: '', name: 'Test', attendance: AttendanceStatus.regular, personType: PersonType.member);
    await controller.savePerson(person);
    debugPrint('DEBUG: savePerson completed! length: ${controller.allPersons.length}');
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

  testWidgets('E2E Person Directory Flow (Create, Read, Update, Delete)', (tester) async {
    // 1. Initial render - should show empty directory state
    await tester.pumpWidget(hostFor());
    await tester.pumpAndSettle();

    expect(find.text('會友通訊錄'), findsOneWidget);
    expect(find.text('Add Person'), findsOneWidget);
    expect(find.text('通訊錄空白'), findsOneWidget);

    // 2. Open PersonFormDialog by clicking "Add Person" FAB
    await tester.tap(find.text('Add Person'));
    await tester.pumpAndSettle();

    expect(find.byType(PersonFormDialog), findsOneWidget);
    expect(find.text('新增會友'), findsOneWidget);

    // 3. Fill in fields and Save
    final Finder nameField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == '姓名 *');
    final Finder phoneField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == '電話(可空)');
    final Finder groupField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == '所屬小組 / 團契');
    final Finder schoolField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == '主日學參與');
    final Finder notesField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == '備註(可空)');

    await tester.enterText(nameField, '林大維');
    await tester.enterText(phoneField, '0912345678');
    await tester.enterText(groupField, '約書亞小組');
    await tester.enterText(schoolField, '馬太福音研讀班');
    await tester.enterText(notesField, '家庭拜訪需求');
    
    debugPrint('DEBUG: Name controller text: ${(tester.widget<TextField>(nameField)).controller?.text}');
    debugPrint('DEBUG: Phone controller text: ${(tester.widget<TextField>(phoneField)).controller?.text}');

    await tester.runAsync(() async {
      await tester.tap(find.text('儲存'));
      int elapsed = 0;
      while ((controller.allPersons.isEmpty ||
              find.byType(PersonFormDialog).evaluate().isNotEmpty) &&
          elapsed < 5000) {
        await tester.pump(const Duration(milliseconds: 50));
        await Future.delayed(const Duration(milliseconds: 50));
        elapsed += 100;
      }
    });
    await tester.pumpAndSettle();

    // Debug help: print active screen widgets or errors
    if (find.text('請輸入姓名').evaluate().isNotEmpty) {
      debugPrint('DEBUG: Validation failed! "請輸入姓名" is visible.');
    }
    final snackbars = find.byType(SnackBar).evaluate();
    if (snackbars.isNotEmpty) {
      final snackBarWidget = tester.widget<SnackBar>(find.byType(SnackBar));
      debugPrint('DEBUG: SnackBar visible with content: ${snackBarWidget.content}');
    }

    // Verify dialog is closed and list contains the added member
    expect(find.byType(PersonFormDialog), findsNothing);
    expect(find.text('林大維'), findsOneWidget);
    expect(find.text('小組:約書亞小組 · 主日學:馬太福音研讀班'), findsOneWidget);

    // 4. Click member to open edit form and update field
    await tester.tap(find.text('林大維'));
    await tester.pumpAndSettle();

    expect(find.byType(PersonFormDialog), findsOneWidget);
    expect(find.text('編輯會友'), findsOneWidget);

    final Finder groupFieldEdit = find.byWidgetPredicate((w) => w is TextField && w.decoration?.labelText == '所屬小組 / 團契');
    await tester.enterText(groupFieldEdit, '迦勒小組');
    await tester.runAsync(() async {
      await tester.tap(find.text('儲存'));
      int elapsed = 0;
      while ((controller.allPersons.any((p) => p.smallGroup == '約書亞小組') ||
              find.byType(PersonFormDialog).evaluate().isNotEmpty) &&
          elapsed < 5000) {
        await tester.pump(const Duration(milliseconds: 50));
        await Future.delayed(const Duration(milliseconds: 50));
        elapsed += 100;
      }
    });
    await tester.pumpAndSettle();

    // Verify list updates with new group info
    expect(find.text('小組:迦勒小組 · 主日學:馬太福音研讀班'), findsOneWidget);

    // 5. Delete member
    await tester.tap(find.text('林大維'));
    await tester.pumpAndSettle();

    expect(find.byType(PersonFormDialog), findsOneWidget);
    await tester.tap(find.text('刪除'));
    await tester.pumpAndSettle();

    // Confirm delete in AlertDialog
    expect(find.text('確認刪除'), findsOneWidget);
    final confirmDialog = find.ancestor(
      of: find.text('確認刪除'),
      matching: find.byType(AlertDialog),
    );
    await tester.runAsync(() async {
      await tester.tap(find.descendant(
        of: confirmDialog,
        matching: find.text('刪除'),
      ));
      int elapsed = 0;
      while ((controller.allPersons.isNotEmpty ||
              find.byType(PersonFormDialog).evaluate().isNotEmpty) &&
          elapsed < 5000) {
        await tester.pump(const Duration(milliseconds: 50));
        await Future.delayed(const Duration(milliseconds: 50));
        elapsed += 100;
      }
    });
    await tester.pumpAndSettle();

    // Clear search text if present
    final Finder searchField = find.byType(TextField);
    if (searchField.evaluate().isNotEmpty) {
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();
    }
    // Tap the '全部' filter chip to clear attendance filter if present
    final Finder allFilter = find.textContaining('全部');
    if (allFilter.evaluate().isNotEmpty) {
      await tester.tap(allFilter);
      await tester.pumpAndSettle();
    }

    // Verify back to empty state
    expect(find.text('林大維'), findsNothing);
    expect(controller.allPersons.isEmpty, true);
    expect(find.byIcon(Icons.contacts_outlined), findsOneWidget);
    final emptyStateText = find.byWidgetPredicate((w) =>
        w is Text &&
        (w.data == '通訊錄空白' || w.data == '無符合搜尋條件嘅會友'));
    expect(emptyStateText, findsOneWidget);
  });
}
