import 'package:flutter/material.dart';

class ChatAppBarActions {
  const ChatAppBarActions({
    required this.onOpenEvaluation,
    required this.onOpenSettings,
    required this.onModelChanged,
    required this.onToggleRag,
    required this.onLoadModels,
    required this.onOpenLibrary,
    required this.onExportChat,
    required this.onClearChat,
    required this.onShowSessionsPath,
    required this.onShowDebugLogPath,
  });

  final VoidCallback onOpenEvaluation;
  final VoidCallback onOpenSettings;
  final ValueChanged<String> onModelChanged;
  final VoidCallback onToggleRag;
  final VoidCallback onLoadModels;
  final VoidCallback onOpenLibrary;
  final VoidCallback onExportChat;
  final VoidCallback onClearChat;
  final VoidCallback onShowSessionsPath;
  final VoidCallback onShowDebugLogPath;
}


