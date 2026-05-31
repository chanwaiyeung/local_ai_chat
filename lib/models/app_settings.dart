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

enum TtsMode {
  auto,
  localOnly,
  cloudOnly;

  static TtsMode fromJson(String? value) {
    return TtsMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => TtsMode.auto,
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
    this.ttsMode = TtsMode.auto,
    this.enableOfficeBridge = true,
    this.officeBridgePort = 61670,
    this.officeBridgeToken = 'YOUR_LOCAL_TOKEN',
    this.officeBridgeLanguage = 'zh-TW',
    this.officeBridgeModel = 'local',
    this.officeBridgeAllowedApps = const ['word', 'excel', 'ppt', 'outlook', 'wps'],
  });

  static const defaultEmbeddingModel = 'nomic-embed-text';

  final String embeddingModel;
  final RetrievalMode retrievalMode;
  final String? geminiApiKey;
  final String? telegramBotToken;
  final String? googleTtsApiKey;
  final TtsMode ttsMode;
  final bool enableOfficeBridge;
  final int officeBridgePort;
  final String officeBridgeToken;
  final String officeBridgeLanguage;
  final String officeBridgeModel;
  final List<String> officeBridgeAllowedApps;

  AppSettings copyWith({
    String? embeddingModel,
    RetrievalMode? retrievalMode,
    String? geminiApiKey,
    String? telegramBotToken,
    String? googleTtsApiKey,
    TtsMode? ttsMode,
    bool? enableOfficeBridge,
    int? officeBridgePort,
    String? officeBridgeToken,
    String? officeBridgeLanguage,
    String? officeBridgeModel,
    List<String>? officeBridgeAllowedApps,
  }) {
    return AppSettings(
      embeddingModel: embeddingModel ?? this.embeddingModel,
      retrievalMode: retrievalMode ?? this.retrievalMode,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      telegramBotToken: telegramBotToken ?? this.telegramBotToken,
      googleTtsApiKey: googleTtsApiKey ?? this.googleTtsApiKey,
      ttsMode: ttsMode ?? this.ttsMode,
      enableOfficeBridge: enableOfficeBridge ?? this.enableOfficeBridge,
      officeBridgePort: officeBridgePort ?? this.officeBridgePort,
      officeBridgeToken: officeBridgeToken ?? this.officeBridgeToken,
      officeBridgeLanguage: officeBridgeLanguage ?? this.officeBridgeLanguage,
      officeBridgeModel: officeBridgeModel ?? this.officeBridgeModel,
      officeBridgeAllowedApps: officeBridgeAllowedApps ?? this.officeBridgeAllowedApps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'embeddingModel': embeddingModel,
      'retrievalMode': retrievalMode.name,
      if (geminiApiKey != null) 'geminiApiKey': geminiApiKey,
      if (telegramBotToken != null) 'telegramBotToken': telegramBotToken,
      if (googleTtsApiKey != null) 'googleTtsApiKey': googleTtsApiKey,
      'ttsMode': ttsMode.name,
      'enableOfficeBridge': enableOfficeBridge,
      'officeBridgePort': officeBridgePort,
      'officeBridgeToken': officeBridgeToken,
      'officeBridgeLanguage': officeBridgeLanguage,
      'officeBridgeModel': officeBridgeModel,
      'officeBridgeAllowedApps': officeBridgeAllowedApps,
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
      ttsMode: TtsMode.fromJson(json['ttsMode'] as String?),
      enableOfficeBridge: json['enableOfficeBridge'] as bool? ?? true,
      officeBridgePort: json['officeBridgePort'] as int? ?? 61670,
      officeBridgeToken: json['officeBridgeToken'] as String? ?? 'YOUR_LOCAL_TOKEN',
      officeBridgeLanguage: json['officeBridgeLanguage'] as String? ?? 'zh-TW',
      officeBridgeModel: json['officeBridgeModel'] as String? ?? 'local',
      officeBridgeAllowedApps: (json['officeBridgeAllowedApps'] as List?)?.map((e) => e as String).toList() ??
          const ['word', 'excel', 'ppt', 'outlook', 'wps'],
    );
  }
}


