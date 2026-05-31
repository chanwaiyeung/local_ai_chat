// lib/models/office_ai_request.dart

class OfficeAiRequest {
  final String app;
  final String task;
  final String text;
  final String? tone;
  final String? target;
  final Map<String, dynamic> metadata;

  const OfficeAiRequest({
    required this.app,
    required this.task,
    required this.text,
    this.tone,
    this.target,
    this.metadata = const {},
  });

  factory OfficeAiRequest.fromJson(Map<String, dynamic> json) {
    final metadataMap = Map<String, dynamic>.from(json['metadata'] as Map? ?? {});
    // For backwards compatibility: if "prompt" is sent at the root level, capture it in metadata
    if (json.containsKey('prompt') && !metadataMap.containsKey('prompt')) {
      metadataMap['prompt'] = json['prompt'] as String?;
    }
    return OfficeAiRequest(
      app: json['app'] as String? ?? 'unknown',
      task: json['task'] as String? ?? 'ask',
      text: json['text'] as String? ?? '',
      tone: json['tone'] as String?,
      target: json['target'] as String?,
      metadata: metadataMap,
    );
  }

  Map<String, dynamic> toJson() => {
    'app': app,
    'task': task,
    'text': text,
    if (tone != null) 'tone': tone,
    if (target != null) 'target': target,
    'metadata': metadata,
  };
}


