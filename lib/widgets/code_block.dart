import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

class CodeBlock extends StatelessWidget {
  const CodeBlock({
    super.key,
    required this.code,
    this.language,
  });

  final String code;
  final String? language;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final label = _languageLabel(language);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.10);
    final headerColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: headerColor,
            child: Padding(
              padding: const EdgeInsets.only(left: 12, right: 6),
              child: SizedBox(
                height: 38,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    Tooltip(
                      message: '複製 code',
                      child: IconButton(
                        key: const Key('copy-code-button'),
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.copy, size: 18),
                        color: cs.onSurfaceVariant,
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: code));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已複製 code')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: HighlightView(
              code,
              language: _highlightLanguage(language),
              theme: isDark ? atomOneDarkTheme : githubTheme,
              padding: const EdgeInsets.all(14),
              textStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _languageLabel(String? language) {
    final value = language?.trim();
    if (value == null || value.isEmpty) return 'text';
    return value;
  }

  static String? _highlightLanguage(String? language) {
    final value = language?.trim().toLowerCase();
    if (value == null || value.isEmpty || value == 'text') return 'plaintext';
    const aliases = {
      'js': 'javascript',
      'ts': 'typescript',
      'sh': 'bash',
      'shell': 'bash',
      'ps': 'powershell',
      'ps1': 'powershell',
      'py': 'python',
    };
    return aliases[value] ?? value;
  }
}

class CodeBlockBuilder extends MarkdownElementBuilder {
  int _preDepth = 0;

  @override
  void visitElementBefore(md.Element element) {
    if (element.tag == 'pre') _preDepth++;
  }

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    if (element.tag == 'pre') {
      _preDepth = math.max(0, _preDepth - 1);
      return null;
    }

    if (element.tag != 'code') return null;
    final language = _languageFrom(element);
    if (language == null && _preDepth == 0) return null;

    return CodeBlock(
      code: _codeFrom(element),
      language: language,
    );
  }

  String _codeFrom(md.Element element) {
    final text = element.textContent;
    return text.endsWith('\n') ? text.substring(0, text.length - 1) : text;
  }

  String? _languageFrom(md.Element element) {
    final className = element.attributes['class'] ?? '';
    for (final part in className.split(RegExp(r'\s+'))) {
      if (part.startsWith('language-')) {
        return part.substring('language-'.length);
      }
    }
    return null;
  }
}


