// test/services/personal_rag_service_extract_test.dart

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/controllers/expense_controller.dart';
import 'package:local_ai_chat/models/health_record.dart';
import 'package:local_ai_chat/models/wealth_record.dart';
import 'package:local_ai_chat/services/personal_rag_service.dart';
import 'package:local_ai_chat/services/vector_store.dart';

void main() {
  group('PersonalRagService.extractSearchTextForTest routing', () {
    test('Expense chunk does not walk Health path', () {
      final expenseChunk = DocChunk(
        id: 'test-expense-1',
        docName: 'expense_test',
        chunkIndex: 0,
        text: '午餐 食物 150.0 TWD 便當',
        collectionName: PersonalRagService.kExpensesCollection,
        metadata: {'type': ExpenseController.kExpenseTypeTag},
      );

      final result = PersonalRagService.extractSearchTextForTest(expenseChunk);

      expect(result, isNot(contains('systolic')));
      expect(result, isNot(contains('diastolic')));
      expect(result, contains('午餐'));
      expect(result, contains('便當'));
    });

    test('Health chunk walks Health path', () {
      final health = HealthRecord(
        id: 'test-health-1',
        date: DateTime(2026, 5, 1),
        systolic: 120,
        diastolic: 80,
        notes: '正常',
        dateAdded: DateTime(2026, 5, 1),
      );
      final healthChunk = DocChunk(
        id: health.id,
        docName: 'health_test',
        chunkIndex: 0,
        text: jsonEncode(health.toJson()),
        collectionName: PersonalRagService.kHealthCollection,
        metadata: {'type': 'personal_hub_health'},
      );

      final result = PersonalRagService.extractSearchTextForTest(healthChunk);

      expect(result, contains('blood pressure 120/80'));
      expect(result, contains('正常'));
    });

    test('Wealth chunk walks Wealth metadata data path when available', () {
      final wealth = WealthRecord(
        id: 'w1',
        date: DateTime(2026, 5, 1),
        assetType: WealthAssetType.stock,
        assetName: 'TSMC',
        amount: 10000,
        currency: 'TWD',
      );
      final wealthChunk = DocChunk(
        id: 'test-wealth-1',
        docName: 'wealth_test',
        chunkIndex: 0,
        text: 'opaque display text',
        collectionName: PersonalRagService.kWealthCollection,
        metadata: {
          'type': 'personal_hub_wealth',
          'data': wealth.toJson(),
        },
      );

      final result = PersonalRagService.extractSearchTextForTest(wealthChunk);

      expect(result, contains('TSMC'));
      expect(result, contains('10000.00 TWD'));
      expect(result, isNot(contains('opaque display text')));
    });

    test('malformed JSON falls back to raw text', () {
      final malformedHealthChunk = DocChunk(
        id: 'bad-health-1',
        docName: 'health_bad',
        chunkIndex: 0,
        text: '{"date":',
        collectionName: PersonalRagService.kHealthCollection,
        metadata: {'type': 'personal_hub_health'},
      );

      final result =
          PersonalRagService.extractSearchTextForTest(malformedHealthChunk);

      expect(result, '{"date":');
    });

    test('unknown collection falls back to raw text', () {
      final unknownChunk = DocChunk(
        id: 'unknown-1',
        docName: 'future_test',
        chunkIndex: 0,
        text: 'future module search text',
        collectionName: 'Future',
        metadata: {'type': 'personal_hub_future'},
      );

      final result = PersonalRagService.extractSearchTextForTest(unknownChunk);

      expect(result, 'future module search text');
    });
  });
}
