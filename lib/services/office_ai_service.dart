// lib/services/office_ai_service.dart

import '../models/office_ai_request.dart';
import '../models/office_ai_response.dart';
import 'office_prompt_template_service.dart';

class OfficeAiService {
  final Stream<String> Function(String prompt) generate;

  OfficeAiService({required this.generate});

  String buildPrompt(OfficeAiRequest req) {
    final app = req.app.toLowerCase();
    final customPrompt = req.metadata['prompt'];
    final taskStr = (customPrompt is String && customPrompt.isNotEmpty) ? customPrompt : req.task;
    final task = taskStr.toLowerCase();

    // 1. PowerPoint specific outline tasks
    if (app == 'ppt' && (task == 'outline' || task == 'outline_presentation' || task == 'bible_study_ppt')) {
      final template = OfficePromptTemplateService().getTemplate(app, task == 'outline' ? 'outline_presentation' : task);
      return '''
你是本機 Office AI 助理。
來源軟體：$app
任務：$template
語氣：${req.tone ?? '自然、清楚、專業'}
輸出語言：${req.target ?? 'zh-TW'}

請將以下內容轉成 8 張 PowerPoint 投影片。
每張投影片包含：
- title (投影片標題)
- bullets (投影片要點，JSON 字串陣列)
- speaker_notes (演講者備忘錄)
- suggested_visual (建議視覺效果)

請務必僅輸出一個合法的 JSON array 格式，不要包含 any markdown 標記（如 ```json）或額外的解釋說明文字。

回傳的 JSON 陣列格式範例如下：
[
  {
    "title": "AI 助理全面整合 Office",
    "bullets": ["Local AI", "Office Bridge", "生活APP / 教會APP"],
    "speaker_notes": "介紹整體架構",
    "suggested_visual": "星形圖"
  }
]

待轉換內容：
${req.text}
''';
    }

    // 2. Outlook specific tasks
    if (app == 'outlook') {
      final template = OfficePromptTemplateService().getTemplate(app, task);
      return '''
你是本機 Office AI 助理。
來源軟體：Outlook / Mail
任務：$template
語氣：${req.tone ?? '自然、清楚、專業'}
輸出語言：${req.target ?? 'zh-TW'}

請根據以下內容完成任務。
不要捏造資料。
回覆內容必須直接且實用，不需要包含額外的對話或問候 AI 本身。

郵件與內容：
${req.text}
''';
    }

    // 3. Word specific tasks
    if (app == 'word') {
      final template = OfficePromptTemplateService().getTemplate(app, task);
      return '''
你是本機 Office AI 助理。
來源軟體：Word / Writer
任務：$template
語氣：${req.tone ?? '自然、清楚、專業'}
輸出語言：${req.target ?? 'zh-TW'}

請根據以下內容完成任務。
不要捏造資料。
請以 Markdown 格式輸出。

內容：
${req.text}
''';
    }

    // 4. Excel specific tasks
    if (app == 'excel') {
      final template = OfficePromptTemplateService().getTemplate(app, task);
      return '''
你是本機 Office AI 助理。
來源軟體：Excel / Spreadsheets
任務：$template
語氣：${req.tone ?? '自然、清楚、專業'}
輸出語言：${req.target ?? 'zh-TW'}

請根據以下內容完成任務。
不要捏造資料。
請以 Markdown 格式輸出。

內容：
${req.text}
''';
    }

    // 5. Church specific tasks
    if (app == 'church') {
      final template = OfficePromptTemplateService().getTemplate(app, task);
      return '''
你是本機 Office AI 助理。
來源軟體：教會行政系統
任務：$template
語氣：${req.tone ?? '自然、清楚、專業'}
輸出語言：${req.target ?? 'zh-TW'}

請根據以下內容完成任務。
不要捏造資料。
請以 Markdown 格式輸出。

內容：
${req.text}
''';
    }

    // Default general/fallback prompt
    return '''
你是本機 Office AI 助理。
來源軟體：$app
任務：$task
語氣：${req.tone ?? '自然、清楚、專業'}
輸出語言：${req.target ?? 'zh-TW'}

請根據以下內容完成任務。
不要捏造資料。
如資訊不足，請明確指出。

內容：
${req.text}
''';
  }

  Future<OfficeAiResponse> ask(OfficeAiRequest request) async {
    try {
      final prompt = buildPrompt(request);
      final buf = StringBuffer();
      await for (final delta in generate(prompt)) {
        buf.write(delta);
      }
      return OfficeAiResponse(
        ok: true,
        result: buf.toString(),
        model: 'local',
      );
    } catch (e) {
      return OfficeAiResponse(
        ok: false,
        result: 'Error generating response: $e',
        model: 'local',
      );
    }
  }

  Stream<String> askStream(OfficeAiRequest request) {
    final prompt = buildPrompt(request);
    return generate(prompt);
  }
}


