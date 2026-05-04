import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/app_settings.dart';
import '../services/ollama_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.currentSettings,
  });

  final AppSettings currentSettings;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _presetModels = [
    'nomic-embed-text',
    'bge-m3',
  ];

  final _customController = TextEditingController();
  final _geminiApiKeyController = TextEditingController();
  final _telegramBotTokenController = TextEditingController();
  final _googleTtsApiKeyController = TextEditingController();

  late bool _useCustom;
  late String _selectedPreset;
  late RetrievalMode _retrievalMode;

  bool _loadingModels = true;
  Set<String> _installedModels = const {};

  @override
  void initState() {
    super.initState();

    final current = widget.currentSettings.embeddingModel;

    if (_presetModels.contains(current)) {
      _useCustom = false;
      _selectedPreset = current;
    } else {
      _useCustom = true;
      _selectedPreset = AppSettings.defaultEmbeddingModel;
      _customController.text = current;
    }
    _retrievalMode = widget.currentSettings.retrievalMode;
    _geminiApiKeyController.text = widget.currentSettings.geminiApiKey ?? '';
    _telegramBotTokenController.text = widget.currentSettings.telegramBotToken ?? '';
    _googleTtsApiKeyController.text = widget.currentSettings.googleTtsApiKey ?? '';

    _loadInstalledModels();
  }

  @override
  void dispose() {
    _customController.dispose();
    _geminiApiKeyController.dispose();
    _telegramBotTokenController.dispose();
    _googleTtsApiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadInstalledModels() async {
    debugPrint('SettingsScreen: loading installed Ollama models');
    try {
      final models = await OllamaService().listModels();
      if (!mounted) return;
      setState(() {
        _installedModels = models.toSet();
        _loadingModels = false;
      });
      debugPrint('SettingsScreen: loaded ${models.length} models');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _installedModels = const {};
        _loadingModels = false;
      });
      debugPrint('SettingsScreen: failed to load installed models');
    }
  }

  void _submit() {
    final model = _useCustom ? _customController.text.trim() : _selectedPreset;

    if (model.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).enterEmbeddingModelName)),
      );
      return;
    }

    Navigator.of(context).pop(
      AppSettings(
        embeddingModel: model,
        retrievalMode: _retrievalMode,
        geminiApiKey: _geminiApiKeyController.text.trim().isEmpty ? null : _geminiApiKeyController.text.trim(),
        telegramBotToken: _telegramBotTokenController.text.trim().isEmpty ? null : _telegramBotTokenController.text.trim(),
        googleTtsApiKey: _googleTtsApiKeyController.text.trim().isEmpty ? null : _googleTtsApiKeyController.text.trim(),
      ),
    );
  }

  bool _isInstalled(String model) {
    return _installedModels.any((installed) {
      if (installed == model) return true;
      if (!model.contains(':') && installed == '$model:latest') return true;
      if (!model.contains(':') && installed.split(':').first == model) {
        return true;
      }
      return false;
    });
  }

  Widget _modelStatus(String model) {
    if (_loadingModels) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final installed = _isInstalled(model);
    return Tooltip(
      message: installed ? AppLocalizations.of(context).modelInstalled : AppLocalizations.of(context).modelNotInstalled,
      child: Icon(
        installed ? Icons.check_circle_outline : Icons.warning_amber_outlined,
        size: 18,
        color: installed ? Colors.green : Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentModel =
        _useCustom ? _customController.text.trim() : _selectedPreset;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).embeddingSettings),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(AppLocalizations.of(context).language),
              trailing: DropdownButton<Locale>(
                value: [
                  const Locale('zh', 'TW'),
                  const Locale('zh', 'CN'),
                  const Locale('en')
                ].firstWhere(
                  (l) => l == Localizations.localeOf(context),
                  orElse: () => [
                    const Locale('zh', 'TW'),
                    const Locale('zh', 'CN'),
                    const Locale('en')
                  ].firstWhere(
                    (l) => l.languageCode == Localizations.localeOf(context).languageCode,
                    orElse: () => const Locale('en'),
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: const Locale('zh', 'TW'),
                    child: Text(AppLocalizations.of(context).languageZhTw),
                  ),
                  DropdownMenuItem(
                    value: const Locale('zh', 'CN'),
                    child: Text(AppLocalizations.of(context).languageZhCn),
                  ),
                  DropdownMenuItem(
                    value: const Locale('en'),
                    child: Text(AppLocalizations.of(context).languageEn),
                  ),
                ],
                onChanged: (l) {
                  if (l != null) MyApp.of(context)?.setLocale(l);
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.palette),
              title: Text(AppLocalizations.of(context).appearance),
              trailing: DropdownButton<ThemeMode>(
                value: MyApp.of(context)?.themeMode ?? ThemeMode.system,
                items: [
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text(AppLocalizations.of(context).systemDefault),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text(AppLocalizations.of(context).lightMode),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text(AppLocalizations.of(context).darkMode),
                  ),
                ],
                onChanged: (m) {
                  if (m != null) MyApp.of(context)?.setThemeMode(m);
                },
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Cloud AI 服務 (Gemini)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '設定您的 API Key 以啟用「雲端大模型教導本地小模型」功能。這將被妥善保存在本機。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Google Gemini API Key',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _geminiApiKeyController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'API Key',
                        hintText: 'AIzaSy...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.key),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Telegram 整合',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '設定您的 Telegram Bot Token，讓 Local AI 成為您的隨身助理。可從 @BotFather 取得。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Telegram Bot Token',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _telegramBotTokenController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Bot Token',
                        hintText: '123456789:ABCdefGHI...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.telegram),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Google Cloud TTS API Key',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _googleTtsApiKeyController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'TTS API Key',
                        hintText: 'AIzaSy...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.record_voice_over),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Embedding Model',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              AppLocalizations.of(context).currentSelection(widget.currentSettings.embeddingModel),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '${AppLocalizations.of(context).retrievalMode}：${widget.currentSettings.retrievalMode.name}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Embedding Model',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: Text(AppLocalizations.of(context).useCustomEmbeddingModel),
                      value: _useCustom,
                      onChanged: (value) {
                        setState(() => _useCustom = value);
                      },
                    ),
                    if (!_useCustom) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _presetModels.map((model) {
                          return FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(model),
                                const SizedBox(width: 8),
                                _modelStatus(model),
                              ],
                            ),
                            selected: _selectedPreset == model,
                            onSelected: (_) {
                              setState(() => _selectedPreset = model);
                            },
                          );
                        }).toList(),
                      ),
                    ] else
                      TextField(
                        controller: _customController,
                        decoration: InputDecoration(
                          labelText: 'Custom embedding model',
                          hintText: AppLocalizations.of(context).customModelHint,
                          border: const OutlineInputBorder(),
                          suffixIcon: currentModel.isEmpty
                              ? null
                              : Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: _modelStatus(currentModel),
                                ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    const SizedBox(height: 12),
                    Text(AppLocalizations.of(context).currentSelection(currentModel)),
                    const SizedBox(height: 12),
                    Text(AppLocalizations.of(context).changeModelWarning),
                    const SizedBox(height: 24),
                      Text(
                        AppLocalizations.of(context).retrievalMode,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<RetrievalMode>(
                      initialValue: _retrievalMode,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: AppLocalizations.of(context).retrievalMode,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: RetrievalMode.dense,
                          child: Text(AppLocalizations.of(context).denseMode),
                        ),
                        DropdownMenuItem(
                          value: RetrievalMode.sparse,
                          child: Text(AppLocalizations.of(context).sparseMode),
                        ),
                        DropdownMenuItem(
                          value: RetrievalMode.hybrid,
                          child: Text(AppLocalizations.of(context).hybridMode),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _retrievalMode = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.save),
                      label: Text(AppLocalizations.of(context).applySettings),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
