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
  });

  static const defaultEmbeddingModel = 'nomic-embed-text';

  final String embeddingModel;
  final RetrievalMode retrievalMode;

  AppSettings copyWith({
    String? embeddingModel,
    RetrievalMode? retrievalMode,
  }) {
    return AppSettings(
      embeddingModel: embeddingModel ?? this.embeddingModel,
      retrievalMode: retrievalMode ?? this.retrievalMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'embeddingModel': embeddingModel,
      'retrievalMode': retrievalMode.name,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final model = (json['embeddingModel'] as String?)?.trim();
    return AppSettings(
      embeddingModel:
          model == null || model.isEmpty ? defaultEmbeddingModel : model,
      retrievalMode: RetrievalMode.fromJson(json['retrievalMode'] as String?),
    );
  }
}
