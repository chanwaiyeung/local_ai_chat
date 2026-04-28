import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/controllers/chat_send_controller.dart';
import 'package:local_ai_chat/models/app_settings.dart';
import 'package:local_ai_chat/models/message.dart';
import 'package:local_ai_chat/services/embedding_service.dart';
import 'package:local_ai_chat/services/rag_service.dart';
import 'package:local_ai_chat/services/vector_store.dart';

void main() {
  test('buildContext adds RAG context for grounded hits', () async {
    final controller = const ChatSendController();
    final context = await controller.buildContext(
      query: 'refund policy',
      ragEnabled: true,
      storeLength: 1,
      rag: _FakeRagService([
        _hit('The refund policy allows returns.', index: 2),
      ]),
      embeddingModel: 'bge-m3',
      retrievalMode: RetrievalMode.hybrid,
      activeDoc: null,
      topK: 4,
      systemPrompt: 'system',
      currentMessages: [
        ChatMessage(role: Role.user, content: 'refund policy'),
      ],
    );

    expect(context.blockedMessage, isNull);
    expect(context.retrieveError, isNull);
    expect(context.hits, hasLength(1));
    expect(context.outgoing.any((m) => m.content.contains('refund policy')),
        isTrue);
  });

  test('buildContext blocks ungrounded RAG hits', () async {
    final controller = const ChatSendController();
    final context = await controller.buildContext(
      query: 'What color is the elephant?',
      ragEnabled: true,
      storeLength: 1,
      rag: _FakeRagService([
        _hit('The owner is Albert Chan.', index: 3),
      ]),
      embeddingModel: 'bge-m3',
      retrievalMode: RetrievalMode.hybrid,
      activeDoc: null,
      topK: 4,
      systemPrompt: 'system',
      currentMessages: const [],
    );

    expect(context.blockedMessage, isNotNull);
  });
}

ScoredChunk _hit(String text, {required int index}) {
  return ScoredChunk(
    DocChunk(
      id: 'doc_$index',
      docName: 'doc.txt',
      chunkIndex: index,
      text: text,
      embedding: const [1, 0, 0],
    ),
    0.9,
  );
}

class _FakeRagService extends RagService {
  _FakeRagService(this.hits)
      : super(embedder: _NoopEmbeddingService(), store: VectorStore());

  final List<ScoredChunk> hits;

  @override
  Future<List<ScoredChunk>> retrieve(
    String query, {
    int k = 4,
    String? docName,
    double minScore = 0.0,
    RetrievalMode mode = RetrievalMode.hybrid,
    RrfConfig rrfConfig = const RrfConfig(),
    bool useQueryExpansion = false,
  }) async {
    return hits;
  }
}

class _NoopEmbeddingService extends EmbeddingService {
  _NoopEmbeddingService() : super(baseUrl: 'http://unused.invalid');
}
