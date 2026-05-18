import 'package:flutter/material.dart';

/// Tag input and chip list.
class BookTagsSection extends StatelessWidget {
  const BookTagsSection({
    super.key,
    required this.tags,
    required this.tagInputCtrl,
    required this.onAddTag,
    required this.onRemoveTag,
  });

  final List<String> tags;
  final TextEditingController tagInputCtrl;
  final VoidCallback onAddTag;
  final ValueChanged<String> onRemoveTag;

  @override
  Widget build(BuildContext context) {
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
          Wrap(
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
      ],
    );
  }
}
