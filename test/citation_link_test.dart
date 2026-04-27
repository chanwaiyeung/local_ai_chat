import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/screens/chat_screen.dart';

void main() {
  test('parses current chunk citation format', () {
    final target = parseCitationLinkTarget(
      'chunk:?doc=report%20final.pdf&i=3',
    );

    expect(target?.docName, 'report final.pdf');
    expect(target?.chunkIndex, 3);
  });

  test('parses chunk authority citation format', () {
    final target = parseCitationLinkTarget(
      'chunk://doc?id=report.pdf&chunk=7',
    );

    expect(target?.docName, 'report.pdf');
    expect(target?.chunkIndex, 7);
  });

  test('normalizes escaped ampersands from markdown', () {
    final target = parseCitationLinkTarget(
      'chunk://doc?id=report.pdf&amp;chunk=2',
    );

    expect(target?.docName, 'report.pdf');
    expect(target?.chunkIndex, 2);
  });

  test('opens citation without chunk index when index is invalid', () {
    final target = parseCitationLinkTarget(
      'chunk://doc?id=report.pdf&chunk=abc',
    );

    expect(target?.docName, 'report.pdf');
    expect(target?.chunkIndex, isNull);
  });

  test('rejects chunk citation without a document id', () {
    expect(parseCitationLinkTarget('chunk://doc?chunk=3'), isNull);
  });
}
