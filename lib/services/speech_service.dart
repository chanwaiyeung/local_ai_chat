// lib/services/speech_service.dart
import 'dart:io';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Windows 上 SpeechToText 有線程問題，直接停用。
/// 其他平台正常使用。
class SpeechService {
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _initialized = false;

  /// Windows 直接視為不可用
  bool get isAvailable => !Platform.isWindows;
  bool get isListening => !Platform.isWindows && _stt.isListening;

  Future<bool> init({void Function(String status)? onStatus}) async {
    // Windows 直接跳過，避免 SpeechToTextWindowsPlugin 線程錯誤
    if (Platform.isWindows) return false;

    if (_initialized) return true;
    _initialized = await _stt.initialize(
      onStatus: (s) => onStatus?.call(s),
      onError: (e) => onStatus?.call('error: ${e.errorMsg}'),
    );
    return _initialized;
  }

  /// 開始聽寫，每次有結果經 [onResult] 回傳
  /// localeId 例如 'zh-HK', 'zh-CN', 'en-US'
  Future<void> start({
    required void Function(String text, bool isFinal) onResult,
    String localeId = 'zh-HK',
  }) async {
    // Windows 靜默忽略，不拋出例外
    if (Platform.isWindows) return;

    if (!_initialized) {
      final ok = await init();
      if (!ok) return;
    }
    await _stt.listen(
      onResult: (r) => onResult(r.recognizedWords, r.finalResult),
      localeId: localeId,
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  Future<void> stop() async {
    if (Platform.isWindows) return;
    await _stt.stop();
  }

  Future<void> cancel() async {
    if (Platform.isWindows) return;
    await _stt.cancel();
  }

  Future<List<stt.LocaleName>> locales() async {
    if (Platform.isWindows) return const <stt.LocaleName>[];
    return _stt.locales();
  }
}
