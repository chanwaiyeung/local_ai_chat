import 'dart:io';

import 'package:path_provider/path_provider.dart';

class DebugLogService {
  static const _fileName = 'rag_debug.log';
  static const _maxBytes = 1024 * 1024;

  static Future<File> logFile() async {
    final dir = await getApplicationSupportDirectory();
    final appDir = Directory(
      '${dir.path}${Platform.pathSeparator}local_ai_chat',
    );

    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }

    return File('${appDir.path}${Platform.pathSeparator}$_fileName');
  }

  static Future<void> append(String message) async {
    try {
      final file = await logFile();
      await _rotateIfNeeded(file);
      final timestamp = DateTime.now().toIso8601String();
      await file.writeAsString(
        '[$timestamp] $message\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {
      // Logging must never break app behavior.
    }
  }

  static Future<void> _rotateIfNeeded(File file) async {
    if (!await file.exists()) return;

    final length = await file.length();
    if (length <= _maxBytes) return;

    final archived = File('${file.path}.old');
    if (await archived.exists()) {
      await archived.delete();
    }
    await file.rename(archived.path);
  }
}
