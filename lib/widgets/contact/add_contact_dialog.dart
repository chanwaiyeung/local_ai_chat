import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../controllers/contact_controller.dart';
import '../../models/contact.dart';
import '../../services/contact_ocr_service.dart';

class AddContactDialog extends StatefulWidget {
  const AddContactDialog({
    super.key,
    required this.controller,
  });

  final ContactController controller;

  @override
  State<AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<AddContactDialog> {
  final _ocrService = ContactOcrService();
  bool _isScanning = false;
  bool _showRawText = false;

  final _rawOcrCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _rawOcrCtrl.dispose();
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _reparse() {
    final text = _rawOcrCtrl.text;
    if (text.trim().isEmpty) return;

    final contact = widget.controller.parseOcrText(text);
    setState(() {
      _nameCtrl.text = contact.name;
      _companyCtrl.text = contact.company;
      _phoneCtrl.text = contact.phone;
      _emailCtrl.text = contact.email;
      _notesCtrl.text = 'Title: ${contact.title}\nWebsite: ${contact.website}\n(Re-parsed from raw text)';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fields re-parsed from edited text')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Contact'),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 24,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isScanning
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);

                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.image,
                          allowMultiple: false,
                        );

                        if (result == null || result.files.isEmpty) {
                          return; // User canceled
                        }

                        final imagePath = result.files.single.path;
                        if (imagePath == null) return;

                        setState(() {
                          _isScanning = true;
                        });
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Scanning business card...')),
                        );

                        try {
                          // Delegate scanning to the boundary service
                          final (scannedText, isFallback) =
                              await _ocrService.scanBusinessCard(imagePath: imagePath);
                          if (!mounted) return;

                          // Delegate parsing to the controller logic
                          final contact = widget.controller.parseOcrText(scannedText);

                          setState(() {
                            _rawOcrCtrl.text = scannedText;
                            _showRawText = true;

                            _nameCtrl.text = contact.name;
                            _companyCtrl.text = contact.company;
                            _phoneCtrl.text = contact.phone;
                            _emailCtrl.text = contact.email;
                            final sourceStr = isFallback ? '(Fallback Mock Data)' : '(Real OCR)';
                            _notesCtrl.text =
                                'Title: ${contact.title}\nWebsite: ${contact.website}\n$sourceStr';
                          });

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(isFallback
                                  ? 'OCR unavailable, using sample data'
                                  : 'Fields auto-filled from OCR'),
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isScanning = false;
                            });
                          }
                        }
                      },
                icon: _isScanning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.document_scanner),
                label: Text(_isScanning ? 'Scanning...' : 'Scan Business Card'),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showRawText = !_showRawText;
                  });
                },
                icon: Icon(_showRawText ? Icons.expand_less : Icons.expand_more),
                label: const Text('Raw OCR Text'),
              ),
            ),
            if (_showRawText) ...[
              TextField(
                controller: _rawOcrCtrl,
                decoration: const InputDecoration(
                  labelText: 'Edit raw text',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: _reparse,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Re-parse'),
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: _companyCtrl, decoration: const InputDecoration(labelText: 'Company')),
            TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final name = _nameCtrl.text.trim();
            final phone = _phoneCtrl.text.trim();
            final email = _emailCtrl.text.trim();

            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Name is required')),
              );
              return;
            }
            if (phone.isEmpty && email.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Phone or Email is required')),
              );
              return;
            }

            Navigator.of(context).pop();

            final newContact = Contact(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              name: name,
              company: _companyCtrl.text.trim(),
              phone: phone,
              email: email,
              notes: _notesCtrl.text.trim(),
            );

            final messenger = ScaffoldMessenger.of(context);

            try {
              await widget.controller.saveContact(newContact);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Added: $name')),
                );
              }
            } catch (e) {
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to save contact: $e')),
                );
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
