import 'package:flutter/material.dart';

class TopKPicker extends StatefulWidget {
  const TopKPicker({super.key, required this.current});

  final int current;

  @override
  State<TopKPicker> createState() => _TopKPickerState();
}

class _TopKPickerState extends State<TopKPicker> {
  late int _value = widget.current;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('檢索片段數量 (Top-K)'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: _value.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: '$_value',
            onChanged: (value) => setState(() => _value = value.round()),
          ),
          Text('每次檢索取最相關嘅 $_value 個片段'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _value),
          child: const Text('確定'),
        ),
      ],
    );
  }
}


