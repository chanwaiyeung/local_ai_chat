// lib/services/secure_storage_service.dart
//
// Small wrapper around flutter_secure_storage for secrets used by the Flutter
// app. The service intentionally stays out of pure-Dart services such as
// VectorStore so CLI entry points can keep running under `dart run`.

import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'debug_log_service.dart';

class SecureStorageService {
  SecureStorageService._({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  static final SecureStorageService instance = SecureStorageService._();

  static const String _vectorStoreKeyName =
      'local_ai_chat_vector_store_aes256_key_v1';

  final FlutterSecureStorage _storage;
  final Map<String, String> _fallbackMemory = {};

  Future<void> init() async {
    await getEncryptionKey();
  }

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      await DebugLogService.append(
        'SecureStorageService: secure read failed for "$key"; '
        'using in-memory fallback. error=$e',
      );
      return _fallbackMemory[key];
    }
  }

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      await DebugLogService.append(
        'SecureStorageService: secure write failed for "$key"; '
        'using in-memory fallback. error=$e',
      );
      _fallbackMemory[key] = value;
    }
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      await DebugLogService.append(
        'SecureStorageService: secure delete failed for "$key"; '
        'clearing in-memory fallback only. error=$e',
      );
    } finally {
      _fallbackMemory.remove(key);
    }
  }

  Future<Uint8List> getEncryptionKey() async {
    final existing = await read(_vectorStoreKeyName);
    if (existing != null && existing.isNotEmpty) {
      final decoded = base64Decode(existing);
      if (decoded.length == 32) return Uint8List.fromList(decoded);
      await DebugLogService.append(
        'SecureStorageService: invalid vector store key length '
        '${decoded.length}; rotating key.',
      );
    }

    final key = encrypt.Key.fromSecureRandom(32).bytes;
    await write(_vectorStoreKeyName, base64Encode(key));
    return Uint8List.fromList(key);
  }
}
