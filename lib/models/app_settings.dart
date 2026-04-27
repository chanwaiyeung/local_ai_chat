class AppSettings {
  const AppSettings({
    required this.embeddingModel,
  });

  static const defaultEmbeddingModel = 'nomic-embed-text';

  final String embeddingModel;

  AppSettings copyWith({
    String? embeddingModel,
  }) {
    return AppSettings(
      embeddingModel: embeddingModel ?? this.embeddingModel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'embeddingModel': embeddingModel,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final model = (json['embeddingModel'] as String?)?.trim();
    return AppSettings(
      embeddingModel:
          model == null || model.isEmpty ? defaultEmbeddingModel : model,
    );
  }
}
