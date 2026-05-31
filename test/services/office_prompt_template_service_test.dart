// test/services/office_prompt_template_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:local_ai_chat/models/office_ai_request.dart';
import 'package:local_ai_chat/services/office_ai_service.dart';
import 'package:local_ai_chat/services/office_prompt_template_service.dart';

void main() {
  setUp(() async {
    // Initialize the template service
    await OfficePromptTemplateService().init();
  });

  group('OfficePromptTemplateService Tests', () {
    test('retrieves default fallback prompts correctly when init is done', () {
      final service = OfficePromptTemplateService();
      
      final wordSummarize = service.getTemplate('word', 'summarize_doc');
      expect(wordSummarize, contains('核心要點'));

      final excelFormula = service.getTemplate('excel', 'formula');
      expect(excelFormula, contains('函數公式'));

      final pptOutline = service.getTemplate('ppt', 'outline_presentation');
      expect(pptOutline, contains('投影片大綱'));

      final outlookReply = service.getTemplate('outlook', 'draft_reply');
      expect(outlookReply, contains('草擬一封專業'));
    });

    test('returns default instructions for unknown task', () {
      final service = OfficePromptTemplateService();
      final unknownTask = service.getTemplate('word', 'unknown_task_123');
      expect(unknownTask, equals('執行 unknown_task_123 任務。'));
    });
  });

  group('OfficeAiService Integration with Prompt Templates', () {
    test('buildPrompt interpolates template prompts into the output', () {
      final generator = OfficeAiService(generate: (p) async* { yield 'OK'; });
      
      final request = OfficeAiRequest(
        app: 'word',
        task: 'summarize_doc',
        text: '這是原始文稿內容。',
        tone: '專業',
        target: 'zh-TW',
      );

      final prompt = generator.buildPrompt(request);
      expect(prompt, contains('來源軟體：Word / Writer'));
      expect(prompt, contains('任務：請針對以下文件內容，產生一份結構清晰的摘要'));
      expect(prompt, contains('這是原始文稿內容。'));
    });
   group('OfficeAiService Church workflow templates', () {
    test('buildPrompt handles church app and custom prompts', () {
      final generator = OfficeAiService(generate: (p) async* { yield 'OK'; });

      final request = OfficeAiRequest(
        app: 'church',
        task: 'care_summary',
        text: '個案：探訪王弟兄。',
        tone: '溫暖',
        target: 'zh-TW',
      );

      final prompt = generator.buildPrompt(request);
      expect(prompt, contains('來源軟體：教會行政系統'));
      expect(prompt, contains('任務：請根據提供的關懷個案背景與歷次探訪紀錄'));
      expect(prompt, contains('個案：探訪王弟兄。'));
    });
   });
  });
}


