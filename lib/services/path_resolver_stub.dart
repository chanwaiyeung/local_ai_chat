import 'dart:io';

Future<Directory> getAppSupportDirectory() async {
  // Headless CLI fallback using a local 'data' folder
  final dir = Directory('data');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}


