import 'dart:io';
import 'package:flutter/material.dart';
import '../../controllers/book_controller.dart';
import '../../controllers/reader_controller.dart';
import '../../main.dart';
import '../../models/book.dart';
import '../../screens/reader_screen.dart';
import '../../services/api_client.dart';
import '../../services/classification_service.dart';

class BookCard extends StatefulWidget {
  const BookCard({
    super.key,
    required this.book,
    this.onTap,
    this.bookController,
  });

  final Book book;
  final VoidCallback? onTap;
  final BookController? bookController;

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCover(),
              const SizedBox(width: 12),
              Expanded(child: _buildInfo(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    Widget? image;
    if (widget.book.coverPath.isNotEmpty) {
      final file = File(widget.book.coverPath);
      if (file.existsSync()) {
        image = Image.file(file, fit: BoxFit.cover);
      }
    }
    if (image == null && widget.book.coverUrl.isNotEmpty) {
      image = Image.network(
        widget.book.coverUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
        loadingBuilder: (_, child, p) => p == null
            ? child
            : const Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
      );
    }
    return SizedBox(
      width: 60,
      height: 90,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: image ?? _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.menu_book, size: 30, color: Colors.grey),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.book.title.isEmpty ? '(Untitled)' : widget.book.title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.book.isRead)
              const Icon(Icons.check_circle, color: Colors.green, size: 18)
            else if (widget.book.isReading)
              const Icon(Icons.menu_book, color: Colors.blue, size: 18),
          ],
        ),
        if (widget.book.author.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              widget.book.author,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if (widget.book.publisher.isNotEmpty || widget.book.year != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              [
                if (widget.book.publisher.isNotEmpty) widget.book.publisher,
                if (widget.book.year != null) widget.book.year.toString(),
              ].join(' · '),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              if (widget.book.location.isNotEmpty) ...[
                const Icon(Icons.place, size: 14, color: Colors.grey),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    widget.book.location,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else
                const Spacer(),
              if (widget.book.rating != null) ...[
                const SizedBox(width: 6),
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 2),
                Text(
                  widget.book.rating!.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: (widget.book.tags.isNotEmpty || (widget.book.interactionMetadata.classificationSource?.isNotEmpty ?? false))
                    ? Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (widget.book.interactionMetadata.classificationSource != null && widget.book.interactionMetadata.classificationSource!.isNotEmpty)
                            _buildSourceBadge(context, widget.book.interactionMetadata.classificationSource!) ?? const SizedBox.shrink(),
                          ...widget.book.tags.map((t) => Chip(
                                label: Text(t, style: const TextStyle(fontSize: 11)),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              )),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),
              _buildAiButton(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget? _buildSourceBadge(BuildContext context, String source) {
    if (source.isEmpty) return null;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color bgColor;
    final Color textColor;
    final IconData icon;
    final String label;

    if (source == 'local') {
      bgColor = isDark ? Colors.green.shade900.withValues(alpha: 0.4) : Colors.green.shade100;
      textColor = isDark ? Colors.green.shade200 : Colors.green.shade900;
      icon = Icons.memory;
      label = '本地 AI';
    } else if (source == 'cloud') {
      bgColor = isDark ? Colors.blue.shade900.withValues(alpha: 0.4) : Colors.blue.shade100;
      textColor = isDark ? Colors.blue.shade200 : Colors.blue.shade900;
      icon = Icons.cloud_done;
      label = '雲端精煉';
    } else {
      return null;
    }

    return Chip(
      avatar: Icon(icon, color: textColor, size: 12),
      label: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: bgColor,
      side: BorderSide.none,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }

  Widget _buildAiButton(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final Color bgColor = isDark ? Colors.indigo.shade900.withValues(alpha: 0.4) : Colors.indigo.shade100;
    final Color textColor = isDark ? Colors.indigo.shade200 : Colors.indigo.shade900;

    return PopupMenuButton<String>(
      onSelected: (val) {
        if (val == 'reclassify') {
          _reclassify(context);
        } else if (val == 'summary') {
          _generateSummary(context);
        } else if (val == 'qa') {
          _startDeepQA(context);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'reclassify',
          child: Row(
            children: [
              Icon(Icons.refresh, size: 20),
              SizedBox(width: 8),
              Text('重算分類/標籤'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'summary',
          child: Row(
            children: [
              Icon(Icons.summarize, size: 20),
              SizedBox(width: 8),
              Text('生成摘要'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'qa',
          child: Row(
            children: [
              Icon(Icons.question_answer, size: 20),
              SizedBox(width: 8),
              Text('深度問答'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '✨ AI',
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: textColor, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _reclassify(BuildContext context) async {
    final controller = widget.bookController ?? globalBookController;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('正在重算分類與標籤...')),
    );
    setState(() {
      _isLoading = true;
    });
    try {
      final text = widget.book.notes.trim().isNotEmpty ? widget.book.notes : '${widget.book.title} ${widget.book.author}';
      final result = await ClassificationService().classifyBook(text);
      await controller.updateClassification(
        widget.book.id,
        result.category,
        result.tags,
        classificationSource: result.source,
      );
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('分類與標籤計算完成！')),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('計算失敗：$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateSummary(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('正在尋找書籍檔案...')),
    );
    setState(() {
      _isLoading = true;
    });
    try {
      final docName = await _findBackendDocName();
      if (docName == null) {
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('未在後端圖書館找到對應的書籍檔案。')),
          );
        }
        return;
      }

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('找到檔案 $docName，正在生成並語音播放總結...')),
        );
      }

      final readerController = ReaderController(
        bookTitle: docName,
      );
      final quality = readerController.readingController.determineQuality(widget.book);
      await readerController.readingController.generateAndSpeakSummary(
        docName,
        quality: quality,
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('生成語音總結失敗：$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startDeepQA(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('正在開啟深度問答...')),
    );
    final docName = await _findBackendDocName();
    if (docName == null) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('未在後端圖書館找到對應的書籍檔案。')),
        );
      }
      return;
    }

    if (mounted) {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ReaderScreen(
            bookTitle: docName,
            enableOcr: const bool.fromEnvironment('ENABLE_OCR'),
          ),
        ),
      );
    }
  }

  Future<String?> _findBackendDocName() async {
    try {
      final docs = await ApiClient().getDocs();
      final targetTitle = widget.book.title.toLowerCase().trim();
      for (final doc in docs) {
        final baseName = doc.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '').toLowerCase().trim();
        if (baseName == targetTitle || doc.toLowerCase().trim() == targetTitle) {
          return doc;
        }
      }
    } catch (_) {}
    return null;
  }
}



