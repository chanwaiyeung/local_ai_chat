// lib/screens/library_screen.dart
import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/network_service.dart';
import 'reader_screen.dart';
import 'reading_mode_screen.dart';

class LibraryScreen extends StatefulWidget {
  /// Inject a [ReaderApi] for tests; production code can leave this null
  /// to use the default client.
  final ReaderApi? apiClient;

  const LibraryScreen({super.key, this.apiClient});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late final ReaderApi _api;
  final TextEditingController _ipController = TextEditingController();
  List<String> _docs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = widget.apiClient ?? ApiClient();
    _autoDetectAndConnect();
  }

  /// On desktop platforms, try to point the API client at this host's
  /// LAN IP so the displayed URL matches what a phone on the same Wi-Fi
  /// would dial. If detection fails, we fall back silently to whatever
  /// `ApiClient` chose by default (`127.0.0.1` on desktop, `10.0.2.2`
  /// on Android emulator). Either way we always proceed to load docs.
  ///
  /// Skipped if a custom `apiClient` was injected (test mode), so widget
  /// tests don't hit `dart:io NetworkInterface`.
  Future<void> _autoDetectAndConnect() async {
    final injected = widget.apiClient != null;
    if (!injected) {
      try {
        final ip = await NetworkService.getLocalIp();
        final api = _api;
        if (ip != null && api is ApiClient) {
          api.updateBaseUrl('http://$ip:8080');
        }
      } catch (_) {
        // Ignore detection failures; default base URL still works.
      }
    }
    if (!mounted) return;
    await _loadDocs();
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _loadDocs() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final docs = await _api.getDocs();
      if (!mounted) return;
      setState(() {
        _docs = docs;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _showIpDialog() async {
    // Pre-fill with whatever is already in the IP field (or empty on
    // first open). Hardcoding a specific home-network address would
    // either leak a developer's LAN topology or mislead users whose
    // routers issue different subnets.
    final ip = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('實機 IP'),
          content: TextField(
            controller: _ipController,
            decoration: const InputDecoration(
              hintText: '例如 192.168.1.42',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, _ipController.text),
              child: const Text('套用'),
            ),
          ],
        );
      },
    );
    final trimmed = ip?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    final api = _api;
    if (api is ApiClient) {
      api.updateBaseUrl('http://$trimmed:8080');
      await _loadDocs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智讀館'),
        actions: [
          IconButton(
            tooltip: '實機 IP',
            onPressed: _loading ? null : _showIpDialog,
            icon: const Icon(Icons.wifi),
          ),
          IconButton(
            tooltip: '重新整理',
            onPressed: _loading ? null : _loadDocs,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('錯誤：$_error'))
              : _docs.isEmpty
                  ? const Center(child: Text('目前沒有書籍'))
                  : ListView.builder(
                      itemCount: _docs.length,
                      itemBuilder: (context, index) {
                        final doc = _docs[index];
                        return ListTile(
                          leading:
                              const Icon(Icons.book, color: Colors.indigo),
                          title: Text(doc),
                          // Tap → Q&A mode (existing). Long-press → Reading
                          // mode (Phase 1C: full text + in-book search).
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReaderScreen(
                                bookTitle: doc,
                                apiClient: _api,
                                enableOcr:
                                    const bool.fromEnvironment('ENABLE_OCR'),
                              ),
                            ),
                          ),
                          onLongPress: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReadingModeScreen(
                                bookTitle: doc,
                                apiClient: _api,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
