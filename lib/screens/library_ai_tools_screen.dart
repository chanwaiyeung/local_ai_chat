import 'package:flutter/material.dart';
import '../widgets/ai/ai_button.dart';

class LibraryAiToolsScreen extends StatelessWidget {
  const LibraryAiToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('圖書館 AI 管理')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('全圖書館 AI 功能', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AiButton(
                  label: "批次重算分類",
                  icon: Icons.category,
                  onPressed: () {
                    // TODO: 觸發批次分類
                  },
                ),
                AiButton(
                  label: "圖書館大綱分析",
                  icon: Icons.analytics,
                  onPressed: () {
                    // TODO: 生成圖書館分析
                  },
                ),
                AiButton(
                  label: "全書庫問答",
                  icon: Icons.question_answer,
                  onPressed: () {
                    // TODO: 進入全書庫 RAG
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


