// test/core/locator_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/controllers/contact_controller.dart';
import 'package:local_ai_chat/controllers/expense_controller.dart';
import 'package:local_ai_chat/controllers/health_controller.dart';
import 'package:local_ai_chat/controllers/wealth_controller.dart';
import 'package:local_ai_chat/core/locator.dart';
import 'package:local_ai_chat/server/ollama_client.dart';
import 'package:local_ai_chat/services/embedding_service.dart';
import 'package:local_ai_chat/services/personal_rag_service.dart';
import 'package:local_ai_chat/services/vector_store.dart';

void main() {
  tearDown(() async {
    await Locator.resetForTest();
  });

  test('registerAppServices exposes app singletons', () async {
    await Locator.init(reset: true);
    final store = VectorStore();
    final expenseController = ExpenseController(store);
    final contactController = ContactController(store: store);
    final healthController = HealthController(store);
    final wealthController = WealthController(store);
    final ollamaClient = OllamaClient();
    final personalRagService = PersonalRagService(
      embedder: EmbeddingService(embedFn: (_) async => [1.0]),
      store: store,
    );

    Locator.registerAppServices(
      store: store,
      expenseController: expenseController,
      contactController: contactController,
      healthController: healthController,
      wealthController: wealthController,
      personalRagService: personalRagService,
      ollamaClient: ollamaClient,
    );

    expect(Locator.store, same(store));
    expect(Locator.expenseController, same(expenseController));
    expect(Locator.contactController, same(contactController));
    expect(Locator.healthController, same(healthController));
    expect(Locator.wealthController, same(wealthController));
    expect(Locator.personalRagService, same(personalRagService));
    expect(Locator.ollamaClient, same(ollamaClient));
  });

  test('registerAppServices replaces previous instances', () async {
    await Locator.init(reset: true);
    final firstStore = VectorStore();
    final secondStore = VectorStore();

    void register(VectorStore store) {
      Locator.registerAppServices(
        store: store,
        expenseController: ExpenseController(store),
        contactController: ContactController(store: store),
        healthController: HealthController(store),
        wealthController: WealthController(store),
        personalRagService: PersonalRagService(
          embedder: EmbeddingService(embedFn: (_) async => [1.0]),
          store: store,
        ),
        ollamaClient: OllamaClient(),
      );
    }

    register(firstStore);
    register(secondStore);

    expect(Locator.store, same(secondStore));
  });
}

