import 'package:flutter/material.dart';

/// Rating, reading dates, and notes.
class BookReadingSection extends StatelessWidget {
  const BookReadingSection({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    required this.notesCtrl,
    required this.startedReadingAt,
    required this.readAt,
    required this.onPickStartedReading,
    required this.onClearStartedReading,
    required this.onPickReadDate,
    required this.onClearReadDate,
  });

  final double rating;
  final ValueChanged<double> onRatingChanged;
  final TextEditingController notesCtrl;
  final DateTime? startedReadingAt;
  final DateTime? readAt;
  final VoidCallback onPickStartedReading;
  final VoidCallback onClearStartedReading;
  final VoidCallback onPickReadDate;
  final VoidCallback onClearReadDate;

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rating: ${rating.toStringAsFixed(1)}'),
        Slider(
          value: rating,
          min: 0,
          max: 5,
          divisions: 10,
          label: rating.toStringAsFixed(1),
          onChanged: onRatingChanged,
        ),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Started reading:'),
            Text(startedReadingAt != null
                ? _formatDate(startedReadingAt!)
                : '(not started)'),
            if (startedReadingAt != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: onClearStartedReading,
              ),
            TextButton(
              onPressed: onPickStartedReading,
              child: const Text('Pick'),
            ),
          ],
        ),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Read date:'),
            Text(readAt != null ? _formatDate(readAt!) : '(not read)'),
            if (readAt != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: onClearReadDate,
              ),
            TextButton(
              onPressed: onPickReadDate,
              child: const Text('Pick'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: notesCtrl,
          decoration: const InputDecoration(
            labelText: 'Notes',
            helperText: 'Will be searchable via AI Q&A',
            alignLabelWithHint: true,
          ),
          maxLines: 5,
        ),
      ],
    );
  }
}


