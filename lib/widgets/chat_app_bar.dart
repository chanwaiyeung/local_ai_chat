import 'package:flutter/material.dart';

import 'chat_app_bar_actions.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatAppBar({
    super.key,
    required this.title,
    required this.activeDoc,
    required this.availableModels,
    required this.model,
    required this.busy,
    required this.ragEnabled,
    required this.actions,
  });

  final String title;
  final String? activeDoc;
  final List<String> availableModels;
  final String model;
  final bool busy;
  final bool ragEnabled;
  final ChatAppBarActions actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (activeDoc != null)
            Text(
              '正在問：$activeDoc',
              style: Theme.of(context).textTheme.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'RAG 評測記錄',
          icon: const Icon(Icons.fact_check_outlined),
          onPressed: actions.onOpenEvaluation,
        ),
        IconButton(
          tooltip: '設定',
          icon: const Icon(Icons.settings_outlined),
          onPressed: actions.onOpenSettings,
        ),
        if (availableModels.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButton<String>(
              value: model,
              underline: const SizedBox(),
              items: availableModels
                  .map((model) => DropdownMenuItem(
                        value: model,
                        child: Text(model),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) actions.onModelChanged(value);
              },
            ),
          ),
        IconButton(
          icon: Icon(
              ragEnabled ? Icons.auto_awesome : Icons.auto_awesome_outlined),
          tooltip: ragEnabled ? '停用 RAG' : '啟用 RAG',
          onPressed: actions.onToggleRag,
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: '重整模型列表',
          onPressed: busy ? null : actions.onLoadModels,
        ),
        IconButton(
          icon: const Icon(Icons.library_books),
          tooltip: '文件庫',
          onPressed: actions.onOpenLibrary,
        ),
        PopupMenuButton<String>(
          onSelected: (key) {
            switch (key) {
              case 'export':
                actions.onExportChat();
                break;
              case 'clear':
                actions.onClearChat();
                break;
              case 'path':
                actions.onShowSessionsPath();
                break;
              case 'debugLog':
                actions.onShowDebugLogPath();
                break;
              case 'settings':
                actions.onOpenSettings();
                break;
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings_outlined),
                title: Text('Embedding 設定'),
              ),
            ),
            PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.ios_share),
                title: Text('匯出對話為 Markdown'),
              ),
            ),
            PopupMenuItem(
              value: 'clear',
              child: ListTile(
                leading: Icon(Icons.delete_sweep),
                title: Text('清除目前對話'),
              ),
            ),
            PopupMenuItem(
              value: 'path',
              child: ListTile(
                leading: Icon(Icons.folder),
                title: Text('Session 儲存位置'),
              ),
            ),
            PopupMenuItem(
              value: 'debugLog',
              child: ListTile(
                leading: Icon(Icons.article_outlined),
                title: Text('RAG debug log 位置'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


