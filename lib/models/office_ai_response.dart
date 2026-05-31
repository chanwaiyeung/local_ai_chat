// lib/models/office_ai_response.dart

class OfficeAiResponse {
  final bool ok;
  final String result;
  final List<String> citations;
  final String model;

  OfficeAiResponse({
    required this.ok,
    required this.result,
    this.citations = const [],
    this.model = 'local',
  });

  factory OfficeAiResponse.fromJson(Map<String, dynamic> json) {
    return OfficeAiResponse(
      ok: json['ok'] as bool? ?? false,
      result: json['result'] as String? ?? '',
      citations: (json['citations'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      model: json['model'] as String? ?? 'local',
    );
  }

  Map<String, dynamic> toJson() => {
    'ok': ok,
    'result': result,
    'citations': citations,
    'model': model,
  };
}


