import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/app_settings.dart';
import '../services/currency_service.dart';
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
  final _officeBridgePortController = TextEditingController();
  final _officeBridgeTokenController = TextEditingController();
  final _officeBridgeModelController = TextEditingController();

  late bool _useCustom;
  late String _selectedPreset;
  late RetrievalMode _retrievalMode;
  late TtsMode _ttsMode;

  late bool _enableOfficeBridge;
  late String _officeBridgeLanguage;
  late List<String> _officeBridgeAllowedApps;

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
    _ttsMode = widget.currentSettings.ttsMode;
    _geminiApiKeyController.text = widget.currentSettings.geminiApiKey ?? '';
    _telegramBotTokenController.text = widget.currentSettings.telegramBotToken ?? '';
    _googleTtsApiKeyController.text = widget.currentSettings.googleTtsApiKey ?? '';

    _enableOfficeBridge = widget.currentSettings.enableOfficeBridge;
    _officeBridgePortController.text = widget.currentSettings.officeBridgePort.toString();
    _officeBridgeTokenController.text = widget.currentSettings.officeBridgeToken;
    _officeBridgeLanguage = widget.currentSettings.officeBridgeLanguage;
    _officeBridgeModelController.text = widget.currentSettings.officeBridgeModel;
    _officeBridgeAllowedApps = List<String>.from(widget.currentSettings.officeBridgeAllowedApps);

    _loadInstalledModels();
  }

  @override
  void dispose() {
    _customController.dispose();
    _geminiApiKeyController.dispose();
    _telegramBotTokenController.dispose();
    _googleTtsApiKeyController.dispose();
    _officeBridgePortController.dispose();
    _officeBridgeTokenController.dispose();
    _officeBridgeModelController.dispose();
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

  Future<void> _testGeminiConnection() async {
    final key = _geminiApiKeyController.text.trim();
    if (key.isEmpty) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsApiKeyRequired)),
      );
      return;
    }
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.settingsTestingConnection)),
    );
    try {
      final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$key');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': 'Hello'}]}]
        }),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 連線成功！')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ 連線失敗 (${response.statusCode})')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ 測試錯誤：$e')));
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

    final portVal = int.tryParse(_officeBridgePortController.text.trim()) ?? 61670;

    Navigator.of(context).pop(
      AppSettings(
        embeddingModel: model,
        retrievalMode: _retrievalMode,
        geminiApiKey: _geminiApiKeyController.text.trim().isEmpty ? null : _geminiApiKeyController.text.trim(),
        telegramBotToken: _telegramBotTokenController.text.trim().isEmpty ? null : _telegramBotTokenController.text.trim(),
        googleTtsApiKey: _googleTtsApiKeyController.text.trim().isEmpty ? null : _googleTtsApiKeyController.text.trim(),
        ttsMode: _ttsMode,
        enableOfficeBridge: _enableOfficeBridge,
        officeBridgePort: portVal,
        officeBridgeToken: _officeBridgeTokenController.text.trim(),
        officeBridgeLanguage: _officeBridgeLanguage,
        officeBridgeModel: _officeBridgeModelController.text.trim(),
        officeBridgeAllowedApps: _officeBridgeAllowedApps,
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
    final l10n = AppLocalizations.of(context);
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
                        ListTile(
              leading: const Icon(Icons.attach_money),
              title: Text(AppLocalizations.of(context).currency),
              trailing: ListenableBuilder(
                listenable: CurrencyService.instance,
                builder: (context, _) {
                  return DropdownButton<String>(
                    value: CurrencyService.instance.code,
                    items: CurrencyService.supported.map((c) {
                      final sym = CurrencyService.symbols[c] ?? c;
                      return DropdownMenuItem(
                        value: c,
                        child: Text('$sym  ($c)'),
                      );
                    }).toList(),
                    onChanged: (c) {
                      if (c != null) CurrencyService.instance.setCode(c);
                    },
                  );
                },
              ),
            ),
            const Divider(),
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
              l10n.settingsCloudAiTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.settingsCloudAiDesc,
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.network_check),
                            label: Text(l10n.settingsTestConnection),
                            onPressed: _testGeminiConnection,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.save),
                            label: Text(l10n.saveButton),
                            onPressed: _submit,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              l10n.settingsTelegramTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.settingsTelegramDesc,
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
                    const SizedBox(height: 24),
                    Text(
                      '語音合成模式',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TtsMode>(
                      initialValue: _ttsMode,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: '語音合成模式',
                        prefixIcon: Icon(Icons.settings_voice),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: TtsMode.auto,
                          child: Text('自動決策（推薦）'),
                        ),
                        DropdownMenuItem(
                          value: TtsMode.localOnly,
                          child: Text('僅本地（節省流量）'),
                        ),
                        DropdownMenuItem(
                          value: TtsMode.cloudOnly,
                          child: Text('高品質雲端（學習模式）'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _ttsMode = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Office Bridge 設定',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '整合 Microsoft Office (Word, Excel, PPT, Outlook) 與 WPS Office 本機伺服端設定',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SwitchListTile(
                      title: const Text('啟用 Office Bridge'),
                      subtitle: const Text('開啟或關閉本機 Office AI 整合伺服器'),
                      value: _enableOfficeBridge,
                      onChanged: (value) {
                        setState(() => _enableOfficeBridge = value);
                      },
                    ),
                    if (_enableOfficeBridge) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _officeBridgePortController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '本機 API 連接埠 (Port)',
                          hintText: '61670',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lan_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _officeBridgeTokenController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'API 安全認證 Token',
                          hintText: 'YOUR_LOCAL_TOKEN',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.security_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _officeBridgeLanguage,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '預設輸出語言',
                          prefixIcon: Icon(Icons.translate),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'zh-TW', child: Text('繁體中文 (zh-TW)')),
                          DropdownMenuItem(value: 'zh-CN', child: Text('簡體中文 (zh-CN)')),
                          DropdownMenuItem(value: 'en-US', child: Text('英文 (en-US)')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _officeBridgeLanguage = val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _officeBridgeModelController,
                        decoration: const InputDecoration(
                          labelText: '預設本機模型 (Ollama)',
                          hintText: 'local',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.smart_toy_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '允許連線的應用程式 (Allowed Apps)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['word', 'excel', 'ppt', 'outlook', 'wps'].map((app) {
                          final isSelected = _officeBridgeAllowedApps.contains(app);
                          return FilterChip(
                            label: Text(app.toUpperCase()),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _officeBridgeAllowedApps.add(app);
                                } else {
                                  _officeBridgeAllowedApps.remove(app);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
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




