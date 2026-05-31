import 'package:flutter/material.dart';

import '../models/rag_evaluation_record.dart';

class RagEvalEditorResult {
  const RagEvalEditorResult({
    required this.question,
    required this.answer,
    required this.citationText,
    required this.citationTarget,
    required this.expectedStatus,
    required this.verdict,
    required this.notes,
  });

  final String question;
  final String answer;
  final String citationText;
  final String citationTarget;
  final RagExpectedStatus expectedStatus;
  final RagVerdict verdict;
  final String notes;
}

class RagEvalEditor extends StatefulWidget {
  const RagEvalEditor({
    super.key,
    required this.chatModel,
    required this.embeddingModel,
    required this.onSubmit,
  });

  final String chatModel;
  final String embeddingModel;
  final Future<void> Function(RagEvalEditorResult result) onSubmit;

  @override
  State<RagEvalEditor> createState() => _RagEvalEditorState();
}

class _RagEvalEditorState extends State<RagEvalEditor> {
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  final _citationTextController = TextEditingController();
  final _citationTargetController = TextEditingController();
  final _notesController = TextEditingController();
  final _editorController = ExpansibleController();

  RagExpectedStatus _expected = RagExpectedStatus.exists;
  RagVerdict _verdict = RagVerdict.unsure;

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _citationTextController.dispose();
    _citationTargetController.dispose();
    _notesController.dispose();
    _editorController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先輸入問題')),
      );
      return;
    }

    debugPrint('Saving expected=$_expected verdict=$_verdict');

    await widget.onSubmit(
      RagEvalEditorResult(
        question: question,
        answer: _answerController.text.trim(),
        citationText: _citationTextController.text.trim(),
        citationTarget: _citationTargetController.text.trim(),
        expectedStatus: _expected,
        verdict: _verdict,
        notes: _notesController.text.trim(),
      ),
    );

    _questionController.clear();
    _answerController.clear();
    _citationTextController.clear();
    _citationTargetController.clear();
    _notesController.clear();
    _editorController.collapse();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        controller: _editorController,
        title: const Text('新增評測記錄'),
        subtitle: Text(
          'Chat: ${widget.chatModel} · Embedding: ${widget.embeddingModel}',
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _questionController,
            decoration: const InputDecoration(
              labelText: 'Question',
              border: OutlineInputBorder(),
            ),
            minLines: 1,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _answerController,
            decoration: const InputDecoration(
              labelText: 'Answer',
              border: OutlineInputBorder(),
            ),
            minLines: 2,
            maxLines: 6,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _citationTextController,
            decoration: const InputDecoration(
              labelText: 'Citation text',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _citationTargetController,
            decoration: const InputDecoration(
              labelText: 'Citation target',
              hintText: 'chunk:?doc=<document>&i=<chunkIndex>',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Current enum: ${_expected.name} / ${_verdict.name}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Expected status',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: _buildExpectedChips(),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Verdict',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: _buildVerdictChips(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
            minLines: 1,
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.add),
              label: const Text('儲存記錄'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpectedChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: RagExpectedStatus.values.map((value) {
        return FilterChip(
          label: Text(value.name),
          selected: _expected == value,
          onSelected: (_) {
            setState(() => _expected = value);
            debugPrint('Expected changed: $value');
          },
        );
      }).toList(),
    );
  }

  Widget _buildVerdictChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: RagVerdict.values.map((value) {
        return FilterChip(
          label: Text(value.name),
          selected: _verdict == value,
          onSelected: (_) {
            setState(() => _verdict = value);
            debugPrint('Verdict changed: $value');
          },
        );
      }).toList(),
    );
  }
}


