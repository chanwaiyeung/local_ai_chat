import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final apiKey = 'AIzaSyByD3cMsY-5o4CnGyfxRDXyl9F4y5Dp8Bw';
  final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
  final response = await http.get(uri);
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final models = data['models'] as List<dynamic>;
  for (var m in models) {
    if (m['name'].toString().contains('gemini')) {
      print(m['name']);
    }
  }
}
