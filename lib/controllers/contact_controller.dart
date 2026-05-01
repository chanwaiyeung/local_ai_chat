// lib/controllers/contact_controller.dart

import 'package:flutter/foundation.dart';

import '../models/contact.dart';
import '../services/vector_store.dart';

class ContactController extends ChangeNotifier {
  ContactController({required this.store});

  final VectorStore store;
  final Map<String, Contact> _contacts = {};

  bool _isLoading = false;
  String? _lastError;

  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  int get contactCount => _contacts.length;

  List<Contact> get contacts {
    return List.unmodifiable(
      _contacts.values.toList()..sort((a, b) => a.name.compareTo(b.name)),
    );
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      _contacts
        ..clear()
        ..addEntries(
          store
              .chunksInCollection(kContactsCollection)
              .where((chunk) => chunk.metadata['type'] == kContactTypeTag)
              .map((chunk) {
            final contact = Contact.fromJson(chunk.metadata);
            return MapEntry(contact.id, contact);
          }),
        );
    } catch (e) {
      _lastError = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveContact(Contact contact) async {
    _lastError = null;
    await store.clear(contact.id, kContactsCollection);
    await store.addToCollection(
      kContactsCollection,
      DocChunk(
        docName: contact.id,
        chunkIndex: 0,
        text: contact.toSearchText(),
        collectionName: kContactsCollection,
        metadata: contact.toJson(),
      ),
      List<double>.filled(384, 0),
    );
    _contacts[contact.id] = contact;
    notifyListeners();
  }

  Future<void> deleteContact(String id) async {
    if (!_contacts.containsKey(id)) {
      throw ContactNotFoundException(id);
    }
    await store.clear(id, kContactsCollection);
    _contacts.remove(id);
    notifyListeners();
  }

  Future<List<Contact>> getAllContacts() async {
    await loadAll();
    return contacts;
  }

  Future<List<Contact>> searchContacts(String query) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return contacts;

    final results = _contacts.values
        .where((contact) => contact.toSearchText().toLowerCase().contains(
              normalized,
            ))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return results;
  }

  Contact parseOcrText(String text) {
    return Contact.fromOcrText(
      text,
      id: DateTime.now().microsecondsSinceEpoch.toString(),
    );
  }
}
