import 'package:flutter/material.dart';

import '../models/message.dart';
import '../services/chat_session_service.dart';

class ChatSessionDrawer extends StatelessWidget {
  const ChatSessionDrawer({
    super.key,
    required this.sessions,
    required this.currentSession,
    required this.onNewSession,
    required this.onSwitchSession,
    required this.onRenameSession,
    required this.onDeleteSession,
  });

  final List<ChatSession> sessions;
  final ChatSession? currentSession;
  final VoidCallback onNewSession;
  final ValueChanged<ChatSession> onSwitchSession;
  final ValueChanged<ChatSession> onRenameSession;
  final ValueChanged<ChatSession> onDeleteSession;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const ListTile(
              leading: Icon(Icons.forum),
              title: Text('AI 語言圖書館'),
              subtitle: Text('多對話 sessions'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FilledButton.icon(
                onPressed: onNewSession,
                icon: const Icon(Icons.add),
                label: const Text('新對話'),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  final selected = session.id == currentSession?.id;
                  return ListTile(
                    selected: selected,
                    leading: const Icon(Icons.chat_bubble_outline),
                    title: Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${session.messages.where((m) => m.role != Role.system).length} 則訊息 · ${_formatTime(session.updatedAt)}',
                    ),
                    onTap: () => onSwitchSession(session),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'rename':
                            onRenameSession(session);
                            break;
                          case 'delete':
                            onDeleteSession(session);
                            break;
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'rename',
                          child: Text('重新命名'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('刪除'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    return '${local.month}/${local.day} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
