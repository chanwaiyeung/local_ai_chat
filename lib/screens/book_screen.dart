// lib/screens/book_screen.dart
import 'package:flutter/material.dart';
import '../controllers/book_controller.dart';
import '../models/book.dart';
import '../widgets/book/book_card.dart';
import '../widgets/book/book_form_dialog.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({super.key, required this.controller});
  final BookController controller;

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  List<Book> _filteredBooks(int tabIndex) {
    var books = _searchQuery.isEmpty
        ? widget.controller.getAllBooks()
        : widget.controller.searchBooks(_searchQuery);
    switch (tabIndex) {
      case 1: // Reading
        books = books.where((b) => b.isReading).toList();
        break;
      case 2: // Read
        books = books.where((b) => b.isRead).toList();
        break;
      case 3: // TBR
        books = books.where((b) => b.isTbr).toList();
        break;
    }
    return books;
  }

  Future<void> _openForm({Book? existing}) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BookFormDialog(
        existing: existing,
        onSave: (b) async {
          await widget.controller.saveBook(b);
        },
        onDelete: existing == null
            ? null
            : () async {
                await widget.controller.deleteBook(existing.id);
              },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.controller.count;
    final read = widget.controller.readCount;
    final reading = widget.controller.readingCount;
    final tbr = widget.controller.tbrCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 Library'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'All ($total)'),
            Tab(text: 'Reading ($reading)'),
            Tab(text: 'Read ($read)'),
            Tab(text: 'TBR ($tbr)'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search title / author / notes / tags...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20)),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(4, (i) {
                final books = _filteredBooks(i);
                if (books.isEmpty) {
                  return const Center(
                    child: Text(
                      'No books yet.\nTap + to add your first book.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: books.length,
                  itemBuilder: (ctx, idx) => BookCard(
                    book: books[idx],
                    onTap: () => _openForm(existing: books[idx]),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
