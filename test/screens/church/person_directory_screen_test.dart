import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/controllers/church/person_controller.dart';
import 'package:local_ai_chat/models/church/person.dart';
import 'package:local_ai_chat/screens/church/person_directory_screen.dart';
import 'package:local_ai_chat/services/vector_store.dart';
import 'package:local_ai_chat/widgets/church/person_form_dialog.dart';

void main() {
  late Directory tempDir;
  late VectorStore store;
  late PersonController controller;

  Widget hostFor() => MaterialApp(
        home: PersonDirectoryScreen(controller: controller),
      );

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync();
    store = VectorStore(storagePath: '${tempDir.path}/test_store.json');
    controller = PersonController(store);
    await controller.loadAll();
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('renders AppBar and FloatingActionButton', (tester) async {
    await tester.pumpWidget(hostFor());
    await tester.pumpAndSettle();

    expect(find.text('會友通訊錄'), findsOneWidget);
    expect(find.text('Add Person'), findsOneWidget);
    expect(find.byIcon(Icons.person_add), findsOneWidget);
  });

  testWidgets('renders search field and empty state', (tester) async {
    await tester.pumpWidget(hostFor());
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('通訊錄空白'), findsOneWidget);
  });

  testWidgets('renders person row and triggers edit dialog on click', (tester) async {
    final person = Person(
      id: 'p1',
      name: '張三',
      phone: '12345678',
      smallGroup: '活水小組',
      sundaySchool: '成人主日學',
      attendance: AttendanceStatus.regular,
      personType: PersonType.member,
      notes: '測試備註',
      createdBy: 'Carer',
    );

    // Save a person to controller
    await tester.runAsync(() async {
      await controller.savePerson(person);
    });

    await tester.pumpWidget(hostFor());
    await tester.pumpAndSettle();

    // Verify row is rendered
    expect(find.text('張三'), findsOneWidget);
    expect(find.text('小組:活水小組 · 主日學:成人主日學'), findsOneWidget);

    // Click to open edit dialog
    await tester.tap(find.text('張三'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify dialog is open
    expect(find.byType(PersonFormDialog), findsOneWidget);
    expect(find.text('編輯會友'), findsOneWidget);
  });
}
