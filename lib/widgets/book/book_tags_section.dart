import 'package:flutter/material.dart';
import '../../models/book.dart';

/// Tag input and chip list.
class BookTagsSection extends StatelessWidget {
  const BookTagsSection({
    super.key,
    this.book,
    required this.tags,
    required this.tagInputCtrl,
    required this.onAddTag,
    required this.onRemoveTag,
  });

  final Book? book;
  final List<String> tags;
  final TextEditingController tagInputCtrl;
  final VoidCallback onAddTag;
  final ValueChanged<String> onRemoveTag;

  Widget? _buildSourceBadge(BuildContext context, String source) {
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
      avatar: Icon(icon, color: textColor, size: 16),
      label: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: bgColor,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final source = book?.interactionMetadata.classificationSource;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: tagInputCtrl,
                decoration: const InputDecoration(
                  labelText: 'Add tag (press +)',
                ),
                onFieldSubmitted: (_) => onAddTag(),
              ),
            ),
            IconButton(onPressed: onAddTag, icon: const Icon(Icons.add)),
          ],
        ),
        if (tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: tags
                        .map(
                          (t) => Chip(
                            label: Text(t),
                            onDeleted: () => onRemoveTag(t),
                          ),
                        )
                        .toList(),
                  ),
                ),
                if (source != null && source.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _buildSourceBadge(context, source) ?? const SizedBox.shrink(),
                ],
              ],
            ),
          ),
      ],
    );
  }
}


