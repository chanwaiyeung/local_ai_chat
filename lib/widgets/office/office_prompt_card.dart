// lib/widgets/office/office_prompt_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OfficePromptCard extends StatelessWidget {
  final String title;
  final String content;
  final bool isLoading;
  final VoidCallback? onClear;
  final String? appName;
  final String? taskName;

  const OfficePromptCard({
    super.key,
    required this.title,
    required this.content,
    this.isLoading = false,
    this.onClear,
    this.appName,
    this.taskName,
  });

  void _copyToClipboard(BuildContext context) {
    if (content.isEmpty) return;
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已複製結果到剪貼簿！'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (appName != null && taskName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$appName · $taskName',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
              ),
              constraints: const BoxConstraints(minHeight: 120, maxHeight: 300),
              child: SingleChildScrollView(
                child: SelectionArea(
                  child: content.isEmpty && isLoading
                      ? Row(
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'AI 正在思考中...',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          content.isEmpty ? '暫無生成內容，請在下方輸入文本並點擊執行' : content,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: content.isEmpty
                                ? Colors.grey.shade500
                                : (isDark ? Colors.greenAccent.shade200 : Colors.grey.shade900),
                            fontFamily: content.isEmpty ? null : 'monospace',
                          ),
                        ),
                ),
              ),
            ),
            if (isLoading) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ],
            if (content.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onClear != null)
                    OutlinedButton.icon(
                      onPressed: onClear,
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('清除'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _copyToClipboard(context),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('複製結果'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}


