import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import '../models/message.dart';
import '../services/debug_log_service.dart';
import '../services/ollama_service.dart';
import '../services/rag_service.dart';
import '../services/vector_store.dart';

class ChatSendContext {
  const ChatSendContext({
    required this.outgoing,
    required this.hits,
    this.blockedMessage,
    this.retrieveError,
  });

  final List<ChatMessage> outgoing;
  final List<ScoredChunk> hits;
  final String? blockedMessage;
  final Object? retrieveError;
}

class ChatSendController {
  const ChatSendController();

  Future<ChatSendContext> buildContext({
    required String query,
    required bool ragEnabled,
    required int storeLength,
    required RagService rag,
    required String embeddingModel,
    required RetrievalMode retrievalMode,
    required String? activeDoc,
    required int topK,
    required String systemPrompt,
    required List<ChatMessage> currentMessages,
  }) async {
    final outgoing = <ChatMessage>[
      ChatMessage(role: Role.system, content: systemPrompt),
    ];

    var hits = <ScoredChunk>[];
    Object? retrieveError;

    if (ragEnabled && storeLength > 0) {
      try {
        hits = await _retrieveWithDiagnostics(
          query: query,
          rag: rag,
          embeddingModel: embeddingModel,
          retrievalMode: retrievalMode,
          activeDoc: activeDoc,
          topK: topK,
          storeLength: storeLength,
        );
        if (hits.isNotEmpty && !RagService.hasKeywordGrounding(query, hits)) {
          return ChatSendContext(
            outgoing: outgoing,
            hits: hits,
            blockedMessage: '在文件中沒有找到相關資訊。請確認已載入正確文件，或換個問法再試。',
          );
        }

        if (hits.isNotEmpty) {
          outgoing.add(ChatMessage(
            role: Role.system,
            content: RagService.buildContext(hits),
          ));
        }
      } catch (error, stackTrace) {
        retrieveError = error;
        await DebugLogService.append(
          'RAG retrieve failed: query="$query" embeddingModel=$embeddingModel '
          'mode=${retrievalMode.name} '
          'doc=${activeDoc ?? '(all)'} error=$error\n$stackTrace',
          level: 'ERROR',
        );
      }
    }

    outgoing.addAll(currentMessages.where(
      (message) =>
          message.role != Role.system ||
          message.content.startsWith('【') ||
          message.content.startsWith('【相關段落】'),
    ));

    return ChatSendContext(
      outgoing: outgoing,
      hits: hits,
      retrieveError: retrieveError,
    );
  }

  Future<String> streamAssistantResponse({
    required OllamaService ollama,
    required List<ChatMessage> outgoing,
    required void Function(String content) onContent,
  }) async {
    final buffer = StringBuffer();
    final stream = ollama.chatStream(outgoing);
    await for (final chunk in stream) {
      buffer.write(chunk);
      onContent(buffer.toString());
    }
    return buffer.toString();
  }

  String appendSources(String content, List<ScoredChunk> hits) {
    if (hits.isEmpty) return content;

    final sources = hits.map((hit) {
      final docName = hit.chunk.docName;
      final doc = Uri.encodeQueryComponent(docName);
      final index = hit.chunk.chunkIndex;
      final score = hit.score.toStringAsFixed(2);
      return '• [$docName #$index ($score)](chunk:?doc=$doc&i=$index)';
    }).join('\n');

    return '${content.trim()}\n\n📚 引用來源：\n$sources';
  }

  Future<List<ScoredChunk>> _retrieveWithDiagnostics({
    required String query,
    required RagService rag,
    required String embeddingModel,
    required RetrievalMode retrievalMode,
    required String? activeDoc,
    required int topK,
    required int storeLength,
  }) async {
    final retrieveStarted = DateTime.now();
    final retrieveStartLog =
        'RAG retrieve: start query="$query" embeddingModel=$embeddingModel '
        'mode=${retrievalMode.name} '
        'doc=${activeDoc ?? '(all)'} topK=$topK chunks=$storeLength';
    debugPrint(retrieveStartLog);
    unawaited(DebugLogService.append(retrieveStartLog));

    final hits = await rag.retrieve(
      query,
      k: topK,
      docName: activeDoc,
      mode: retrievalMode,
    );
    final retrieveMs =
        DateTime.now().difference(retrieveStarted).inMilliseconds;
    final scores = hits
        .map((hit) =>
            '${hit.chunk.docName}#${hit.chunk.chunkIndex}:${hit.score.toStringAsFixed(3)}')
        .join(', ');
    final diagnostics = rag.lastDiagnostics?.summary();
    final retrieveDoneLog =
        'RAG retrieve: done hits=${hits.length} durationMs=$retrieveMs '
        'scores=[$scores]'
        '${diagnostics == null ? '' : ' $diagnostics'}';
    debugPrint(retrieveDoneLog);
    unawaited(DebugLogService.append(retrieveDoneLog));
    return hits;
  }
}


