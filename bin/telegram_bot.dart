import 'dart:io';

import 'package:local_ai_chat/config/telegram_bot_config.dart';
import 'package:local_ai_chat/models/message.dart';
import 'package:local_ai_chat/services/embedding_service.dart';
import 'package:local_ai_chat/services/ollama_service.dart';
import 'package:local_ai_chat/services/personal_rag_service.dart';
import 'package:local_ai_chat/services/telegram_bot_service.dart';
import 'package:local_ai_chat/services/vector_store.dart';

void main() async {
  print('Starting Telegram Bot initialization...');

  TelegramBotConfig config;
  try {
    config = TelegramBotConfig.fromEnvironment(Platform.environment);
  } catch (e) {
    print('Failed to start Telegram Bot: $e');
    exit(1);
  }

  print('Config loaded. Username: ${config.username}, Ollama URL: ${config.ollamaUrl}');

  final vectorStore = VectorStore(storagePath: 'vector_store.json');
  // Initialize the store
  await vectorStore.load();

  final embeddingService = EmbeddingService(
    baseUrl: config.ollamaUrl,
    model: config.embedModel,
  );

  final ollamaService = OllamaService(
    baseUrl: config.ollamaUrl,
    model: config.ollamaModel,
  );

  final ragService = PersonalRagService(
    embedder: embeddingService,
    store: vectorStore,
    llmComplete: ({required systemPrompt, required userPrompt}) async {
      return ollamaService.chat([
        ChatMessage(role: 'system', content: systemPrompt),
        ChatMessage(role: 'user', content: userPrompt),
      ]);
    },
  );

  final telegramService = TelegramBotService(
    token: config.token,
    ragService: ragService,
  );

  // Set up graceful shutdown
  void stopBot(ProcessSignal signal) {
    print('\nReceived $signal. Stopping Telegram Bot...');
    telegramService.stop();
    exit(0);
  }

  ProcessSignal.sigint.watch().listen(stopBot);
  if (!Platform.isWindows) {
    ProcessSignal.sigterm.watch().listen(stopBot);
  }

  print('Starting polling...');
  telegramService.start();
  
  // Keep the process running
  await ProcessSignal.sigint.watch().first;
}
