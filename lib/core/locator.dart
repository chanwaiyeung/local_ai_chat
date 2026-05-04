// lib/core/locator.dart
//
// Transitional service locator for v2.6.
//
// The app still exposes the legacy global variables from main.dart. This
// locator registers those already-initialized instances so new code can migrate
// toward dependency lookup without rebuilding services or changing startup
// order in one risky patch.

import 'package:get_it/get_it.dart';

import '../controllers/contact_controller.dart';
import '../controllers/expense_controller.dart';
import '../controllers/health_controller.dart';
import '../controllers/wealth_controller.dart';
import '../server/ollama_client.dart';
import '../services/personal_rag_service.dart';
import '../services/vector_store.dart';

final class Locator {
  const Locator._();

  static final GetIt I = GetIt.instance;

  /// Initializes the locator container.
  ///
  /// Keep this intentionally light. Services such as [VectorStore] require
  /// async loading and environment-specific configuration, so main.dart remains
  /// responsible for constructing them before calling [registerAppServices].
  static Future<void> init({bool reset = false}) async {
    if (reset) {
      await I.reset();
    }
  }

  static void registerAppServices({
    required VectorStore store,
    required ExpenseController expenseController,
    required ContactController contactController,
    required HealthController healthController,
    required WealthController wealthController,
    required PersonalRagService personalRagService,
    required OllamaClient ollamaClient,
  }) {
    _replace<VectorStore>(store);
    _replace<ExpenseController>(expenseController);
    _replace<ContactController>(contactController);
    _replace<HealthController>(healthController);
    _replace<WealthController>(wealthController);
    _replace<PersonalRagService>(personalRagService);
    _replace<OllamaClient>(ollamaClient);
  }

  static Future<void> resetForTest() => I.reset();

  static VectorStore get store => I<VectorStore>();
  static ExpenseController get expenseController => I<ExpenseController>();
  static ContactController get contactController => I<ContactController>();
  static HealthController get healthController => I<HealthController>();
  static WealthController get wealthController => I<WealthController>();
  static PersonalRagService get personalRagService => I<PersonalRagService>();
  static OllamaClient get ollamaClient => I<OllamaClient>();

  static void _replace<T extends Object>(T instance) {
    if (I.isRegistered<T>()) {
      I.unregister<T>();
    }
    I.registerSingleton<T>(instance);
  }
}

