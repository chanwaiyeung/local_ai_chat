import 'package:flutter/material.dart';

class RagContextBanner extends StatelessWidget {
  const RagContextBanner({
    super.key,
    required this.hasChunks,
    required this.docCount,
    required this.activeDoc,
    required this.topK,
    required this.embeddingModel,
  });

  final bool hasChunks;
  final int docCount;
  final String? activeDoc;
  final int topK;
  final String embeddingModel;

  @override
  Widget build(BuildContext context) {
    if (!hasChunks) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.menu_book, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              activeDoc != null ? '正在問：$activeDoc' : '搜尋全部文件（$docCount 份）',
            ),
          ),
          Text(
            'Top-$topK · $embeddingModel',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
