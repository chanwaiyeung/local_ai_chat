import 'package:flutter/material.dart';

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

  late bool _useCustom;
  late String _selectedPreset;

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

    _loadInstalledModels();
  }

  @override
  void dispose() {
    _customController.dispose();
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
        const SnackBar(content: Text('請輸入 embedding model 名稱')),
      );
      return;
    }

    Navigator.of(context).pop(
      AppSettings(embeddingModel: model),
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
      message: installed ? '已安裝' : '未安裝，請先用 Ollama pull 此 model',
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
        title: const Text('Embedding 設定'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Embedding Model',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '目前使用：${widget.currentSettings.embeddingModel}',
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
                      title: const Text('使用自訂 embedding model'),
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
                          hintText: '例如：mxbai-embed-large',
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
                    Text('目前選擇：$currentModel'),
                    const SizedBox(height: 12),
                    const Text(
                      '注意：更換 embedding model 會清空目前 vector store，請重新匯入文件。',
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.save),
                      label: const Text('套用設定'),
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
