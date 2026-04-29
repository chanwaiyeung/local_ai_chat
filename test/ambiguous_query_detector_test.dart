import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/services/ambiguous_query_detector.dart';

void main() {
  const detector = AmbiguousQueryDetector();

  test('detects vague or underspecified questions', () {
    expect(detector.isAmbiguous('How do I configure it correctly?'), isTrue);
    expect(detector.isAmbiguous('How do I fix the mouse?'), isTrue);
    expect(detector.isAmbiguous('Where do I put my settings?'), isTrue);
  });

  test('keeps explicit DOSBox questions eligible for retrieval', () {
    expect(
      detector.isAmbiguous(
        'What is the default key combination to release the mouse in DOSBox?',
      ),
      isFalse,
    );
    expect(
      detector.isAmbiguous('How can I control CPU speed?'),
      isFalse,
    );
  });
}
