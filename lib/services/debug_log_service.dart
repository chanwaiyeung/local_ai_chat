import 'dart:io';

import 'package:path_provider/path_provider.dart';

class DebugLogService {
  static const _fileName = 'rag_debug.log';
  static const _maxBytes = 1024 * 1024;
  static Future<void> _writeQueue = Future.value();

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

  static Future<void> append(
    String message, {
    String level = 'INFO',
    String? requestId,
    String? sessionId,
  }) {
    final write = _writeQueue.then(
      (_) => _appendNow(
        message,
        level: level,
        requestId: requestId,
        sessionId: sessionId,
      ),
    );

    _writeQueue = write.catchError((_) {
      // Logging must never break future log writes.
    });

    return write.catchError((_) {
      // Logging must never break app behavior.
    });
  }

  static Future<void> _rotateIfNeeded(File file) async {
    try {
      if (!await file.exists()) return;

      final length = await file.length();
      if (length <= _maxBytes) return;

      final archived = File('${file.path}.old');
      if (await archived.exists()) {
        await archived.delete();
      }

      try {
        await file.rename(archived.path);
      } catch (_) {
        await _copyAndTruncate(file, archived);
      }
    } catch (_) {
      // Rotation is best-effort; never let it stop logging.
    }
  }

  static Future<void> _appendNow(
    String message, {
    required String level,
    String? requestId,
    String? sessionId,
  }) async {
    final file = await logFile();
    await _rotateIfNeeded(file);

    final timestamp = DateTime.now().toUtc().toIso8601String();
    final meta = [
      if (requestId != null && requestId.trim().isNotEmpty)
        'requestId=${requestId.trim()}',
      if (sessionId != null && sessionId.trim().isNotEmpty)
        'sessionId=${sessionId.trim()}',
    ].join(' ');
    final normalizedLevel = level.trim().isEmpty ? 'INFO' : level.trim();
    final suffix = meta.isEmpty ? '' : ' $meta';

    await file.writeAsString(
      '[$timestamp][$normalizedLevel]$suffix $message\n',
      mode: FileMode.append,
      flush: true,
    );
  }

  static Future<void> _copyAndTruncate(File file, File archived) async {
    try {
      await file.copy(archived.path);
      await file.writeAsString('', flush: true);
    } catch (_) {
      // Last fallback: leave current log untouched.
    }
  }
}
