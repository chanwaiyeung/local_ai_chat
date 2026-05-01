// lib/models/contact.dart

class InvalidContactException implements Exception {
  const InvalidContactException(this.message);

  final String message;

  @override
  String toString() => 'InvalidContactException: $message';
}

class ContactNotFoundException implements Exception {
  const ContactNotFoundException(this.id);

  final String id;

  @override
  String toString() => 'ContactNotFoundException: "$id" not found.';
}

const String kContactsCollection = 'Contacts';
const String kContactTypeTag = 'personal_hub_contact';

class Contact {
  Contact({
    required this.id,
    required this.name,
    this.company = '',
    this.title = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.website = '',
    List<String>? tags,
    this.notes = '',
    DateTime? scannedAt,
  })  : tags = List.unmodifiable(tags ?? const []),
        scannedAt = (scannedAt ?? DateTime.now()).toUtc() {
    if (name.trim().isEmpty) {
      throw const InvalidContactException('Contact name must not be empty.');
    }
  }

  final String id;
  final String name;
  final String company;
  final String title;
  final String phone;
  final String email;
  final String address;
  final String website;
  final List<String> tags;
  final String notes;
  final DateTime scannedAt;

  Map<String, dynamic> toJson() => {
        'type': kContactTypeTag,
        'id': id,
        'name': name,
        'company': company,
        'title': title,
        'phone': phone,
        'email': email,
        'address': address,
        'website': website,
        'tags': List<String>.from(tags),
        'notes': notes,
        'scannedAt': scannedAt.toIso8601String(),
      };

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      company: json['company'] as String? ?? '',
      title: json['title'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      address: json['address'] as String? ?? '',
      website: json['website'] as String? ?? '',
      tags: (json['tags'] as List? ?? const [])
          .map((tag) => tag.toString())
          .toList(),
      notes: json['notes'] as String? ?? '',
      scannedAt: _parseDate(json['scannedAt']),
    );
  }

  String toSearchText() {
    return [
      name,
      title,
      company,
      phone,
      email,
      address,
      website,
      tags.join(' '),
      notes,
    ].where((value) => value.trim().isNotEmpty).join(' | ');
  }

  static Contact fromOcrText(String ocrText, {required String id}) {
    final lines = ocrText
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final emailRe = RegExp(
      r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}',
      caseSensitive: false,
    );
    final urlRe = RegExp(
      r'(?:https?://|www\.)[^\s]+',
      caseSensitive: false,
    );
    final phoneRe = RegExp(r'(?:\+?\d[\d\s().-]{6,}\d)');

    var email = '';
    var website = '';
    var phone = '';
    final identityLines = <String>[];

    for (final line in lines) {
      final emailMatch = emailRe.firstMatch(line);
      if (email.isEmpty && emailMatch != null) {
        email = emailMatch.group(0) ?? '';
        continue;
      }

      final urlMatch = urlRe.firstMatch(line);
      if (website.isEmpty && urlMatch != null) {
        website = urlMatch.group(0) ?? '';
        continue;
      }

      final phoneMatch = phoneRe.firstMatch(line);
      if (phone.isEmpty && phoneMatch != null) {
        phone = (phoneMatch.group(0) ?? '').trim();
        continue;
      }

      identityLines.add(line);
    }

    var name = '';
    var title = '';
    var company = '';
    for (final line in identityLines) {
      final wordCount = line.split(RegExp(r'\s+')).length;
      if (name.isEmpty && wordCount <= 4) {
        name = line;
      } else if (title.isEmpty && wordCount <= 6) {
        title = line;
      } else if (company.isEmpty) {
        company = line;
      }
    }

    return Contact(
      id: id,
      name: name.isEmpty ? (lines.isEmpty ? 'Unknown' : lines.first) : name,
      company: company,
      title: title,
      phone: phone,
      email: email,
      website: website,
    );
  }

  static DateTime _parseDate(Object? raw) {
    if (raw is String) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed.toUtc();
    }
    return DateTime.now().toUtc();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Contact &&
        id == other.id &&
        name == other.name &&
        company == other.company &&
        title == other.title &&
        phone == other.phone &&
        email == other.email &&
        address == other.address &&
        website == other.website &&
        _listEquals(tags, other.tags) &&
        notes == other.notes;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        company,
        title,
        phone,
        email,
        address,
        website,
        Object.hashAll(tags),
        notes,
      );

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
