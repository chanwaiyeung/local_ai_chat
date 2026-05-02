// test/controllers/health_controller_test.dart
//
// Phase 6.7 (v2.3) — Tests for HealthRecord model + HealthController.
// Mirrors expense_controller_test.dart / contact_controller_test.dart structure.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:local_ai_chat/controllers/health_controller.dart';
import 'package:local_ai_chat/models/health_record.dart';
import 'package:local_ai_chat/services/vector_store.dart';

void main() {
  // --------------------------------------------------------------------------
  // HealthRecord model
  // --------------------------------------------------------------------------
  group('HealthRecord model', () {
    test('JSON round-trip preserves all fields', () {
      final r = HealthRecord(
        id: 'h_1',
        date: DateTime(2026, 5, 1),
        weight: 65.4,
        systolic: 120,
        diastolic: 80,
        heartRate: 72,
        steps: 8000,
        sleepHours: 7.5,
        notes: 'after run',
        tags: const ['morning', 'post-workout'],
        dateAdded: DateTime(2026, 5, 1, 10),
        source: 'manual',
      );
      final reloaded = HealthRecord.fromJson(
        jsonDecode(jsonEncode(r.toJson())) as Map<String, dynamic>,
      );
      expect(reloaded, r);
      expect(reloaded.hashCode, r.hashCode);
    });

    test('encode/decode helpers mirror toJson/fromJson', () {
      final r = HealthRecord(
        id: 'h_2',
        date: DateTime(2026, 5, 2),
        weight: 70.0,
        dateAdded: DateTime(2026, 5, 2),
      );
      expect(HealthRecord.decode(r.encode()), r);
    });

    test('legacy JSON missing optional fields uses defaults', () {
      final j = <String, dynamic>{
        'id': 'x',
        'date': '2026-01-01T00:00:00.000',
        'dateAdded': '2026-01-01T00:00:00.000',
      };
      final r = HealthRecord.fromJson(j);
      expect(r.weight, isNull);
      expect(r.systolic, isNull);
      expect(r.notes, '');
      expect(r.tags, isEmpty);
      expect(r.source, 'manual');
    });

    test('hasAnyMeasurement is false when all numeric fields null', () {
      final r = HealthRecord(
        date: DateTime(2026, 5, 1),
        dateAdded: DateTime(2026, 5, 1),
      );
      expect(r.hasAnyMeasurement, isFalse);
    });

    test('hasAnyMeasurement is true if any single metric set', () {
      final r = HealthRecord(
        date: DateTime(2026, 5, 1),
        dateAdded: DateTime(2026, 5, 1),
        weight: 60,
      );
      expect(r.hasAnyMeasurement, isTrue);
    });

    test('toSearchText includes labelled measurements', () {
      final r = HealthRecord(
        date: DateTime(2026, 5, 1),
        dateAdded: DateTime(2026, 5, 1),
        weight: 65.0,
        systolic: 120,
        diastolic: 80,
      );
      final t = r.toSearchText();
      expect(t.contains('weight'), isTrue);
      expect(t.contains('blood pressure'), isTrue);
      expect(t.contains('120/80'), isTrue);
    });

    test('copyWith with clearWeight nulls out weight', () {
      final r = HealthRecord(
        date: DateTime(2026, 5, 1),
        dateAdded: DateTime(2026, 5, 1),
        weight: 65,
      );
      final r2 = r.copyWith(clearWeight: true);
      expect(r2.weight, isNull);
    });
  });

  // --------------------------------------------------------------------------
  // HealthController CRUD
  // --------------------------------------------------------------------------
  group('HealthController CRUD', () {
    late Directory tempDir;
    late VectorStore store;
    late HealthController controller;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('health_crud_');
      store = VectorStore(
        storagePath: '${tempDir.path}${Platform.pathSeparator}vstore.json',
      );
      controller = HealthController(store);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('saveRecord generates id when input id is empty', () async {
      final saved = await controller.saveRecord(HealthRecord(
        date: DateTime(2026, 5, 1),
        dateAdded: DateTime(2026, 5, 1),
        weight: 60,
      ));
      expect(saved.id, isNotEmpty);
      expect(saved.id, startsWith('health_'));
    });

    test('saveRecord persists into "Health" collection only', () async {
      await controller.saveRecord(HealthRecord(
        date: DateTime(2026, 5, 1),
        dateAdded: DateTime(2026, 5, 1),
        weight: 60,
      ));
      expect(store.listCollections(), [HealthController.collectionName, 'default']);
      expect(
        store.chunksInCollection(HealthController.collectionName),
        hasLength(1),
      );
    });

    test('saveRecord upserts on existing id', () async {
      await controller.saveRecord(HealthRecord(
        id: 'fixed',
        date: DateTime(2026, 5, 1),
        dateAdded: DateTime(2026, 5, 1),
        weight: 60,
      ));
      await controller.saveRecord(HealthRecord(
        id: 'fixed',
        date: DateTime(2026, 5, 1),
        dateAdded: DateTime(2026, 5, 1),
        weight: 65,
      ));
      final all = controller.getAllRecords();
      expect(all, hasLength(1));
      expect(all.first.weight, 65);
    });

    test('deleteRecord returns true and removes the row', () async {
      await controller.saveRecord(HealthRecord(
        id: 'kill_me',
        date: DateTime(2026, 5, 1),
        dateAdded: DateTime(2026, 5, 1),
        weight: 60,
      ));
      expect(await controller.deleteRecord('kill_me'), isTrue);
      expect(controller.getAllRecords(), isEmpty);
    });

    test('deleteRecord returns false on unknown id', () async {
      expect(await controller.deleteRecord('nope'), isFalse);
    });

    test('deleteAllRecords clears collection but spares others', () async {
      await controller.saveRecord(HealthRecord(
        date: DateTime(2026, 5, 1),
        dateAdded: DateTime(2026, 5, 1),
        weight: 60,
      ));
      await store.add(
        DocChunk(docName: 'book', chunkIndex: 0, text: 'page'),
      );
      final removed = await controller.deleteAllRecords();
      expect(removed, 1);
      expect(controller.getAllRecords(), isEmpty);
      expect(store.chunksInCollection('default'), hasLength(1));
    });

    test('getAllRecords sorts newest-first by date', () async {
      await controller.saveRecord(HealthRecord(
        id: 'old',
        date: DateTime(2026, 1, 1),
        dateAdded: DateTime(2026, 1, 1),
        weight: 70,
      ));
      await controller.saveRecord(HealthRecord(
        id: 'new',
        date: DateTime(2026, 5, 1),
        dateAdded: DateTime(2026, 5, 1),
        weight: 65,
      ));
      final all = controller.getAllRecords();
      expect(all.first.id, 'new');
      expect(all.last.id, 'old');
    });

    test('count getter matches collection size', () async {
      expect(controller.count, 0);
      await controller.saveRecord(HealthRecord(
        date: DateTime(2026, 5, 1),
        dateAdded: DateTime(2026, 5, 1),
        weight: 60,
      ));
      expect(controller.count, 1);
    });

    test('saveRecord and deleteRecord fire ChangeNotifier events',
        () async {
      var changes = 0;
      controller.addListener(() => changes++);
      final saved = await controller.saveRecord(HealthRecord(
        date: DateTime(2026, 5, 1),
        dateAdded: DateTime(2026, 5, 1),
        weight: 60,
      ));
      await controller.deleteRecord(saved.id);
      expect(changes, 2);
    });
  });

  // --------------------------------------------------------------------------
  // HealthController stats
  // --------------------------------------------------------------------------
  group('HealthController stats', () {
    late Directory tempDir;
    late VectorStore store;
    late HealthController controller;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('health_stats_');
      store = VectorStore(
        storagePath: '${tempDir.path}${Platform.pathSeparator}vstore.json',
      );
      controller = HealthController(store);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('empty store returns isEmpty stats', () {
      final s = controller.getStats();
      expect(s.isEmpty, isTrue);
      expect(s.recordCount, 0);
      expect(s.avgWeight, isNull);
    });

    test('avgWeight handles records that omit weight', () async {
      await controller.saveRecord(HealthRecord(
        date: DateTime(2026, 5, 1),
        dateAdded: DateTime(2026, 5, 1),
        weight: 60,
      ));
      await controller.saveRecord(HealthRecord(
        date: DateTime(2026, 5, 2),
        dateAdded: DateTime(2026, 5, 2),
        weight: 70,
      ));
      // Record with no weight, only steps — should be excluded from avgWeight.
      await controller.saveRecord(HealthRecord(
        date: DateTime(2026, 5, 3),
        dateAdded: DateTime(2026, 5, 3),
        steps: 5000,
      ));
      final s = controller.getStats();
      expect(s.weightCount, 2);
      expect(s.avgWeight, 65.0);
      expect(s.minWeight, 60.0);
      expect(s.maxWeight, 70.0);
    });

    test('blood pressure averages reflect only records that recorded BP',
        () async {
      await controller.saveRecord(HealthRecord(
        date: DateTime(2026, 5, 1),
        dateAdded: DateTime(2026, 5, 1),
        systolic: 120,
        diastolic: 80,
      ));
      await controller.saveRecord(HealthRecord(
        date: DateTime(2026, 5, 2),
        dateAdded: DateTime(2026, 5, 2),
        systolic: 130,
        diastolic: 90,
      ));
      final s = controller.getStats();
      expect(s.bloodPressureCount, 2);
      expect(s.avgSystolic, 125);
      expect(s.avgDiastolic, 85);
    });

    test('totalSteps sums across records', () async {
      await controller.saveRecord(HealthRecord(
        date: DateTime(2026, 5, 1),
        dateAdded: DateTime(2026, 5, 1),
        steps: 8000,
      ));
      await controller.saveRecord(HealthRecord(
        date: DateTime(2026, 5, 2),
        dateAdded: DateTime(2026, 5, 2),
        steps: 12000,
      ));
      final s = controller.getStats();
      expect(s.totalSteps, 20000);
      expect(s.stepsCount, 2);
    });

    test('lastNDays window filters older records', () async {
      final now = DateTime.now();
      // 60 days ago — should be excluded by lastNDays: 30.
      await controller.saveRecord(HealthRecord(
        date: now.subtract(const Duration(days: 60)),
        dateAdded: now.subtract(const Duration(days: 60)),
        weight: 80,
      ));
      // 5 days ago — included.
      await controller.saveRecord(HealthRecord(
        date: now.subtract(const Duration(days: 5)),
        dateAdded: now.subtract(const Duration(days: 5)),
        weight: 65,
      ));
      final s = controller.getStats(lastNDays: 30);
      expect(s.weightCount, 1);
      expect(s.avgWeight, 65.0);
    });
  });

  // --------------------------------------------------------------------------
  // Search
  // --------------------------------------------------------------------------
  group('HealthController search', () {
    late Directory tempDir;
    late VectorStore store;
    late HealthController controller;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('health_search_');
      store = VectorStore(
        storagePath: '${tempDir.path}${Platform.pathSeparator}vstore.json',
      );
      controller = HealthController(store);
      await controller.saveRecord(HealthRecord(
        date: DateTime(2026, 5, 1),
        dateAdded: DateTime(2026, 5, 1),
        weight: 65,
        notes: 'after morning run',
        tags: const ['cardio'],
      ));
      await controller.saveRecord(HealthRecord(
        date: DateTime(2026, 5, 2),
        dateAdded: DateTime(2026, 5, 2),
        systolic: 130,
        diastolic: 85,
        notes: 'feeling stressed',
      ));
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('search by notes', () {
      expect(controller.searchRecords('stressed').length, 1);
    });

    test('search by tag', () {
      expect(controller.searchRecords('cardio').length, 1);
    });

    test('search by measurement label', () {
      // toSearchText emits "blood pressure 130/85"
      expect(controller.searchRecords('blood pressure').length, 1);
    });

    test('empty query returns all', () {
      expect(controller.searchRecords('').length, 2);
    });
  });

  // --------------------------------------------------------------------------
  // Persistence + isolation
  // --------------------------------------------------------------------------
  group('HealthController persistence', () {
    test('records survive store reload from disk', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('health_persist_');
      final path = '${tempDir.path}${Platform.pathSeparator}vstore.json';
      try {
        final writer = VectorStore(storagePath: path);
        final c1 = HealthController(writer);
        await c1.saveRecord(HealthRecord(
          id: 'persist_me',
          date: DateTime(2026, 5, 1),
          dateAdded: DateTime(2026, 5, 1),
          weight: 65,
          systolic: 120,
          diastolic: 80,
        ));

        final reader = VectorStore(storagePath: path);
        await reader.load();
        final c2 = HealthController(reader);

        final all = c2.getAllRecords();
        expect(all, hasLength(1));
        expect(all.first.id, 'persist_me');
        expect(all.first.weight, 65);
        expect(all.first.systolic, 120);
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('Health does not pollute other collections', () async {
      final tempDir =
          await Directory.systemTemp.createTemp('health_iso_');
      final path = '${tempDir.path}${Platform.pathSeparator}vstore.json';
      try {
        final store = VectorStore(storagePath: path);
        final controller = HealthController(store);

        await store.add(DocChunk(
          docName: 'book.epub',
          chunkIndex: 0,
          text: 'chapter content',
        ));
        await controller.saveRecord(HealthRecord(
          date: DateTime(2026, 5, 1),
          dateAdded: DateTime(2026, 5, 1),
          weight: 60,
        ));

        expect(
          store.chunksInCollection('default'),
          hasLength(1),
        );
        expect(
          store.chunksInCollection(HealthController.collectionName),
          hasLength(1),
        );
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}
