// Scratch script for Gemini API smoke testing.
// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:http/http.dart' as http;

Future<void> main() async {
  final apiKey = const String.fromEnvironment('GEMINI_API_KEY');
  if (apiKey.isEmpty) {
    throw StateError(
      'Set GEMINI_API_KEY env var: dart --define=GEMINI_API_KEY=xxx ...',
    );
  }
  final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
  final response = await http.get(uri);
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final models = data['models'] as List<dynamic>;
  for (final m in models) {
    if (m['name'].toString().contains('gemini')) {
      print(m['name']);
    }
  }
}
