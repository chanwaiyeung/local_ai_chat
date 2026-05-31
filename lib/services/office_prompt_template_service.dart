// lib/services/office_prompt_template_service.dart

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class OfficePromptTemplateService {
  static final OfficePromptTemplateService _instance = OfficePromptTemplateService._internal();

  factory OfficePromptTemplateService() => _instance;

  OfficePromptTemplateService._internal();

  final Map<String, Map<String, String>> _templates = {};
  bool _isLoaded = false;

  // Robust default templates to fallback on if loading assets fails
  static const Map<String, Map<String, String>> _defaultTemplates = {
    'word': {
      'summarize_doc': '請針對以下文件內容，產生一份結構清晰的摘要，包含核心要點、關鍵結論與行動建議。請保留原有的 Markdown 標題或清單格式。',
      'rewrite_tone': '請幫我改寫以下內容的語氣。請將其修改得更正式、得體、流暢，並符合商務/公務用字與公文格式規範。不要變更原文的核心語意。',
      'meeting_notes': '請把以下逐字稿或會議草案整理成正式的會議紀錄。報告需結構化呈現，包含開會時間地點(若有)、討論主題、決議事項、負責人與待辦期限。',
    },
    'excel': {
      'analyze_table': '請分析以下表格資料（以 CSV 格式提供），指出其核心趨勢、異常數據或值得注意的亮點，並給出 3 點具體的操作建議。',
      'suggest_charts': '請分析以下表格結構與數據，建議最適合繪製的 2-3 種圖表類型（例如折線圖、圓餅圖或直條圖），並說明為什麼以及對應的數據維度。',
      'monthly_report': '請根據以下財務或銷售數據，撰寫一份簡明扼要的月報摘要，指出本月亮點、主要成長/衰退原因及下月展望。',
      'formula': '將自然語言需求翻譯成標準的 Excel / Spreadsheets 函數公式。請直接輸出公式本身，不要包含多餘的敘述。',
    },
    'ppt': {
      'outline_presentation': '請將以下內容轉成 8 張 PowerPoint 投影片大綱的 JSON array。每張投影片包含 title (標題)、bullets (要點，JSON 字串陣列)、speaker_notes (備忘錄)、suggested_visual (視覺效果)。請務必僅輸出合法 JSON，不要包含 ```json 標記或額外敘述。',
      'bible_study_ppt': '請將查經教材或經文主題規劃成 8 張小組查經簡報投影片大綱。回傳格式必須符合包含 title、bullets (要點，JSON 字串陣列)、speaker_notes 與 suggested_visual 的 JSON array，且僅輸出 JSON。',
    },
    'outlook': {
      'draft_reply': '請根據提供的郵件內容草擬一封專業、得體且親切的回信。如果有適合，可以加入溫暖的問候。',
      'summarize_email': '請將以下郵件內容提煉為三點關鍵摘要（列點說明），以便於快速閱讀與理解。',
      'todos': '請從以下郵件或內容中，提取出所有需要跟進的待辦事項 (Action Items) 與指派對象。',
      'meeting_notes': '請將以下內容整理為結構化、易讀的會議紀錄、重點決議及後續追蹤事項。',
    },
    'church': {
      'sermon_refine': '請對以下講道逐字稿進行摘要與整理。報告應包含核心摘要、主要生活實踐重點以及引用的聖經經文。',
      'care_summary': '請根據提供的關懷個案背景與歷次探訪紀錄，整理撰寫一份關懷個案進度摘要報告。包含個案基本狀況、歷次探訪摘要及後續代禱跟進事項。',
      'bulletin_draft': '請將提供的主日講題、宣讀經文、報告事項及代禱內容，整理草擬成一份正式、排版精美的教會週報宣傳文稿。',
    }
  };

  /// Initialize templates by loading them from application assets.
  /// If it runs in unit test environments without asset bundle, it falls back gracefully to defaults.
  Future<void> init() async {
    if (_isLoaded) return;
    try {
      final List<Map<String, String>> files = [
        {'app': 'word', 'path': 'assets/prompts/office_word_zh_tw.json'},
        {'app': 'excel', 'path': 'assets/prompts/office_excel_zh_tw.json'},
        {'app': 'ppt', 'path': 'assets/prompts/office_powerpoint_zh_tw.json'},
        {'app': 'outlook', 'path': 'assets/prompts/office_outlook_zh_tw.json'},
        {'app': 'church', 'path': 'assets/prompts/church_office_zh_tw.json'},
      ];

      for (final f in files) {
        final content = await rootBundle.loadString(f['path']!);
        final json = jsonDecode(content) as Map<String, dynamic>;
        final tasks = json['tasks'] as Map<String, dynamic>;
        _templates[f['app']!] = tasks.map((k, v) => MapEntry(k, v.toString()));
      }
      _isLoaded = true;
    } catch (_) {
      // Fallback to default hardcoded templates on failure (e.g. inside unit tests)
      _templates.clear();
      _defaultTemplates.forEach((app, tasks) {
        _templates[app] = Map<String, String>.from(tasks);
      });
      _isLoaded = true;
    }
  }

  /// Get the prompt template for a specific application and task.
  /// Falls back to the hardcoded default mapping if initialization was not run or has failed.
  String getTemplate(String app, String task) {
    final appLower = app.toLowerCase();
    final taskLower = task.toLowerCase();

    // Ensure loaded or fallback initialized
    if (!_isLoaded) {
      _defaultTemplates.forEach((a, t) {
        _templates[a] = Map<String, String>.from(t);
      });
      _isLoaded = true;
    }

    final appMap = _templates[appLower] ?? _defaultTemplates[appLower];
    if (appMap != null) {
      final t = appMap[taskLower];
      if (t != null) return t;
    }

    // Default return
    return '執行 $task 任務。';
  }
}


