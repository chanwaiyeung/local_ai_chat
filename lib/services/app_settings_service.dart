import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/app_settings.dart';

class AppSettingsService {
  static const _fileName = 'app_settings.json';

  Future<File> _settingsFile() async {
    final dir = await getApplicationSupportDirectory();
    final appDir = Directory(
      '${dir.path}${Platform.pathSeparator}local_ai_chat',
    );

    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }

    return File('${appDir.path}${Platform.pathSeparator}$_fileName');
  }

  Future<AppSettings> load() async {
    final file = await _settingsFile();

    if (!await file.exists()) {
      return const AppSettings(
        embeddingModel: AppSettings.defaultEmbeddingModel,
      );
    }

    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return AppSettings.fromJson(json);
    } catch (_) {
      return const AppSettings(
        embeddingModel: AppSettings.defaultEmbeddingModel,
      );
    }
  }

  Future<void> save(AppSettings settings) async {
    final file = await _settingsFile();
    final tmp = File('${file.path}.tmp');

    const encoder = JsonEncoder.withIndent('  ');
    await tmp.writeAsString(encoder.convert(settings.toJson()), flush: true);

    if (await file.exists()) {
      await file.delete();
    }

    await tmp.rename(file.path);
  }
}
