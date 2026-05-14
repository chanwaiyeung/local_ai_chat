// lib/controllers/church/person_controller.dart
import 'package:flutter/foundation.dart';
import '../../models/church/person.dart';
import '../../services/vector_store.dart';

class PersonController extends ChangeNotifier {
  PersonController(this._store);

  static const String kCollection = 'ChurchPersons';
  static const String kTypeTag = 'church_person';

  final VectorStore _store;
  List<Person> _persons = const [];
  bool _loaded = false;

  Future<void> loadAll() async {
    final persons = <Person>[];
    for (final c in _store.chunks) {
      if (c.collectionName == kCollection &&
          c.metadata['type'] == kTypeTag) {
        final data = c.metadata['data'];
        if (data is! Map) continue;
        try {
          persons.add(Person.fromJson(Map<String, dynamic>.from(data)));
        } catch (_) {}
      }
    }
    persons.sort((a, b) => a.name.compareTo(b.name));
    _persons = List.unmodifiable(persons);
    _loaded = true;
    notifyListeners();
  }

  bool get isLoaded => _loaded;

  List<Person> get allPersons => _persons;
  int get totalCount => _persons.length;
  int get regularCount => _persons
      .where((p) => p.attendance == AttendanceStatus.regular).length;
  int get occasionalCount => _persons
      .where((p) => p.attendance == AttendanceStatus.occasional).length;
  int get inactiveCount => _persons
      .where((p) => p.attendance == AttendanceStatus.inactive).length;
  int get seekerCount => _persons
      .where((p) => p.personType == PersonType.seeker).length;
  int get memberCount => _persons
      .where((p) => p.personType == PersonType.member).length;
  int get memberRegularCount => _persons.where((p) =>
      p.personType == PersonType.member &&
      p.attendance == AttendanceStatus.regular).length;
  int get memberOccasionalCount => _persons.where((p) =>
      p.personType == PersonType.member &&
      p.attendance == AttendanceStatus.occasional).length;
  int get memberInactiveCount => _persons.where((p) =>
      p.personType == PersonType.member &&
      p.attendance == AttendanceStatus.inactive).length;
  int get seekerRegularCount => _persons.where((p) =>
      p.personType == PersonType.seeker &&
      p.attendance == AttendanceStatus.regular).length;
  int get seekerOccasionalCount => _persons.where((p) =>
      p.personType == PersonType.seeker &&
      p.attendance == AttendanceStatus.occasional).length;
  int get seekerInactiveCount => _persons.where((p) =>
      p.personType == PersonType.seeker &&
      p.attendance == AttendanceStatus.inactive).length;

  Person? findPerson(String id) {
    for (final p in _persons) {
      if (p.id == id) return p;
    }
    return null;
  }

  Person? findByName(String name) {
    final trimmed = name.trim();
    for (final p in _persons) {
      if (p.name == trimmed) return p;
    }
    return null;
  }

  List<Person> searchPersons(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _persons;
    return _persons
        .where((p) => p.toSearchText().toLowerCase().contains(q))
        .toList();
  }

  Future<Person> savePerson(Person personObj) async {
    final isNew = personObj.id.isEmpty;
    final finalPerson =
        isNew ? personObj.copyWith(id: _generatePersonId()) : personObj;

    if (!isNew) {
      await _store.deleteById(finalPerson.id);
    }

    final chunk = DocChunk(
      id: finalPerson.id,
      docName: 'person_${finalPerson.id}',
      chunkIndex: 0,
      text: finalPerson.toSearchText(),
      embedding: const [],
      collectionName: kCollection,
      metadata: {
        'type': kTypeTag,
        'data': finalPerson.toJson(),
      },
    );

    await _store.add(chunk);
    await _store.save();
    await loadAll();
    return finalPerson;
  }

  Future<void> deletePerson(String personId) async {
    await _store.deleteById(personId);
    await _store.save();
    await loadAll();
  }

  String _generatePersonId() =>
      'person_${DateTime.now().microsecondsSinceEpoch}';
}