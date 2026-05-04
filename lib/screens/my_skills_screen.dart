import 'dart:convert';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

import '../models/skill_card.dart';
import '../services/app_settings_service.dart';
import '../services/cloud_llm_service.dart';
import '../services/personal_rag_service.dart';

class MySkillsScreen extends StatefulWidget {
  const MySkillsScreen({super.key, required this.ragService});

  final PersonalRagService ragService;

  @override
  State<MySkillsScreen> createState() => _MySkillsScreenState();
}

class _MySkillsScreenState extends State<MySkillsScreen> {
  List<SkillCard> _skills = [];
  bool _isLoading = true;

  // UI State
  String _searchQuery = '';
  String? _selectedDomain;

  @override
  void initState() {
    super.initState();
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    setState(() => _isLoading = true);
    final skills = widget.ragService.skillsService!.getAllSkills();
    setState(() {
      _skills = skills;
      _isLoading = false;
    });
  }

  Future<void> _deleteSkill(String id) async {
    await widget.ragService.skillsService!.deleteSkill(id);
    _loadSkills();
  }

  Future<void> _generateFromCloud() async {
    final settings = await AppSettingsService().load();
    final apiKey = settings.geminiApiKey;

    if (!mounted) return;

    if (apiKey == null || apiKey.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('請先至設定頁面設定 Gemini API Key')),
        );
      }
      return;
    }

    final controller = TextEditingController();
    final topic = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('請 AI 幫我生成技能'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '例如：如何規劃每月開支？',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('生成'),
          ),
        ],
      ),
    );

    if (topic == null || topic.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final prompt = '''
你是一個專業的 AI 導師。使用者想學習一個主題：「$topic」。
請為這個主題提供一個簡明扼要的高品質回答，並且萃取出適用的「思考路徑 (Reasoning Path)」。
回覆請嚴格遵循以下 JSON 格式（不要加上任何 Markdown 標記，只要純 JSON）：
{
  "reasoningPath": "關鍵洞見...\\n適用情境...\\n解決策略...",
  "answer": "高品質回答..."
}
''';

      final cloudService = CloudLLMService(apiKey: apiKey);
      final response = await cloudService.generateContent(
        systemPrompt: '你是知識提煉助手，必須只回傳符合格式的 JSON 字串。',
        userPrompt: prompt,
      );

      final jsonStr = response.replaceAll(RegExp(r'```json|```'), '').trim();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      await widget.ragService.skillsService!.extractAndSaveSkill(
        query: topic,
        reasoningPath: data['reasoningPath'] as String? ?? '',
        answer: data['answer'] as String? ?? response,
        domain: 'cloud_generated',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⭐ AI 技能生成成功！')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失敗：$e')),
        );
      }
    } finally {
      if (mounted) _loadSkills();
    }
  }

  List<SkillCard> get _filteredSkills {
    return _skills.where((s) {
      final matchesSearch = _searchQuery.isEmpty ||
          s.query.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.answer.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesDomain = _selectedDomain == null || s.domain == _selectedDomain;
      return matchesSearch && matchesDomain;
    }).toList();
  }

  Set<String> get _availableDomains {
    return _skills.map((s) => s.domain).toSet();
  }

  void _showSkillDetails(SkillCard skill) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.psychology, color: Colors.teal),
            const SizedBox(width: 8),
            Expanded(child: Text(skill.query, maxLines: 2, overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (skill.reasoningPath.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withAlpha(25), // ~0.1 opacity
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.teal.withAlpha(76)), // ~0.3 opacity
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb_outline, size: 16, color: Colors.teal),
                            SizedBox(width: 6),
                            Text('思考路徑', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SelectableText(skill.reasoningPath, style: const TextStyle(height: 1.4)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text('最終回答：', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                SelectableText(skill.answer, style: const TextStyle(height: 1.5)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final filtered = _filteredSkills;
    final domains = _availableDomains.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text('🧠 ${loc.mySkills}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download_outlined),
            tooltip: '請 AI 生成技能',
            onPressed: _generateFromCloud,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜尋技能...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(76), // ~0.3 opacity
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          
          // Domain Filter Chips
          if (domains.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: const Text('全部'),
                      selected: _selectedDomain == null,
                      onSelected: (val) => setState(() => _selectedDomain = null),
                    ),
                  ),
                  ...domains.map((domain) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(domain),
                        selected: _selectedDomain == domain,
                        onSelected: (val) {
                          setState(() => _selectedDomain = val ? domain : null);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          
          const Divider(height: 1),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _skills.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.psychology_outlined, size: 80, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              '尚無技能卡',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '使用 AI 回答後點擊「⭐ 儲存為技能」\n或點擊右上角雲端按鈕來生成',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? const Center(child: Text('找不到符合的技能'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final skill = filtered[index];
                              return Card(
                                elevation: 2,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _showSkillDetails(skill),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                skill.query,
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.primaryContainer,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                skill.domain,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          skill.answer,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: Colors.grey.shade600),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '建立於 ${skill.createdAt.toString().substring(0, 10)}',
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () => _deleteSkill(skill.id),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
