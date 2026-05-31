// lib/screens/library_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/book_controller.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/book.dart';
import '../services/api_client.dart';
import '../services/classification_service.dart';
import '../services/network_service.dart';
import 'reader_screen.dart';
import 'reading_mode_screen.dart';

class LibraryScreen extends StatefulWidget {
  /// Inject a [ReaderApi] for tests; production code can leave this null
  /// to use the default client.
  final ReaderApi? apiClient;
  final BookController? bookController;

  const LibraryScreen({super.key, this.apiClient, this.bookController});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late final ReaderApi _api;
  final TextEditingController _ipController = TextEditingController();
  List<String> _docs = [];
  bool _loading = true;
  String? _error;
  Timer? _backgroundTimer;

  BookController? get _bookController {
    if (widget.bookController != null) return widget.bookController;
    try {
      return globalBookController;
    } catch (_) {
      return null;
    }
  }
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _api = widget.apiClient ?? ApiClient();
    _autoDetectAndConnect();
    _bookController?.addListener(_onBookControllerChanged);
    _backgroundTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _bookController?.processUnclassifiedBooks();
      }
    });
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
    _backgroundTimer?.cancel();
    _ipController.dispose();
    _bookController?.removeListener(_onBookControllerChanged);
    super.dispose();
  }

  void _onBookControllerChanged() {
    if (mounted) {
      setState(() {});
    }
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
          title: const Text('實機 IP' /* l10n: deviceIpDialogTitle */),
          content: TextField(
            controller: _ipController,
            decoration: const InputDecoration(
              hintText: '例如 192.168.1.42' /* l10n: ipAddressHint */,
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消' /* l10n: cancel */),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, _ipController.text),
              child: const Text('套用' /* l10n: apply */),
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

  String _getDocCategory(String docName) {
    final controller = _bookController;
    if (controller == null) return '';
    final baseName = docName.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '').toLowerCase().trim();
    for (final book in controller.getAllBooks()) {
      if (book.title.toLowerCase().trim() == baseName ||
          book.title.toLowerCase().trim() == docName.toLowerCase().trim()) {
        return book.category;
      }
    }
    return '';
  }

  List<String> _getAvailableCategories() {
    final controller = _bookController;
    if (controller == null) return const ['All'];
    final categories = <String>{};
    bool hasUncategorized = false;
    for (final doc in _docs) {
      final cat = _getDocCategory(doc);
      if (cat.isNotEmpty) {
        categories.add(cat);
      } else {
        hasUncategorized = true;
      }
    }
    final list = categories.toList()..sort();
    return [
      'All',
      ...list,
      if (hasUncategorized) 'Uncategorized',
    ];
  }

  List<String> get _filteredDocs {
    List<String> docs = _docs;
    if (_selectedCategory != 'All') {
      if (_selectedCategory == 'Uncategorized') {
        docs = _docs.where((doc) => _getDocCategory(doc).isEmpty).toList();
      } else {
        docs = _docs.where((doc) => _getDocCategory(doc) == _selectedCategory).toList();
      }
    }

    final controller = _bookController;
    if (controller != null) {
      final filtered = controller.filteredBooks;
      final filteredTitles = filtered.map((b) => b.title.toLowerCase().trim()).toSet();
      if (controller.sourceFilter != null && controller.sourceFilter!.isNotEmpty) {
        docs = docs.where((doc) {
          final baseName = doc.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '').toLowerCase().trim();
          return filteredTitles.contains(baseName) || filteredTitles.contains(doc.toLowerCase().trim());
        }).toList();
      }
    }

    return docs;
  }

  Widget _buildCategoryFilters() {
    final categories = _getAvailableCategories();
    if (categories.length <= 1) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == _selectedCategory;
          
          String displayLabel = cat;
          if (cat == 'All') {
            displayLabel = '全部';
          } else if (cat == 'Uncategorized') {
            displayLabel = '未分類';
          }
          
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Material(
                color: isSelected ? colorScheme.primary : colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                elevation: isSelected ? 2 : 0,
                shadowColor: colorScheme.primary.withValues(alpha: 0.4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.transparent : colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        displayLabel,
                        style: TextStyle(
                          color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSourceFilters() {
    final controller = _bookController;
    if (controller == null) return const SizedBox.shrink();

    // Get books in the current category
    final List<Book> categoryBooks;
    if (_selectedCategory == 'All') {
      categoryBooks = controller.getAllBooks();
    } else if (_selectedCategory == 'Uncategorized') {
      categoryBooks = controller.getAllBooks().where((b) => b.category.isEmpty).toList();
    } else {
      categoryBooks = controller.getAllBooks().where((b) => b.category == _selectedCategory).toList();
    }

    final totalCount = categoryBooks.length;
    final localCount = categoryBooks.where((b) => b.interactionMetadata.classificationSource == 'local').length;
    final cloudCount = categoryBooks.where((b) => b.interactionMetadata.classificationSource == 'cloud').length;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final activeSource = controller.sourceFilter;

    final filters = [
      {'label': '全部', 'value': null, 'count': totalCount},
      {'label': '本地處理', 'value': 'local', 'count': localCount},
      {'label': '雲端精煉', 'value': 'cloud', 'count': cloudCount},
    ];

    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final val = filter['value'] as String?;
          final label = filter['label'] as String;
          final count = filter['count'] as int;
          
          final isSelected = activeSource == val;

          Color bgColor;
          Color textColor;

          if (isSelected) {
            if (val == 'local') {
              bgColor = isDark ? Colors.green.shade900.withValues(alpha: 0.4) : Colors.green.shade100;
              textColor = isDark ? Colors.green.shade200 : Colors.green.shade900;
            } else if (val == 'cloud') {
              bgColor = isDark ? Colors.blue.shade900.withValues(alpha: 0.4) : Colors.blue.shade100;
              textColor = isDark ? Colors.blue.shade200 : Colors.blue.shade900;
            } else {
              bgColor = colorScheme.primary;
              textColor = colorScheme.onPrimary;
            }
          } else {
            bgColor = colorScheme.surfaceContainer;
            textColor = colorScheme.onSurfaceVariant;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Material(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                elevation: isSelected ? 2 : 0,
                shadowColor: isSelected
                    ? (val == 'local'
                        ? Colors.green.withValues(alpha: 0.4)
                        : (val == 'cloud' ? Colors.blue.withValues(alpha: 0.4) : colorScheme.primary.withValues(alpha: 0.4)))
                    : Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    controller.setSourceFilter(val);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.transparent : colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        '$label ($count)',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAiManagementSheet(BuildContext context) {
    final controller = _bookController;
    if (controller == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: StatefulBuilder(
                builder: (context, setSheetState) {
                  bool showTagsOnly = false;
                  // Compute counts
                  final unclassified = controller.getAllBooks().where((b) => b.category.isEmpty).toList();
                  final Map<String, int> tagCounts = {};
                  for (final book in controller.getAllBooks()) {
                    for (final tag in book.tags) {
                      tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
                    }
                  }
                  final sortedTags = tagCounts.keys.toList()..sort((a, b) => tagCounts[b]!.compareTo(tagCounts[a]!));

                  return StatefulBuilder(
                    builder: (context, setSubSheetState) {
                      return Column(
                        children: [
                          // Pull handle
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          if (!showTagsOnly) ...[
                            ListTile(
                              title: const Text(
                                '圖書館 AI 管理',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.batch_prediction, color: Colors.indigo),
                              title: const Text('批次掃描圖書館'),
                              subtitle: Text('為所有未分類書籍進行 AI 分類 (未分類書籍: ${unclassified.length})'),
                              onTap: () {
                                Navigator.pop(context);
                                _startBatchClassification(context, unclassified, controller);
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.bar_chart, color: Colors.indigo),
                              title: const Text('檢視全部標籤'),
                              subtitle: Text('條列出所有標籤的分類統計 (標籤數: ${sortedTags.length})'),
                              onTap: () {
                                setSubSheetState(() {
                                  showTagsOnly = true;
                                });
                              },
                            ),
                          ] else ...[
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  onPressed: () {
                                    setSubSheetState(() {
                                      showTagsOnly = false;
                                    });
                                  },
                                ),
                                const Text(
                                  '全部標籤統計',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                              ],
                            ),
                            const Divider(),
                            Expanded(
                              child: sortedTags.isEmpty
                                  ? const Center(
                                      child: Text('目前沒有任何標籤'),
                                    )
                                  : ListView.builder(
                                      controller: scrollController,
                                      itemCount: sortedTags.length,
                                      itemBuilder: (context, index) {
                                        final tag = sortedTags[index];
                                        final count = tagCounts[tag] ?? 0;
                                        return ListTile(
                                          leading: const Icon(Icons.tag, color: Colors.blue),
                                          title: Text(tag),
                                          trailing: Chip(
                                            label: Text('$count 本書'),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ],
                      );
                    }
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _startBatchClassification(BuildContext context, List<Book> unclassified, BookController controller) {
    if (unclassified.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('所有書籍皆已分類！')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _BatchProgressDialog(
          books: unclassified,
          controller: controller,
        );
      },
    );
  }

  Widget _buildReadingProfile(BuildContext context) {
    final controller = _bookController;
    if (controller == null) return const SizedBox.shrink();

    final stats = controller.tagStatistics;
    if (stats.isEmpty) return const SizedBox.shrink();

    final sortedTags = stats.keys.toList()
      ..sort((a, b) => stats[b]!.compareTo(stats[a]!));
    final top5 = sortedTags.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle("閱讀輪廓"),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: top5.map((tag) {
              final count = stats[tag] ?? 0;
              return ActionChip(
                label: Text('$tag ($count)'),
                onPressed: () {},
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8.0),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final displayDocs = _filteredDocs;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.libraryTitle),
        actions: [
          IconButton(
            tooltip: 'AI 管理',
            onPressed: _loading ? null : () => _showAiManagementSheet(context),
            icon: const Icon(Icons.auto_awesome),
          ),
          IconButton(
            tooltip: '實機 IP' /* l10n: deviceIpTooltip */,
            onPressed: _loading ? null : _showIpDialog,
            icon: const Icon(Icons.wifi),
          ),
          IconButton(
            tooltip: '重新整理' /* l10n: refresh */,
            onPressed: _loading ? null : _loadDocs,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('錯誤：$_error' /* l10n: errorPrefix(e) */))
              : _docs.isEmpty
                  ? Center(child: Text(l10n.libraryEmpty))
                  : Column(
                      children: [
                        _buildCategoryFilters(),
                        _buildReadingProfile(context),
                        _buildSourceFilters(),
                        Expanded(
                          child: displayDocs.isEmpty
                              ? const Center(
                                  child: Text(
                                    '此類別下無書籍',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: displayDocs.length,
                                  itemBuilder: (context, index) {
                                    final doc = displayDocs[index];
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
                        ),
                      ],
                    ),
    );
  }
}

class _BatchProgressDialog extends StatefulWidget {
  final List<Book> books;
  final BookController controller;

  const _BatchProgressDialog({
    required this.books,
    required this.controller,
  });

  @override
  State<_BatchProgressDialog> createState() => _BatchProgressDialogState();
}

class _BatchProgressDialogState extends State<_BatchProgressDialog> {
  int _currentIndex = 0;
  bool _isCancelled = false;
  String _statusText = '';

  @override
  void initState() {
    super.initState();
    _startProcessing();
  }

  Future<void> _startProcessing() async {
    for (int i = 0; i < widget.books.length; i++) {
      if (_isCancelled) break;
      final book = widget.books[i];
      if (mounted) {
        setState(() {
          _currentIndex = i;
          _statusText = '正在分類：${book.title}...';
        });
      }

      try {
        final text = book.notes.trim().isNotEmpty ? book.notes : '${book.title} ${book.author}';
        final result = await ClassificationService().classifyBook(text);
        await widget.controller.updateClassification(
          book.id,
          result.category,
          result.tags,
          classificationSource: result.source,
        );
      } catch (e) {
        debugPrint('Failed to classify book ${book.title}: $e');
      }
    }

    if (mounted) {
      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isCancelled ? '批次分類已取消' : '批次分類完成！')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.books.length;
    final progress = total > 0 ? _currentIndex / total : 0.0;

    return AlertDialog(
      title: const Text('批次 AI 分類中'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_statusText, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 8),
          Text('進度：$_currentIndex / $total'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _isCancelled = true;
            Navigator.pop(context);
          },
          child: const Text('取消'),
        ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}



