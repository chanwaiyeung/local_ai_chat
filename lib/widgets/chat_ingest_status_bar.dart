import 'package:flutter/material.dart';

class ChatIngestStatusBar extends StatelessWidget {
  const ChatIngestStatusBar({
    super.key,
    required this.ingesting,
    required this.busy,
    required this.cancelIngest,
    required this.progressText,
    required this.onCancel,
  });

  final bool ingesting;
  final bool busy;
  final bool cancelIngest;
  final String? progressText;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    if (ingesting) {
      return Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  progressText ?? '正在建立向量索引…',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: cancelIngest ? null : onCancel,
                icon: const Icon(Icons.close),
                label: const Text('取消'),
              ),
            ],
          ),
        ),
      );
    }

    if (busy) {
      return const LinearProgressIndicator(minHeight: 2);
    }

    return const SizedBox.shrink();
  }
}
