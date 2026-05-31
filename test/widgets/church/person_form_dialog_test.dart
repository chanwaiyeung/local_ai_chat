import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/models/church/person.dart';
import 'package:local_ai_chat/widgets/church/person_form_dialog.dart';

void main() {
  Widget hostFor({
    Person? existing,
    String? defaultType,
    required Future<void> Function(Person) onSave,
    Future<void> Function()? onDelete,
  }) =>
      MaterialApp(
        home: Scaffold(
          body: PersonFormDialog(
            existing: existing,
            defaultType: defaultType,
            onSave: onSave,
            onDelete: onDelete,
          ),
        ),
      );

  testWidgets('renders all fields in add mode', (tester) async {
    await tester.pumpWidget(hostFor(
      onSave: (p) async {},
    ));
    await tester.pumpAndSettle();

    expect(find.text('新增會友'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '姓名 *'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '電話(可空)'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '所屬小組 / 團契'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '主日學參與'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '建立者(傳道人姓名)'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '備註(可空)'), findsOneWidget);
  });

  testWidgets('validates required fields', (tester) async {
    Person? savedPerson;
    await tester.pumpWidget(hostFor(
      onSave: (p) async {
        savedPerson = p;
      },
    ));
    await tester.pumpAndSettle();

    // Click Save
    await tester.tap(find.text('儲存'));
    await tester.pumpAndSettle();

    // Verification errors should show up
    expect(find.text('請輸入姓名'), findsOneWidget);
    expect(savedPerson, isNull);
  });
}


