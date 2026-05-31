// lib/screens/office_ai_screen.dart

import 'package:flutter/material.dart';

import '../main.dart';
import '../models/office_ai_request.dart';
import '../services/app_settings_service.dart';
import '../services/office_ai_service.dart';
import '../widgets/office/office_prompt_card.dart';

class OfficeAiScreen extends StatefulWidget {
  final String? initialApp;
  final String? initialTask;

  const OfficeAiScreen({
    super.key,
    this.initialApp,
    this.initialTask,
  });

  @override
  State<OfficeAiScreen> createState() => _OfficeAiScreenState();
}

class _OfficeAiScreenState extends State<OfficeAiScreen> {
  late final OfficeAiService _officeService;

  // Selected item in the toolbox (null means no task selected, 'settings' means settings page)
  String? _selectedApp;
  String? _selectedTask;
  bool _isSettingsSelected = false;

  // Sandbox inputs
  final TextEditingController _textController = TextEditingController();
  String _selectedTone = 'standard';
  String _selectedTarget = 'zh-TW';
  String _generatedResult = '';
  bool _isLoading = false;

  // Office Bridge Settings inputs
  bool _enableOfficeBridge = true;
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  String _defaultLanguage = 'zh-TW';
  List<String> _allowedApps = ['word', 'excel', 'ppt', 'outlook', 'wps'];

  final Map<String, String> _tones = {
    'standard': '標準 (Standard)',
    'formal': '正式 (Formal)',
    'casual': '親切/口語 (Casual)',
    'bulletPoints': '列點整理 (Bullet Points)',
  };

  final Map<String, String> _targets = {
    'zh-TW': '繁體中文 (zh-TW)',
    'zh-CN': '簡體中文 (zh-CN)',
    'en-US': '英文 (en-US)',
  };

  @override
  void initState() {
    super.initState();
    _officeService = OfficeAiService(generate: globalOllama.generate);
    _loadSettings();

    // Setup initial selection if passed
    if (widget.initialApp != null && widget.initialTask != null) {
      _selectedApp = widget.initialApp;
      _selectedTask = widget.initialTask;
      _isSettingsSelected = false;
    } else {
      // Default selection: Word Assistant -> Summarize
      _selectedApp = 'word';
      _selectedTask = 'summarize_doc';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _portController.dispose();
    _tokenController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final settings = await AppSettingsService().load();
    if (mounted) {
      setState(() {
        _enableOfficeBridge = settings.enableOfficeBridge;
        _portController.text = settings.officeBridgePort.toString();
        _tokenController.text = settings.officeBridgeToken;
        _defaultLanguage = settings.officeBridgeLanguage;
        _modelController.text = settings.officeBridgeModel;
        _allowedApps = List<String>.from(settings.officeBridgeAllowedApps);
      });
    }
  }

  Future<void> _saveSettings() async {
    final current = await AppSettingsService().load();
    final port = int.tryParse(_portController.text) ?? 61670;
    final token = _tokenController.text.trim();
    final model = _modelController.text.trim();

    final updated = current.copyWith(
      enableOfficeBridge: _enableOfficeBridge,
      officeBridgePort: port,
      officeBridgeToken: token,
      officeBridgeLanguage: _defaultLanguage,
      officeBridgeModel: model,
      officeBridgeAllowedApps: _allowedApps,
    );

    await AppSettingsService().save(updated);
    await startOrRestartServer(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Office Bridge 設定已儲存並重新啟動伺服器！')),
      );
    }
  }

  Future<void> _runAiRequest() async {
    if (_selectedApp == null || _selectedTask == null) return;

    setState(() {
      _isLoading = true;
      _generatedResult = '';
    });

    final request = OfficeAiRequest(
      app: _selectedApp!,
      task: _selectedTask!,
      text: _textController.text,
      tone: _selectedTone,
      target: _selectedTarget,
    );

    try {
      final stream = _officeService.askStream(request);
      await for (final delta in stream) {
        if (!mounted) return;
        setState(() {
          _generatedResult += delta;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _generatedResult = '執行時發生錯誤：\n$e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _selectTask(String app, String task) {
    setState(() {
      _selectedApp = app;
      _selectedTask = task;
      _isSettingsSelected = false;
      _generatedResult = '';
      _textController.clear();
    });
  }

  void _selectSettings() {
    setState(() {
      _selectedApp = null;
      _selectedTask = null;
      _isSettingsSelected = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final useSplitLayout = width > 720;

    final appTitle = 'Office AI 工具箱';

    Widget body;
    if (useSplitLayout) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Sidebar (Toolbox Menu)
          SizedBox(
            width: 280,
            child: Card(
              margin: const EdgeInsets.fromLTRB(16, 16, 8, 16),
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: _buildNavigationMenu(),
            ),
          ),
          // Right Workspace
          Expanded(
            child: Card(
              margin: const EdgeInsets.fromLTRB(8, 16, 16, 16),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: _buildWorkspace(),
            ),
          ),
        ],
      );
    } else {
      // Mobile single pane layout: if a task/settings is active, show workspace with a back button, otherwise show menu.
      body = _selectedTask != null || _isSettingsSelected
          ? Column(
              children: [
                AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _selectedApp = null;
                        _selectedTask = null;
                        _isSettingsSelected = false;
                      });
                    },
                  ),
                  title: Text(_isSettingsSelected
                      ? 'Office Bridge 設定'
                      : _getTaskLabel(_selectedApp!, _selectedTask!)),
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                ),
                Expanded(child: _buildWorkspace()),
              ],
            )
          : _buildNavigationMenu();
    }

    return Scaffold(
      appBar: (useSplitLayout || (_selectedTask == null && !_isSettingsSelected))
          ? AppBar(title: Text(appTitle))
          : null,
      body: body,
    );
  }

  String _getTaskLabel(String app, String task) {
    if (app == 'word') {
      if (task == 'summarize_doc') return '摘要文件';
      if (task == 'rewrite_tone') return '改寫語氣';
      if (task == 'meeting_notes') return '產生會議紀錄';
    } else if (app == 'excel') {
      if (task == 'analyze_table') return '分析表格';
      if (task == 'suggest_charts') return '產生圖表建議';
      if (task == 'monthly_report') return '月報摘要';
    } else if (app == 'ppt') {
      if (task == 'outline_presentation') return '大綱轉簡報';
      if (task == 'bible_study_ppt') return '教會查經簡報';
    } else if (app == 'outlook') {
      if (task == 'draft_reply') return '草擬回信';
      if (task == 'summarize_email') return '摘要郵件';
    }
    return task;
  }

  Widget _buildNavigationMenu() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildAssistantGroup(
          title: 'Word 助理',
          icon: Icons.description_outlined,
          color: Colors.blue.shade700,
          app: 'word',
          tasks: [
            {'task': 'summarize_doc', 'label': '摘要文件'},
            {'task': 'rewrite_tone', 'label': '改寫語氣'},
            {'task': 'meeting_notes', 'label': '產生會議紀錄'},
          ],
        ),
        _buildAssistantGroup(
          title: 'Excel 助理',
          icon: Icons.table_chart_outlined,
          color: Colors.green.shade700,
          app: 'excel',
          tasks: [
            {'task': 'analyze_table', 'label': '分析表格'},
            {'task': 'suggest_charts', 'label': '產生圖表建議'},
            {'task': 'monthly_report', 'label': '月報摘要'},
          ],
        ),
        _buildAssistantGroup(
          title: 'PowerPoint 助理',
          icon: Icons.slideshow_outlined,
          color: Colors.orange.shade700,
          app: 'ppt',
          tasks: [
            {'task': 'outline_presentation', 'label': '大綱轉簡報'},
            {'task': 'bible_study_ppt', 'label': '教會查經簡報'},
          ],
        ),
        _buildAssistantGroup(
          title: 'Outlook 助理',
          icon: Icons.mail_outline,
          color: Colors.indigo.shade700,
          app: 'outlook',
          tasks: [
            {'task': 'draft_reply', 'label': '草擬回信'},
            {'task': 'summarize_email', 'label': '摘要郵件'},
          ],
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.settings_ethernet, color: Colors.blueGrey),
          title: const Text('Office Bridge 設定', style: TextStyle(fontWeight: FontWeight.bold)),
          selected: _isSettingsSelected,
          selectedTileColor: Colors.blueGrey.withValues(alpha: 0.15),
          selectedColor: Colors.blueGrey.shade800,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onTap: _selectSettings,
        ),
      ],
    );
  }

  Widget _buildAssistantGroup({
    required String title,
    required IconData icon,
    required Color color,
    required String app,
    required List<Map<String, String>> tasks,
  }) {
    final isSelectedGroup = _selectedApp == app;

    return ExpansionTile(
      initiallyExpanded: isSelectedGroup,
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      children: tasks.map((t) {
        final isSelected = _selectedApp == app && _selectedTask == t['task'];
        return Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 8.0, bottom: 4.0),
          child: ListTile(
            dense: true,
            title: Text(t['label']!, style: const TextStyle(fontSize: 13)),
            selected: isSelected,
            selectedTileColor: color.withValues(alpha: 0.1),
            selectedColor: color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onTap: () => _selectTask(app, t['task']!),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWorkspace() {
    if (_isSettingsSelected) {
      return _buildSettingsWorkspace();
    }

    if (_selectedApp == null || _selectedTask == null) {
      return const Center(
        child: Text('請選擇左側選單的任務開始使用。', style: TextStyle(color: Colors.grey)),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '⚙️ 任務設定：${_getTaskLabel(_selectedApp!, _selectedTask!)}',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 20),
          // Configuration options
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedTone,
                  decoration: const InputDecoration(
                    labelText: '語氣與風格 (Tone)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _tones.entries.map((e) {
                    return DropdownMenuItem(value: e.key, child: Text(e.value));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedTone = val);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedTarget,
                  decoration: const InputDecoration(
                    labelText: '目標語言 (Target)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _targets.entries.map((e) {
                    return DropdownMenuItem(value: e.key, child: Text(e.value));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedTarget = val);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Text Input field
          Text(
            '📝 待處理文件內容',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _textController,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: '請貼上您想修改、精煉或編修的文字內容...',
              border: const OutlineInputBorder(),
              fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
              filled: true,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _textController.clear();
                    _generatedResult = '';
                  });
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('全部清空'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _runAiRequest,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.flash_on, color: Colors.white),
                label: Text(
                  _isLoading ? 'AI 處理中...' : '執行 AI 處理',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Output Result Card
          OfficePromptCard(
            title: '✨ AI 生成結果',
            content: _generatedResult,
            isLoading: _isLoading,
            onClear: () {
              setState(() {
                _generatedResult = '';
              });
            },
            appName: _selectedApp,
            taskName: _getTaskLabel(_selectedApp!, _selectedTask!),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsWorkspace() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '⚙️ Office Bridge 設定',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Divider(height: 20),
          SwitchListTile(
            title: const Text('啟用 Office Bridge 伺服器'),
            subtitle: const Text('開啟後可供 Excel VBA 巨集或 Word JavaScript Add-in 連線呼叫本機 AI'),
            value: _enableOfficeBridge,
            onChanged: (val) {
              setState(() {
                _enableOfficeBridge = val;
              });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _portController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '本機 API Port',
              hintText: '預設 61670',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tokenController,
            decoration: const InputDecoration(
              labelText: 'API 驗證 Token (Authorization Bearer)',
              hintText: '防範未授權的呼叫，預設為 YOUR_LOCAL_TOKEN',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _modelController,
            decoration: const InputDecoration(
              labelText: '預設大語言模型',
              hintText: '留空表示使用本機 Ollama 預設模型',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _defaultLanguage,
            decoration: const InputDecoration(
              labelText: '預設語言',
              border: OutlineInputBorder(),
            ),
            items: _targets.entries.map((e) {
              return DropdownMenuItem(value: e.key, child: Text(e.value));
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _defaultLanguage = val);
              }
            },
          ),
          const SizedBox(height: 16),
          const Text('允許的應用程式 (Allowed Apps)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: ['word', 'excel', 'ppt', 'outlook', 'wps'].map((app) {
              final isAllowed = _allowedApps.contains(app);
              return FilterChip(
                label: Text(app.toUpperCase()),
                selected: isAllowed,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _allowedApps.add(app);
                    } else {
                      _allowedApps.remove(app);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('儲存並套用設定', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}


