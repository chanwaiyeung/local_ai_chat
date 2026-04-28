import 'dart:async';

import 'package:flutter/material.dart';

import '../services/vector_store.dart';
import 'top_k_picker.dart';

class ChatLibrarySheet extends StatelessWidget {
  const ChatLibrarySheet({
    super.key,
    required this.store,
    required this.activeDoc,
    required this.topK,
    required this.onOpenDoc,
    required this.onRemoveDoc,
    required this.onSetActiveDoc,
    required this.onTopKChanged,
  });

  final VectorStore store;
  final String? activeDoc;
  final int topK;
  final void Function(String docName) onOpenDoc;
  final Future<void> Function(String docName) onRemoveDoc;
  final void Function(String? docName) onSetActiveDoc;
  final void Function(int topK) onTopKChanged;

  @override
  Widget build(BuildContext context) {
    final docs = store.docNames;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.library_books),
              title: const Text('文件庫'),
              subtitle: Text('共 ${docs.length} 份文件 / ${store.length} 個片段'),
            ),
            const Divider(height: 1),
            if (docs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('尚未載入任何文件'),
              ),
            ...docs.map(
              (docName) => ListTile(
                leading: Icon(
                  activeDoc == docName
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                title: Text(docName),
                subtitle: Text('${store.chunksOf(docName).length} 個片段 — 點擊預覽'),
                onTap: () {
                  Navigator.pop(context);
                  onOpenDoc(docName);
                },
                onLongPress: () {
                  final nextActiveDoc = activeDoc == docName ? null : docName;
                  onSetActiveDoc(nextActiveDoc);
                  Navigator.pop(context);
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    Navigator.pop(context);
                    unawaited(onRemoveDoc(docName));
                  },
                ),
              ),
            ),
            if (docs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: Text(activeDoc == null ? '搜全部 ✓' : '搜全部'),
                      selected: activeDoc == null,
                      onSelected: (_) {
                        onSetActiveDoc(null);
                        Navigator.pop(context);
                      },
                    ),
                    InputChip(
                      avatar: const Icon(Icons.tune, size: 18),
                      label: Text('Top-K：$topK'),
                      onPressed: () async {
                        final value = await showDialog<int>(
                          context: context,
                          builder: (_) => TopKPicker(current: topK),
                        );
                        if (value != null) onTopKChanged(value);
                      },
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
