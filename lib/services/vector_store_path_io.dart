// lib/services/vector_store_path_io.dart

import 'dart:io';

Future<Directory> vectorStoreSupportDirectory() async {
  final dir = Directory('data');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}
