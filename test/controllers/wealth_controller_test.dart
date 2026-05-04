// test/controllers/wealth_controller_test.dart

//

// Phase 7.0 (v2.4) — Tests for WealthRecord model + WealthController.



import 'dart:convert';

import 'dart:io';



import 'package:flutter_test/flutter_test.dart';



import 'package:local_ai_chat/controllers/wealth_controller.dart';

import 'package:local_ai_chat/models/wealth_record.dart';

import 'package:local_ai_chat/services/vector_store.dart';



void main() {

  // --------------------------------------------------------------------------

  // WealthRecord model

  // --------------------------------------------------------------------------

  group('WealthRecord model', () {

    test('JSON round-trip preserves all fields', () {

      final r = WealthRecord(

        id: 'w_1',

        date: DateTime(2026, 5, 1),

        assetType: WealthAssetType.stock,

        assetName: 'AAPL',

        amount: 12500,

        currency: 'USD',

        notes: 'long-term hold',

        tags: const ['tech'],

        dateAdded: DateTime(2026, 5, 1),

        source: 'manual',

      );

      final reloaded = WealthRecord.fromJson(

        jsonDecode(jsonEncode(r.toJson())) as Map<String, dynamic>,

      );

      expect(reloaded, r);

      expect(reloaded.hashCode, r.hashCode);

    });



//     test('encode/decode helpers mirror toJson/fromJson', () {
// 
//       final r = WealthRecord(
// 
//         id: 'w_2',
// 
//         date: DateTime(2026, 5, 2),
// 
//         assetType: WealthAssetType.cash,
// 
//         amount: 100000,
// 
//         currency: 'TWD',
// 
//         dateAdded: DateTime(2026, 5, 2),
// 
//       );
// 
//       // expect(WealthRecord.decode(r.encode()), r);
// 
//     });



    test('legacy JSON missing optional fields uses defaults', () {

      final j = <String, dynamic>{

        'id': 'x',

        'date': '2026-01-01T00:00:00.000',

        'amount': 1000,

        'dateAdded': '2026-01-01T00:00:00.000',

      };

      final r = WealthRecord.fromJson(j);

      expect(r.assetType, WealthAssetType.other);

      expect(r.assetName, '');

      expect(r.currency, 'TWD');

      expect(r.tags, isEmpty);

      expect(r.source, 'manual');

    });



    test('assetKey groups by type+name+currency', () {

      final r1 = WealthRecord(

        date: DateTime(2026, 5, 1),

        assetType: 'stock',

        assetName: 'AAPL',

        amount: 100,

        currency: 'USD',

        dateAdded: DateTime(2026, 5, 1),

      );

      final r2 = WealthRecord(

        date: DateTime(2026, 5, 5),

        assetType: 'stock',

        assetName: 'AAPL',

        amount: 110,

        currency: 'USD',

        dateAdded: DateTime(2026, 5, 5),

      );

      expect(r1.assetKey, r2.assetKey);

    });



    test('toSearchText includes label, type and asset name', () {

      final r = WealthRecord(

        date: DateTime(2026, 5, 1),

        assetType: WealthAssetType.crypto,

        assetName: 'BTC',

        amount: 30000,

        currency: 'USD',

        dateAdded: DateTime(2026, 5, 1),

      );

      final t = r.toSearchText();

      expect(t.contains('加密貨幣'), isTrue);

      expect(t.contains('crypto'), isTrue);

      expect(t.contains('BTC'), isTrue);

      expect(t.contains('USD'), isTrue);

    });



    test('WealthAssetType.label translates known codes', () {

      expect(WealthAssetType.label(WealthAssetType.stock), '股票');

      expect(WealthAssetType.label(WealthAssetType.crypto), '加密貨幣');

      // Unknown codes pass through

      expect(WealthAssetType.label('mystery_coin'), 'mystery_coin');

    });

  });



  // --------------------------------------------------------------------------

  // WealthController CRUD

  // --------------------------------------------------------------------------

  group('WealthController CRUD', () {

    late Directory tempDir;

    late VectorStore store;

    late WealthController controller;



    setUp(() async {

      tempDir = await Directory.systemTemp.createTemp('wealth_crud_');

      store = VectorStore(

        storagePath: '${tempDir.path}${Platform.pathSeparator}vstore.json',

      );

      controller = WealthController(store);

    });



    tearDown(() async {

      if (await tempDir.exists()) {

        await tempDir.delete(recursive: true);

      }

    });



    test('saveRecord generates id when input id is empty', () async {

      final saved = await controller.saveRecord(WealthRecord(

        date: DateTime(2026, 5, 1),

        assetType: WealthAssetType.cash,

        amount: 5000,

        dateAdded: DateTime(2026, 5, 1),

      ));

      expect(saved.id, isNotEmpty);

      expect(saved.id, startsWith('wealth_'));

    });



    test('saveRecord persists into "Wealth" collection only', () async {

      await controller.saveRecord(WealthRecord(

        date: DateTime(2026, 5, 1),

        assetType: WealthAssetType.cash,

        amount: 5000,

        dateAdded: DateTime(2026, 5, 1),

      ));

      expect(store.listCollections(), contains(WealthController.kWealthCollection));

      expect(

        store.chunksInCollection(WealthController.kWealthCollection),

        hasLength(1),

      );

    });



    test('saveRecord upserts on existing id', () async {

      await controller.saveRecord(WealthRecord(

        id: 'fixed',

        date: DateTime(2026, 5, 1),

        assetType: WealthAssetType.stock,

        amount: 100,

        dateAdded: DateTime(2026, 5, 1),

      ));

      await controller.saveRecord(WealthRecord(

        id: 'fixed',

        date: DateTime(2026, 5, 1),

        assetType: WealthAssetType.stock,

        amount: 200,

        dateAdded: DateTime(2026, 5, 1),

      ));

      final all = controller.getAllRecords();

      expect(all, hasLength(1));

      expect(all.first.amount, 200);

    });



    test('deleteRecord returns true and removes the row', () async {

      await controller.saveRecord(WealthRecord(

        id: 'kill_me',

        date: DateTime(2026, 5, 1),

        assetType: WealthAssetType.cash,

        amount: 1,

        dateAdded: DateTime(2026, 5, 1),

      ));

      expect(await controller.deleteRecord('kill_me'), isTrue);

      expect(controller.getAllRecords(), isEmpty);

    });



    test('deleteRecord returns false on unknown id', () async {

      expect(await controller.deleteRecord('nope'), isFalse);

    });



    test('deleteAllRecords clears collection but spares others', () async {

      await controller.saveRecord(WealthRecord(

        date: DateTime(2026, 5, 1),

        assetType: WealthAssetType.cash,

        amount: 1,

        dateAdded: DateTime(2026, 5, 1),

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

      await controller.saveRecord(WealthRecord(

        id: 'old',

        date: DateTime(2026, 1, 1),

        assetType: WealthAssetType.cash,

        amount: 100,

        dateAdded: DateTime(2026, 1, 1),

      ));

      await controller.saveRecord(WealthRecord(

        id: 'new',

        date: DateTime(2026, 5, 1),

        assetType: WealthAssetType.cash,

        amount: 200,

        dateAdded: DateTime(2026, 5, 1),

      ));

      final all = controller.getAllRecords();

      expect(all.first.id, 'new');

      expect(all.last.id, 'old');

    });



    test('saveRecord and deleteRecord fire ChangeNotifier events',

        () async {

      var changes = 0;

      controller.addListener(() => changes++);

      final saved = await controller.saveRecord(WealthRecord(

        date: DateTime(2026, 5, 1),

        assetType: WealthAssetType.cash,

        amount: 100,

        dateAdded: DateTime(2026, 5, 1),

      ));

      await controller.deleteRecord(saved.id);

      expect(changes, 2);

    });

  });



  // --------------------------------------------------------------------------

  // Latest-per-asset semantics + stats

  // --------------------------------------------------------------------------

  group('WealthController latest-per-asset & stats', () {

    late Directory tempDir;

    late VectorStore store;

    late WealthController controller;



    setUp(() async {

      tempDir = await Directory.systemTemp.createTemp('wealth_stats_');

      store = VectorStore(

        storagePath: '${tempDir.path}${Platform.pathSeparator}vstore.json',

      );

      controller = WealthController(store);

    });



    tearDown(() async {

      if (await tempDir.exists()) {

        await tempDir.delete(recursive: true);

      }

    });



    test('latestPerAsset picks the record with greatest date', () async {

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

      final latest = controller.latestPerAsset();

      expect(latest, hasLength(1));

      expect(latest.values.first.amount, 110);

    });



    test('getCurrentTotalByCurrency sums latest per asset', () async {

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

        amount: 120,

        currency: 'USD',

        dateAdded: DateTime(2026, 5, 5),

      ));

      await controller.saveRecord(WealthRecord(

        date: DateTime(2026, 5, 5),

        assetType: WealthAssetType.cash,

        amount: 5000,

        currency: 'TWD',

        dateAdded: DateTime(2026, 5, 5),

      ));

      final totals = controller.getCurrentTotalByCurrency();

      expect(totals['USD'], 120);

      expect(totals['TWD'], 5000);

    });



    test('getAllocationByType groups by type within a currency',

        () async {

      await controller.saveRecord(WealthRecord(

        date: DateTime(2026, 5, 1),

        assetType: WealthAssetType.stock,

        assetName: 'AAPL',

        amount: 1000,

        currency: 'USD',

        dateAdded: DateTime(2026, 5, 1),

      ));

      await controller.saveRecord(WealthRecord(

        date: DateTime(2026, 5, 1),

        assetType: WealthAssetType.crypto,

        assetName: 'BTC',

        amount: 500,

        currency: 'USD',

        dateAdded: DateTime(2026, 5, 1),

      ));

      await controller.saveRecord(WealthRecord(

        date: DateTime(2026, 5, 1),

        assetType: WealthAssetType.crypto,

        assetName: 'ETH',

        amount: 200,

        currency: 'USD',

        dateAdded: DateTime(2026, 5, 1),

      ));

      // Unrelated currency — should NOT contribute.

      await controller.saveRecord(WealthRecord(

        date: DateTime(2026, 5, 1),

        assetType: WealthAssetType.cash,

        amount: 99999,

        currency: 'TWD',

        dateAdded: DateTime(2026, 5, 1),

      ));

      final alloc = controller.getAllocationByType(currency: 'USD');

      expect(alloc[WealthAssetType.stock], 1000);

      expect(alloc[WealthAssetType.crypto], 700);

      expect(alloc.containsKey(WealthAssetType.cash), isFalse);

    });



    test('getStats bundles total, allocation, asset count', () async {

      await controller.saveRecord(WealthRecord(

        date: DateTime(2026, 5, 1),

        assetType: WealthAssetType.stock,

        assetName: 'AAPL',

        amount: 1000,

        currency: 'USD',

        dateAdded: DateTime(2026, 5, 1),

      ));

      await controller.saveRecord(WealthRecord(

        date: DateTime(2026, 5, 1),

        assetType: WealthAssetType.crypto,

        assetName: 'BTC',

        amount: 500,

        currency: 'USD',

        dateAdded: DateTime(2026, 5, 1),

      ));

      final stats = controller.getStats(currency: 'USD');

      expect(stats.isEmpty, isFalse);

      expect(stats.totalNetWorth, 1500);

      expect(stats.assetCount, 2);

      expect(stats.allocationByType.length, 2);

    });



    test('getStats on empty store returns isEmpty stats', () {

      final stats = controller.getStats(currency: 'USD');

      expect(stats.isEmpty, isTrue);

      expect(stats.totalNetWorth, 0);

    });



    test('getNetWorthHistory walks dates in chronological order',

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

      // Day 1: only AAPL=100 → total 100

      expect(history.first.total, 100);

      // Day 5: AAPL=130 + BTC=200 → total 330

      expect(history.last.total, 330);

      // Chronological

      expect(

        history.first.date.isBefore(history.last.date),

        isTrue,

      );

    });



    test('getNetWorthHistory filters by currency', () async {

      await controller.saveRecord(WealthRecord(

        date: DateTime(2026, 5, 1),

        assetType: WealthAssetType.cash,

        amount: 100,

        currency: 'USD',

        dateAdded: DateTime(2026, 5, 1),

      ));

      await controller.saveRecord(WealthRecord(

        date: DateTime(2026, 5, 1),

        assetType: WealthAssetType.cash,

        amount: 30000,

        currency: 'TWD',

        dateAdded: DateTime(2026, 5, 1),

      ));

      final usd = controller.getNetWorthHistory(currency: 'USD');

      final twd = controller.getNetWorthHistory(currency: 'TWD');

      expect(usd.first.total, 100);

      expect(twd.first.total, 30000);

    });



    test('getNetWorthHistory respects lastNDays window', () async {

      final now = DateTime.now();

      // 60 days ago

      await controller.saveRecord(WealthRecord(

        date: now.subtract(const Duration(days: 60)),

        assetType: WealthAssetType.cash,

        amount: 100,

        currency: 'USD',

        dateAdded: now.subtract(const Duration(days: 60)),

      ));

      // 5 days ago

      await controller.saveRecord(WealthRecord(

        date: now.subtract(const Duration(days: 5)),

        assetType: WealthAssetType.cash,

        amount: 200,

        currency: 'USD',

        dateAdded: now.subtract(const Duration(days: 5)),

      ));

      final history = controller.getNetWorthHistory(

        currency: 'USD',

        lastNDays: 30,

      );

      // Only the 5-days-ago snapshot fits inside the window.

      expect(history, hasLength(1));

      expect(history.first.total, 200);

    });



    test('getCurrencies lists distinct currencies', () async {

      await controller.saveRecord(WealthRecord(

        date: DateTime(2026, 5, 1),

        assetType: WealthAssetType.cash,

        amount: 100,

        currency: 'USD',

        dateAdded: DateTime(2026, 5, 1),

      ));

      await controller.saveRecord(WealthRecord(

        date: DateTime(2026, 5, 1),

        assetType: WealthAssetType.cash,

        amount: 100,

        currency: 'TWD',

        dateAdded: DateTime(2026, 5, 1),

      ));

      expect(controller.getCurrencies(), ['TWD', 'USD']);

    });

  });



  // --------------------------------------------------------------------------

  // Persistence + isolation

  // --------------------------------------------------------------------------

  group('WealthController persistence', () {

    test('records survive store reload from disk', () async {

      final tempDir =

          await Directory.systemTemp.createTemp('wealth_persist_');

      final path = '${tempDir.path}${Platform.pathSeparator}vstore.json';

      try {

        final writer = VectorStore(storagePath: path);

        final c1 = WealthController(writer);

        await c1.saveRecord(WealthRecord(

          id: 'persist_me',

          date: DateTime(2026, 5, 1),

          assetType: WealthAssetType.fund,

          assetName: '0050.TW',

          amount: 50000,

          currency: 'TWD',

          dateAdded: DateTime(2026, 5, 1),

        ));



        final reader = VectorStore(storagePath: path);

        await reader.load();

        final c2 = WealthController(reader);



        await c2.loadAll();




        final all = c2.getAllRecords();

        expect(all, hasLength(1));

        expect(all.first.id, 'persist_me');

        expect(all.first.assetName, '0050.TW');

        expect(all.first.amount, 50000);

      } finally {

        if (await tempDir.exists()) {

          await tempDir.delete(recursive: true);

        }

      }

    });



    test('Wealth does not pollute other collections', () async {

      final tempDir =

          await Directory.systemTemp.createTemp('wealth_iso_');

      final path = '${tempDir.path}${Platform.pathSeparator}vstore.json';

      try {

        final store = VectorStore(storagePath: path);

        final controller = WealthController(store);



        await store.add(DocChunk(

          docName: 'book.epub',

          chunkIndex: 0,

          text: 'chapter content',

        ));

        await controller.saveRecord(WealthRecord(

          date: DateTime(2026, 5, 1),

          assetType: WealthAssetType.cash,

          amount: 100,

          dateAdded: DateTime(2026, 5, 1),

        ));



        expect(

          store.chunksInCollection('default'),

          hasLength(1),

        );

        expect(

          store.chunksInCollection(WealthController.kWealthCollection),

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

