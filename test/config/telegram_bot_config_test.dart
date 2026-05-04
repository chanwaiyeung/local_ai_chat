import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/config/telegram_bot_config.dart';

void main() {
  group('TelegramBotConfig', () {
    test('throws when token is missing', () {
      expect(
        () => TelegramBotConfig.fromEnvironment({'TELEGRAM_BOT_USERNAME': 'mybot'}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when username is missing', () {
      expect(
        () => TelegramBotConfig.fromEnvironment({'TELEGRAM_BOT_TOKEN': '1234'}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('removes @ from username', () {
      final config = TelegramBotConfig.fromEnvironment({
        'TELEGRAM_BOT_TOKEN': '1234',
        'TELEGRAM_BOT_USERNAME': '@mybot',
      });
      expect(config.username, 'mybot');
    });

    test('uses default models when not provided', () {
      final config = TelegramBotConfig.fromEnvironment({
        'TELEGRAM_BOT_TOKEN': '1234',
        'TELEGRAM_BOT_USERNAME': 'mybot',
      });
      expect(config.ollamaUrl, 'http://localhost:11434');
      expect(config.ollamaModel, 'llama3.1:8b');
      expect(config.embedModel, 'bge-m3');
    });

    test('custom env overrides defaults', () {
      final config = TelegramBotConfig.fromEnvironment({
        'TELEGRAM_BOT_TOKEN': '1234',
        'TELEGRAM_BOT_USERNAME': 'mybot',
        'OLLAMA_URL': 'http://custom:11434',
        'OLLAMA_MODEL': 'custom-model',
        'EMBED_MODEL': 'custom-embed',
      });
      expect(config.ollamaUrl, 'http://custom:11434');
      expect(config.ollamaModel, 'custom-model');
      expect(config.embedModel, 'custom-embed');
    });
  });
}
