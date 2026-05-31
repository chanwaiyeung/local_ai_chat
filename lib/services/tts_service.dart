import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/app_settings.dart';
import 'app_settings_service.dart';
import 'cloud_tts_service.dart';

enum TtsQuality { fast, learning }

class TTSService {
  TTSService({
    FlutterTts? tts,
    CloudTTSService? cloudTts,
  }) : _tts = tts ?? FlutterTts(),
       _cloudTTSService = cloudTts;

  final FlutterTts _tts;
  final CloudTTSService? _cloudTTSService;
  bool _isSpeaking = false;
  VoidCallback? onCompletion;
  TtsQuality _activeQuality = TtsQuality.fast;

  TtsQuality get activeQuality => _activeQuality;

  Future<void> init() async {
    try {
      await _tts.setLanguage('zh-CN');
      await _tts.setSpeechRate(0.95);
      await _tts.setPitch(1.0);
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        if (onCompletion != null) onCompletion!();
      });
    } on MissingPluginException {
      // Widget tests and some desktop environments do not register the native
      // TTS plugin. The app can still render and exercise the reader flow.
    }
  }

  Future<void> speak(String text, {TtsQuality quality = TtsQuality.fast, String? lang}) async {
    if (text.trim().isEmpty) return;
    if (_isSpeaking) await stop();
    _isSpeaking = true;

    TtsMode ttsMode = TtsMode.auto;
    String googleTtsApiKey = '';
    try {
      final settings = await AppSettingsService().load();
      ttsMode = settings.ttsMode;
      googleTtsApiKey = settings.googleTtsApiKey ?? '';
    } catch (e) {
      debugPrint('Failed to load settings in TTSService: $e');
    }

    final bool shouldSpeakCloud;
    if (ttsMode == TtsMode.localOnly) {
      shouldSpeakCloud = false;
    } else if (ttsMode == TtsMode.cloudOnly) {
      shouldSpeakCloud = true;
    } else {
      shouldSpeakCloud = (quality == TtsQuality.learning);
    }

    _activeQuality = shouldSpeakCloud ? TtsQuality.learning : TtsQuality.fast;

    if (shouldSpeakCloud) {
      try {
        if (googleTtsApiKey.isNotEmpty || _cloudTTSService != null) {
          final cloudTts = _cloudTTSService ?? CloudTTSService(apiKey: googleTtsApiKey);
          final bytes = await cloudTts.synthesize(text);
          debugPrint('Synthesized ${bytes.length} bytes via Cloud TTS.');
          try {
            await _tts.setLanguage(lang ?? 'zh-CN');
          } on MissingPluginException {
            // Safe for tests
          }
          await _tts.speak(text);
          return;
        }
      } catch (e) {
        debugPrint('Cloud TTS synthesis failed: $e. Falling back to local TTS.');
      }
    }

    try {
      await _tts.setLanguage(lang ?? 'zh-CN');
      await _tts.speak(text);
    } on MissingPluginException {
      _isSpeaking = false;
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } on MissingPluginException {
      // No native plugin registered in the current runtime.
    } finally {
      _isSpeaking = false;
    }
  }

  Future<void> pause() async {
    try {
      await _tts.pause();
    } on MissingPluginException {
      // No native plugin registered.
    }
  }

  bool get isSpeaking => _isSpeaking;
}


