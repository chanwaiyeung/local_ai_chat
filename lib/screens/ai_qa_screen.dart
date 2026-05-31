import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/api_client.dart';
import '../services/app_settings_service.dart';
import '../services/cloud_llm_service.dart';
import '../services/ollama_service.dart';

class AiQaScreen extends StatefulWidget {
  const AiQaScreen({
    super.key,
    required this.bookTitle,
    this.initialChunk,
    this.apiClient,
    this.ollama,
  });

  final String bookTitle;
  final String? initialChunk;
  final ReaderApi? apiClient;
  final OllamaService? ollama;

  @override
  State<AiQaScreen> createState() => _AiQaScreenState();
}

class _AiQaScreenState extends State<AiQaScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _useCloud = false;
  bool _hasCloudKey = false;
  String? _apiKey;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _addInitialGreeting();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await AppSettingsService().load();
      if (mounted) {
        setState(() {
          _apiKey = settings.geminiApiKey;
          _hasCloudKey = settings.geminiApiKey != null && settings.geminiApiKey!.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Failed to load settings in AiQaScreen: $e');
    }
  }

  void _addInitialGreeting() {
    final hasChunk = widget.initialChunk != null && widget.initialChunk!.trim().isNotEmpty;
    final greeting = hasChunk
        ? '您好！我已經載入您所選的段落作為專屬上下文。您可以針對這段文字進行提問，我會僅根據此段內容為您詳細解答！'
        : '您好！我是您的閱讀助理。您可以隨時向我提問關於《${widget.bookTitle}》的任何問題，我會先從圖書館的索引片段中為您精準檢索，再進行 grounded 回答！';

    _messages.add(ChatMessage(
      role: Role.assistant,
      content: greeting,
    ));
  }

  Future<void> _sendQuestion() async {
    final query = _questionController.text.trim();
    if (query.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(role: Role.user, content: query));
      _questionController.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final String systemPrompt = '你現在是一個閱讀助理，請僅根據以下提供的書籍片段進行回答。若片段內無資訊，請明確告知，切勿從外部知識庫幻覺生成。若資訊充足，請使用繁體中文，以親切、結構化且有條理的口吻回答。';
      String contextText = '';

      if (widget.initialChunk != null && widget.initialChunk!.trim().isNotEmpty) {
        contextText = widget.initialChunk!;
      } else {
        final api = widget.apiClient ?? ApiClient();
        final hits = await api.retrieve(
          query: query,
          docName: widget.bookTitle,
          topK: 4,
        );
        if (hits.isNotEmpty) {
          contextText = hits.map((h) => h['text'] ?? h['snippet'] ?? '').join('\n\n');
        }
      }

      if (contextText.isEmpty) {
        setState(() {
          _messages.add(ChatMessage(
            role: Role.assistant,
            content: '抱歉，圖書館索引庫中找不到與此問題相關的參考內容。請試著換個問法，或先對書籍進行完整的 AI 分類/索引處理。',
          ));
          _isLoading = false;
        });
        _scrollToBottom();
        return;
      }

      final userPrompt = '【參考書籍內容片段】：\n$contextText\n\n【使用者問題】：\n$query';
      String response = '';

      if (_useCloud && _hasCloudKey && _apiKey != null) {
        final cloudService = CloudLLMService(apiKey: _apiKey!);
        response = await cloudService.generateContent(
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
        );
      } else {
        final ollama = widget.ollama ?? OllamaService();
        response = await ollama.chat([
          ChatMessage(role: Role.system, content: systemPrompt),
          ChatMessage(role: Role.user, content: userPrompt),
        ]);
      }

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(role: Role.assistant, content: response));
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            role: Role.assistant,
            content: '詢問過程中發生錯誤：$e\n請確保 Local AI 服務已開啟，或是 API 金鑰配置正確。',
          ));
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 深度問答'),
        actions: [
          if (_hasCloudKey)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Icon(
                    _useCloud ? Icons.cloud : Icons.memory,
                    size: 18,
                    color: _useCloud ? Colors.blue : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: _useCloud,
                    onChanged: (val) {
                      setState(() => _useCloud = val);
                    },
                    activeThumbColor: Colors.blue,
                    activeTrackColor: Colors.blue.withValues(alpha: 0.3),
                    inactiveThumbColor: Colors.green,
                    inactiveTrackColor: Colors.green.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _useCloud ? '雲端 AI' : '本地 AI',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _useCloud ? Colors.blue : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Grounding Context Header
          if (widget.initialChunk != null && widget.initialChunk!.trim().isNotEmpty)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.blueGrey.shade900.withValues(alpha: 0.4) : Colors.blue.shade50,
                border: Border.all(
                  color: isDark ? Colors.blueGrey.shade700 : Colors.blue.shade200,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bookmark, color: isDark ? Colors.blue.shade200 : Colors.blue.shade800, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '當前段落參考來源',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.blue.shade200 : Colors.blue.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.initialChunk!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

          // Message history list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message.role == Role.user;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6.0),
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? colorScheme.primary
                          : (isDark ? colorScheme.surfaceContainerHigh : Colors.grey.shade100),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUser ? '您' : 'AI 助理',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isUser ? colorScheme.onPrimary.withValues(alpha: 0.7) : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          message.content,
                          style: TextStyle(
                            fontSize: 15,
                            color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),

          // Input field and submit action
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    offset: Offset(0, -1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: widget.initialChunk != null ? '詢問關於此段落的問題...' : '詢問關於此書的問題...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _sendQuestion(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isLoading ? null : _sendQuestion,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


