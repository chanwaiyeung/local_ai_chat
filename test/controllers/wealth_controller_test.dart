// test/controllers/wealth_controller_test.dart
//
// v2.4 Phase 7.0'b — covers the bugs the v2.4 Final shipped with:
//   * cross-currency mixing in totals/allocation
//   * latest-per-asset semantics
//   * net-worth history step-function
//   * load-after-construct ordering

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/controllers/wealth_controller.dart';
import 'package:local_ai_chat/models/wealth_record.dart';
import 'package:local_ai_chat/services/vector_store.dart';

void main() {
  late Directory tempDir;
  late VectorStore store;
  late WealthController controller;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wealth_ctl_');
    store = VectorStore(
      storagePath: '${tempDir.path}${Platform.pathSeparator}vstore.json',
    );
    controller = WealthController(store);
    await controller.loadAll();
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  group('CRUD', () {
    test('save with empty id generates a wealth_-prefixed id', () async {
      final saved = await controller.saveRecord(WealthRecord(
        date: DateTime(2026, 5, 1),
        assetType: WealthAssetType.cash,
        amount: 100,
        dateAdded: DateTime(2026, 5, 1),
      ));
      expect(saved.id, isNotEmpty);
      expect(saved.id, startsWith('wealth_'));
      expect(RegExp(r'^wealth_\d+_[0-9a-f]{8}$').hasMatch(saved.id), isTrue);
    });

    test('generated ids include entropy suffix to avoid batch collisions',
        () async {
      final ids = <String>{};

      for (var i = 0; i < 20; i++) {
        final saved = await controller.saveRecord(WealthRecord(
          date: DateTime(2026, 5, 1),
          assetType: WealthAssetType.cash,
          amount: i + 1,
          dateAdded: DateTime(2026, 5, 1),
        ));
        ids.add(saved.id);
      }

      expect(ids, hasLength(20));
      expect(
        ids.every((id) => RegExp(r'^wealth_\d+_[0-9a-f]{8}$').hasMatch(id)),
        isTrue,
      );
    });

    test('save then delete returns true and clears the row', () async {
      final saved = await controller.saveRecord(WealthRecord(
        date: DateTime(2026, 5, 1),
        assetType: WealthAssetType.cash,
        amount: 1,
        dateAdded: DateTime(2026, 5, 1),
      ));
      expect(await controller.deleteRecord(saved.id), isTrue);
      expect(controller.count, 0);
    });

    test('deleteRecord returns false on unknown id', () async {
      expect(await controller.deleteRecord('does-not-exist'), isFalse);
    });

    test('records are sorted newest-first', () async {
      await controller.saveRecord(WealthRecord(
        id: 'old',
        date: DateTime(2026, 1, 1),
        assetType: WealthAssetType.cash,
        amount: 1,
        dateAdded: DateTime(2026, 1, 1),
      ));
      await controller.saveRecord(WealthRecord(
        id: 'new',
        date: DateTime(2026, 5, 1),
        assetType: WealthAssetType.cash,
        amount: 1,
        dateAdded: DateTime(2026, 5, 1),
      ));
      expect(controller.getAllRecords().first.id, 'new');
    });
  });

  group('latest-per-asset semantics', () {
    test(
      'two valuations of same asset → only newest counted in net worth',
      () async {
        await controller.saveRecord(WealthRecord(
          date: DateTime(2026, 5, 1),
          assetType: WealthAssetType.stock,
          assetName: 'AAPL',
          amount: 100,
          currency: 'USD',
          dateAdded: DateTime(2026, 5, 1),
        ));
        await controller.saveRecord(WealthRecord(
          date: DateTime(2026, 5, 5),
          assetType: WealthAssetType.stock,
          assetName: 'AAPL',
          amount: 110,
          currency: 'USD',
          dateAdded: DateTime(2026, 5, 5),
        ));
        // KEY: must be 110, not 210.
        final stats = controller.getStats(currency: 'USD');
        expect(stats.totalNetWorth, 110);
        expect(stats.assetCount, 1);
      },
    );
  });

  group('multi-currency safety (the v2.4 Final bug)', () {
    test('TWD and USD never get summed into one number', () async {
      await controller.saveRecord(WealthRecord(
        date: DateTime(2026, 5, 1),
        assetType: WealthAssetType.cash,
        amount: 100000,
        currency: 'TWD',
        dateAdded: DateTime(2026, 5, 1),
      ));
      await controller.saveRecord(WealthRecord(
        date: DateTime(2026, 5, 1),
        assetType: WealthAssetType.cash,
        amount: 1000,
        currency: 'USD',
        dateAdded: DateTime(2026, 5, 1),
      ));
      final totals = controller.getCurrentTotalByCurrency();
      expect(totals['TWD'], 100000);
      expect(totals['USD'], 1000);
      // And per-currency stats stay segregated:
      expect(controller.getStats(currency: 'TWD').totalNetWorth, 100000);
      expect(controller.getStats(currency: 'USD').totalNetWorth, 1000);
    });

    test('getCurrencies returns distinct sorted list', () async {
      await controller.saveRecord(WealthRecord(
        date: DateTime(2026, 5, 1),
        assetType: WealthAssetType.cash,
        amount: 1,
        currency: 'USD',
        dateAdded: DateTime(2026, 5, 1),
      ));
      await controller.saveRecord(WealthRecord(
        date: DateTime(2026, 5, 1),
        assetType: WealthAssetType.cash,
        amount: 1,
        currency: 'TWD',
        dateAdded: DateTime(2026, 5, 1),
      ));
      expect(controller.getCurrencies(), ['TWD', 'USD']);
    });
  });

  group('net worth history', () {
    test('step function: newer asset valuations replace older for same key',
        () async {
      await controller.saveRecord(WealthRecord(
        date: DateTime(2026, 5, 1),
        assetType: WealthAssetType.stock,
        assetName: 'AAPL',
        amount: 100,
        currency: 'USD',
        dateAdded: DateTime(2026, 5, 1),
      ));
      await controller.saveRecord(WealthRecord(
        date: DateTime(2026, 5, 5),
        assetType: WealthAssetType.stock,
        assetName: 'AAPL',
        amount: 130,
        currency: 'USD',
        dateAdded: DateTime(2026, 5, 5),
      ));
      await controller.saveRecord(WealthRecord(
        date: DateTime(2026, 5, 5),
        assetType: WealthAssetType.crypto,
        assetName: 'BTC',
        amount: 200,
        currency: 'USD',
        dateAdded: DateTime(2026, 5, 5),
      ));
      final history = controller.getNetWorthHistory(currency: 'USD');
      expect(history, hasLength(2));
      expect(history.first.total, 100); // 5/1: AAPL=100
      expect(history.last.total, 330); // 5/5: AAPL=130 + BTC=200
    });
  });

  group('persistence', () {
    test('records survive store reload via second controller', () async {
      await controller.saveRecord(WealthRecord(
        id: 'persist',
        date: DateTime(2026, 5, 1),
        assetType: WealthAssetType.fund,
        assetName: '0050.TW',
        amount: 50000,
        currency: 'TWD',
        dateAdded: DateTime(2026, 5, 1),
      ));

      final reader = VectorStore(
        storagePath: '${tempDir.path}${Platform.pathSeparator}vstore.json',
      );
      await reader.load();
      final c2 = WealthController(reader);
      await c2.loadAll();

      expect(c2.count, 1);
      expect(c2.getAllRecords().first.assetName, '0050.TW');
    });
  });

  group('search', () {
    test('search by assetName is case-insensitive', () async {
      await controller.saveRecord(WealthRecord(
        date: DateTime(2026, 5, 1),
        assetType: WealthAssetType.fund,
        assetName: 'Vanguard 500',
        amount: 5000,
        dateAdded: DateTime(2026, 5, 1),
      ));
      expect(controller.searchRecords('vanguard'), hasLength(1));
      expect(controller.searchRecords('VANGUARD'), hasLength(1));
      expect(controller.searchRecords('xyz'), isEmpty);
    });

    test('empty query returns all', () async {
      await controller.saveRecord(WealthRecord(
        date: DateTime(2026, 5, 1),
        assetType: WealthAssetType.cash,
        amount: 1,
        dateAdded: DateTime(2026, 5, 1),
      ));
      expect(controller.searchRecords(''), hasLength(1));
    });
  });
}
