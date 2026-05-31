import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/message.dart';
import '../utils/citation_parser.dart';
import 'code_block.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onCitationTap,
  });

  final ChatMessage message;
  final Future<void> Function(String docName, int? chunkIndex)? onCitationTap;

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleLink(BuildContext context, String? href) async {
    if (href == null || href.trim().isEmpty) {
      _showSnack(context, '連結格式錯誤');
      return;
    }

    final normalizedHref = href.trim().replaceAll('&amp;', '&');
    final uri = Uri.tryParse(normalizedHref);
    if (uri == null) {
      _showSnack(context, '連結格式錯誤');
      return;
    }

    if (uri.scheme == 'chunk') {
      final target = parseCitationLinkTarget(normalizedHref);
      if (target == null) {
        _showSnack(context, '引用缺少文件名稱');
        return;
      }

      await onCitationTap?.call(target.docName, target.chunkIndex);
      return;
    }

    const allowedSchemes = {'http', 'https', 'mailto', 'tel'};
    if (!allowedSchemes.contains(uri.scheme)) {
      _showSnack(context, '不支援的連結類型');
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      _showSnack(context, '無法開啟連結');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == Role.user;
    final cs = Theme.of(context).colorScheme;
    final codeBlockBuilder = CodeBlockBuilder();

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: MarkdownBody(
          data: message.content.isEmpty ? '…' : message.content,
          selectable: true,
          builders: {
            'pre': codeBlockBuilder,
            'code': codeBlockBuilder,
          },
          onTapLink: (text, href, title) {
            unawaited(_handleLink(context, href));
          },
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            p: TextStyle(
              color: isUser ? cs.onPrimaryContainer : cs.onSurface,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}


