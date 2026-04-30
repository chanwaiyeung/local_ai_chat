import 'package:ai_library_server/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app starts at library screen', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('智讀館'), findsOneWidget);
  });
}
