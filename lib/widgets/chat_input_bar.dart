import 'package:flutter/material.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.busy,
    required this.listening,
    required this.onPickFile,
    required this.onToggleMic,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool busy;
  final bool listening;
  final VoidCallback onPickFile;
  final VoidCallback onToggleMic;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              tooltip: '載入 PDF / TXT',
              onPressed: busy ? null : onPickFile,
            ),
            IconButton(
              icon: Icon(listening ? Icons.mic : Icons.mic_none),
              color: listening ? Colors.red : null,
              tooltip: '語音輸入',
              onPressed: busy ? null : onToggleMic,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: '輸入訊息…',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 4),
            FilledButton.icon(
              onPressed: busy ? null : onSend,
              icon: const Icon(Icons.send),
              label: const Text('傳送'),
            ),
          ],
        ),
      ),
    );
  }
}


