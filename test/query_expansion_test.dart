import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/services/query_expansion.dart';

void main() {
  test('expands mouse cursor query', () {
    final expanded = const QueryExpansion().expandSparseQuery(
      'How do I let go of the mouse cursor?',
      maxTerms: 20,
    );

    expect(expanded, contains('release'));
    expect(expanded, contains('release mouse'));
    expect(expanded, contains('mouse lock'));
  });

  test('limits expanded terms', () {
    final expanded = const QueryExpansion().expandSparseQuery(
      'Windows MacOS keyboard mapping configuration file startup config CPU speed mouse cursor let go',
      maxTerms: 12,
    );

    expect(expanded.split(RegExp(r'\s+')), hasLength(lessThanOrEqualTo(12)));
  });
}


