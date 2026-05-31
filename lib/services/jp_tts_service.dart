import 'tts_service.dart';

class JpTtsService {
  final TTSService tts; 

  JpTtsService(this.tts);

  // 播放日文語音
  Future<void> speak(String text) async {
    // 強制設定語言為日文 ja-JP
    await tts.speak(text, lang: "ja-JP");
  }

  // 停止播放
  Future<void> stop() async {
    await tts.stop();
  }

  // 暫停播放
  Future<void> pause() async {
    await tts.pause();
  }
}


