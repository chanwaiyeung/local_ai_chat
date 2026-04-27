import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/models/app_settings.dart';

void main() {
  test('uses default embedding model when json is empty', () {
    final settings = AppSettings.fromJson({});

    expect(settings.embeddingModel, 'nomic-embed-text');
  });

  test('trims embedding model', () {
    final settings = AppSettings.fromJson({
      'embeddingModel': '  bge-m3  ',
    });

    expect(settings.embeddingModel, 'bge-m3');
  });

  test('serializes embedding model', () {
    const settings = AppSettings(
      embeddingModel: 'bge-m3',
    );

    expect(settings.toJson()['embeddingModel'], 'bge-m3');
  });

  test('copyWith updates embedding model', () {
    const settings = AppSettings(
      embeddingModel: 'nomic-embed-text',
    );

    final updated = settings.copyWith(
      embeddingModel: 'bge-m3',
    );

    expect(updated.embeddingModel, 'bge-m3');
  });
}
