enum RetrievalMode {
  dense,
  sparse,
  hybrid;

  static RetrievalMode fromJson(String? value) {
    return RetrievalMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => RetrievalMode.hybrid,
    );
  }
}

class AppSettings {
  const AppSettings({
    required this.embeddingModel,
    this.retrievalMode = RetrievalMode.hybrid,
    this.geminiApiKey,
    this.telegramBotToken,
    this.googleTtsApiKey,
  });

  static const defaultEmbeddingModel = 'nomic-embed-text';

  final String embeddingModel;
  final RetrievalMode retrievalMode;
  final String? geminiApiKey;
  final String? telegramBotToken;
  final String? googleTtsApiKey;

  AppSettings copyWith({
    String? embeddingModel,
    RetrievalMode? retrievalMode,
    String? geminiApiKey,
    String? telegramBotToken,
    String? googleTtsApiKey,
  }) {
    return AppSettings(
      embeddingModel: embeddingModel ?? this.embeddingModel,
      retrievalMode: retrievalMode ?? this.retrievalMode,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      telegramBotToken: telegramBotToken ?? this.telegramBotToken,
      googleTtsApiKey: googleTtsApiKey ?? this.googleTtsApiKey,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'embeddingModel': embeddingModel,
      'retrievalMode': retrievalMode.name,
      if (geminiApiKey != null) 'geminiApiKey': geminiApiKey,
      if (telegramBotToken != null) 'telegramBotToken': telegramBotToken,
      if (googleTtsApiKey != null) 'googleTtsApiKey': googleTtsApiKey,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final model = (json['embeddingModel'] as String?)?.trim();
    return AppSettings(
      embeddingModel:
          model == null || model.isEmpty ? defaultEmbeddingModel : model,
      retrievalMode: RetrievalMode.fromJson(json['retrievalMode'] as String?),
      geminiApiKey: json['geminiApiKey'] as String?,
      telegramBotToken: json['telegramBotToken'] as String?,
      googleTtsApiKey: json['googleTtsApiKey'] as String?,
    );
  }
}
