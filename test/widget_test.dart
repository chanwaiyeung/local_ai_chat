import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/core/locator.dart';

void main() {
  setUp(() async {
    await Locator.resetForTest();
  });

  testWidgets('dummy test', (tester) async {
    expect(true, isTrue);
  });
}
