// lib/services/vector_store_path_flutter.dart

import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<Directory> vectorStoreSupportDirectory() {
  return getApplicationSupportDirectory();
}
