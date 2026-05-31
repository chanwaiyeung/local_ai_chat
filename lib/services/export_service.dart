// lib/services/export_service.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/message.dart';

class ExportService {
  /// 將對話轉成 Markdown 字串
  static String toMarkdown(
    List<ChatMessage> messages, {
    String title = 'AI 對話記錄',
  }) {
    final now = DateTime.now();
    final ts =
        '${now.year}-${_pad(now.month)}-${_pad(now.day)} ${_pad(now.hour)}:${_pad(now.minute)}';

    final sb = StringBuffer()
      ..writeln('# $title')
      ..writeln()
      ..writeln('> 匯出時間：$ts')
      ..writeln();

    for (final m in messages) {
      switch (m.role) {
        case Role.system:
          sb
            ..writeln('---')
            ..writeln('**[系統]**')
            ..writeln()
            ..writeln('> ${m.content.replaceAll("\n", "\n> ")}')
            ..writeln();
          break;
        case Role.user:
          sb
            ..writeln('## 🧑 用戶')
            ..writeln()
            ..writeln(m.content)
            ..writeln();
          break;
        case Role.assistant:
          sb
            ..writeln('## 🤖 助手')
            ..writeln()
            ..writeln(m.content)
            ..writeln();
          break;
      }
    }
    return sb.toString();
  }

  /// 彈出儲存對話框、寫入檔案，回傳檔案路徑（取消則 null）
  /// 部分平台 (e.g. iOS) 唔支援 saveFile，會 fallback 寫去 Documents。
  static Future<String?> saveAs({
    required List<ChatMessage> messages,
    String defaultName = 'chat_export',
  }) async {
    final md = toMarkdown(messages);
    final ts =
        DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final suggested = '${defaultName}_$ts.md';

    String? path;
    bool platformUnsupported = false;
    try {
      path = await FilePicker.platform.saveFile(
        dialogTitle: '匯出對話為 Markdown',
        fileName: suggested,
        type: FileType.custom,
        allowedExtensions: ['md'],
      );
      // path == null 即係用戶按咗取消（Windows / macOS / Linux 都會係咁）
    } on UnimplementedError {
      // 部分平台（iOS / Android）file_picker 唔支援 saveFile
      platformUnsupported = true;
    } catch (_) {
      platformUnsupported = true;
    }

    // 用戶取消 → 中止匯出，唔好默默寫去其他位置
    if (path == null && !platformUnsupported) return null;

    // 平台唔支援 → 落 Documents
    if (path == null) {
      final dir = await getApplicationDocumentsDirectory();
      path = '${dir.path}/$suggested';
    }

    // Windows 嘅 saveFile 可能唔自動加副檔名，補上去確保正確
    if (!path.toLowerCase().endsWith('.md')) {
      path = '$path.md';
    }

    final file = File(path);
    await file.writeAsString(md);
    return path;
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}


