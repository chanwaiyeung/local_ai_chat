import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/message.dart';

class ChatSession {
  final String id;
  String title;
  DateTime updatedAt;
  String? activeDoc;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.messages,
    this.activeDoc,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'updatedAt': updatedAt.toIso8601String(),
        'activeDoc': activeDoc,
        'messages': messages.map((message) => message.toJson()).toList(),
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as String? ?? _newId(),
      title: json['title'] as String? ?? '新對話',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      activeDoc: json['activeDoc'] as String?,
      messages: ((json['messages'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  static ChatSession createNew({required ChatMessage systemPrompt}) {
    return ChatSession(
      id: _newId(),
      title: '新對話',
      updatedAt: DateTime.now(),
      messages: [
        systemPrompt,
        ChatMessage(
          role: Role.assistant,
          content: '你好！👋\n你想聊些什麼？😊',
        ),
      ],
    );
  }

  static String _newId() => 'session_${DateTime.now().microsecondsSinceEpoch}';
}

class SaveDebouncer {
  SaveDebouncer({
    required this.delay,
    required this.onSave,
  });

  final Duration delay;
  final Future<void> Function(ChatSession session) onSave;
  Timer? _timer;
  ChatSession? _pending;

  void schedule(ChatSession session) {
    _pending = session;
    _timer?.cancel();
    _timer = Timer(delay, () {
      final pending = _pending;
      _pending = null;
      if (pending != null) {
        unawaited(onSave(pending));
      }
    });
  }

  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    final pending = _pending;
    _pending = null;
    if (pending != null) {
      await onSave(pending);
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _pending = null;
  }
}

class ChatSessionService {
  static Future<Directory> sessionsDirectory() async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory('${root.path}${Platform.pathSeparator}sessions');
    await dir.create(recursive: true);
    return dir;
  }

  static Future<List<ChatSession>> loadSessions() async {
    await migrateOldHistoryIfNeeded();
    final dir = await sessionsDirectory();
    final sessions = <ChatSession>[];

    await for (final entity in dir.list()) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.json')) {
        continue;
      }
      try {
        final text = await entity.readAsString();
        final json = jsonDecode(text) as Map<String, dynamic>;
        sessions.add(ChatSession.fromJson(json));
      } catch (_) {
        // Ignore corrupt session files so one bad file cannot break startup.
      }
    }

    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sessions;
  }

  static Future<void> saveSession(ChatSession session) async {
    final dir = await sessionsDirectory();
    session.updatedAt = DateTime.now();
    final file = File('${dir.path}${Platform.pathSeparator}${session.id}.json');
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(session.toJson()));
    try {
      await file.delete();
    } on FileSystemException {
      // File may not exist on first save.
    }
    await tmp.rename(file.path);
  }

  static Future<void> deleteSession(String id) async {
    final dir = await sessionsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}$id.json');
    try {
      await file.delete();
    } on FileSystemException {
      // Already gone.
    }
  }

  static Future<ChatSession> createNew({
    required ChatMessage systemPrompt,
  }) async {
    final session = ChatSession.createNew(systemPrompt: systemPrompt);
    await saveSession(session);
    return session;
  }

  static Future<void> migrateOldHistoryIfNeeded() async {
    final root = await getApplicationSupportDirectory();
    final candidates = <File>[
      File('${root.path}${Platform.pathSeparator}chat_history.json'),
      File('${root.path}${Platform.pathSeparator}chat.json'),
      if (Platform.environment['APPDATA'] != null)
        File(
          '${Platform.environment['APPDATA']}${Platform.pathSeparator}'
          'local_ai_chat${Platform.pathSeparator}chat_history.json',
        ),
      if (Platform.environment['APPDATA'] != null)
        File(
          '${Platform.environment['APPDATA']}${Platform.pathSeparator}'
          'local_ai_chat${Platform.pathSeparator}chat.json',
        ),
    ];

    for (final file in candidates) {
      final migrated = File('${file.path}.migrated');
      if (await migrated.exists() || !await file.exists()) {
        continue;
      }

      try {
        final text = await file.readAsString();
        if (text.trim().isEmpty) continue;
        final json = jsonDecode(text) as Map<String, dynamic>;
        final session = ChatSession(
          id: ChatSession._newId(),
          title: '舊對話',
          updatedAt: DateTime.now(),
          activeDoc: json['activeDoc'] as String?,
          messages: ((json['messages'] as List?) ?? const [])
              .whereType<Map>()
              .map((item) =>
                  ChatMessage.fromJson(Map<String, dynamic>.from(item)))
              .toList(),
        );

        if (session.messages.isEmpty) continue;
        await saveSession(session);
        await file.rename(migrated.path);
      } catch (_) {
        // Leave the old file in place if migration fails.
      }
    }
  }
}
