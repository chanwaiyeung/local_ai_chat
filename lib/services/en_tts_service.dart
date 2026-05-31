import 'tts_service.dart';

class EnTtsService {
  final TTSService tts; 

  EnTtsService(this.tts);

  /// 播放英文語音 (en-US)
  Future<void> speak(String text) async {
    await tts.speak(text, lang: "en-US");
  }

  /// 停止播放
  Future<void> stop() async {
    await tts.stop();
  }

  /// 暫停播放
  Future<void> pause() async {
    await tts.pause();
  }
}


