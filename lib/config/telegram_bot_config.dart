class TelegramBotConfig {
  final String token;
  final String username;
  final String ollamaUrl;
  final String ollamaModel;
  final String embedModel;

  TelegramBotConfig({
    required this.token,
    required this.username,
    this.ollamaUrl = 'http://localhost:11434',
    this.ollamaModel = 'llama3.1:8b',
    this.embedModel = 'bge-m3',
  });

  factory TelegramBotConfig.fromEnvironment(Map<String, String> env) {
    final token = env['TELEGRAM_BOT_TOKEN'];
    var username = env['TELEGRAM_BOT_USERNAME'];

    if (token == null || token.trim().isEmpty) {
      throw ArgumentError('Missing required environment variable: TELEGRAM_BOT_TOKEN');
    }

    if (username == null || username.trim().isEmpty) {
      throw ArgumentError('Missing required environment variable: TELEGRAM_BOT_USERNAME');
    }

    if (username.startsWith('@')) {
      username = username.substring(1);
    }

    return TelegramBotConfig(
      token: token.trim(),
      username: username.trim(),
      ollamaUrl: (env['OLLAMA_URL']?.trim().isNotEmpty == true) ? env['OLLAMA_URL']!.trim() : 'http://localhost:11434',
      ollamaModel: (env['OLLAMA_MODEL']?.trim().isNotEmpty == true) ? env['OLLAMA_MODEL']!.trim() : 'llama3.1:8b',
      embedModel: (env['EMBED_MODEL']?.trim().isNotEmpty == true) ? env['EMBED_MODEL']!.trim() : 'bge-m3',
    );
  }
}
