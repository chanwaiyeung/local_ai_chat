// lib/models/message.dart

enum Role { user, assistant, system }

class ChatMessage {
  final Role role;
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: _roleFromJson(json['role']),
      content: json['content'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toOllamaJson() => {
        'role': role.name,
        'content': content,
      };

  static Role _roleFromJson(Object? value) {
    final name = value?.toString();
    return Role.values.firstWhere(
      (role) => role.name == name,
      orElse: () => Role.assistant,
    );
  }
}


