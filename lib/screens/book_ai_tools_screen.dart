import 'package:flutter/material.dart';
import '../widgets/ai/ai_button.dart';

class BookAiToolsScreen extends StatelessWidget {
  const BookAiToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('書籍 AI 工具')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 書籍基本資訊 Wireframe
            Container(
              height: 150,
              color: Colors.grey[300],
              child: const Center(child: Text('書本封面')),
            ),
            const SizedBox(height: 16),
            Text('書名 (book.title)', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Wrap(
              spacing: 8,
              children: [
                Chip(label: Text('標籤 1')),
                Chip(label: Text('標籤 2')),
              ],
            ),
            const Divider(height: 32),
            Text('專屬 AI 工具', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AiButton(
                  label: "AI 分類",
                  icon: Icons.auto_awesome,
                  onPressed: () {},
                ),
                AiButton(
                  label: "AI 摘要",
                  icon: Icons.summarize,
                  onPressed: () {},
                ),
                AiButton(
                  label: "AI 問這本書",
                  icon: Icons.search,
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


