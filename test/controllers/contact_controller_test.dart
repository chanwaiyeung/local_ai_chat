import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/controllers/contact_controller.dart';
import 'package:local_ai_chat/models/contact.dart';
import 'package:local_ai_chat/services/vector_store.dart';

void main() {
  group('Contact model', () {
    test('toJson/fromJson round-trip preserves fields', () {
      final contact = _contact(
        id: 'c1',
        name: 'Ada Lovelace',
        company: 'Analytical Engines',
        title: 'Founder',
        phone: '+1 555 0100',
        email: 'ada@example.com',
        address: 'London',
        website: 'https://example.com',
        tags: ['math', 'vip'],
        notes: 'First programmer',
      );

      expect(Contact.fromJson(contact.toJson()), contact);
    });

    test('scannedAt is excluded from equality and hashCode', () {
      final a = _contact(
        id: 'c1',
        name: 'Ada',
        scannedAt: DateTime.utc(2024),
      );
      final b = _contact(
        id: 'c1',
        name: 'Ada',
        scannedAt: DateTime.utc(2025),
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('missing optional json fields use safe defaults', () {
      final contact = Contact.fromJson({'id': 'c1', 'name': 'Ada'});

      expect(contact.company, '');
      expect(contact.title, '');
      expect(contact.phone, '');
      expect(contact.email, '');
      expect(contact.address, '');
      expect(contact.website, '');
      expect(contact.tags, isEmpty);
      expect(contact.notes, '');
    });

    test('empty name throws InvalidContactException', () {
      expect(
        () => Contact(id: 'c1', name: ' '),
        throwsA(isA<InvalidContactException>()),
      );
    });

    test('toSearchText concatenates human-readable fields', () {
      final text = _contact(
        id: 'c1',
        name: 'Ada',
        company: 'Engines',
        title: 'Founder',
        tags: ['math'],
        notes: 'VIP',
      ).toSearchText();

      expect(text, contains('Ada'));
      expect(text, contains('Engines'));
      expect(text, contains('Founder'));
      expect(text, contains('math'));
      expect(text, contains('VIP'));
    });

    test('fromOcrText extracts email phone website and identity lines', () {
      final contact = Contact.fromOcrText(
        '''
Ada Lovelace
Chief Scientist
Analytical Engines Ltd
+1 (555) 010-2000
ada@example.com
www.example.com
''',
        id: 'ocr1',
      );

      expect(contact.name, 'Ada Lovelace');
      expect(contact.title, 'Chief Scientist');
      expect(contact.company, 'Analytical Engines Ltd');
      expect(contact.phone, '+1 (555) 010-2000');
      expect(contact.email, 'ada@example.com');
      expect(contact.website, 'www.example.com');
    });

    test('fromOcrText falls back to Unknown for blank OCR', () {
      final contact = Contact.fromOcrText('', id: 'ocr1');

      expect(contact.name, 'Unknown');
    });
  });

  group('ContactController', () {
    test('saveContact stores a contact in Contacts collection', () async {
      final store = VectorStore();
      final controller = ContactController(store: store);
      final contact = _contact(id: 'c1', name: 'Ada');

      await controller.saveContact(contact);

      expect(controller.contactCount, 1);
      expect(store.chunksInCollection(kContactsCollection), hasLength(1));
      expect(store.chunksInCollection(kContactsCollection).single.metadata,
          containsPair('type', kContactTypeTag));
    });

    test('loadAll hydrates contacts from VectorStore metadata', () async {
      final store = VectorStore();
      final contact = _contact(id: 'c1', name: 'Ada');
      await store.addToCollection(
        kContactsCollection,
        DocChunk(
          docName: contact.id,
          chunkIndex: 0,
          text: contact.toSearchText(),
          collectionName: kContactsCollection,
          metadata: contact.toJson(),
        ),
      );

      final controller = ContactController(store: store);
      await controller.loadAll();

      expect(controller.contacts, [contact]);
    });

    test('loadAll ignores non-contact metadata in Contacts collection',
        () async {
      final store = VectorStore();
      await store.addToCollection(
        kContactsCollection,
        DocChunk(
          docName: 'note1',
          chunkIndex: 0,
          text: 'not a contact',
          collectionName: kContactsCollection,
          metadata: const {'type': 'note'},
        ),
      );

      final controller = ContactController(store: store);
      await controller.loadAll();

      expect(controller.contacts, isEmpty);
    });

    test('saveContact replaces existing contact with same id', () async {
      final store = VectorStore();
      final controller = ContactController(store: store);

      await controller.saveContact(_contact(id: 'c1', name: 'Ada'));
      await controller.saveContact(_contact(id: 'c1', name: 'Ada Updated'));

      expect(controller.contacts.single.name, 'Ada Updated');
      expect(store.chunksInCollection(kContactsCollection), hasLength(1));
    });

    test('deleteContact removes contact and vector chunk', () async {
      final store = VectorStore();
      final controller = ContactController(store: store);
      await controller.saveContact(_contact(id: 'c1', name: 'Ada'));

      await controller.deleteContact('c1');

      expect(controller.contacts, isEmpty);
      expect(store.chunksInCollection(kContactsCollection), isEmpty);
    });

    test('deleteContact throws ContactNotFoundException for unknown id',
        () async {
      final controller = ContactController(store: VectorStore());

      expect(
        () => controller.deleteContact('missing'),
        throwsA(isA<ContactNotFoundException>()),
      );
    });

    test('searchContacts returns matching contacts only', () async {
      final controller = ContactController(store: VectorStore());
      await controller.saveContact(_contact(id: 'c1', name: 'Ada'));
      await controller.saveContact(_contact(id: 'c2', name: 'Grace'));

      final results = await controller.searchContacts('ada');

      expect(results.map((c) => c.id), ['c1']);
    });

    test('searchContacts blank query returns all sorted contacts', () async {
      final controller = ContactController(store: VectorStore());
      await controller.saveContact(_contact(id: 'c2', name: 'Grace'));
      await controller.saveContact(_contact(id: 'c1', name: 'Ada'));

      final results = await controller.searchContacts('  ');

      expect(results.map((c) => c.name), ['Ada', 'Grace']);
    });

    test('parseOcrText delegates to Contact OCR parser', () {
      final controller = ContactController(store: VectorStore());

      final contact = controller.parseOcrText('Ada Lovelace\nada@example.com');

      expect(contact.name, 'Ada Lovelace');
      expect(contact.email, 'ada@example.com');
      expect(contact.id, isNotEmpty);
    });

    test('notifies listeners on save and delete', () async {
      final controller = ContactController(store: VectorStore());
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.saveContact(_contact(id: 'c1', name: 'Ada'));
      await controller.deleteContact('c1');

      expect(notifications, 2);
    });

    test('getAllContacts loads and returns contacts', () async {
      final store = VectorStore();
      final controller = ContactController(store: store);
      await controller.saveContact(_contact(id: 'c1', name: 'Ada'));

      final fresh = ContactController(store: store);
      final contacts = await fresh.getAllContacts();

      expect(contacts.map((c) => c.name), ['Ada']);
    });
  });

  group('Contact VectorStore integration', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('contact-store-');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Contacts collection is isolated from default collection search',
        () async {
      final store = VectorStore();
      final contact = _contact(id: 'c1', name: 'Ada Lovelace');
      await ContactController(store: store).saveContact(contact);
      await store.add(
        DocChunk(docName: 'default', chunkIndex: 0, text: 'Ada'),
        List<double>.filled(384, 0),
      );

      final query = List<double>.filled(384, 0);
      final defaultHits = store.search(query, topK: 10);
      final contactHits = store.search(
        query,
        topK: 10,
        collectionName: kContactsCollection,
      );

      expect(defaultHits.map((hit) => hit.chunk.docName), ['default']);
      expect(contactHits.map((hit) => hit.chunk.docName), ['c1']);
    });

    test('Contact metadata persists through save/load', () async {
      final path = '${tempDir.path}${Platform.pathSeparator}vectors.json';
      final contact = _contact(id: 'c1', name: 'Ada Lovelace');
      final store = VectorStore(storagePath: path);
      await ContactController(store: store).saveContact(contact);

      final reloadedStore = VectorStore(storagePath: path);
      await reloadedStore.load();
      final controller = ContactController(store: reloadedStore);
      await controller.loadAll();

      expect(controller.contacts, [contact]);
      expect(
          reloadedStore
              .chunksInCollection(kContactsCollection)
              .single
              .collectionName,
          kContactsCollection);
    });

    test('legacy chunks without collectionName load into default collection',
        () async {
      final path = '${tempDir.path}${Platform.pathSeparator}vectors.json';
      final file = File(path);
      await file.writeAsString('''
{
  "schemaVersion": 3,
  "chunks": [
    {
      "id": "legacy",
      "docName": "legacy.txt",
      "chunkIndex": 0,
      "text": "legacy text",
      "embedding": [1.0]
    }
  ]
}
''');

      final store = VectorStore(storagePath: path);
      await store.load();

      expect(store.chunksInCollection('default'), hasLength(1));
      expect(store.chunksInCollection(kContactsCollection), isEmpty);
    });
  });
}

Contact _contact({
  required String id,
  required String name,
  String company = '',
  String title = '',
  String phone = '',
  String email = '',
  String address = '',
  String website = '',
  List<String> tags = const [],
  String notes = '',
  DateTime? scannedAt,
}) {
  return Contact(
    id: id,
    name: name,
    company: company,
    title: title,
    phone: phone,
    email: email,
    address: address,
    website: website,
    tags: tags,
    notes: notes,
    scannedAt: scannedAt ?? DateTime.utc(2026),
  );
}


