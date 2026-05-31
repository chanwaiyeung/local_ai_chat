import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/models/app_settings.dart';

void main() {
  test('uses default embedding model when json is empty', () {
    final settings = AppSettings.fromJson({});

    expect(settings.embeddingModel, 'nomic-embed-text');
    expect(settings.retrievalMode, RetrievalMode.hybrid);
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
      retrievalMode: RetrievalMode.sparse,
    );

    expect(settings.toJson()['embeddingModel'], 'bge-m3');
    expect(settings.toJson()['retrievalMode'], 'sparse');
  });

  test('copyWith updates embedding model', () {
    const settings = AppSettings(
      embeddingModel: 'nomic-embed-text',
    );

    final updated = settings.copyWith(
      embeddingModel: 'bge-m3',
      retrievalMode: RetrievalMode.dense,
    );

    expect(updated.embeddingModel, 'bge-m3');
    expect(updated.retrievalMode, RetrievalMode.dense);
  });

  test('deserializes retrieval mode with hybrid fallback', () {
    final dense = AppSettings.fromJson({
      'embeddingModel': 'bge-m3',
      'retrievalMode': 'dense',
    });
    final invalid = AppSettings.fromJson({
      'embeddingModel': 'bge-m3',
      'retrievalMode': 'unknown',
    });

    expect(dense.retrievalMode, RetrievalMode.dense);
    expect(invalid.retrievalMode, RetrievalMode.hybrid);
  });

  test('deserializes tts mode with auto fallback', () {
    final localOnly = AppSettings.fromJson({
      'embeddingModel': 'nomic-embed-text',
      'ttsMode': 'localOnly',
    });
    final invalid = AppSettings.fromJson({
      'embeddingModel': 'nomic-embed-text',
      'ttsMode': 'unknown',
    });

    expect(localOnly.ttsMode, TtsMode.localOnly);
    expect(invalid.ttsMode, TtsMode.auto);
  });

  test('serializes tts mode', () {
    const settings = AppSettings(
      embeddingModel: 'nomic-embed-text',
      ttsMode: TtsMode.cloudOnly,
    );

    expect(settings.toJson()['ttsMode'], 'cloudOnly');
  });

  test('copyWith updates tts mode', () {
    const settings = AppSettings(
      embeddingModel: 'nomic-embed-text',
      ttsMode: TtsMode.auto,
    );

    final updated = settings.copyWith(
      ttsMode: TtsMode.localOnly,
    );

    expect(updated.ttsMode, TtsMode.localOnly);
  });

  test('deserializes office bridge settings with default fallbacks', () {
    final settings = AppSettings.fromJson({
      'embeddingModel': 'nomic-embed-text',
    });

    expect(settings.enableOfficeBridge, isTrue);
    expect(settings.officeBridgePort, 61670);
    expect(settings.officeBridgeToken, 'YOUR_LOCAL_TOKEN');
    expect(settings.officeBridgeLanguage, 'zh-TW');
    expect(settings.officeBridgeModel, 'local');
    expect(settings.officeBridgeAllowedApps, equals(['word', 'excel', 'ppt', 'outlook', 'wps']));
  });

  test('serializes office bridge settings', () {
    final settings = AppSettings(
      embeddingModel: 'nomic-embed-text',
      enableOfficeBridge: false,
      officeBridgePort: 12345,
      officeBridgeToken: 'MY_TOKEN',
      officeBridgeLanguage: 'en-US',
      officeBridgeModel: 'custom-model',
      officeBridgeAllowedApps: const ['word', 'wps'],
    );

    final json = settings.toJson();
    expect(json['enableOfficeBridge'], isFalse);
    expect(json['officeBridgePort'], 12345);
    expect(json['officeBridgeToken'], 'MY_TOKEN');
    expect(json['officeBridgeLanguage'], 'en-US');
    expect(json['officeBridgeModel'], 'custom-model');
    expect(json['officeBridgeAllowedApps'], equals(['word', 'wps']));
  });
}



