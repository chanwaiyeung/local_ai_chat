import 'package:flutter/material.dart';

import '../../models/book.dart';
import 'book_cover_section.dart';
import 'book_metadata_section.dart';
import 'book_reading_section.dart';
import 'book_tags_section.dart';

class BookFormDialog extends StatefulWidget {
  const BookFormDialog({
    super.key,
    this.existing,
    required this.onSave,
    this.onDelete,
  });

  final Book? existing;
  final Future<void> Function(Book) onSave;
  final Future<void> Function()? onDelete;

  @override
  State<BookFormDialog> createState() => _BookFormDialogState();
}

class _BookFormDialogState extends State<BookFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _authorCtrl;
  late final TextEditingController _publisherCtrl;
  late final TextEditingController _isbnCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _coverUrlCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _tagInputCtrl;
  late String _category;
  late List<String> _tags;
  late double _rating;
  DateTime? _readAt;
  DateTime? _startedReadingAt;
  bool _saving = false;
  bool _lookingUpIsbn = false;
  bool _scanningCover = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _authorCtrl = TextEditingController(text: e?.author ?? '');
    _publisherCtrl = TextEditingController(text: e?.publisher ?? '');
    _isbnCtrl = TextEditingController(text: e?.isbn ?? '');
    _yearCtrl = TextEditingController(text: e?.year?.toString() ?? '');
    _coverUrlCtrl = TextEditingController(text: e?.coverUrl ?? '');
    _locationCtrl = TextEditingController(text: e?.location ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _tagInputCtrl = TextEditingController();
    _category = e?.category ?? '';
    _tags = List<String>.from(e?.tags ?? const []);
    _rating = e?.rating ?? 0.0;
    _readAt = e?.readAt;
    _startedReadingAt = e?.startedReadingAt;
  }

  @override
  void dispose() {
    for (final c in [
      _titleCtrl,
      _authorCtrl,
      _publisherCtrl,
      _isbnCtrl,
      _yearCtrl,
      _coverUrlCtrl,
      _locationCtrl,
      _notesCtrl,
      _tagInputCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _notify() => setState(() {});
  Future<void> _lookupIsbn() => bookFormLookupIsbn(
        context,
        isbnCtrl: _isbnCtrl,
        titleCtrl: _titleCtrl,
        authorCtrl: _authorCtrl,
        publisherCtrl: _publisherCtrl,
        yearCtrl: _yearCtrl,
        coverUrlCtrl: _coverUrlCtrl,
        setLookingUp: (v) => _lookingUpIsbn = v,
        notify: _notify,
      );

  Future<void> _scanCoverImage() => bookFormScanCover(
        context,
        titleCtrl: _titleCtrl,
        authorCtrl: _authorCtrl,
        publisherCtrl: _publisherCtrl,
        yearCtrl: _yearCtrl,
        coverUrlCtrl: _coverUrlCtrl,
        isbnCtrl: _isbnCtrl,
        setScanning: (v) => _scanningCover = v,
        notify: _notify,
      );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final book = Book(
      id: widget.existing?.id ?? '',
      title: _titleCtrl.text.trim(),
      author: _authorCtrl.text.trim(),
      publisher: _publisherCtrl.text.trim(),
      isbn: _isbnCtrl.text.trim(),
      year: int.tryParse(_yearCtrl.text.trim()),
      coverUrl: _coverUrlCtrl.text.trim(),
      coverPath: widget.existing?.coverPath ?? '',
      location: _locationCtrl.text.trim(),
      category: _category,
      tags: _tags,
      rating: _rating > 0 ? _rating : null,
      notes: _notesCtrl.text.trim(),
      readAt: _readAt,
      startedReadingAt: widget.existing?.startedReadingAt,
      addedAt: widget.existing?.addedAt,
      source: widget.existing?.source ?? 'manual',
    );
    try {
      await widget.onSave(book);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete book?'),
        content: Text('"${widget.existing?.title}" will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true && widget.onDelete != null) {
      await widget.onDelete!();
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  Future<void> _pickDate({required bool started}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (started ? _startedReadingAt : _readAt) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => started ? _startedReadingAt = picked : _readAt = picked);
    }
  }

  void _addTag() {
    final t = _tagInputCtrl.text.trim();
    if (t.isEmpty || _tags.contains(t)) return;
    setState(() {
      _tags = [..._tags, t];
      _tagInputCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Book' : 'Add Book'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BookCoverSection(
                  coverUrlCtrl: _coverUrlCtrl,
                  scanningCover: _scanningCover,
                  onScanCover: _scanCoverImage,
                ),
                BookMetadataSection(
                  titleCtrl: _titleCtrl,
                  authorCtrl: _authorCtrl,
                  publisherCtrl: _publisherCtrl,
                  isbnCtrl: _isbnCtrl,
                  yearCtrl: _yearCtrl,
                  locationCtrl: _locationCtrl,
                  category: _category,
                  onCategoryChanged: (v) => setState(() => _category = v ?? ''),
                  lookingUpIsbn: _lookingUpIsbn,
                  onLookupIsbn: _lookupIsbn,
                ),
                BookReadingSection(
                  rating: _rating,
                  onRatingChanged: (v) => setState(() => _rating = v),
                  notesCtrl: _notesCtrl,
                  startedReadingAt: _startedReadingAt,
                  readAt: _readAt,
                  onPickStartedReading: () => _pickDate(started: true),
                  onClearStartedReading: () =>
                      setState(() => _startedReadingAt = null),
                  onPickReadDate: () => _pickDate(started: false),
                  onClearReadDate: () => setState(() => _readAt = null),
                ),
                BookTagsSection(
                  book: widget.existing,
                  tags: _tags,
                  tagInputCtrl: _tagInputCtrl,
                  onAddTag: _addTag,
                  onRemoveTag: (t) => setState(
                    () => _tags = _tags.where((x) => x != t).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (isEdit && widget.onDelete != null)
          TextButton(onPressed: _saving ? null : _confirmDelete, child: const Text('Delete', style: TextStyle(color: Colors.red))),
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}


