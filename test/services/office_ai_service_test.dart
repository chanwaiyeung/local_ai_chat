// test/services/office_ai_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/models/office_ai_request.dart';
import 'package:local_ai_chat/services/office_ai_service.dart';

Stream<String> _fakeGenerator(String prompt) async* {
  yield 'Simulated result for: ';
  if (prompt.toLowerCase().contains('word')) {
    yield 'Word';
  } else {
    yield 'General';
  }
}

void main() {
  group('OfficeAiService Tests', () {
    late OfficeAiService service;

    setUp(() {
      service = OfficeAiService(generate: _fakeGenerator);
    });

    test('buildPrompt includes required request parameters', () {
      final req = OfficeAiRequest(
        app: 'excel',
        task: 'formula',
        text: 'Calculate sum of column A',
        tone: 'formal',
        target: 'zh-TW',
      );

      final prompt = service.buildPrompt(req);
      expect(prompt, contains('來源軟體：Excel / Spreadsheets'));
      expect(prompt, contains('將自然語言需求翻譯成標準'));
      expect(prompt, contains('語氣：formal'));
      expect(prompt, contains('輸出語言：zh-TW'));
      expect(prompt, contains('Calculate sum of column A'));
    });

    test('buildPrompt ppt outline requests JSON array structure', () {
      final req = OfficeAiRequest(
        app: 'ppt',
        task: 'outline',
        text: 'AI Integration in Office',
        tone: 'professional',
        target: 'zh-TW',
      );

      final prompt = service.buildPrompt(req);
      expect(prompt, contains('來源軟體：ppt'));
      expect(prompt, contains('請將以下內容轉成 8 張 PowerPoint 投影片'));
      expect(prompt, contains('請務必僅輸出一個合法的 JSON array 格式'));
      expect(prompt, contains('AI Integration in Office'));
    });

    test('buildPrompt outlook draft_reply uses custom Outlook formatting', () {
      final req = OfficeAiRequest(
        app: 'outlook',
        task: 'draft_reply',
        text: 'Please send me the report.',
        tone: 'formal',
        target: 'zh-TW',
      );

      final prompt = service.buildPrompt(req);
      expect(prompt, contains('來源軟體：Outlook / Mail'));
      expect(prompt, contains('任務：請根據提供的郵件內容草擬一封專業、得體且親切的回信'));
      expect(prompt, contains('Please send me the report.'));
    });

    test('ask executes generation fully and returns valid OfficeAiResponse', () async {
      final req = OfficeAiRequest(
        app: 'word',
        task: 'polish',
        text: 'Unpolished doc.',
      );

      final res = await service.ask(req);
      expect(res.ok, isTrue);
      expect(res.result, equals('Simulated result for: Word'));
      expect(res.model, equals('local'));
    });

    test('askStream streams tokens correctly', () async {
      final req = OfficeAiRequest(
        app: 'ppt',
        task: 'outline',
        text: 'Presentation text.',
      );

      final stream = service.askStream(req);
      final List<String> deltas = await stream.toList();

      expect(deltas.length, equals(2));
      expect(deltas.join(), equals('Simulated result for: General'));
    });
  });
}


