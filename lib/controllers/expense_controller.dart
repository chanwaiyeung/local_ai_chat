// lib/controllers/expense_controller.dart
import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../services/vector_store.dart';

class ExpenseController extends ChangeNotifier {
  ExpenseController(this._vectorStore);

  final VectorStore _vectorStore;

  static const String kExpenseCollection = 'Expenses';
  static const String kExpenseTypeTag = 'personal_hub_expense';

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Expense> _expenses = [];
  List<Expense> get expenses => List.unmodifiable(_expenses);

  // 產生假向量。Phase 6.3 跨模組 RAG 時再接上真實 Embedding。
  List<double> _generateDummyEmbedding(String text) {
    return List.filled(384, 0.0);
  }

  Future<void> saveExpense(Expense expense) async {
    _setLoading(true);
    try {
      final finalExpense = expense.id.isEmpty
          ? expense.copyWith(id: DateTime.now().microsecondsSinceEpoch.toString())
          : expense;

      if (expense.id.isNotEmpty) {
        await _vectorStore.deleteById(expense.id);
      }

      final chunk = DocChunk(
        id: finalExpense.id,
        docName: 'expense_${finalExpense.id}',
        chunkIndex: 0,
        text: finalExpense.toSearchText(),
        collectionName: kExpenseCollection,
        metadata: {
          'type': kExpenseTypeTag,
          'data': finalExpense.toJson(),
        },
      );

      await _vectorStore.add(chunk, _generateDummyEmbedding(chunk.text));
      await getAllExpenses();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteExpense(String id) async {
    _setLoading(true);
    try {
      await _vectorStore.deleteById(id);
      await getAllExpenses();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> getAllExpenses() async {
    _setLoading(true);
    try {
      final allChunks = _vectorStore.chunks
          .where((c) => c.collectionName == kExpenseCollection)
          .toList();

      _expenses = allChunks
          .map((c) {
            final data = c.metadata['data'] as Map<String, dynamic>?;
            if (data == null || c.metadata['type'] != kExpenseTypeTag) {
              return null;
            }
            return Expense.fromJson(data);
          })
          .whereType<Expense>()
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Expense>> searchExpenses(String query) async {
    if (query.trim().isEmpty) return expenses;

    final dummyQueryEmbedding = _generateDummyEmbedding(query);

    final results = _vectorStore.search(
      dummyQueryEmbedding,
      topK: 20,
      collectionName: kExpenseCollection,
    );

    return results
        .map((r) {
          final data = r.chunk.metadata['data'] as Map<String, dynamic>?;
          if (data == null || r.chunk.metadata['type'] != kExpenseTypeTag) {
            return null;
          }
          return Expense.fromJson(data);
        })
        .whereType<Expense>()
        .toList();
  }

  Map<String, double> getMonthlySummary(int year, int month) {
    final filtered = getMonthlyExpenses(year, month);
    final summary = <String, double>{};

    for (final expense in filtered) {
      summary.update(
        expense.currency,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return summary;
  }

  List<Expense> getMonthlyExpenses(int year, int month) {
    return _expenses.where((e) => e.date.year == year && e.date.month == month).toList();
  }

  Map<String, double> getMonthlyByCategory(int year, int month) {
    final filtered = getMonthlyExpenses(year, month);
    final byCategory = <String, double>{};

    for (final expense in filtered) {
      // We assume a single primary currency for simplicity in category totals,
      // or we just sum the raw amounts. Here we sum raw amounts.
      byCategory.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return byCategory;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}


