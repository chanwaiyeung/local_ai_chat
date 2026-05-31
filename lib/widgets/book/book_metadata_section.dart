import 'package:flutter/material.dart';

import '../../models/book.dart';
import '../../services/book_isbn_service.dart';

/// Fills empty metadata controllers from a [Book] lookup result.
int fillEmptyMetadataFromBook(
  Book book, {
  required TextEditingController titleCtrl,
  required TextEditingController authorCtrl,
  required TextEditingController publisherCtrl,
  required TextEditingController yearCtrl,
  required TextEditingController coverUrlCtrl,
  TextEditingController? isbnCtrl,
}) {
  var n = 0;
  void fill(TextEditingController c, String v) {
    if (c.text.trim().isEmpty && v.isNotEmpty) {
      c.text = v;
      n++;
    }
  }

  fill(titleCtrl, book.title);
  fill(authorCtrl, book.author);
  fill(publisherCtrl, book.publisher);
  if (yearCtrl.text.trim().isEmpty && book.year != null) {
    yearCtrl.text = book.year!.toString();
    n++;
  }
  fill(coverUrlCtrl, book.coverUrl);
  if (isbnCtrl != null) fill(isbnCtrl, book.isbn);
  return n;
}

/// ISBN lookup flow; parent dialog invokes this to coordinate fill + feedback.
Future<void> bookFormLookupIsbn(
  BuildContext context, {
  required TextEditingController isbnCtrl,
  required TextEditingController titleCtrl,
  required TextEditingController authorCtrl,
  required TextEditingController publisherCtrl,
  required TextEditingController yearCtrl,
  required TextEditingController coverUrlCtrl,
  required void Function(bool) setLookingUp,
  required VoidCallback notify,
}) async {
  final isbn = isbnCtrl.text.trim();
  if (isbn.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('請先輸入 ISBN')),
    );
    return;
  }
  setLookingUp(true);
  notify();
  try {
    final book = await BookIsbnService.lookup(isbn).timeout(
      const Duration(seconds: 10),
    );
    if (!context.mounted) return;
    if (book == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('找不到此 ISBN 的書籍資料')),
      );
      return;
    }
    final n = fillEmptyMetadataFromBook(
      book,
      titleCtrl: titleCtrl,
      authorCtrl: authorCtrl,
      publisherCtrl: publisherCtrl,
      yearCtrl: yearCtrl,
      coverUrlCtrl: coverUrlCtrl,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已從 ISBN 自動填入 $n 個欄位')),
    );
    notify();
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('查詢失敗: $e')),
    );
  } finally {
    setLookingUp(false);
    if (context.mounted) notify();
  }
}

/// Title, author, publisher, ISBN, and year fields.
class BookMetadataSection extends StatelessWidget {
  const BookMetadataSection({
    super.key,
    required this.titleCtrl,
    required this.authorCtrl,
    required this.publisherCtrl,
    required this.isbnCtrl,
    required this.yearCtrl,
    required this.locationCtrl,
    required this.category,
    required this.onCategoryChanged,
    required this.lookingUpIsbn,
    required this.onLookupIsbn,
  });

  final TextEditingController titleCtrl;
  final TextEditingController authorCtrl;
  final TextEditingController publisherCtrl;
  final TextEditingController isbnCtrl;
  final TextEditingController yearCtrl;
  final TextEditingController locationCtrl;
  final String category;
  final ValueChanged<String?> onCategoryChanged;
  final bool lookingUpIsbn;
  final VoidCallback onLookupIsbn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: titleCtrl,
          decoration: const InputDecoration(labelText: 'Title *'),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Required' : null,
        ),
        TextFormField(
          controller: authorCtrl,
          decoration: const InputDecoration(labelText: 'Author'),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 200, maxWidth: 380),
              child: TextFormField(
                controller: publisherCtrl,
                decoration: const InputDecoration(labelText: 'Publisher'),
              ),
            ),
            SizedBox(
              width: 100,
              child: TextFormField(
                controller: yearCtrl,
                decoration: const InputDecoration(labelText: 'Year'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 200, maxWidth: 420),
              child: TextFormField(
                controller: isbnCtrl,
                decoration: const InputDecoration(
                  labelText: 'ISBN',
                  helperText: 'Phase 2: auto-fill from Google Books',
                ),
              ),
            ),
            if (lookingUpIsbn)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                tooltip: '從 ISBN 自動填入',
                icon: const Icon(Icons.search),
                onPressed: onLookupIsbn,
              ),
          ],
        ),
        TextFormField(
          controller: locationCtrl,
          decoration: const InputDecoration(labelText: 'Shelf location'),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: category.isEmpty ? null : category,
          decoration: const InputDecoration(labelText: 'Category'),
          items: [
            const DropdownMenuItem(value: '', child: Text('(none)')),
            ...BookCategory.all.map(
              (c) => DropdownMenuItem(value: c, child: Text(c)),
            ),
          ],
          onChanged: onCategoryChanged,
        ),
      ],
    );
  }
}


