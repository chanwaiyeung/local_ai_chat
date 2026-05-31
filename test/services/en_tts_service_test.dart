import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/services/en_tts_service.dart';
import 'package:local_ai_chat/services/tts_service.dart';

class _FakeTTSService extends Fake implements TTSService {
  String? lastText;
  String? lastLang;
  bool isSpeakingValue = false;
  bool stopCalled = false;
  bool pauseCalled = false;

  @override
  Future<void> speak(String text, {TtsQuality quality = TtsQuality.fast, String? lang}) async {
    lastText = text;
    lastLang = lang;
    isSpeakingValue = true;
  }

  @override
  Future<void> stop() async {
    stopCalled = true;
    isSpeakingValue = false;
  }

  @override
  Future<void> pause() async {
    pauseCalled = true;
    isSpeakingValue = false;
  }

  @override
  bool get isSpeaking => isSpeakingValue;
}

void main() {
  group('EnTtsService Tests', () {
    late _FakeTTSService fakeTts;
    late EnTtsService service;

    setUp(() {
      fakeTts = _FakeTTSService();
      service = EnTtsService(fakeTts);
    });

    test('speak calls underlying speak with en-US lang', () async {
      await service.speak('Hello');
      expect(fakeTts.lastText, 'Hello');
      expect(fakeTts.lastLang, 'en-US');
    });

    test('stop calls underlying stop', () async {
      await service.stop();
      expect(fakeTts.stopCalled, isTrue);
    });

    test('pause calls underlying pause', () async {
      await service.pause();
      expect(fakeTts.pauseCalled, isTrue);
    });
  });
}


