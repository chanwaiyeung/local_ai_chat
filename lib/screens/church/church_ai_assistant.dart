// lib/screens/church/church_ai_assistant.dart
//
// ChurchAiAssistant v2.16 — 68 quick AI functions for pastoral team.
//
// v1   (4 cards): 生成探訪摘要 / 整理代禱事項 / 講道PPT大綱 / 會友近況查詢
// v2.1 (+ 4): 小組討論問題 / 活動文案海報 / 財務報告草稿 / 牧養行動建議
// v2.2 (+ 4): 主日週報草稿 / 講道重點摘要 / 活動海報設計提示 / 小組長牧養建議
// v2.3 (+ 4): 新人歡迎信 / 會友關懷離開信 / 牧養週訊 / 兒童主日學教案
// v2.4 (+ 4): 部門會議議程 / 年度事工計劃 / 志工招募文案 / 感謝狀草稿
// v2.5 (+ 4): 牧養禱告信 / 受洗見證引導 / 長執就職感言 / 年終牧函
// v2.6 (+ 4): 佈道會邀請文案 / 喪禮安慰信 / 人生里程碑禱告 / 宣教報告草稿
// v2.7 (+ 4): 教會年報摘要 / 婚禮崇拜程序 / 嬰兒奉獻典禮程序 / 多週查經課程
// v2.8 (+ 4): 佈道後跟進計劃 / 小組長培訓大綱 / 青少年事工方案 / 長執會議議程
// v2.9 (+ 4): 小組長月報模板 / 佈道訓練課程 / 新人整合計劃 / 年度大會演講稿
// v2.10(+ 4): 年度預算草案 / 小組倍增計劃 / 牧者靈修休假計劃 / 危機處理指引
// v2.11(+ 4): 青少年年度計劃 / 長執退修議程 / 靈命成長追蹤 / 禱告文化建立計劃
// v2.12(+ 4): 教會異象宣言 / 新堂會設立計劃 / 短宣隊招募培訓 / 轉會推薦信
// v2.13(+ 4): 年度讀經計劃 / 青年營會方案 / 志工管理系統 / 牧師交棒計劃
// v2.14(+ 4): 直播崇拜腳本 / 家庭事工方案 / 社群媒體月計劃 / 人生轉變關懷計劃
// v2.15(+ 4): 線上奉獻設定 / 兒主線上課程 / 直播設備指南 / 線上小組手冊
// v2.16(+ 4): 禱告會主題流程 / 婚姻輔導課程 / 兒童事工培訓手冊 / 緊急事工計劃
//
// Each card builds a context-aware prompt from live controller data and
// opens PersonalQueryScreen with that pre-filled query.
//
// WRITE: only this file.
// NEVER TOUCH: controllers, models, services, l10n, main.dart.

import 'package:flutter/material.dart';

import '../../controllers/church/care_controller.dart';
import '../../main.dart';
import '../personal_query_screen.dart';

// ============================================================================
// Screen
// ============================================================================

class ChurchAiAssistant extends StatefulWidget {
  const ChurchAiAssistant({super.key});

  @override
  State<ChurchAiAssistant> createState() => _ChurchAiAssistantState();
}

class _ChurchAiAssistantState extends State<ChurchAiAssistant> {
  // ── helpers ─────────────────────────────────────────────────────────────

  void _run(String prompt) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonalQueryScreen(
          ragService: globalPersonalRagService,
          initialQuery: prompt,
        ),
      ),
    );
  }

  // ── prompt builders ──────────────────────────────────────────────────────

  String _buildVisitSummaryPrompt() {
    final care = globalCareController;
    final buf = StringBuffer();
    buf.writeln('請根據以下教會關懷案件資料，生成本週探訪工作摘要報告，'
        '包括：(1) 緊急/需優先跟進的案件；(2) 本週已探訪情況；'
        '(3) 給牧者的行動建議。請用繁體中文，條列式回答。\n');

    final active = care.activeCases;
    if (active.isEmpty) {
      buf.writeln('目前無活躍關懷案件。');
    } else {
      buf.writeln('【活躍案件 ${active.length} 件】');
      for (final c in active.take(20)) {
        final level = care.alertLevel(c).name.toUpperCase();
        final days = care.daysSinceLastTouch(c);
        final daysStr = days == null ? '未知' : '$days 天未探訪';
        buf.writeln('- ${c.memberName}｜緣由：${c.reason}｜緊急度：${c.urgency}'
            '｜狀態：$level｜$daysStr');
        final last = care.lastVisitFor(c.id);
        if (last != null) {
          buf.writeln('  最近探訪：${last.visitDate.year}/${last.visitDate.month}/${last.visitDate.day}'
              ' 由 ${last.visitedBy}，${last.summary}');
        }
      }
    }

    buf.writeln('\n統計：紅燈 ${care.redCount} 件 / 黃燈 ${care.yellowCount} 件 / '
        '綠燈 ${care.greenCount} 件');
    return buf.toString();
  }

  String _buildPrayerPrompt() {
    final care = globalCareController;
    final buf = StringBuffer();
    buf.writeln('請根據以下教會關懷案件，整理成本週代禱清單，'
        '格式：姓名 + 簡短代禱事項（1 句話），按緊急度排序。請用繁體中文。\n');

    final active = care.activeCases;
    if (active.isEmpty) {
      buf.writeln('目前無活躍關懷案件。');
    } else {
      for (final c in active.take(30)) {
        final extra = c.notes.isNotEmpty ? '（備註：${c.notes}）' : '';
        buf.writeln('- ${c.memberName}：${c.reason}$extra');
      }
    }
    return buf.toString();
  }

  String _buildSermonPrompt(String topic) {
    return '請為題目「$topic」設計一份主日講道 PowerPoint 大綱，包括：'
        '(1) 主題經文（請引用具體章節）；'
        '(2) 講道結構（開場 / 主體 3 點 / 呼召）；'
        '(3) 每個段落的重點句與參考例子；'
        '(4) 適合會眾討論的反思問題 2 條。'
        '請用繁體中文，條列式回答。';
  }

  String _buildMemberStatusPrompt(String name) {
    final care = globalCareController;
    final people = globalPersonController;
    final buf = StringBuffer();
    buf.writeln('請查詢會友「$name」的近況，並給出牧關建議。\n');

    final person = people.findByName(name);
    if (person != null) {
      buf.writeln('【會友資料】');
      buf.writeln('姓名：${person.name}');
      buf.writeln('出席狀況：${person.attendance}');
      buf.writeln('類型：${person.personType}');
      if (person.phone.isNotEmpty) buf.writeln('電話：${person.phone}');
      if (person.notes.isNotEmpty) buf.writeln('備註：${person.notes}');
    } else {
      buf.writeln('（在會友通訊錄中找不到此姓名，將根據關懷記錄查詢）');
    }

    final related = care.activeCases
        .where((c) => c.memberName.contains(name) || name.contains(c.memberName))
        .toList();
    if (related.isNotEmpty) {
      buf.writeln('\n【相關關懷案件】');
      for (final c in related) {
        buf.writeln('- 緣由：${c.reason}｜緊急度：${c.urgency}');
        final last = care.lastVisitFor(c.id);
        if (last != null) {
          buf.writeln('  最近探訪：${last.visitDate.year}/${last.visitDate.month}/${last.visitDate.day}，${last.summary}');
        }
      }
    }

    buf.writeln('\n請根據以上資料分析此會友的近況，並建議牧者如何跟進。');
    return buf.toString();
  }

  // ── v2.1 prompt builders ─────────────────────────────────────────────────

  String _buildGroupDiscussionPrompt(String topic) {
    return '請為小組查經或小組聚會設計一套討論問題，主題／經文：「$topic」。\n'
        '要求：\n'
        '(1) 破冰問題 1 條（輕鬆、生活化）；\n'
        '(2) 深入查經問題 4 條（引導小組思考經文意義與應用）；\n'
        '(3) 生活應用問題 2 條（促進個人行動）；\n'
        '(4) 結束禱告重點 1 條。\n'
        '請用繁體中文，每條問題後附上簡短「引導提示」供帶領者參考。';
  }

  String _buildEventCopyPrompt(String eventName) {
    return '請為教會活動「$eventName」生成完整宣傳文案套件，包括：\n'
        '(1) 活動主題句（15 字以內，吸引人）；\n'
        '(2) 海報副標題（25 字以內）；\n'
        '(3) 活動介紹段落（3-4 句，說明活動內容與對象）；\n'
        '(4) WhatsApp／Line 分享短文（100 字以內）；\n'
        '(5) 三個可用的 hashtag 建議；\n'
        '(6) 呼召行動句（Call to Action，例：立即報名、歡迎帶朋友參加）。\n'
        '請用繁體中文，風格溫暖親切，適合教會社群。';
  }

  String _buildFinanceReportPrompt(String period) {
    final care = globalCareController;
    final people = globalPersonController;
    return '請為教會生成「$period」財務報告草稿範本，包括：\n'
        '(1) 報告標題與日期欄位；\n'
        '(2) 收入項目清單（奉獻、什一、特別奉獻、其他）及合計欄；\n'
        '(3) 支出項目清單（人事、房租/場地、事工、行政、其他）及合計欄；\n'
        '(4) 結餘計算欄；\n'
        '(5) 重點摘要段落（給長執會閱讀）；\n'
        '(6) 財務健康指標建議（例：緊急備用金≥3個月支出）。\n\n'
        '教會目前概況（供參考）：\n'
        '- 會友人數：${people.totalCount} 人（定期出席 ${people.regularCount} 人）\n'
        '- 活躍關懷案件：${care.activeCount} 件\n\n'
        '請用繁體中文，表格部分用文字列出欄位名稱，方便貼入 Excel。';
  }

  String _buildPastoralActionPrompt(String name) {
    final care = globalCareController;
    final people = globalPersonController;
    final buf = StringBuffer();
    buf.writeln('請為會友「$name」制定具體的牧養行動計劃，'
        '包含短期（本週）、中期（本月）和長期（3 個月）的跟進步驟。\n');

    final person = people.findByName(name);
    if (person != null) {
      buf.writeln('【會友基本資料】');
      buf.writeln('姓名：${person.name} ／ 類型：${person.personType}');
      buf.writeln('出席狀況：${person.attendance}');
      if (person.notes.isNotEmpty) buf.writeln('備註：${person.notes}');
    } else {
      buf.writeln('（通訊錄中未找到「$name」，請根據以下關懷記錄判斷）');
    }

    final related = care.allCases
        .where((c) => c.memberName.contains(name) || name.contains(c.memberName))
        .toList();
    if (related.isNotEmpty) {
      buf.writeln('\n【關懷案件歷史（${related.length} 件）】');
      for (final c in related.take(10)) {
        buf.writeln('- [${c.status}] ${c.reason}（緊急度：${c.urgency}）');
        final visits = care.visitsForCase(c.id);
        for (final v in visits.take(3)) {
          buf.writeln('  探訪 ${v.visitDate.year}/${v.visitDate.month}/${v.visitDate.day}'
              '：${v.summary}（狀況：${v.condition}）');
        }
      }
    }

    buf.writeln('\n請根據以上資料，生成：\n'
        '(1) 當前屬靈需要評估；\n'
        '(2) 本週具體跟進行動（1-2 項）；\n'
        '(3) 本月牧養目標；\n'
        '(4) 3 個月長期培育方向；\n'
        '(5) 可邀請參與的教會活動或事工建議。\n'
        '請用繁體中文，具體可執行，避免空泛。');
    return buf.toString();
  }

  // ── v2.2 prompt builders ─────────────────────────────────────────────────

  String _buildBulletinPrompt(String date) {
    final care = globalCareController;
    final people = globalPersonController;
    final buf = StringBuffer();
    buf.writeln('請為教會「$date」主日崇拜生成週報內容草稿，包含以下版塊：\n'
        '(1) 本週崇拜資訊（崇拜主題欄、講員欄、司琴欄 — 留空供填寫）；\n'
        '(2) 本週金句（隨機推薦 1 節相關經文，附章節）；\n'
        '(3) 教會消息（3 則範例公告，格式：[消息標題] 內容 50 字以內）；\n'
        '(4) 代禱事項（請根據以下活躍案件整理 3-5 條）；\n'
        '(5) 本週奉獻提醒（溫馨提示語 1-2 句）；\n'
        '(6) 下週預告欄（留空格式）。\n');

    final active = care.activeCases.take(5).toList();
    if (active.isNotEmpty) {
      buf.writeln('【代禱參考資料】');
      for (final c in active) {
        final extra = c.notes.isNotEmpty ? '（${c.notes}）' : '';
        buf.writeln('- ${c.memberName}：${c.reason}$extra');
      }
    }
    buf.writeln('\n教會概況：${people.totalCount} 位會友，定期出席 ${people.regularCount} 人。');
    buf.writeln('請用繁體中文，語氣溫暖友善，適合印刷或電子週報。');
    return buf.toString();
  }

  String _buildSermonKeyPointsPrompt(String passage) {
    return '請為聖經章節或主題「$passage」整理 3-5 個講道重點，格式如下：\n\n'
        '重點一：[標題（5 字以內）]\n'
        '  - 經文根據：[引用章節]\n'
        '  - 核心信息：[1-2 句闡述]\n'
        '  - 生活應用：[1 個具體例子]\n\n'
        '（重複以上格式，共 3-5 個重點）\n\n'
        '最後加上：\n'
        '- 呼召信息（1 段，4-6 句）\n'
        '- 結束禱告重點（3 條）\n\n'
        '請用繁體中文，適合主日講道使用，語氣莊重而溫暖。';
  }

  String _buildPosterDesignPrompt(String eventName) {
    return '請為教會活動「$eventName」提供完整的海報設計方案，包括：\n\n'
        '【視覺風格】\n'
        '(1) 整體設計風格建議（例：現代簡約 / 溫暖復古 / 清新自然）；\n'
        '(2) 主色調方案（提供 3 個色碼 #RRGGBB，說明情感聯想）；\n'
        '(3) 字型組合建議（標題字體 + 內文字體，繁體中文適用）；\n\n'
        '【版面配置】\n'
        '(4) A4 / Instagram 方形 / Story 三種尺寸的版面草稿描述；\n'
        '(5) 圖片元素建議（背景意象、裝飾圖形、插圖風格）；\n\n'
        '【AI 繪圖提示詞】\n'
        '(6) Midjourney / DALL-E 海報背景圖提示詞（英文，100 字以內）；\n'
        '(7) Canva 搜尋關鍵字建議（3-5 個英文關鍵字）；\n\n'
        '請用繁體中文說明，設計建議應符合教會氛圍，溫馨、聖潔、有活力。';
  }

  String _buildSmallGroupLeaderPrompt(String groupName) {
    final care = globalCareController;
    final people = globalPersonController;
    final buf = StringBuffer();
    buf.writeln('請為小組或部門「$groupName」提供小組長牧養策略建議。\n');

    final total = people.totalCount;
    final regular = people.regularCount;
    final occasional = people.occasionalCount;
    final inactive = people.inactiveCount;

    buf.writeln('【教會整體出席概況（參考背景）】');
    buf.writeln('- 總會友：$total 人');
    buf.writeln('- 定期出席：$regular 人 / 偶爾出席：$occasional 人 / 久未出席：$inactive 人');

    final relatedCases = care.activeCases
        .where((c) => c.notes.contains(groupName) ||
            c.memberName.contains(groupName) ||
            groupName.length <= 2)
        .take(5)
        .toList();
    if (relatedCases.isNotEmpty) {
      buf.writeln('\n【相關關懷案件】');
      for (final c in relatedCases) {
        buf.writeln('- ${c.memberName}：${c.reason}');
      }
    }

    buf.writeln('\n請提供：\n'
        '(1) 小組健康評估框架（4 個維度：靈命成長 / 關係建立 / 外展 / 行政）；\n'
        '(2) 每月小組聚會建議結構（開場 / 查經 / 分享 / 代禱 / 行動）；\n'
        '(3) 如何跟進久未出席的小組員（3 個具體步驟）；\n'
        '(4) 小組長自我靈命保養建議（3 條）；\n'
        '(5) 本季可操作的小組成長目標範例（2 個）。\n'
        '請用繁體中文，內容具體實用，適合基層小組長使用。');
    return buf.toString();
  }

  // ── v2.3 prompt builders ─────────────────────────────────────────────────

  String _buildWelcomeLetterPrompt(String name) {
    final people = globalPersonController;
    return '請為新來教會的朋友「$name」撰寫一封歡迎信，風格溫暖、真誠，'
        '不過度宗教化，讓初來者感到被接納。\n\n'
        '信件結構：\n'
        '(1) 開場問候（提及名字，表達真誠喜悅）；\n'
        '(2) 簡短介紹教會氛圍與核心價值（3-4 句）；\n'
        '(3) 邀請參加的活動或小組（列 2-3 個具體選項）；\n'
        '(4) 提供聯絡方式欄位（留空供填寫：牧師姓名、電話、email）；\n'
        '(5) 溫馨結語（鼓勵、祝福語）；\n'
        '(6) 署名欄位（教會名稱 + 牧師姓名，留空）。\n\n'
        '目前教會有 ${people.totalCount} 位會友，定期出席 ${people.regularCount} 人，'
        '歡迎氛圍友善多元。\n'
        '請用繁體中文，約 200-300 字，適合列印或電子郵件發送。';
  }

  String _buildFarewellCarePrompt(String name) {
    final care = globalCareController;
    final people = globalPersonController;
    final buf = StringBuffer();
    buf.writeln('請為久未出席或即將離開教會的會友「$name」撰寫一封關懷信，'
        '語氣溫柔、不施壓、充滿愛，目的是維繫關係而非強迫回歸。\n');

    final person = people.findByName(name);
    if (person != null) {
      buf.writeln('【會友資料】出席狀況：${person.attendance}');
      if (person.notes.isNotEmpty) buf.writeln('備註：${person.notes}');
    }

    final related = care.allCases
        .where((c) =>
            c.memberName.contains(name) || name.contains(c.memberName))
        .take(3)
        .toList();
    if (related.isNotEmpty) {
      buf.writeln('【相關關懷背景】');
      for (final c in related) {
        buf.writeln('- ${c.reason}');
      }
    }

    buf.writeln('\n信件結構：\n'
        '(1) 開場：表達真誠惦念，不提責備；\n'
        '(2) 回顧：一句美好的共同回憶（可留通用版）；\n'
        '(3) 關心：詢問近況，表示願意傾聽；\n'
        '(4) 留門：告訴對方教會永遠歡迎他/她回來；\n'
        '(5) 結語：祝福語 + 署名欄（留空）。\n'
        '請用繁體中文，約 150-200 字，語氣像朋友而非機構。');
    return buf.toString();
  }

  String _buildPastoralNewsletterPrompt(String period) {
    final care = globalCareController;
    final people = globalPersonController;
    final buf = StringBuffer();
    buf.writeln('請為「$period」生成一份教會牧養週訊草稿，'
        '適合以 WhatsApp 群組或 Email 發送給教牧同工。\n');
    buf.writeln('【本期教牧資料】');
    buf.writeln('- 活躍關懷案件：${care.activeCount} 件'
        '（紅燈 ${care.redCount} / 黃燈 ${care.yellowCount} / 綠燈 ${care.greenCount}）');
    buf.writeln('- 總會友：${people.totalCount} 人'
        '（定期 ${people.regularCount} / 偶爾 ${people.occasionalCount} / 久缺 ${people.inactiveCount}）');

    final redCases = care.casesByAlert(CareAlertLevel.red).take(5).toList();
    if (redCases.isNotEmpty) {
      buf.writeln('\n【需緊急跟進（紅燈）】');
      for (final c in redCases) {
        final days = care.daysSinceLastTouch(c) ?? 0;
        buf.writeln('- ${c.memberName}｜${c.reason}｜已 $days 天未探訪');
      }
    }

    buf.writeln('\n週訊結構：\n'
        '(1) 本期關懷重點（根據以上紅燈案件，2-3 句）；\n'
        '(2) 感恩事項（鼓勵同工，1-2 項，留空供填寫）；\n'
        '(3) 本週行動清單（每位同工各 1-2 項待辦，格式：【負責人】事項）；\n'
        '(4) 下次同工會議提醒欄（留空）；\n'
        '(5) 牧者話語（鼓勵性金句或禱告，2-3 句）。\n'
        '請用繁體中文，語氣專業而溫暖，適合同工團隊閱讀。');
    return buf.toString();
  }

  String _buildSundaySchoolPrompt(String topic) {
    return '請為兒童主日學設計一份完整教案，主題：「$topic」。\n\n'
        '適合年齡：4-12 歲（可分低年級 4-7 歲 / 高年級 8-12 歲兩版本）\n\n'
        '教案結構：\n'
        '(1) 學習目標（3 條，使用「孩子能…」句式）；\n'
        '(2) 主題經文（1 節，附章節，選孩子易懂的版本）；\n'
        '(3) 開場暖身活動（5 分鐘，互動遊戲或問題）；\n'
        '(4) 故事講述大綱（10 分鐘，3-4 個情節點，生動具畫面感）；\n'
        '(5) 互動問答（3 條問題，由淺入深）；\n'
        '(6) 手工 ／ 繪畫活動建議（10 分鐘，材料清單 + 步驟）；\n'
        '(7) 結束禱告（兒童能跟著說的短禱告，5 句以內）；\n'
        '(8) 帶回家的信息（1 句話，讓孩子告訴父母今天學到什麼）。\n\n'
        '請用繁體中文，語言生動活潑，避免過深神學術語。';
  }

  // ── v2.4 prompt builders ─────────────────────────────────────────────────

  String _buildMeetingAgendaPrompt(String dept) {
    final care = globalCareController;
    final people = globalPersonController;
    final buf = StringBuffer();
    buf.writeln('請為「$dept」生成一份部門會議議程草稿，格式專業、結構清晰，'
        '可直接在會議中使用。\n');
    buf.writeln('【教會目前概況（背景參考）】');
    buf.writeln('- 總會友：${people.totalCount} 人 ／ 活躍關懷案件：${care.activeCount} 件');
    buf.writeln('- 紅燈案件：${care.redCount} 件（需優先處理）\n');
    buf.writeln('議程結構（請依以下格式生成）：\n'
        '【$dept 會議議程】\n'
        '日期：_______ ／ 時間：_______ ／ 地點：_______\n'
        '主持：_______ ／ 記錄：_______\n\n'
        '1. 開會禱告（5 分鐘）\n'
        '2. 上次會議行動事項跟進（10 分鐘）\n'
        '   - [請列出 3 個常見待跟進項目範例]\n'
        '3. 本月重點報告（15 分鐘）\n'
        '   - [請針對 $dept 列出 3 個常見報告項目]\n'
        '4. 討論事項（20 分鐘）\n'
        '   - [請列出 2-3 個 $dept 常見討論議題]\n'
        '5. 行動事項確認（5 分鐘）\n'
        '   - 負責人：_______ ／ 完成日期：_______\n'
        '6. 下次會議日期：_______\n'
        '7. 結束禱告\n\n'
        '請用繁體中文，實際內容請根據 $dept 的常見職責填寫。');
    return buf.toString();
  }

  String _buildMinistryPlanPrompt(String dept) {
    final people = globalPersonController;
    return '請為「$dept」生成一份年度事工計劃草稿，涵蓋 12 個月，'
        '格式適合提交長執會或教牧會議審閱。\n\n'
        '教會會友人數：${people.totalCount} 人（定期出席 ${people.regularCount} 人）。\n\n'
        '計劃結構：\n'
        '1. 事工異象與目標（2-3 句，說明本年度重點方向）\n'
        '2. 年度目標（3 個 SMART 目標，可量化）\n'
        '3. 月度活動計劃（1 月至 12 月，每月 1-2 個重點活動）\n'
        '4. 人力需求（義工人數、技能要求）\n'
        '5. 預算概估（分：場地 / 物資 / 宣傳 / 其他）\n'
        '6. 成效評估方式（如何知道目標達成）\n'
        '7. 緊急聯絡人欄位（留空）\n\n'
        '請用繁體中文，計劃要實際可行，適合 $dept 的常見事工範圍。';
  }

  String _buildVolunteerRecruitPrompt(String role) {
    return '請為教會服事崗位「$role」生成一套完整的志工招募文案，包括：\n\n'
        '(1) 招募海報標題（10 字以內，吸引人）；\n'
        '(2) 崗位介紹（50 字，說明這份服事的意義與影響力）；\n'
        '(3) 主要職責（條列 3-5 項）；\n'
        '(4) 適合對象（技能、性格、時間承諾）；\n'
        '(5) 時間要求（每週/每月幾小時，清晰說明）；\n'
        '(6) 提供支援（培訓、同行、屬靈陪伴）；\n'
        '(7) 報名方式欄位（留空：聯絡人、電話、截止日期）；\n'
        '(8) WhatsApp 群組分享版本（100 字以內，包含 emoji 讓視覺更活潑）。\n\n'
        '請用繁體中文，語氣熱情邀請，強調服事的屬靈意義，避免只列職責。';
  }

  String _buildAppreciationLetterPrompt(String input) {
    // input format: "姓名|事由" or just "姓名"
    final parts = input.split('|');
    final name = parts[0].trim();
    final reason = parts.length > 1 ? parts[1].trim() : '';
    final people = globalPersonController;
    final person = people.findByName(name);

    final buf = StringBuffer();
    buf.writeln('請為「$name」撰寫一封教會感謝狀，'
        '語氣真誠溫暖，讓收信人感受到被珍視與肯定。\n');
    if (reason.isNotEmpty) buf.writeln('感謝事由：$reason\n');
    if (person != null && person.notes.isNotEmpty) {
      buf.writeln('會友備註（參考）：${person.notes}\n');
    }
    buf.writeln('感謝狀結構：\n'
        '(1) 稱謂（親愛的 $name 弟兄/姊妹）；\n'
        '(2) 開場感謝（1-2 句，具體說明感謝什麼）；\n'
        '(3) 肯定段落（描述此人服事的影響與貢獻，3-4 句，生動有畫面感）；\n'
        '(4) 屬靈鼓勵（引用 1 節聖經，附上個人化鼓勵語）；\n'
        '(5) 結語祝福（1-2 句，溫暖有力）；\n'
        '(6) 署名欄（教會名稱 ／ 牧師姓名 ／ 日期，留空）。\n\n'
        '請用繁體中文，約 200 字，可作為正式感謝狀列印或電郵發送。\n'
        '格式提示：以「感謝狀」為標題，正文居中，莊重而溫馨。');
    return buf.toString();
  }

  // ── v2.5 prompt builders ─────────────────────────────────────────────────

  String _buildPastoralPrayerLetterPrompt(String name) {
    final care = globalCareController;
    final people = globalPersonController;
    final buf = StringBuffer();
    buf.writeln('請為會友「$name」撰寫一封牧養禱告信，'
        '目的是讓對方感受到牧者真誠的關懷與代禱。\n');

    final person = people.findByName(name);
    if (person != null) {
      buf.writeln('【會友資料】');
      buf.writeln('出席狀況：${person.attendance}');
      if (person.notes.isNotEmpty) buf.writeln('備註：${person.notes}');
    }

    final related = care.allCases
        .where((c) =>
            c.memberName.contains(name) || name.contains(c.memberName))
        .take(3)
        .toList();
    if (related.isNotEmpty) {
      buf.writeln('\n【關懷背景】');
      for (final c in related) {
        final last = care.lastVisitFor(c.id);
        buf.writeln('- ${c.reason}');
        if (last != null) buf.writeln('  最近探訪摘要：${last.summary}');
      }
    }

    buf.writeln('\n信件結構：\n'
        '(1) 稱謂與問候（溫暖親切，提及名字）；\n'
        '(2) 牧者代禱段落（根據上述背景寫出 3 個具體代禱點，引用 1 節聖經）；\n'
        '(3) 屬靈鼓勵（2-3 句，針對當前處境給予力量）；\n'
        '(4) 邀請對話（表達願意傾聽，不施壓）；\n'
        '(5) 祝福結語 + 署名欄（留空）。\n'
        '請用繁體中文，約 200 字，語氣如同牧者親筆書寫。');
    return buf.toString();
  }

  String _buildBaptismWitnessPrompt(String name) {
    return '請為準備受洗的慕道友「$name」設計一套受洗見證引導問卷，'
        '幫助輔導員與受洗者整理信仰歷程。\n\n'
        '問卷結構（共 3 個部分）：\n\n'
        '【第一部分：信仰歷程（6 條問題）】\n'
        '- 您是如何第一次接觸基督教的？\n'
        '- [再列出 5 條引導回顧信仰旅程的問題]\n\n'
        '【第二部分：生命改變（4 條問題）】\n'
        '- 信主後您在哪方面有最大的改變？\n'
        '- [再列出 3 條探討生命轉變的問題]\n\n'
        '【第三部分：未來方向（3 條問題）】\n'
        '- 受洗後您希望如何在教會生活中成長？\n'
        '- [再列出 2 條關於未來屬靈承諾的問題]\n\n'
        '最後提供：\n'
        '- 受洗見證撰寫框架（200-300 字，3 段式：過去 / 遇見主 / 現在）\n'
        '- 受洗典禮常見問答 3 條（Q&A 格式）\n\n'
        '請用繁體中文，問題簡單易懂，適合初信者作答。';
  }

  String _buildElderOrdainationPrompt(String name) {
    final people = globalPersonController;
    return '請為即將就職的長老或執事「$name」撰寫一份就職感言草稿框架，'
        '幫助他/她在就職典禮上分享屬靈心志。\n\n'
        '教會現有 ${people.totalCount} 位會友（定期出席 ${people.regularCount} 人）。\n\n'
        '感言結構（約 300-400 字，可朗讀 2-3 分鐘）：\n'
        '(1) 開場感謝（感謝神、教會弟兄姊妹、家人，各 1-2 句）；\n'
        '(2) 蒙召見證（簡述神如何引領走上服事之路，3-4 句）；\n'
        '(3) 服事心志（3 個承諾，具體說明如何牧養/服事弟兄姊妹）；\n'
        '(4) 主題經文（引用 1 節與服事相關的聖經，附上個人詮釋）；\n'
        '(5) 對教會的期望（1-2 句，盼望教會同心合意）；\n'
        '(6) 結束禱告（簡短，20 字以內，可帶領會眾同聲禱告）。\n\n'
        '請用繁體中文，語氣謙遜而有力，展現屬靈深度與服事熱忱。\n'
        '請留[方括號]標示需個人化填寫的部分。';
  }

  String _buildYearEndPastoralLetterPrompt(String year) {
    final care = globalCareController;
    final people = globalPersonController;
    final buf = StringBuffer();
    buf.writeln('請為教會生成「$year 年」年終牧師信（牧函）草稿，'
        '寄送給全體會友，語氣溫暖、有屬靈深度。\n');
    buf.writeln('【教會年度概況】');
    buf.writeln('- 總會友：${people.totalCount} 人'
        '（定期 ${people.regularCount} / 偶爾 ${people.occasionalCount} / 久缺 ${people.inactiveCount}）');
    buf.writeln('- 全年關懷案件：${care.allCases.length} 件'
        '（目前活躍 ${care.activeCount} 件）');
    buf.writeln('\n牧函結構（約 400-500 字）：\n'
        '(1) 年度回顧段落（感恩主恩，提及 2-3 個教會亮點，留空供填寫具體事件）；\n'
        '(2) 挑戰與成長（坦誠分享困難，但以感恩和信心回應，2-3 句）；\n'
        '(3) 主題經文（為全年選一節聖經，附上牧者詮釋與應用）；\n'
        '(4) 展望新年（3 個教會方向 / 目標，簡潔有力）；\n'
        '(5) 對弟兄姊妹的個人寄語（溫暖、鼓勵、看見每個人）；\n'
        '(6) 祝福禱告結語（4-6 句，可帶領讀者同禱）；\n'
        '(7) 署名欄（牧師名 / 教會名 / 日期，留空）。\n'
        '請用繁體中文，語氣如同牧者親筆，讓每位會友感受到被牧者記念。');
    return buf.toString();
  }

  // ── v2.6 prompt builders ─────────────────────────────────────────────────

  String _buildEvangelismInvitePrompt(String eventName) {
    final people = globalPersonController;
    return '請為教會佈道會「$eventName」生成完整的邀請文案套件，'
        '目標對象：未信主的朋友、家人、同事。\n\n'
        '教會目前有 ${people.totalCount} 位會友。\n\n'
        '文案套件包括：\n'
        '(1) 邀請卡正面文案（20 字以內標題 + 30 字副標，吸引非信徒）；\n'
        '(2) 邀請卡背面資訊欄（日期/時間/地點/停車，留空供填寫）；\n'
        '(3) 口頭邀請話術（3 個版本：朋友版 / 同事版 / 家人版，各 2-3 句）；\n'
        '(4) WhatsApp/Line 分享短文（100 字，包含活動亮點，不過度宗教化）；\n'
        '(5) 社群媒體 Instagram 短文（3 句 + 5 個 hashtag）；\n'
        '(6) 反對意見回應指引（3 個常見拒絕理由 + 溫和回應方式）。\n\n'
        '請用繁體中文，語氣友善、現代、不強迫，讓會友容易開口邀請。';
  }

  String _buildFuneralComfortPrompt(String name) {
    final care = globalCareController;
    final related = care.allCases
        .where((c) =>
            c.memberName.contains(name) || name.contains(c.memberName))
        .take(2)
        .toList();

    final buf = StringBuffer();
    buf.writeln('請為喪親的「$name」生成牧關支援套件，幫助牧者在哀傷陪伴中有所依循。\n');

    if (related.isNotEmpty) {
      buf.writeln('【相關背景】');
      for (final c in related) {
        buf.writeln('- ${c.reason}');
      }
      buf.writeln();
    }

    buf.writeln('套件包括：\n'
        '(1) 安慰信（150-200 字，真誠溫暖，不說空話，引用 1 節安慰經文）；\n'
        '(2) 追思禮拜程序建議（含詩歌建議 2 首、追思分享引導問題 3 條）；\n'
        '(3) 哀傷陪伴指引（牧者探訪時的 5 個注意事項 + 3 句禁忌語）；\n'
        '(4) 後續關懷時間表（第 1 週 / 第 1 個月 / 3 個月後各 1 個具體行動）；\n'
        '(5) 聖經安慰金句（5 節，附簡短說明，可用於卡片或分享）。\n'
        '請用繁體中文，語氣莊重、溫柔，體現基督徒對死亡的盼望而非回避悲傷。');
    return buf.toString();
  }

  String _buildLifeMilestonePrayerPrompt(String occasion) {
    return '請為「$occasion」典禮生成一套完整的禱告詞框架，'
        '適合在教會典禮中由牧者帶領。\n\n'
        '套件包括：\n'
        '(1) 開場禱告（2-3 句，感謝神賜下此美好時刻）；\n'
        '(2) 主禱文朗讀引導（適合此場合的主禱文簡介語 1 句）；\n'
        '(3) 主禮祝福禱告（8-10 句，具體為當事人祈求神的恩典，'
        '根據場合強調不同祝福重點）；\n'
        '(4) 會眾同心禱告（帶領詞 + 2-3 句會眾可跟著說的回應語）；\n'
        '(5) 結束祝禱（4-6 句，莊嚴美麗，以「阿們」結束）；\n'
        '(6) 場合專屬詩歌建議（2 首，附建議用途：進場/結束）。\n\n'
        '請用繁體中文，語氣莊嚴而喜悅，展現基督信仰對此里程碑的祝聖意義。\n'
        '請用[方括號]標示牧者需個人化填寫的部分。';
  }

  String _buildMissionReportPrompt(String mission) {
    final people = globalPersonController;
    return '請為「$mission」宣教行動生成一份宣教報告草稿，'
        '適合在主日宣教報告或長執會提交。\n\n'
        '教會背景：${people.totalCount} 位會友，定期出席 ${people.regularCount} 人。\n\n'
        '報告結構：\n'
        '(1) 封面資訊欄（宣教地點 / 日期 / 參與人數 / 報告人，留空）；\n'
        '(2) 行程概述（每天一行重點，留空格式供填寫）；\n'
        '(3) 神蹟與感恩（3-5 個可分享的恩典時刻，格式：事件 + 感受 + 聖經印證）；\n'
        '(4) 挑戰與禱告事項（2-3 項，坦誠分享困難，請會眾代禱）；\n'
        '(5) 對差派教會的影響（宣教隊員的個人生命改變，3 個見證框架）；\n'
        '(6) 後續跟進計劃（3 個短期 + 1 個長期行動）；\n'
        '(7) 財務使用摘要（支出類別列表，留空）；\n'
        '(8) 感謝段落（感謝教會支持，鼓勵未來參與，2-3 句）。\n\n'
        '請用繁體中文，語氣真誠感恩，讓會眾感受到宣教的使命感。';
  }

  // ── v2.7 prompt builders ─────────────────────────────────────────────────

  String _buildAnnualReportPrompt(String year) {
    final care = globalCareController;
    final people = globalPersonController;
    final buf = StringBuffer();
    buf.writeln('請為「$year 年」生成一份教會年報摘要草稿，'
        '格式正式，適合印刷成冊或 PDF 對外發布。\n');
    buf.writeln('【年度數據（自動帶入）】');
    buf.writeln('- 總會友人數：${people.totalCount} 人');
    buf.writeln(
        '  （正式會員 ${people.memberCount} / 慕道友 ${people.seekerCount}）');
    buf.writeln('  （定期出席 ${people.regularCount} / 偶爾 ${people.occasionalCount}'
        ' / 久缺 ${people.inactiveCount}）');
    buf.writeln('- 全年關懷案件：${care.allCases.length} 件'
        '（活躍 ${care.activeCount} / 已結案 ${care.closedCount}）');
    buf.writeln('- 全年探訪記錄：${care.allVisits.length} 次\n');
    buf.writeln('年報結構：\n'
        '(1) 封面頁元素（教會名稱 / 年份 / 主題經文，留空）；\n'
        '(2) 牧者序言（200 字，感恩回顧 + 展望，請留[方括號]個人化）；\n'
        '(3) 教會簡介（歷史沿革、異象使命，各 2-3 句，留空格式）；\n'
        '(4) $year 年主要事工回顧（按季度，每季 2-3 項，留空格式）；\n'
        '(5) 關懷與牧養統計摘要（用上方數據整理成段落）；\n'
        '(6) 財務摘要（收支欄位表格，留空）；\n'
        '(7) 感謝義工頁（格式：姓名 / 服事崗位，留空）；\n'
        '(8) 展望新年（3 個方向，簡潔）；\n'
        '(9) 封底元素（聯絡資訊、網址、社群，留空）。\n'
        '請用繁體中文，語氣正式而溫暖。');
    return buf.toString();
  }

  String _buildWeddingServicePrompt(String coupleName) {
    return '請為「$coupleName」的婚禮崇拜生成一份完整的典禮程序稿，'
        '包含司儀詞、牧者引導詞和所有禱告，可直接在婚禮中使用。\n\n'
        '程序稿結構（每個環節附：時間估算 / 司儀詞 / 牧者詞 / 備注）：\n'
        '1. 賓客入場（10 分鐘）\n'
        '   - 背景詩歌建議 2 首\n'
        '2. 新人進場（司儀引導詞）\n'
        '3. 開場禱告（牧者，4-6 句）\n'
        '4. 詩歌敬拜（1-2 首，建議曲目）\n'
        '5. 聖經讀段（推薦章節 2 個，附朗讀者引導語）\n'
        '6. 婚禮講道提綱（牧者，3 點式，10 分鐘）\n'
        '7. 婚誓（繁體中文版本，男女方各一段，莊嚴而真誠）\n'
        '8. 戒指禮（司儀詞 + 牧者祝福語）\n'
        '9. 宣告成婚（牧者宣告詞，引用聖經 創 2:24 或 可 10:9）\n'
        '10. 簽署婚書（背景音樂建議）\n'
        '11. 婚禮禱告（牧者，為新人未來生活代禱，8-10 句）\n'
        '12. 新人退場（司儀詞 + 詩歌建議）\n\n'
        '請用繁體中文，語氣莊嚴喜樂，在[方括號]標示需個人化填寫的部分。';
  }

  String _buildDedicationServicePrompt(String babyInfo) {
    // babyInfo: "嬰兒名字" or "父母姓名｜嬰兒名字"
    final parts = babyInfo.split('｜');
    final babyName = parts.length > 1 ? parts[1].trim() : parts[0].trim();
    final parentNames = parts.length > 1 ? parts[0].trim() : '';

    return '請為嬰兒「$babyName」'
        '${parentNames.isNotEmpty ? '（父母：$parentNames）' : ''}'
        '的奉獻禮生成完整典禮程序稿，可直接在主日崇拜中使用。\n\n'
        '程序稿（每個環節附：時間 / 引導語 / 注意事項）：\n'
        '1. 嬰兒奉獻宣告（司儀介紹，30 秒）\n'
        '2. 父母上台（司儀引導詞，溫馨）\n'
        '3. 牧者與家庭對話（問答式，3 個承諾問題）：\n'
        '   - 問父母：承諾在基督信仰中養育孩子（1 問）\n'
        '   - 問會眾：承諾支持與代禱（1 問）\n'
        '   - 問祖父母（如在場）：承諾的話（選用）\n'
        '4. 抱嬰兒禱告（牧者，8-10 句，溫柔有力，呼求神保守嬰兒一生）\n'
        '5. 為父母禱告（牧者，4-6 句，祈求智慧與力量）\n'
        '6. 為家庭代禱（會眾同心，牧者帶領 3-4 句）\n'
        '7. 奉獻詩歌（1 首推薦，牧者引導轉接詞）\n'
        '8. 拍照留念（司儀安排詞）\n\n'
        '請用繁體中文，語氣溫暖喜悅，充滿對新生命的感恩。\n'
        '在[方括號]標示需個人化填寫的部分。';
  }

  String _buildBibleSeriesPrompt(String seriesTitle) {
    return '請為「$seriesTitle」設計一套完整的多週小組查經課程，'
        '適合 8-12 人的小組，每週 90 分鐘。\n\n'
        '課程總覽：\n'
        '(1) 系列目標（3 條學習目標，說明完成後小組成員能…）；\n'
        '(2) 建議週數（根據主題建議 4-8 週）；\n'
        '(3) 所需材料清單（聖經版本建議、筆記本、備用資源）。\n\n'
        '每週課程格式（生成第 1 週完整版，其餘週數提供標題與核心經文）：\n\n'
        '【第 1 週：[標題]】\n'
        '- 主題經文：[章節]\n'
        '- 預習功課：[1-2 項，讓組員提前閱讀]\n'
        '- 開場暖身（10 分鐘）：[破冰問題 1 條]\n'
        '- 觀察環節（15 分鐘）：[3 條觀察問題，What does it say?]\n'
        '- 詮釋環節（25 分鐘）：[3 條詮釋問題，What does it mean?]\n'
        '- 應用環節（20 分鐘）：[3 條應用問題，How do I live it?]\n'
        '- 代禱分享（10 分鐘）：[引導組員分享代禱事項的提示語]\n'
        '- 下週功課：[預習任務]\n\n'
        '[第 2-N 週：僅提供標題、主題經文與核心問題各 1 條]\n\n'
        '請用繁體中文，問題由淺入深，鼓勵真實分享而非標準答案。';
  }

  // ── v2.8 prompt builders ─────────────────────────────────────────────────

  String _buildPostEvangelismFollowUpPrompt(String eventName) {
    final care = globalCareController;
    final people = globalPersonController;
    return '請為「$eventName」佈道會結束後，生成一份新信徒跟進計劃，'
        '幫助教會同工在黃金 72 小時內有效牧養決志者。\n\n'
        '教會背景：${people.totalCount} 位會友，目前活躍關懷案件 ${care.activeCount} 件。\n\n'
        '跟進計劃結構：\n\n'
        '【第一階段：72 小時內】\n'
        '(1) 感謝信範本（給決志者，100 字，溫暖真誠，附邀請下次聚會）；\n'
        '(2) 首次跟進電話話術（3-5 句，自我介紹 + 關心 + 邀請）；\n'
        '(3) 新信徒資料表欄位（姓名/電話/Email/如何決志，留空格式）。\n\n'
        '【第二階段：首兩週】\n'
        '(4) 新信徒第一次見面議程（30 分鐘，分享信仰/回答問題/禱告）；\n'
        '(5) 建議送出的資源（聖經版本、入門小冊、WhatsApp 群組）；\n'
        '(6) 配對輔導員原則（如何為新信徒選擇合適的跟進同工）。\n\n'
        '【第三階段：首 3 個月】\n'
        '(7) 新信徒栽培路徑圖（每月里程碑：第 1 月 / 第 2 月 / 第 3 月）；\n'
        '(8) 受洗準備時間表（建議接觸受洗課程的時機）；\n'
        '(9) 融入小組策略（如何自然地邀請新信徒加入小組）。\n\n'
        '請用繁體中文，語氣積極實際，讓普通義工也能按步執行。';
  }

  String _buildSmallGroupLeaderTrainingPrompt(String duration) {
    final people = globalPersonController;
    return '請為教會設計一套「小組長培訓課程」大綱，培訓時長：$duration。\n\n'
        '教會規模：${people.totalCount} 位會友（${people.regularCount} 人定期出席）。\n\n'
        '課程目標：培育有效帶領小組、牧養組員的小組長。\n\n'
        '培訓大綱結構：\n\n'
        '【模組一：小組長的身份認同（25%）】\n'
        '- 學習目標（3 條）\n'
        '- 核心內容：服事呼召、僕人領袖、靈命自我照顧\n'
        '- 實踐練習：個人靈命評估表（5 題）\n\n'
        '【模組二：帶領查經的技巧（25%）】\n'
        '- 學習目標（3 條）\n'
        '- 核心內容：歸納式查經法、提問技巧、避免單向教導\n'
        '- 實踐練習：模擬帶領查經 10 分鐘\n\n'
        '【模組三：牧養與關係建立（25%）】\n'
        '- 學習目標（3 條）\n'
        '- 核心內容：主動關心、危機識別、轉介牧者的時機\n'
        '- 實踐練習：角色扮演 —— 如何回應組員的哀傷\n\n'
        '【模組四：小組倍增與傳承（25%）】\n'
        '- 學習目標（3 條）\n'
        '- 核心內容：識別潛力領袖、授權文化、健康分組\n'
        '- 實踐練習：制定本組未來 6 個月倍增計劃\n\n'
        '附：培訓後評估問卷（5 條問題）\n'
        '請用繁體中文，內容實用，避免純理論。';
  }

  String _buildYouthMinistryPlanPrompt(String theme) {
    final people = globalPersonController;
    final youthCount = people.seekerCount + (people.totalCount ~/ 5);
    return '請為主題「$theme」設計一份青少年事工活動方案，'
        '適合 13-25 歲青少年，約 ${youthCount > 0 ? youthCount : 20} 人參與。\n\n'
        '活動方案結構：\n\n'
        '(1) 活動名稱與標語（中英對照，各 10 字以內）；\n'
        '(2) 活動目標（3 個，說明參與後青少年能…）；\n'
        '(3) 活動形式選項（至少 3 種：退修營 / 主日延伸 / 週間活動，各附時長）；\n\n'
        '【完整方案（選其中一種形式展開，建議半天活動）】\n'
        '(4) 詳細流程（時間軸，每段 15-30 分鐘，含：\n'
        '    - 暖場遊戲 / 敬拜讚美 / 信息 / 小組分享 / 回應與禱告）；\n'
        '(5) 信息大綱（3 點，結合主題與青少年生活處境）；\n'
        '(6) 小組討論問題（3 條，適合青少年真實表達）；\n'
        '(7) 遊戲活動設計（1 個暖場遊戲，附規則與所需材料）；\n'
        '(8) 物資清單（場地/音響/食物/文具，分類列出）；\n'
        '(9) 社群宣傳文案（Instagram 版 + WhatsApp 版，各 1 則）；\n'
        '(10) 跟進建議（活動後 1 週如何鞏固果效）。\n\n'
        '請用繁體中文，語氣年輕活潑，貼近青少年文化，避免說教。';
  }

  String _buildElderBoardMeetingPrompt(String date) {
    final care = globalCareController;
    final people = globalPersonController;
    final buf = StringBuffer();
    buf.writeln('請為「$date」長執會議生成一份完整的議程與決議追蹤表，'
        '格式正式，適合教會治理使用。\n');
    buf.writeln('【教會即時數據（自動帶入）】');
    buf.writeln('- 總會友：${people.totalCount} 人'
        '（定期 ${people.regularCount} / 偶爾 ${people.occasionalCount} / 久缺 ${people.inactiveCount}）');
    buf.writeln('- 活躍關懷案件：${care.activeCount} 件'
        '（紅燈 ${care.redCount} 需優先處理）');
    buf.writeln('- 新慕道友：${people.seekerCount} 人\n');
    buf.writeln('會議議程格式：\n\n'
        '【$date 長執會議議程】\n'
        '會議時間：_______ ／ 地點：_______\n'
        '出席：_______ ／ 列席：_______ ／ 記錄：_______\n\n'
        '1. 開會禱告（5 分鐘）\n'
        '2. 確認上次會議記錄（5 分鐘）\n'
        '3. 牧者報告（15 分鐘）\n'
        '   3.1 教牧關懷：活躍案件 ${care.activeCount} 件（含紅燈 ${care.redCount} 件），[具體說明]\n'
        '   3.2 屬靈動態：[近期教會屬靈狀況]\n'
        '   3.3 待長執會決議事項：[列出需要決議的事項]\n'
        '4. 部門報告（20 分鐘，各部門 3-5 分鐘）\n'
        '   - 敬拜部：[留空]\n'
        '   - 兒童/青少年部：[留空]\n'
        '   - 關懷部：[留空]\n'
        '   - 財務：[留空]\n'
        '5. 討論與決議（20 分鐘）\n'
        '   [請列出 3 個教會常見需要長執決議的議題作範例]\n'
        '6. 代禱事項（10 分鐘）\n'
        '7. 下次會議日期：_______ ／ 散會禱告\n\n'
        '---\n'
        '【決議追蹤表】\n'
        '| 決議事項 | 負責人 | 完成期限 | 狀態 | 備注 |\n'
        '|----------|--------|----------|------|------|\n'
        '| [範例 1] | ______ | ________ | 進行中 | |\n'
        '| [範例 2] | ______ | ________ | 待辦 | |\n'
        '| [範例 3] | ______ | ________ | 已完成 | |\n\n'
        '請用繁體中文，格式正式，符合教會治理規範。');
    return buf.toString();
  }

  // ── v2.9 prompt builders ─────────────────────────────────────────────────

  String _buildSmallGroupMonthlyReportPrompt(String month) {
    final care = globalCareController;
    return '請為小組長生成「$month」月度報告模板，'
        '方便小組長每月向牧者／教牧同工提交，格式簡潔高效。\n\n'
        '教會整體：活躍關懷案件 ${care.activeCount} 件，供小組長參考對照。\n\n'
        '月報模板結構：\n\n'
        '【$month 小組月報】\n'
        '小組名稱：_______ ／ 組長姓名：_______ ／ 提交日期：_______\n\n'
        '1. 出席統計\n'
        '   - 本月平均出席人數：_____ 人 ／ 總組員人數：_____ 人\n'
        '   - 出席率：_____%\n'
        '   - 新加入組員：（姓名 + 首次出席日期）\n'
        '   - 本月缺席超過 2 次的組員：（姓名 + 原因）\n\n'
        '2. 靈命與查經\n'
        '   - 本月查經主題：_______\n'
        '   - 組員參與度評估（1-5 分）：_____ ／ 主要收穫：_______\n'
        '   - 組員分享的生命改變：（1-2 則）\n\n'
        '3. 關懷狀況\n'
        '   - 需要牧者跟進的組員：（姓名 + 情況摘要）\n'
        '   - 本月關懷行動：（探訪 / 電話 / 祝福食物等）\n'
        '   - 有緊急需要的組員：（請標明，牧者優先跟進）\n\n'
        '4. 外展與邀請\n'
        '   - 本月新朋友帶來人數：_____ 人\n'
        '   - 佈道對象跟進情況：_______\n\n'
        '5. 組長個人反思\n'
        '   - 本月帶領最大挑戰：_______\n'
        '   - 需要牧者支援的事項：_______\n'
        '   - 下月計劃：_______\n\n'
        '6. 代禱事項（3-5 條，為組員保密原則下摘要）\n\n'
        '請用繁體中文，格式清晰，小組長填寫不超過 15 分鐘。';
  }

  String _buildEvangelismTrainingPrompt(String format) {
    final people = globalPersonController;
    return '請為教會設計一套「門徒佈道訓練課程」大綱，格式：$format。\n\n'
        '目標學員：普通會友（非神學背景），教會共 ${people.totalCount} 位會友。\n\n'
        '課程目標：裝備會友能自然、有信心地向親友分享信仰。\n\n'
        '課程大綱：\n\n'
        '【單元一：為什麼要傳福音？（20%）】\n'
        '- 學習目標：理解大使命、克服恐懼、明白福音本質\n'
        '- 核心內容：大使命（太 28:19）、愛的動機、福音的定義\n'
        '- 互動活動：分享「我不開口的原因」+ 小組禱告\n\n'
        '【單元二：我的見證（20%）】\n'
        '- 學習目標：能用 3 分鐘說清楚個人信仰見證\n'
        '- 核心內容：見證三段式（信主前/關鍵時刻/信主後）\n'
        '- 實踐練習：兩人一組練習分享，互相給予回饋\n\n'
        '【單元三：清楚表達福音（30%）】\n'
        '- 學習目標：能用生活語言解釋福音核心\n'
        '- 核心內容：橋梁圖 / 四個屬靈定律 / 簡單問題引導法\n'
        '- 角色扮演：模擬朋友問「什麼是基督徒」的對話\n\n'
        '【單元四：日常生活中的佈道（30%）】\n'
        '- 學習目標：建立長期關係佈道的習慣\n'
        '- 核心內容：禱告名單（3 位未信朋友）、服侍佈道、邀請\n'
        '- 行動承諾：每人寫下 3 位代禱對象 + 30 天行動計劃\n\n'
        '附：評估問卷（課前/課後對比，各 5 題）\n'
        '請用繁體中文，語氣鼓勵，讓普通會友不感到壓力。';
  }

  String _buildNewcomerIntegrationPrompt(String name) {
    final people = globalPersonController;
    final care = globalCareController;
    return '請為剛開始定期來教會的新人「$name」制定一份「6 個月融入計劃」，'
        '目標是讓他/她在半年內從訪客變成有歸屬感的肢體。\n\n'
        '（注意：此計劃針對已多次出席的新人，有別於佈道會後的 72 小時緊急跟進。）\n\n'
        '教會背景：${people.totalCount} 位會友，定期出席 ${people.regularCount} 人，'
        '活躍關懷 ${care.activeCount} 件。\n\n'
        '六個月路徑圖：\n\n'
        '【第 1 個月：認識與接納】\n'
        '- 配對歡迎同工（職責、第一個月行動清單）\n'
        '- 重點里程碑：完成個人探訪 1 次 + 邀請參加小組 1 次\n'
        '- 同工話術：3 句自然邀約語\n\n'
        '【第 2-3 個月：參與與歸屬】\n'
        '- 重點里程碑：穩定參與小組 + 認識 5 位弟兄姊妹\n'
        '- 建議邀請活動（2-3 個適合新人的教會活動）\n'
        '- 評估：用 3 個問題評估歸屬感進度\n\n'
        '【第 4-5 個月：服事探索】\n'
        '- 重點里程碑：嘗試一個服事崗位（試用期）\n'
        '- 恩賜探索對話（牧者/小組長與新人的 30 分鐘談話框架）\n\n'
        '【第 6 個月：委身確認】\n'
        '- 重點里程碑：參加入會課程 / 考慮受洗\n'
        '- 6 個月總結對話（評估問題 5 條）\n\n'
        '請用繁體中文，計劃具體可執行，讓義工同工照著做。';
  }

  String _buildAGMSpeechPrompt(String year) {
    final care = globalCareController;
    final people = globalPersonController;
    final buf = StringBuffer();
    buf.writeln('請為「$year 年」教會年度大會（AGM）生成牧者演講稿草稿，'
        '供牧者在全體會友年度大會上口頭報告，時長約 15-20 分鐘。\n\n'
        '（注意：此為口頭演講稿，有別於印刷版年報。'
        '語氣自然、口語化，適合即席朗讀或提示卡使用。）\n');
    buf.writeln('【年度數據（自動帶入供演講參考】');
    buf.writeln('- 總會友：${people.totalCount} 人（定期 ${people.regularCount} 人）');
    buf.writeln('- 慕道友：${people.seekerCount} 人');
    buf.writeln('- 全年關懷案件：${care.allCases.length} 件（結案 ${care.closedCount} 件）');
    buf.writeln('- 全年探訪：${care.allVisits.length} 次\n');
    buf.writeln('演講稿結構（請在每段落提供完整口語化文字）：\n\n'
        '1. 開場白（2 分鐘）：感謝弟兄姊妹出席，開場禱告引用語，輕鬆拉近距離\n'
        '2. 過去一年回顧（5 分鐘）：3 個感恩亮點，坦誠提及 1-2 個挑戰\n'
        '3. 數字背後的故事（3 分鐘）：用上方數據說出有溫度的牧養故事\n'
        '4. 感謝同工段落（2 分鐘）：感謝義工、長執、部門同工（留空格式）\n'
        '5. 財務報告簡述（1 分鐘）：口頭摘要版，引導查看書面報告\n'
        '6. 新年展望（3 分鐘）：3 個方向，熱情有感染力\n'
        '7. 結束呼召（2 分鐘）：邀請委身，結束禱告\n\n'
        '請用繁體中文口語化表達，加入[掌聲/停頓]等提示，'
        '讓演講自然流暢，有笑點也有感動點。');
    return buf.toString();
  }

  // ── v2.10 prompt builders ────────────────────────────────────────────────

  String _buildAnnualBudgetPrompt(String year) {
    final care = globalCareController;
    final people = globalPersonController;
    return '請為「$year 年度」生成一份教會預算草案框架，'
        '協助財務同工與長執會制定全年收支計劃。\n\n'
        '教會規模：${people.totalCount} 位會友（定期出席 ${people.regularCount} 人）。\n'
        '關懷事工：活躍案件 ${care.activeCount} 件，需預留關懷探訪資源。\n\n'
        '預算草案結構：\n\n'
        '【A. 收入預算】\n'
        '1. 定期奉獻（按出席人數估算範圍）\n'
        '2. 什一收入（估算欄）\n'
        '3. 特別奉獻（聖誕/感恩/建堂等，列出場合）\n'
        '4. 活動收入（報名費等）\n'
        '5. 其他收入\n'
        '   → 收入合計欄\n\n'
        '【B. 支出預算（按優先順序）】\n'
        '1. 人事費用（牧者薪酬、兼職同工，佔比建議）\n'
        '2. 場地租金/按揭\n'
        '3. 崇拜事工（音響/詩歌版權/投影）\n'
        '4. 關懷事工（探訪/慰問/危機支援，參考 ${care.activeCount} 件案件）\n'
        '5. 兒童/青少年事工\n'
        '6. 宣教奉獻（建議比例）\n'
        '7. 行政費用（印刷/辦公/保險）\n'
        '8. 訓練發展（同工培訓/會議）\n'
        '9. 緊急備用金（建議 3 個月支出）\n'
        '   → 支出合計欄 → 預計結餘\n\n'
        '【C. 財務健康指標】\n'
        '- 人事費用佔總收入建議上限（%）\n'
        '- 宣教奉獻建議下限（%）\n'
        '- 備用金目標（月數）\n\n'
        '請用繁體中文，每項提供「建議金額範圍」或「計算公式」，'
        '方便財務同工填入實際數字。';
  }

  String _buildCellMultiplicationPrompt(String groupName) {
    final people = globalPersonController;
    return '請為「$groupName」設計一份小組倍增（分植）計劃，'
        '幫助組長和牧者有策略地培育下一代領袖並健康分組。\n\n'
        '教會目前：${people.totalCount} 位會友（定期 ${people.regularCount} 人），'
        '小組倍增有助達到理想的牧養比例。\n\n'
        '倍增計劃結構：\n\n'
        '【評估階段（現在）】\n'
        '1. 倍增時機評估表（5 個指標：人數/領袖成熟度/組員委身/外展果效/財務）\n'
        '2. 潛力領袖識別框架（3 個特質 + 觀察期建議）\n\n'
        '【培育階段（3-6 個月）】\n'
        '3. 副組長培育路徑（月度里程碑：帶查經→帶關懷→帶聚會）\n'
        '4. 組員心理準備：如何溝通「分組是祝福」的信息框架\n'
        '5. 送舊迎新禮儀建議（告別聚會流程 + 新組第一次聚會設計）\n\n'
        '【分植後支援（3 個月）】\n'
        '6. 新組第 1 個月重點行動清單（牧者 + 新組長各 3 項）\n'
        '7. 倍增後追蹤評估（第 4 週 / 第 8 週 / 第 12 週各 1 次）\n'
        '8. 危機處理：若分組出現問題，牧者介入的 3 個步驟\n\n'
        '請用繁體中文，避免讓「分組」感覺是懲罰，強調倍增的屬靈意義。';
  }

  String _buildPastorSabbaticalPrompt(String duration) {
    final care = globalCareController;
    final people = globalPersonController;
    return '請為牧者生成一份「$duration」靈修休假計劃，'
        '包含安排交接、個人更新和復元的完整框架。\n\n'
        '教會背景：${people.totalCount} 位會友，活躍關懷案件 ${care.activeCount} 件，'
        '需在牧者休假前做好妥善交接。\n\n'
        '計劃結構：\n\n'
        '【休假前準備（出發前 2-4 週）】\n'
        '1. 交接清單：需移交給代理牧者/長執的事項（8-10 項）\n'
        '2. 緊急聯絡指引：哪些情況才需要打擾牧者（3-4 個明確標準）\n'
        '3. 代理安排：主日講道/探訪/長執會議的臨時安排建議\n'
        '4. 告別信：給會眾的簡短說明（100 字，溫暖不讓人擔心）\n\n'
        '【休假期間靈修計劃】\n'
        '5. 每日靈修框架（早禱 / 聖經閱讀 / 靈修日記 / 傍晚反思）\n'
        '6. 休假中建議的靈命更新活動（靜修 / 閱讀清單 / 創意表達）\n'
        '7. 身體健康：運動/飲食/睡眠的簡單目標\n'
        '8. 關係修復：家庭時間優先事項（若已婚/有子女）\n\n'
        '【復返後重新融入（回來後 2 週）】\n'
        '9. 復返第一週行動清單（輕緩接手，不立即全負荷）\n'
        '10. 分享更新：向長執和會眾分享靈修收穫的簡短框架\n\n'
        '請用繁體中文，語氣鼓勵，讓牧者真正得到休息而非帶著罪惡感離開。';
  }

  String _buildCrisisManagementPrompt(String crisisType) {
    final people = globalPersonController;
    return '請為教會「$crisisType」類型的危機生成一份處理指引，'
        '幫助牧者和長執在壓力下有序應對。\n\n'
        '教會規模：${people.totalCount} 位會友（${people.regularCount} 人定期出席）。\n\n'
        '危機處理指引結構：\n\n'
        '【第一步：立即評估（危機發生後 24 小時內）】\n'
        '1. 事件嚴重性評分表（1-5 級，各級別描述 + 對應行動）\n'
        '2. 第一時間通知對象清單（誰必須在 24 小時內知道）\n'
        '3. 緊急應對核心小組組成（牧者/長執/指定同工，各自職責）\n\n'
        '【第二步：對內溝通（受影響會友）】\n'
        '4. 對直接相關會友的溝通指引（面談話術 + 禁忌語）\n'
        '5. 對一般會眾的通知範本（簡短、誠實、不恐慌，100 字以內）\n'
        '6. 社群媒體管理：是否公開、如何回應詢問的 3 個原則\n\n'
        '【第三步：對外溝通（如需要）】\n'
        '7. 媒體詢問回應指引（統一發言人原則 + 標準回應格式）\n'
        '8. 法律考量提醒（哪些情況需諮詢法律顧問）\n\n'
        '【第四步：牧養與恢復】\n'
        '9. 受影響會友的牧養跟進計劃（3 個月時間軸）\n'
        '10. 全教會療癒儀式建議（特別祈禱會 / 牧者公開信 / 小組討論）\n'
        '11. 危機後學習：事後檢討會議框架（3 個問題）\n\n'
        '請用繁體中文，語氣沉穩而有希望，讓教會在危機中仍能見到神的帶領。\n'
        '注意：請避免對具體情況作出法律建議，提醒查詢專業人士。';
  }

  // ── v2.11 prompt builders ────────────────────────────────────────────────

  String _buildYouthAnnualPlanPrompt(String year) {
    final people = globalPersonController;
    final youthEst = people.seekerCount + (people.totalCount ~/ 5);
    return '請為「$year 年度」青少年事工生成一份完整的年度策略計劃，'
        '涵蓋全年 12 個月，適合向長執會提交審批。\n\n'
        '（注意：此為年度策略計劃，有別於單次活動方案。）\n\n'
        '估計青少年人數：約 ${youthEst > 5 ? youthEst : 15}-${youthEst + 10} 人。\n\n'
        '年度計劃結構：\n\n'
        '【異象與目標】\n'
        '1. 本年度青少年事工主題（1 句話，含主題經文）\n'
        '2. 三大年度目標（SMART 格式，可量化）\n\n'
        '【月度行事曆（1-12 月）】\n'
        '每月格式：月份 ｜ 主要活動 ｜ 查經主題 ｜ 外展行動 ｜ 備注\n'
        '（請依季節、節日和校曆合理分配活動密度）\n\n'
        '【重點事工計劃】\n'
        '3. 門徒栽培路徑（初信→成長→裝備→領袖，各階段描述）\n'
        '4. 外展策略（校園/社交媒體/活動各 1 個具體計劃）\n'
        '5. 領袖培育（識別、培育、授權的步驟）\n\n'
        '【資源規劃】\n'
        '6. 人力需求（同工/義工數量及職責）\n'
        '7. 預算概估（分：活動/物資/培訓/宣傳）\n'
        '8. 場地需求（常規聚會 + 特別活動）\n\n'
        '【成效評估】\n'
        '9. 每季度評估指標（4 個，可量化）\n'
        '10. 年終成效回顧框架（3 個問題）\n\n'
        '請用繁體中文，計劃既有異象深度，也有執行細節。';
  }

  String _buildElderRetreatPrompt(String duration) {
    final care = globalCareController;
    final people = globalPersonController;
    return '請為長執退修會生成一份完整議程，時長：$duration。\n\n'
        '（注意：退修會 ≠ 例行長執會。退修會重點是：異象更新、屬靈更新、'
        '深層議題討論、同工關係建立，而非處理日常行政。）\n\n'
        '教會背景：${people.totalCount} 位會友，活躍關懷 ${care.activeCount} 件。\n\n'
        '退修會議程框架：\n\n'
        '【開場：設立退修基調（佔 10%）】\n'
        '- 開幕禱告與靜默（15 分鐘）\n'
        '- 破冰活動：分享「我服事教會最感恩的一刻」\n'
        '- 退修會守則宣讀（保密、尊重、誠實）\n\n'
        '【核心一：屬靈更新（佔 30%）】\n'
        '- 聖經默想與分享（選 1 節與教會領袖相關的經文）\n'
        '- 個人靈命自我評估（5 題問卷，不公開）\n'
        '- 小組代禱：為彼此的服事重擔代禱\n\n'
        '【核心二：教會健康深度評估（佔 30%）】\n'
        '- 現況討論：優勢/挑戰/機遇/威脅（SWOT，各 3 條）\n'
        '- 教牧關懷：回顧關懷數據（${care.activeCount} 件案件的質性討論）\n'
        '- 未說出口的議題：給每人空白卡片匿名寫下未被討論的擔憂\n\n'
        '【核心三：未來異象凝聚（佔 20%）】\n'
        '- 異象重溫：教會使命宣言是否仍有共識？\n'
        '- 未來 3 年最重要的 1 件事：投票共識\n'
        '- 行動承諾：每人寫下退修後的 1 個個人承諾\n\n'
        '【結束：委身與祝福（佔 10%）】\n'
        '- 彼此禱告覆手祝福\n'
        '- 結束聖餐（可選）\n'
        '- 下次退修會日期\n\n'
        '請用繁體中文，議程設計讓長執真正得到更新，而非另一個工作會議。';
  }

  String _buildSpiritualGrowthTrackingPrompt(String name) {
    final people = globalPersonController;
    final care = globalCareController;
    final buf = StringBuffer();
    buf.writeln('請為會友「$name」設計一份個人靈命成長追蹤計劃，'
        '幫助牧者系統地陪伴其屬靈成長旅程。\n');

    final person = people.findByName(name);
    if (person != null) {
      buf.writeln('【會友資料】');
      buf.writeln('類型：${person.personType} ／ 出席：${person.attendance}');
      if (person.notes.isNotEmpty) buf.writeln('備註：${person.notes}');
    }

    final related = care.allCases
        .where((c) =>
            c.memberName.contains(name) || name.contains(c.memberName))
        .take(3)
        .toList();
    if (related.isNotEmpty) {
      buf.writeln('\n【關懷背景】');
      for (final c in related) {
        buf.writeln('- ${c.reason}（${c.status}）');
      }
    }

    buf.writeln('\n追蹤計劃結構：\n\n'
        '【靈命現況評估（起點）】\n'
        '1. 靈命成熟度初評（4 個維度：聖經認識/禱告生活/群體委身/外展服事，各 1-5 分）\n'
        '2. 個人屬靈目標（此人希望在哪方面成長，引導問題 3 條）\n\n'
        '【3 個月成長目標】\n'
        '3. 聖經閱讀計劃（推薦書卷 + 每日份量）\n'
        '4. 禱告習慣建立（每日禱告時間建議 + 代禱事項框架）\n'
        '5. 群體參與目標（小組 / 服事 / 主日的具體委身）\n\n'
        '【月度跟進框架】\n'
        '6. 每月牧者見面議題（3-4 個標準問題，追蹤進度）\n'
        '7. 里程碑慶祝建議（完成第一個月 / 第三個月時如何認可）\n\n'
        '【半年評估】\n'
        '8. 靈命重評（與初評對比，看見成長）\n'
        '9. 調整與下一階段目標設定\n\n'
        '請用繁體中文，計劃要有彈性，尊重個人節奏，避免律法主義感。');
    return buf.toString();
  }

  String _buildPrayerCulturePrompt(String focus) {
    final people = globalPersonController;
    return '請為教會設計一套「禱告文化建立計劃」，'
        '重點：$focus，幫助整間教會從個人到群體建立更深的禱告生命。\n\n'
        '教會規模：${people.totalCount} 位會友（定期 ${people.regularCount} 人）。\n\n'
        '計劃結構：\n\n'
        '【一、現況評估】\n'
        '1. 教會禱告文化健康指標（5 項，可自評 1-5 分）\n'
        '2. 常見障礙分析（為什麼弟兄姊妹不禱告的 5 個原因 + 應對策略）\n\n'
        '【二、個人禱告裝備（1-3 個月）】\n'
        '3. 禱告生活 30 天挑戰計劃（每日 1 個小步驟）\n'
        '4. 禱告日記框架（ACTS 格式：讚美/認罪/感恩/祈求）\n'
        '5. 禱告伙伴配對計劃（如何在教會中建立禱告伙伴關係）\n\n'
        '【三、小組禱告深化（3-6 個月）】\n'
        '6. 小組禱告升級方案（從代禱清單到真實代禱分享的 3 個步驟）\n'
        '7. 禱告操練建議（輪流帶禱告/禁食禱告/默想禱告）\n\n'
        '【四、全教會禱告事工（6 個月以上）】\n'
        '8. 禱告室/禱告角設立建議（空間設計 + 使用規則）\n'
        '9. 通宵禱告會策劃框架（主題/流程/時間分配）\n'
        '10. 禱告事工核心團隊組建（人選條件 + 職責 + 運作模式）\n\n'
        '【五、成效評估】\n'
        '11. 6 個月後禱告文化健康重評\n'
        '12. 見證收集方式（禱告答覆分享）\n\n'
        '請用繁體中文，讓禱告文化成為自然流露而非宗教義務。';
  }

  // ── v2.12 prompt builders ────────────────────────────────────────────────

  String _buildVisionStatementPrompt(String focus) {
    final people = globalPersonController;
    return '請為教會生成一份「異象宣言草稿套件」，重點方向：$focus。\n\n'
        '教會背景：${people.totalCount} 位會友（正式會員 ${people.memberCount} 人，'
        '慕道友 ${people.seekerCount} 人）。\n\n'
        '套件包括：\n\n'
        '【一、使命宣言（Mission）】\n'
        '1. 三個版本（長版 50 字 / 中版 25 字 / 短版 10 字以內）\n'
        '2. 撰寫時的核心問題：教會為何存在？服事誰？如何服事？\n\n'
        '【二、異象宣言（Vision）】\n'
        '3. 5-10 年後教會希望成為的樣子（1 段，3-4 句，具體有畫面感）\n'
        '4. 異象呈現的 3 個選項（不同側重點，讓長執會選擇）\n\n'
        '【三、核心價值（Core Values）】\n'
        '5. 5-7 個核心價值（每個：1 個詞 + 1 句解釋 + 1 節經文）\n\n'
        '【四、策略重點（Strategic Focus）】\n'
        '6. 本年度 3 大策略重點（與異象對齊，可執行）\n\n'
        '【五、對外呈現】\n'
        '7. 教會簡介段落（對外使用，100 字，溫暖吸引人）\n'
        '8. 社群媒體簡介版本（30 字以內）\n\n'
        '請用繁體中文，異象要有属靈深度，使命要清晰實際。\n'
        '用[方括號]標示需要長執會共同確認的部分。';
  }

  String _buildChurchPlantingPrompt(String location) {
    final people = globalPersonController;
    return '請為在「$location」設立新堂會生成一份初步計劃框架，'
        '幫助母堂牧者和長執評估可行性並開始籌備。\n\n'
        '母堂背景：${people.totalCount} 位會友（定期 ${people.regularCount} 人）。\n\n'
        '計劃框架：\n\n'
        '【階段一：可行性評估（第 1-3 個月）】\n'
        '1. 地區需求分析（人口/已有教會/屬靈需求，3 個評估問題）\n'
        '2. 母堂資源評估（人力/財務/禱告，自評表）\n'
        '3. 核心創堂團隊組成（建議人數 + 理想屬靈恩賜組合）\n\n'
        '【階段二：籌備期（第 4-12 個月）】\n'
        '4. 創堂牧者/帶領人標準（屬靈/性格/能力要求）\n'
        '5. 聚會地點評估清單（5 個實際考量）\n'
        '6. 財務支持架構（母堂供給比例 + 新堂自立時間表）\n'
        '7. 核心成員招募策略（從母堂差遣還是當地建立）\n\n'
        '【階段三：開堂年（第 13-24 個月）】\n'
        '8. 開堂崇拜策劃要點（首次主日崇拜的 5 個關鍵元素）\n'
        '9. 第一年事工重點（3 個，不貪多）\n'
        '10. 母子堂關係架構（牧養連結 + 治理獨立的平衡）\n\n'
        '【持續支援】\n'
        '11. 母堂持續支援計劃（第 1-3 年各年度支援重點）\n'
        '12. 健康指標追蹤（新堂會發展的 5 個里程碑）\n\n'
        '請用繁體中文，框架實際可行，讓沒有創堂經驗的教會也能按步推進。';
  }

  String _buildShortTermMissionPrompt(String destination) {
    final people = globalPersonController;
    return '請為前往「$destination」的短宣隊生成完整的招募與培訓計劃。\n\n'
        '差派教會：${people.totalCount} 位會友（估計潛在短宣隊員 ${(people.regularCount ~/ 8).clamp(3, 20)} 人）。\n\n'
        '計劃包括：\n\n'
        '【招募計劃】\n'
        '1. 招募公告草稿（含：目的地/日期/人數上限/費用/申請截止，留空格式）\n'
        '2. 申請表問題（10 題，評估呼召/健康/能力/委身程度）\n'
        '3. 遴選標準（5 個必要條件 + 3 個優先考量）\n'
        '4. 口頭邀請話術（教牧向潛在隊員提名的 3 句話）\n\n'
        '【培訓計劃（出發前）】\n'
        '5. 培訓課程大綱（3-4 次聚會，各 2 小時）\n'
        '   - 第一次：宣教神學與心態準備\n'
        '   - 第二次：$destination 文化與服事內容了解\n'
        '   - 第三次：實際技能（探訪/兒童事工/見證分享）\n'
        '   - 第四次：隊伍建立與出發禱告\n'
        '6. 出發前個人準備清單（屬靈/體力/實際裝備）\n\n'
        '【差遣禮拜框架】\n'
        '7. 短宣差遣典禮程序（在主日崇拜中進行，15 分鐘內）\n\n'
        '【回來後】\n'
        '8. 回程後匯報分享框架（主日見證 5 分鐘版 + 長執會報告版）\n'
        '9. 短宣後屬靈整合期建議（2-4 週）\n\n'
        '請用繁體中文，讓第一次帶短宣的牧者也能照著做。';
  }

  String _buildTransferLetterPrompt(String input) {
    // input: "姓名" or "姓名｜轉往教會"
    final parts = input.split('｜');
    final name = parts[0].trim();
    final destination = parts.length > 1 ? parts[1].trim() : '';
    final people = globalPersonController;
    final person = people.findByName(name);

    final buf = StringBuffer();
    buf.writeln('請為會友「$name」生成一封正式的轉會推薦信，'
        '由本教會牧者或長執簽署，推薦給接收教會。\n');
    if (destination.isNotEmpty) {
      buf.writeln('轉往教會：$destination\n');
    }
    if (person != null) {
      buf.writeln('【會友資料】');
      buf.writeln('類型：${person.personType} ／ 出席狀況：${person.attendance}');
      if (person.notes.isNotEmpty) buf.writeln('備註：${person.notes}');
    }

    buf.writeln('\n推薦信結構：\n\n'
        '(1) 信頭（本教會名稱、地址、日期，留空格式）\n'
        '(2) 收信方稱謂（「親愛的${destination.isNotEmpty ? destination : '________'}牧者/長執：」）\n'
        '(3) 推薦段落（3-4 句）：\n'
        '    - 確認會友身份（正式會員/慕道友，在本會年數）\n'
        '    - 肯定其品格與屬靈生命（留通用正面評語）\n'
        '    - 說明離開原因（溫和措辭，如：因遷居/學業/主的帶領）\n'
        '(4) 在本會服事摘要（留空格：「___在本會曾參與______服事」）\n'
        '(5) 真誠推薦語（請接收教會接納並牧養）\n'
        '(6) 為其祝福的禱告語（1-2 句）\n'
        '(7) 署名欄（牧師姓名/職銜/教會名稱/聯絡電話，留空）\n'
        '(8) 副本說明（一式兩份：接收教會留底 + 會友自存）\n\n'
        '請用繁體中文，語氣正式而溫暖，展現兩間教會之間的合一精神。\n'
        '約 200-250 字，適合正式信件格式列印。');
    return buf.toString();
  }

  // ── v2.13 prompt builders ────────────────────────────────────────────────

  String _buildAnnualBibleReadingPrompt(String year) {
    final people = globalPersonController;
    return '請為教會「$year 年」生成一份全教會年度靈修讀經計劃，'
        '讓所有會友（${people.totalCount} 人）一同讀完聖經或特定書卷。\n\n'
        '計劃選項（請提供 3 個版本，讓教牧選擇）：\n\n'
        '【版本 A：一年讀完全本聖經】\n'
        '1. 每日讀經份量（章節數 + 估計時間）\n'
        '2. 月度安排總覽（1-12 月，每月完成哪幾卷）\n'
        '3. 建議搭配靈修書目（2-3 本）\n\n'
        '【版本 B：一年讀完新約 + 詩篇】\n'
        '4. 週計劃框架（週一至週六讀經，週日崇拜整合）\n'
        '5. 每月主題（與教會講道系列配合的主題建議）\n\n'
        '【版本 C：聚焦主題讀經（4 個主題，每季一個）】\n'
        '6. 四季主題建議（例：一季福音書 / 一季書信 / 一季歷史書 / 一季智慧書）\n'
        '7. 每季推薦經文選讀清單\n\n'
        '【全教會推廣配套】\n'
        '8. 讀經記錄表設計（可列印，週/月格式）\n'
        '9. 激勵機制建議（小組分享/里程碑慶祝/年終見證會）\n'
        '10. 讀經 App 推薦（適合繁體中文的 3 個選項）\n'
        '11. 落後者恩典指引（跟不上進度時的鼓勵話語 + 補救方案）\n\n'
        '請用繁體中文，讓不同靈命程度的會友都能參與。';
  }

  String _buildYouthCampPrompt(String theme) {
    final people = globalPersonController;
    final youthEst = (people.totalCount ~/ 5).clamp(10, 50);
    return '請為主題「$theme」的青年營會生成完整活動方案，'
        '預計參加人數：約 $youthEst 人，為期 2 天 1 夜（可調整）。\n\n'
        '（注意：營會 ≠ 單日活動，需包含住宿生活、夜間程序、早晨靈修等元素。）\n\n'
        '完整方案包括：\n\n'
        '【行程時間表】\n'
        '第一天（Day 1）：逐小時行程\n'
        '  - 報到/暖身遊戲 → 晚餐 → 晚間聚會（信息 + 敬拜）→ 小組時間 → 宵夜\n'
        '第二天（Day 2）：逐小時行程\n'
        '  - 早晨靈修 → 早餐 → 上午聚會（信息 2）→ 戶外活動 → 午餐 → 回應時間 → 散營\n\n'
        '【信息大綱（2 篇）】\n'
        '- 第一篇：主題切入（痛點共鳴 + 聖經基礎 + 3 個重點）\n'
        '- 第二篇：呼召回應（深化 + 個人委身 + 小組禱告）\n\n'
        '【活動設計（3 個）】\n'
        '- 暖身破冰遊戲（全體，30 分鐘）\n'
        '- 主題戶外活動（與信息相關，60-90 分鐘）\n'
        '- 小組查經討論（5-8 人一組，45 分鐘，附 4 條討論問題）\n\n'
        '【後勤清單】\n'
        '- 物資採購清單（食物/文具/遊戲器材/急救）\n'
        '- 工作人員職責分配表（隊長/組長/敬拜/後勤各 1 行）\n'
        '- 家長知情同意書要點（5 項必要資訊）\n\n'
        '【跟進計劃】\n'
        '- 營後 1 週：組長關心電話話術\n'
        '- 營後 2-4 週：鞏固行動 3 個\n\n'
        '請用繁體中文，語氣充滿青春活力。';
  }

  String _buildVolunteerManagementPrompt(String churchSize) {
    return '請為一間「$churchSize」規模的教會設計一套完整的義工招募與管理系統，'
        '幫助同工有效地組織和關顧義工隊伍。\n\n'
        '系統包括以下模組：\n\n'
        '【模組一：招募系統】\n'
        '1. 義工需求評估表（各部門填寫，格式統一）\n'
        '2. 恩賜探索問卷（10 題，幫助會友發現適合的服事崗位）\n'
        '3. 義工崗位清單範本（格式：崗位名稱/職責/時間要求/聯絡人）\n'
        '4. 義工申請流程（填表 → 面談 → 試用 → 確認的標準程序）\n\n'
        '【模組二：入職培訓】\n'
        '5. 義工入職指引（必須知道的 10 件事）\n'
        '6. 新義工首月陪伴計劃（導師制，每週一個里程碑）\n\n'
        '【模組三：持續關顧】\n'
        '7. 義工季度評估對話框架（組長與義工的 30 分鐘談話）\n'
        '8. 義工倦怠預警信號（8 個早期跡象 + 應對策略）\n'
        '9. 年度義工感恩禮拜建議（流程 + 感謝方式）\n\n'
        '【模組四：記錄與追蹤】\n'
        '10. 義工資料表範本（姓名/崗位/開始日期/服事時數/聯絡）\n'
        '11. 月度服事時數記錄表（各部門匯總格式）\n\n'
        '【模組五：退出機制】\n'
        '12. 義工轉換崗位流程（健康方式說再見並重新開始）\n'
        '13. 長期義工感謝與傳承儀式（服事滿 1/3/5 年的認可方式）\n\n'
        '請用繁體中文，系統實際可操作，讓教會行政同工照著執行。';
  }

  String _buildPastoralSuccessionPrompt(String timeline) {
    final care = globalCareController;
    final people = globalPersonController;
    return '請為教會生成一份「牧師退休/交棒計劃」框架，'
        '交棒時間線：$timeline，幫助牧者和長執有序完成世代傳承。\n\n'
        '教會現況：${people.totalCount} 位會友（定期 ${people.regularCount} 人），'
        '活躍關懷案件 ${care.activeCount} 件。\n\n'
        '計劃框架：\n\n'
        '【一、宣告前準備（靜默期）】\n'
        '1. 牧者個人禱告確認框架（5 個自問問題）\n'
        '2. 與長執私下溝通的 3 個步驟\n'
        '3. 交棒時機成熟的 5 個指標\n\n'
        '【二、繼任者物色與培育】\n'
        '4. 繼任牧者資格標準（屬靈/品格/能力/家庭，各 3-4 項）\n'
        '5. 內部培育 vs 外部招聘的評估框架\n'
        '6. 繼任者培育路徑（$timeline 時間線下的月度里程碑）\n\n'
        '【三、過渡期安排】\n'
        '7. 知識與關係交接清單（20 項必須移交的事項）\n'
        '8. 與各部門/小組組長的過渡對話框架\n'
        '9. 向會眾宣告的方式與時機建議\n\n'
        '【四、告別與感恩】\n'
        '10. 退休/告別崇拜框架（感恩敬拜 + 見證 + 委任新牧者）\n'
        '11. 退休牧者在新局面中的角色定位（避免干預的健康界限）\n\n'
        '【五、新牧者首年支援】\n'
        '12. 新牧者第一年重點事項（每季度 3 個目標）\n'
        '13. 長執會對新牧者的支持承諾框架\n\n'
        '請用繁體中文，處理這敏感議題時語氣尊重而有盼望，'
        '強調傳承是教會生命力的見證。';
  }

  // ── v2.14 prompt builders ────────────────────────────────────────────────

  String _buildLivestreamScriptPrompt(String sermonTitle) {
    return '請為主題「$sermonTitle」的主日線上崇拜直播生成完整腳本，'
        '供司儀、技術同工和牧者使用。\n\n'
        '腳本格式（三欄：時間戳 ｜ 誰說/做什麼 ｜ 台詞/備注）：\n\n'
        '【直播前準備（-15 分鐘至開始）】\n'
        '- 技術檢查清單（音訊/畫面/字幕/直播連結測試，5 項）\n'
        '- 直播預告畫面文字（30 字倒數提示）\n\n'
        '【開場段落（0:00-5:00）】\n'
        '- 直播歡迎詞（30 秒，熱情迎接線上會眾，請他們在留言區打招呼）\n'
        '- 技術提示（如何開啟字幕/如何奉獻/如何分享直播）\n'
        '- 過渡到敬拜的引導語\n\n'
        '【敬拜時段（5:00-25:00）】\n'
        '- 每首詩歌前後的司儀接駁詞（各 1-2 句）\n'
        '- 螢幕字幕顯示指示（歌詞何時顯示）\n'
        '- 奉獻提示插入時機建議\n\n'
        '【信息時段（25:00-55:00）】\n'
        '- 牧者介紹語（司儀，20 秒）\n'
        '- 畫面切換指示（全螢幕牧者/PPT 投影/金句字卡）\n'
        '- 重要金句字幕顯示指示（3-5 個時機）\n\n'
        '【回應與結束（55:00-70:00）】\n'
        '- 回應邀請語（司儀，線上觀眾如何回應信息）\n'
        '- 線上代禱方式介紹（留言/表單/私訊）\n'
        '- 結束告別語（歡迎下週/分享直播/點讚提醒）\n'
        '- 直播後剪輯上傳建議（標題格式/縮圖提示）\n\n'
        '請用繁體中文，腳本清晰，讓義工技術組也能照著執行。';
  }

  String _buildFamilyMinistryPrompt(String theme) {
    final people = globalPersonController;
    final familyEst = (people.regularCount ~/ 3).clamp(5, 30);
    return '請為主題「$theme」設計一份家庭事工活動方案，'
        '目標：讓父母與孩子同時參與，建立家庭屬靈生命。\n\n'
        '估計參與家庭數：約 $familyEst 個家庭。\n\n'
        '活動方案（建議半天活動，3-4 小時）：\n\n'
        '【一、活動概覽】\n'
        '1. 活動名稱與標語（中英各一，吸引家長和孩子）\n'
        '2. 適合年齡段（建議 2-12 歲子女的家庭）\n'
        '3. 活動目標（3 個，涵蓋家長/孩子/家庭關係）\n\n'
        '【二、分組學習時段（60 分鐘，親子分開）】\n'
        '4. 兒童組課程大綱（與主題相關，適合 4-12 歲）\n'
        '5. 家長組課程大綱（裝備父母的對應主題，30 分鐘教導 + 30 分鐘討論）\n\n'
        '【三、親子合一時段（60 分鐘，家庭同樂）】\n'
        '6. 親子互動遊戲（2 個，與主題相關，不需器材）\n'
        '7. 家庭挑戰任務（每個家庭共同完成，15 分鐘）\n'
        '8. 家庭禱告時刻（引導語 + 家長帶孩子禱告的框架）\n\n'
        '【四、後勤與宣傳】\n'
        '9. 物資清單\n'
        '10. 宣傳文案（WhatsApp 家長群版本，80 字）\n\n'
        '【五、回家功課】\n'
        '11. 本週家庭靈修材料（5 天，每天 10 分鐘親子靈修活動）\n\n'
        '請用繁體中文，語氣溫馨，讓家庭感受到教會對家庭的重視。';
  }

  String _buildSocialMediaCalendarPrompt(String month) {
    final people = globalPersonController;
    final care = globalCareController;
    return '請為教會生成「$month」社群媒體內容月計劃，'
        '涵蓋 Facebook / Instagram / WhatsApp 三個平台。\n\n'
        '教會概況：${people.totalCount} 位會友，活躍關懷 ${care.activeCount} 件。\n\n'
        '月計劃結構：\n\n'
        '【一、月度主題與策略】\n'
        '1. 本月社群主題（1 句話，與教會事工節奏配合）\n'
        '2. 發文頻率建議（各平台每週幾次，說明理由）\n'
        '3. 本月重點活動/節日（需要特別發文的日期）\n\n'
        '【二、內容類型組合（建議比例）】\n'
        '4. 七種內容類型及比例：\n'
        '   - 靈感/金句（30%）\n'
        '   - 活動宣傳（20%）\n'
        '   - 會友見證/故事（15%）\n'
        '   - 聖經問答互動（15%）\n'
        '   - 幕後生活/教會文化（10%）\n'
        '   - 代禱邀請（5%）\n'
        '   - 節日/節氣相關（5%）\n\n'
        '【三、週計劃範本（4 週）】\n'
        '每週格式：週一至週日，各平台當天發什麼內容（主題 + 30 字文案草稿）\n\n'
        '【四、高互動貼文範本（3 則）】\n'
        '5. 靈感金句帖（含建議配圖描述 + 30 字文案）\n'
        '6. 互動問題帖（引發留言的問題 + 20 字引導語）\n'
        '7. 見證徵集帖（邀請會友分享，50 字文案）\n\n'
        '【五、實用提示】\n'
        '8. 最佳發文時間（各平台，根據一般教會會眾習慣）\n'
        '9. 5 個免費設計工具推薦（Canva 等）\n'
        '10. 危機處理：若出現負面留言的 3 個回應原則\n\n'
        '請用繁體中文，計劃實際可執行，讓義工媒體組照著做。';
  }

  String _buildLifeTransitionCarePrompt(String input) {
    // input: "姓名" or "姓名｜轉變類型"
    final parts = input.split('｜');
    final name = parts[0].trim();
    final transition = parts.length > 1 ? parts[1].trim() : '';
    final care = globalCareController;
    final people = globalPersonController;
    final person = people.findByName(name);

    final buf = StringBuffer();
    buf.writeln('請為會友「$name」在人生重大轉變期間制定牧養關懷計劃。');
    if (transition.isNotEmpty) buf.writeln('轉變類型：$transition\n');

    if (person != null) {
      buf.writeln('【會友資料】出席：${person.attendance}');
      if (person.notes.isNotEmpty) buf.writeln('備註：${person.notes}');
    }

    final related = care.allCases
        .where((c) =>
            c.memberName.contains(name) || name.contains(c.memberName))
        .take(2)
        .toList();
    if (related.isNotEmpty) {
      buf.writeln('【相關關懷記錄】');
      for (final c in related) {
        buf.writeln('- ${c.reason}（${c.status}）');
      }
    }

    buf.writeln('\n關懷計劃結構：\n\n'
        '【一、轉變期特別需要分析】\n'
        '1. 此類轉變（${transition.isNotEmpty ? transition : "搬家/轉職/退休/離婚/子女離家"}）'
        '的常見屬靈與情感挑戰（5 個）\n'
        '2. 需要優先關注的 3 個牧養層面\n\n'
        '【二、即時關懷（轉變發生後 1 個月內）】\n'
        '3. 首次探訪/通話議程（30 分鐘，3 個討論重點）\n'
        '4. 實際支援行動建議（禱告/食物/協助搬遷/介紹新環境資源）\n'
        '5. 傳送給對方的鼓勵經文（3 節，附個人化應用）\n\n'
        '【三、3 個月陪伴期】\n'
        '6. 每月一次的跟進問題（3 個月各有 3 條問題）\n'
        '7. 里程碑慶祝：轉變滿 1 個月/3 個月的認可方式\n\n'
        '【四、重新融入教會生活】\n'
        '8. 若已搬離：推薦接觸新城市教會的方式（3 個步驟）\n'
        '9. 若仍在本教會：如何在新人生階段找到新的事奉崗位\n\n'
        '請用繁體中文，展現教會對生命各個階段的全人關懷。');
    return buf.toString();
  }

  // ── v2.15 prompt builders ────────────────────────────────────────────────

  String _buildOnlineGivingGuidePrompt(String platform) {
    final people = globalPersonController;
    return '請為教會生成一份「線上奉獻系統」設定與推廣指南，'
        '參考平台/情境：$platform。\n\n'
        '教會規模：${people.totalCount} 位會友（定期 ${people.regularCount} 人）。\n\n'
        '指南內容：\n\n'
        '【一、平台選擇建議】\n'
        '1. 適合教會使用的線上奉獻工具比較表（3-5 個選項）：\n'
        '   - 格式：平台名稱 ｜ 手續費 ｜ 支援方式 ｜ 難易度 ｜ 適合規模\n'
        '2. 針對「$platform」的具體設定步驟（5-8 步）\n\n'
        '【二、推廣與教育】\n'
        '3. 向會眾介紹線上奉獻的主日講解稿（2 分鐘，含示範邀請語）\n'
        '4. 週報/WhatsApp 說明文（100 字，簡單清晰）\n'
        '5. 線上奉獻操作指引（給長者/不熟科技會友，圖文說明框架）\n\n'
        '【三、財務治理】\n'
        '6. 線上奉獻記錄與核對流程（每週/每月步驟）\n'
        '7. 年度奉獻收據發送時間表與格式\n'
        '8. 常見問題解答（Q&A，5 條）\n\n'
        '【四、教牧考量】\n'
        '9. 如何在靈命上平衡實體奉獻與線上奉獻的牧養信息（3 點）\n'
        '10. 對無法使用數碼工具的會友的配套關懷\n\n'
        '請用繁體中文，讓財務同工和科技義工都能照著執行。';
  }

  String _buildOnlineSundaySchoolPrompt(String topic) {
    return '請為兒童主日學主題「$topic」設計一份專為線上（Zoom/視訊）教學的課程大綱。\n\n'
        '（注意：此為線上版本，需應對注意力短暫、家長在旁、技術限制等挑戰，\n'
        '有別於實體主日學教案。）\n\n'
        '課程設計（45-60 分鐘線上課，適合 4-12 歲）：\n\n'
        '【技術準備】\n'
        '1. 老師設備清單（攝影機/麥克風/背景/道具）\n'
        '2. 家長預備提示（提前 5 分鐘傳給家長的準備事項）\n\n'
        '【課程流程（線上優化版）】\n'
        '3. 開場簽到遊戲（5 分鐘，Zoom 互動功能：舉手/反應/改名字）\n'
        '4. 故事時間（10 分鐘，視覺化說故事技巧 + 3 個互動提問）\n'
        '5. 互動活動（10 分鐘，孩子在家可做的手工/繪畫，老師示範）\n'
        '6. 聖經金句教唱（5 分鐘，配動作，培養記憶）\n'
        '7. 分組討論（10 分鐘，2-3 人小組 Breakout Room，討論問題 2 條）\n'
        '8. 禱告與結束（5 分鐘，孩子輪流帶短禱告）\n\n'
        '【家長參與】\n'
        '9. 課後家庭活動（15 分鐘，家長帶孩子在家延伸學習）\n'
        '10. 本週帶回家的 1 句話（孩子向家人分享今天學到什麼）\n\n'
        '【技術應急指引】\n'
        '11. 孩子中途離線怎麼辦（3 個應急步驟）\n'
        '12. 課程錄影處理建議（是否錄影/如何保護兒童隱私）\n\n'
        '請用繁體中文，讓義工老師輕鬆上手線上教學。';
  }

  String _buildLivestreamEquipmentPrompt(String budget) {
    return '請為教會生成一份線上直播設備清單與設定指南，預算範圍：$budget。\n\n'
        '（注意：此為設備與技術設定指南，有別於直播崇拜腳本。）\n\n'
        '指南內容：\n\n'
        '【一、設備清單（按預算分級）】\n'
        '入門級（HKD 3,000-8,000 / TWD 15,000-40,000）：\n'
        '- 攝影機 / 網路攝影機：[推薦型號 2 個 + 理由]\n'
        '- 麥克風：[推薦型號 2 個]\n'
        '- 照明：[推薦方案]\n'
        '- 電腦/設備：[最低規格要求]\n\n'
        '進階級（按 $budget 調整）：\n'
        '- [進階推薦清單，含切換器/多機位建議]\n\n'
        '【二、軟體設定】\n'
        '- OBS Studio 基本設定步驟（5 步）\n'
        '- YouTube/Facebook 直播設定步驟（各 3 步）\n'
        '- 字幕工具推薦（2 個免費選項）\n\n'
        '【三、崇拜場地設定建議】\n'
        '- 攝影機擺位圖（文字描述：台前正面 + 側面補充機位）\n'
        '- 燈光設置原則（3 個基本燈位說明）\n'
        '- 聲音收音注意事項（5 個常見錯誤 + 解決方法）\n\n'
        '【四、直播前檢查清單】\n'
        '- 崇拜前 30 分鐘技術測試步驟（8 項）\n'
        '- 緊急備用方案（設備故障時的 3 個應急方案）\n\n'
        '【五、義工培訓】\n'
        '- 技術義工入職培訓大綱（2 小時課程）\n'
        '- 常見技術問題 Q&A（5 條）\n\n'
        '請用繁體中文，讓沒有技術背景的義工也能按步設定。';
  }

  String _buildOnlineSmallGroupHandbookPrompt(String platform) {
    final people = globalPersonController;
    return '請為教會生成一份「線上小組引導手冊」，'
        '使用平台：$platform，幫助小組長帶領線上聚會。\n\n'
        '（注意：此手冊針對線上小組的獨特挑戰，有別於實體小組牧養建議。）\n\n'
        '教會：${people.totalCount} 位會友，部分小組已轉為線上或混合形式。\n\n'
        '手冊內容：\n\n'
        '【第一章：線上小組的獨特挑戰與機遇（2 頁）】\n'
        '1. 線上聚會 vs 實體聚會的 5 個主要差異\n'
        '2. 線上小組的 3 個優勢（跨地域/靈活時間/錄影回放）\n\n'
        '【第二章：$platform 使用指引（2 頁）】\n'
        '3. 組長必學功能（5 個：靜音/分組/投票/共享螢幕/錄影）\n'
        '4. 組員入會前的技術準備指引（發給組員的說明，200 字）\n'
        '5. 技術問題快速處理（5 個常見問題 + 1 行解決方法）\n\n'
        '【第三章：線上查經技巧（3 頁）】\n'
        '6. 開場暖身（線上適用，5 種方式）\n'
        '7. 保持互動的 7 個技巧（輪流發言/聊天室/投票/Breakout Room）\n'
        '8. 如何應對「沉默的螢幕」（3 個應對策略）\n'
        '9. 線上代禱分享的引導方式（文字禱告 vs 語音禱告）\n\n'
        '【第四章：關係建立（1 頁）】\n'
        '10. 線上建立真實關係的 5 個習慣\n'
        '11. 如何識別組員的屬靈/情緒需要（不在現場時的信號）\n\n'
        '【第五章：線上聚會結構範本（1 頁）】\n'
        '12. 90 分鐘標準線上聚會流程（逐段時間分配）\n\n'
        '請用繁體中文，格式像真正的小冊子，讓組長可以列印使用。';
  }

  // ── v2.16 prompt builders ────────────────────────────────────────────────

  String _buildPrayerMeetingPrompt(String theme) {
    final care = globalCareController;
    return '請為主題「$theme」設計一場教會禱告會的完整主題與流程，'
        '時長 60-90 分鐘，適合 10-50 人的聚集禱告。\n\n'
        '（注意：此為具體禱告聚會設計，有別於禱告文化建立的長期策略計劃。）\n\n'
        '目前活躍關懷案件 ${care.activeCount} 件，可整合入代禱事項。\n\n'
        '禱告會設計：\n\n'
        '【一、主題與經文】\n'
        '1. 禱告主題的聖經根據（2-3 節經文，附禱告應用說明）\n'
        '2. 本次禱告會目標（3 個，讓參與者知道在求什麼）\n\n'
        '【二、流程設計（90 分鐘版）】\n'
        '0:00-10:00 靜心進入（敬拜詩歌 1-2 首 + 靜默等候）\n'
        '10:00-20:00 禱告信息（牧者分享主題背景，10 分鐘）\n'
        '20:00-40:00 引導性代禱時段一（圍繞主題，引導語 + 靜默禱告 + 開口分享）\n'
        '40:00-55:00 引導性代禱時段二（關懷案件/個人需要）\n'
        '55:00-70:00 認罪與感恩禱告（小組 3-4 人）\n'
        '70:00-85:00 宣告禱告（站立，積極宣告神的應許）\n'
        '85:00-90:00 結束敬拜與祝禱\n\n'
        '【三、帶領者工具】\n'
        '3. 每個時段的引導語範本（各 2-3 句，自然過渡）\n'
        '4. 處理「無人開口」的 3 個應對方式\n'
        '5. 適合主題的詩歌建議（3 首，附使用時機）\n\n'
        '【四、跟進】\n'
        '6. 禱告記錄表（讓參與者記下禱告事項，追蹤答覆）\n'
        '7. 下次禱告會預告文案（WhatsApp，50 字）\n\n'
        '請用繁體中文，流程設計讓初次帶禱告會的同工也能按步引導。';
  }

  String _buildMarriageCounselingPrompt(String format) {
    final people = globalPersonController;
    return '請為教會設計一套「婚姻輔導/豐盛婚姻」課程大綱，格式：$format。\n\n'
        '教會規模：${people.totalCount} 位會友（估計已婚夫婦約 ${(people.regularCount ~/ 3).clamp(5, 40)} 對）。\n\n'
        '課程目標：裝備夫婦建立以基督為中心的健康婚姻。\n\n'
        '課程大綱：\n\n'
        '【模組一：婚姻的屬靈基礎（第 1-2 次）】\n'
        '- 核心聖經：創 2:18-25、弗 5:22-33\n'
        '- 主題：神設立婚姻的目的；委身的意義\n'
        '- 夫婦練習：「我娶/嫁你的原因」見證分享\n\n'
        '【模組二：溝通與衝突處理（第 3-4 次）】\n'
        '- 核心聖經：雅 1:19、弗 4:26\n'
        '- 主題：傾聽技巧；健康衝突的 5 個原則\n'
        '- 夫婦練習：角色扮演——如何表達需要而非指責\n\n'
        '【模組三：愛的行動（第 5-6 次）】\n'
        '- 核心聖經：林前 13 章；五種愛語\n'
        '- 主題：發現配偶的愛語；具體愛的行動\n'
        '- 夫婦練習：愛語問卷 + 本月愛的行動承諾\n\n'
        '【模組四：家庭財務與目標（第 7 次）】\n'
        '- 主題：共同財務觀；設立家庭屬靈目標\n\n'
        '【模組五：親密關係與更新（第 8 次）】\n'
        '- 主題：身體親密的神聖性；婚姻更新與委身禮\n'
        '- 結業儀式：夫婦在教會面前重申婚誓\n\n'
        '附：每次課程的討論問題（各 3 條）、推薦參考書目（3 本）\n'
        '請用繁體中文，內容敏感但正面，避免令夫婦感到被評判。';
  }

  String _buildChildrensVolunteerTrainingPrompt(String role) {
    return '請為教會兒童事工「$role」崗位生成一份完整的義工培訓手冊，'
        '幫助新義工安全有效地服事孩子。\n\n'
        '（注意：此為兒童事工義工的崗位培訓手冊，有別於一般志工管理系統或主日學教案。）\n\n'
        '手冊結構（可列印小冊子格式）：\n\n'
        '【第一章：兒童事工的使命與心志（1 頁）】\n'
        '1. 我們為何服事孩子（3 節聖經 + 2 個原則）\n'
        '2. $role 崗位對教會的重要性\n\n'
        '【第二章：兒童保護政策（重要，2 頁）】\n'
        '3. 兒童保護 5 大原則（絕不獨處/報告機制/肢體接觸守則）\n'
        '4. 可疑情況如何處理（舉報流程 3 步）\n'
        '5. 社交媒體與兒童的守則（4 條）\n\n'
        '【第三章：$role 崗位職責（2 頁）】\n'
        '6. 主要職責清單（8-10 項，每項一行）\n'
        '7. 標準課堂/聚會流程（逐段時間分配）\n'
        '8. 點名與接送程序（安全規程）\n'
        '9. 緊急情況處理（孩子受傷/生病/哭鬧的步驟）\n\n'
        '【第四章：與孩子互動技巧（1 頁）】\n'
        '10. 有效管理課堂秩序的 5 個方法（正面管教）\n'
        '11. 禁止言行清單（絕不說的 5 句話）\n'
        '12. 如何回應孩子的屬靈問題（3 個原則）\n\n'
        '【第五章：自我照顧與成長（0.5 頁）】\n'
        '13. 義工倦怠預防（3 個習慣）\n'
        '14. 進修與支援資源\n\n'
        '請用繁體中文，兒童保護部分要清晰嚴格，其餘語氣鼓勵溫暖。';
  }

  String _buildEmergencyMinistryPrompt(String emergencyType) {
    final care = globalCareController;
    final people = globalPersonController;
    return '請為教會制定一份「$emergencyType 緊急事工計劃」，'
        '幫助教會在非常時期持續牧養會眾並服事社區。\n\n'
        '（注意：此計劃聚焦於如何在緊急情況下維持事工運作，'
        '有別於危機公關處理指引。）\n\n'
        '教會背景：${people.totalCount} 位會友（定期 ${people.regularCount} 人），'
        '活躍關懷案件 ${care.activeCount} 件。\n\n'
        '緊急事工計劃：\n\n'
        '【一、事工持續運作計劃】\n'
        '1. 緊急崇拜安排（線上轉移 / 小規模分散聚會 / 錄影崇拜的選項）\n'
        '2. 牧養通訊替代方案（WhatsApp群組/電話樹/特別週報）\n'
        '3. 緊急情況下的事工優先順序（哪些事工暫停，哪些必須繼續）\n\n'
        '【二、會眾關懷升級計劃】\n'
        '4. 脆弱群體識別與支援（長者/獨居/有小孩家庭的優先關懷清單）\n'
        '5. 緊急關懷呼叫系統（如何快速接觸所有 ${people.totalCount} 位會友）\n'
        '6. 物資互助計劃（食物/藥品/生活必需品的調配機制）\n\n'
        '【三、社區外展】\n'
        '7. 緊急情況下的社區服務計劃（3 個可立即執行的服事）\n'
        '8. 與其他教會/機構的協作機制\n\n'
        '【四、財務應急】\n'
        '9. 緊急奉獻基金設立與使用原則\n'
        '10. 教會運作最低財務需求評估\n\n'
        '【五、復原計劃】\n'
        '11. 從緊急狀態恢復正常事工的 3 個階段\n'
        '12. 事後心理與屬靈關懷需要評估\n\n'
        '請用繁體中文，計劃實際可執行，讓教會在危機中仍能成為社區的光和鹽。';
  }

  // ── input dialogs ────────────────────────────────────────────────────────

  /// Generic single-field input dialog — avoids duplicating dialog code.
  Future<void> _askInput({
    required String title,
    required String hint,
    required String confirmLabel,
    required String Function(String) buildPrompt,
  }) async {
    final ctrl = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (value == null || value.isEmpty) return;
    _run(buildPrompt(value));
  }

  Future<void> _askSermonTopic() => _askInput(
        title: '講道題目',
        hint: '例：盼望、悔改、恩典…',
        confirmLabel: '生成',
        buildPrompt: _buildSermonPrompt,
      );

  Future<void> _askMemberName() => _askInput(
        title: '會友姓名',
        hint: '請輸入會友姓名',
        confirmLabel: '查詢',
        buildPrompt: _buildMemberStatusPrompt,
      );

  // ── v2.1 dialog triggers ─────────────────────────────────────────────────

  Future<void> _askGroupTopic() => _askInput(
        title: '小組主題 ／ 聖經章節',
        hint: '例：約翰福音 3:16、寬恕、信心…',
        confirmLabel: '生成',
        buildPrompt: _buildGroupDiscussionPrompt,
      );

  Future<void> _askEventName() => _askInput(
        title: '活動名稱',
        hint: '例：2026 青年退修會、感恩節晚宴…',
        confirmLabel: '生成文案',
        buildPrompt: _buildEventCopyPrompt,
      );

  Future<void> _askFinancePeriod() => _askInput(
        title: '報告期間',
        hint: '例：2026 年 5 月、2026 年第二季…',
        confirmLabel: '生成草稿',
        buildPrompt: _buildFinanceReportPrompt,
      );

  Future<void> _askPastoralName() => _askInput(
        title: '會友姓名',
        hint: '請輸入需要牧養建議的會友姓名',
        confirmLabel: '生成建議',
        buildPrompt: _buildPastoralActionPrompt,
      );

  // ── v2.2 dialog triggers ─────────────────────────────────────────────────

  Future<void> _askBulletinDate() => _askInput(
        title: '主日日期',
        hint: '例：2026 年 6 月 1 日、下週主日…',
        confirmLabel: '生成週報',
        buildPrompt: _buildBulletinPrompt,
      );

  Future<void> _askSermonPassage() => _askInput(
        title: '講道章節或主題',
        hint: '例：路加福音 15:11-32、浪子回頭…',
        confirmLabel: '生成重點',
        buildPrompt: _buildSermonKeyPointsPrompt,
      );

  Future<void> _askPosterEvent() => _askInput(
        title: '活動名稱',
        hint: '例：2026 聖誕崇拜、母親節感恩主日…',
        confirmLabel: '生成設計方案',
        buildPrompt: _buildPosterDesignPrompt,
      );

  Future<void> _askGroupName() => _askInput(
        title: '小組 ／ 部門名稱',
        hint: '例：青年小組、恩典小組、詩歌部…',
        confirmLabel: '生成建議',
        buildPrompt: _buildSmallGroupLeaderPrompt,
      );

  // ── v2.3 dialog triggers ─────────────────────────────────────────────────

  Future<void> _askWelcomeName() => _askInput(
        title: '新來者姓名',
        hint: '例：陳大明、Sarah…',
        confirmLabel: '生成歡迎信',
        buildPrompt: _buildWelcomeLetterPrompt,
      );

  Future<void> _askFarewellName() => _askInput(
        title: '會友姓名',
        hint: '請輸入久未出席或離開的會友姓名',
        confirmLabel: '生成關懷信',
        buildPrompt: _buildFarewellCarePrompt,
      );

  Future<void> _askNewsletterPeriod() => _askInput(
        title: '週訊期間',
        hint: '例：2026 年 6 月第 1 週、本週…',
        confirmLabel: '生成週訊',
        buildPrompt: _buildPastoralNewsletterPrompt,
      );

  Future<void> _askSundaySchoolTopic() => _askInput(
        title: '主日學主題',
        hint: '例：神愛世人、大衛打倒歌利亞、感恩…',
        confirmLabel: '生成教案',
        buildPrompt: _buildSundaySchoolPrompt,
      );

  // ── v2.4 dialog triggers ─────────────────────────────────────────────────

  Future<void> _askMeetingDept() => _askInput(
        title: '部門名稱',
        hint: '例：長執會、詩歌部、關懷小組、青年部…',
        confirmLabel: '生成議程',
        buildPrompt: _buildMeetingAgendaPrompt,
      );

  Future<void> _askMinistryDept() => _askInput(
        title: '事工部門',
        hint: '例：兒童主日學、青年事工、社關部…',
        confirmLabel: '生成計劃',
        buildPrompt: _buildMinistryPlanPrompt,
      );

  Future<void> _askVolunteerRole() => _askInput(
        title: '服事崗位',
        hint: '例：司琴義工、主日學老師、關懷探訪員…',
        confirmLabel: '生成招募文案',
        buildPrompt: _buildVolunteerRecruitPrompt,
      );

  Future<void> _askAppreciationTarget() => _askInput(
        title: '姓名（選填事由：姓名｜事由）',
        hint: '例：陳大明  或  陳大明｜主日學服事 3 年',
        confirmLabel: '生成感謝狀',
        buildPrompt: _buildAppreciationLetterPrompt,
      );

  // ── v2.5 dialog triggers ─────────────────────────────────────────────────

  Future<void> _askPrayerLetterName() => _askInput(
        title: '會友姓名',
        hint: '請輸入要寄送禱告信的會友姓名',
        confirmLabel: '生成禱告信',
        buildPrompt: _buildPastoralPrayerLetterPrompt,
      );

  Future<void> _askBaptismName() => _askInput(
        title: '慕道友姓名',
        hint: '請輸入準備受洗者的姓名',
        confirmLabel: '生成見證引導',
        buildPrompt: _buildBaptismWitnessPrompt,
      );

  Future<void> _askElderName() => _askInput(
        title: '長老 ／ 執事姓名',
        hint: '請輸入即將就職者的姓名',
        confirmLabel: '生成感言草稿',
        buildPrompt: _buildElderOrdainationPrompt,
      );

  Future<void> _askYearEndYear() => _askInput(
        title: '年份',
        hint: '例：2026、2025…',
        confirmLabel: '生成牧函',
        buildPrompt: _buildYearEndPastoralLetterPrompt,
      );

  // ── v2.6 dialog triggers ─────────────────────────────────────────────────

  Future<void> _askEvangelismEvent() => _askInput(
        title: '佈道會名稱',
        hint: '例：2026 聖誕佈道會、青年福音夜…',
        confirmLabel: '生成邀請文案',
        buildPrompt: _buildEvangelismInvitePrompt,
      );

  Future<void> _askFuneralName() => _askInput(
        title: '喪親者姓名',
        hint: '請輸入需要牧關支援的會友姓名',
        confirmLabel: '生成安慰套件',
        buildPrompt: _buildFuneralComfortPrompt,
      );

  Future<void> _askMilestoneOccasion() => _askInput(
        title: '典禮類別',
        hint: '例：嬰兒奉獻禮、婚禮、金婚感恩禮…',
        confirmLabel: '生成禱告詞',
        buildPrompt: _buildLifeMilestonePrayerPrompt,
      );

  Future<void> _askMissionName() => _askInput(
        title: '宣教行動名稱',
        hint: '例：泰北短宣 2026、本地社區外展…',
        confirmLabel: '生成宣教報告',
        buildPrompt: _buildMissionReportPrompt,
      );

  // ── v2.7 dialog triggers ─────────────────────────────────────────────────

  Future<void> _askAnnualReportYear() => _askInput(
        title: '年份',
        hint: '例：2026、2025…',
        confirmLabel: '生成年報',
        buildPrompt: _buildAnnualReportPrompt,
      );

  Future<void> _askWeddingCouple() => _askInput(
        title: '新人姓名',
        hint: '例：陳大明 & 李小花',
        confirmLabel: '生成程序稿',
        buildPrompt: _buildWeddingServicePrompt,
      );

  Future<void> _askDedicationBaby() => _askInput(
        title: '嬰兒名字（選填父母：父母姓名｜嬰兒名字）',
        hint: '例：恩典  或  陳大明 & 李小花｜陳恩典',
        confirmLabel: '生成程序稿',
        buildPrompt: _buildDedicationServicePrompt,
      );

  Future<void> _askBibleSeriesTitle() => _askInput(
        title: '查經系列名稱或主題',
        hint: '例：約翰福音、登山寶訓、保羅書信…',
        confirmLabel: '生成課程',
        buildPrompt: _buildBibleSeriesPrompt,
      );

  // ── v2.8 dialog triggers ─────────────────────────────────────────────────

  Future<void> _askPostEvangelismEvent() => _askInput(
        title: '佈道會名稱',
        hint: '例：2026 聖誕佈道會、青年福音夜…',
        confirmLabel: '生成跟進計劃',
        buildPrompt: _buildPostEvangelismFollowUpPrompt,
      );

  Future<void> _askLeaderTrainingDuration() => _askInput(
        title: '培訓時長',
        hint: '例：4 小時、2 天 1 夜、6 週課程…',
        confirmLabel: '生成培訓大綱',
        buildPrompt: _buildSmallGroupLeaderTrainingPrompt,
      );

  Future<void> _askYouthTheme() => _askInput(
        title: '青少年事工主題',
        hint: '例：身份認同、友誼、信仰與學業…',
        confirmLabel: '生成活動方案',
        buildPrompt: _buildYouthMinistryPlanPrompt,
      );

  Future<void> _askElderBoardDate() => _askInput(
        title: '會議日期',
        hint: '例：2026 年 6 月 5 日、本月長執會…',
        confirmLabel: '生成議程',
        buildPrompt: _buildElderBoardMeetingPrompt,
      );

  // ── v2.9 dialog triggers ─────────────────────────────────────────────────

  Future<void> _askMonthlyReportMonth() => _askInput(
        title: '報告月份',
        hint: '例：2026 年 5 月、本月…',
        confirmLabel: '生成模板',
        buildPrompt: _buildSmallGroupMonthlyReportPrompt,
      );

  Future<void> _askEvangelismTrainingFormat() => _askInput(
        title: '培訓形式',
        hint: '例：4 週課程、半天工作坊、週六退修…',
        confirmLabel: '生成課程大綱',
        buildPrompt: _buildEvangelismTrainingPrompt,
      );

  Future<void> _askNewcomerName() => _askInput(
        title: '新人姓名',
        hint: '請輸入已多次出席的新人姓名',
        confirmLabel: '生成融入計劃',
        buildPrompt: _buildNewcomerIntegrationPrompt,
      );

  Future<void> _askAGMYear() => _askInput(
        title: '年份',
        hint: '例：2026、2025…',
        confirmLabel: '生成演講稿',
        buildPrompt: _buildAGMSpeechPrompt,
      );

  // ── v2.10 dialog triggers ────────────────────────────────────────────────

  Future<void> _askBudgetYear() => _askInput(
        title: '預算年度',
        hint: '例：2027 年度、下一財政年度…',
        confirmLabel: '生成預算草案',
        buildPrompt: _buildAnnualBudgetPrompt,
      );

  Future<void> _askMultiplyGroupName() => _askInput(
        title: '小組名稱',
        hint: '例：恩典小組、青年小組 B…',
        confirmLabel: '生成倍增計劃',
        buildPrompt: _buildCellMultiplicationPrompt,
      );

  Future<void> _askSabbaticalDuration() => _askInput(
        title: '靈修休假時長',
        hint: '例：2 週、1 個月、3 個月安息年…',
        confirmLabel: '生成計劃',
        buildPrompt: _buildPastorSabbaticalPrompt,
      );

  Future<void> _askCrisisType() => _askInput(
        title: '危機類型',
        hint: '例：會友衝突、財務醜聞、牧者離職、意外事故…',
        confirmLabel: '生成處理指引',
        buildPrompt: _buildCrisisManagementPrompt,
      );

  // ── v2.11 dialog triggers ────────────────────────────────────────────────

  Future<void> _askYouthPlanYear() => _askInput(
        title: '計劃年度',
        hint: '例：2027 年度、明年…',
        confirmLabel: '生成年度計劃',
        buildPrompt: _buildYouthAnnualPlanPrompt,
      );

  Future<void> _askRetreatDuration() => _askInput(
        title: '退修時長',
        hint: '例：一天、兩天一夜、半天…',
        confirmLabel: '生成議程',
        buildPrompt: _buildElderRetreatPrompt,
      );

  Future<void> _askGrowthTrackingName() => _askInput(
        title: '會友姓名',
        hint: '請輸入需要靈命成長追蹤的會友姓名',
        confirmLabel: '生成追蹤計劃',
        buildPrompt: _buildSpiritualGrowthTrackingPrompt,
      );

  Future<void> _askPrayerCultureFocus() => _askInput(
        title: '禱告文化重點',
        hint: '例：個人禱告習慣、小組代禱深化、全教會禱告運動…',
        confirmLabel: '生成建立計劃',
        buildPrompt: _buildPrayerCulturePrompt,
      );

  // ── v2.12 dialog triggers ────────────────────────────────────────────────

  Future<void> _askVisionFocus() => _askInput(
        title: '異象重點方向',
        hint: '例：關懷社區、門徒訓練、跨文化宣教、年輕化…',
        confirmLabel: '生成異象宣言',
        buildPrompt: _buildVisionStatementPrompt,
      );

  Future<void> _askPlantingLocation() => _askInput(
        title: '新堂會地點',
        hint: '例：九龍東、台中南區、溫哥華列治文…',
        confirmLabel: '生成設立計劃',
        buildPrompt: _buildChurchPlantingPrompt,
      );

  Future<void> _askMissionDestination() => _askInput(
        title: '短宣目的地',
        hint: '例：泰北清邁、菲律賓宿霧、本地社區…',
        confirmLabel: '生成招募培訓計劃',
        buildPrompt: _buildShortTermMissionPrompt,
      );

  Future<void> _askTransferMember() => _askInput(
        title: '會友姓名（選填轉往教會：姓名｜教會名稱）',
        hint: '例：陳大明  或  陳大明｜恩典堂',
        confirmLabel: '生成推薦信',
        buildPrompt: _buildTransferLetterPrompt,
      );

  // ── v2.13 dialog triggers ────────────────────────────────────────────────

  Future<void> _askBibleReadingYear() => _askInput(
        title: '讀經年份',
        hint: '例：2027 年、下一個教會年度…',
        confirmLabel: '生成讀經計劃',
        buildPrompt: _buildAnnualBibleReadingPrompt,
      );

  Future<void> _askYouthCampTheme() => _askInput(
        title: '營會主題',
        hint: '例：破框而出、身份認同、勇敢追夢…',
        confirmLabel: '生成營會方案',
        buildPrompt: _buildYouthCampPrompt,
      );

  Future<void> _askChurchSizeForVolunteer() => _askInput(
        title: '教會規模',
        hint: '例：50 人小型教會、200 人中型教會…',
        confirmLabel: '生成管理系統',
        buildPrompt: _buildVolunteerManagementPrompt,
      );

  Future<void> _askSuccessionTimeline() => _askInput(
        title: '交棒時間線',
        hint: '例：1 年內、2-3 年過渡期、5 年長期規劃…',
        confirmLabel: '生成交棒計劃',
        buildPrompt: _buildPastoralSuccessionPrompt,
      );

  // ── v2.14 dialog triggers ────────────────────────────────────────────────

  Future<void> _askLivestreamSermon() => _askInput(
        title: '講道題目',
        hint: '例：從恐懼到信心、愛的功課…',
        confirmLabel: '生成直播腳本',
        buildPrompt: _buildLivestreamScriptPrompt,
      );

  Future<void> _askFamilyMinistryTheme() => _askInput(
        title: '活動主題',
        hint: '例：同心守約、父母的榜樣、家的意義…',
        confirmLabel: '生成活動方案',
        buildPrompt: _buildFamilyMinistryPrompt,
      );

  Future<void> _askSocialMediaMonth() => _askInput(
        title: '計劃月份',
        hint: '例：2026 年 7 月、下個月…',
        confirmLabel: '生成月計劃',
        buildPrompt: _buildSocialMediaCalendarPrompt,
      );

  Future<void> _askLifeTransitionInput() => _askInput(
        title: '會友姓名（選填轉變類型：姓名｜類型）',
        hint: '例：陳大明  或  陳大明｜搬遷至台北',
        confirmLabel: '生成關懷計劃',
        buildPrompt: _buildLifeTransitionCarePrompt,
      );

  // ── v2.15 dialog triggers ────────────────────────────────────────────────

  Future<void> _askOnlineGivingPlatform() => _askInput(
        title: '奉獻平台或情境',
        hint: '例：PayMe、轉數快、Stripe、一般QR code…',
        confirmLabel: '生成設定指南',
        buildPrompt: _buildOnlineGivingGuidePrompt,
      );

  Future<void> _askOnlineSundaySchoolTopic() => _askInput(
        title: '主日學主題',
        hint: '例：神愛世人、感恩節、大衛的故事…',
        confirmLabel: '生成線上課程',
        buildPrompt: _buildOnlineSundaySchoolPrompt,
      );

  Future<void> _askLivestreamBudget() => _askInput(
        title: '直播設備預算範圍',
        hint: '例：HKD 5,000 入門、TWD 30,000 中級、不限預算…',
        confirmLabel: '生成設備清單',
        buildPrompt: _buildLivestreamEquipmentPrompt,
      );

  Future<void> _askOnlineGroupPlatform() => _askInput(
        title: '線上平台',
        hint: '例：Zoom、Google Meet、Microsoft Teams…',
        confirmLabel: '生成引導手冊',
        buildPrompt: _buildOnlineSmallGroupHandbookPrompt,
      );

  // ── v2.16 dialog triggers ────────────────────────────────────────────────

  Future<void> _askPrayerMeetingTheme() => _askInput(
        title: '禱告會主題',
        hint: '例：為城市禱告、感恩節禱告會、突破禱告…',
        confirmLabel: '生成流程設計',
        buildPrompt: _buildPrayerMeetingPrompt,
      );

  Future<void> _askMarriageCourseFormat() => _askInput(
        title: '課程形式',
        hint: '例：8 週課程、週末婚姻退修、單次婚姻講座…',
        confirmLabel: '生成課程大綱',
        buildPrompt: _buildMarriageCounselingPrompt,
      );

  Future<void> _askChildrensVolunteerRole() => _askInput(
        title: '服事崗位',
        hint: '例：主日學老師、兒童崇拜帶領、嬰兒室義工…',
        confirmLabel: '生成培訓手冊',
        buildPrompt: _buildChildrensVolunteerTrainingPrompt,
      );

  Future<void> _askEmergencyType() => _askInput(
        title: '緊急情況類型',
        hint: '例：疫症防控、颱風/自然災害、社會動盪…',
        confirmLabel: '生成事工計劃',
        buildPrompt: _buildEmergencyMinistryPrompt,
      );

  // ── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('AI 助手')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(context),
          const SizedBox(height: 16),
          _AiCard(
            icon: Icons.summarize_outlined,
            color: Colors.deepPurple,
            title: '生成探訪摘要',
            subtitle: '根據活躍案件自動整理本週探訪重點與行動建議',
            onTap: () => _run(_buildVisitSummaryPrompt()),
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.volunteer_activism_outlined,
            color: Colors.indigo,
            title: '整理代禱事項',
            subtitle: '將所有活躍關懷案件整合成本週代禱清單',
            onTap: () => _run(_buildPrayerPrompt()),
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.present_to_all_outlined,
            color: Colors.teal,
            title: '產生講道 PPT 大綱',
            subtitle: '輸入講道題目，AI 自動生成結構化 PPT 大綱與反思問題',
            onTap: _askSermonTopic,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.person_search_outlined,
            color: Colors.blueGrey,
            title: '會友近況查詢',
            subtitle: '輸入會友姓名，AI 整合關懷記錄並給出牧關建議',
            onTap: _askMemberName,
          ),
          const SizedBox(height: 24),
          _SectionDivider(label: '事工輔助'),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.groups_2_outlined,
            color: Colors.orange,
            title: '小組討論問題',
            subtitle: '輸入查經主題或經文，生成破冰、深入與應用問題套組',
            onTap: _askGroupTopic,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.campaign_outlined,
            color: Colors.pink,
            title: '活動文案與海報提示',
            subtitle: '輸入活動名稱，AI 生成海報標題、介紹段落與分享短文',
            onTap: _askEventName,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.receipt_long_outlined,
            color: Colors.green,
            title: '財務報告草稿',
            subtitle: '輸入報告期間，自動生成財務報告範本與健康指標建議',
            onTap: _askFinancePeriod,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.edit_note_outlined,
            color: Colors.deepOrange,
            title: '牧養行動建議',
            subtitle: '輸入會友姓名，生成短中長期具體牧養行動計劃',
            onTap: _askPastoralName,
          ),
          const SizedBox(height: 24),
          _SectionDivider(label: '行政事工'),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.newspaper_outlined,
            color: Colors.cyan,
            title: '主日週報草稿',
            subtitle: '輸入主日日期，自動生成含代禱、公告、奉獻提醒的完整週報',
            onTap: _askBulletinDate,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.format_list_numbered_outlined,
            color: Colors.purple,
            title: '講道重點摘要',
            subtitle: '輸入聖經章節或主題，生成 3-5 個講道重點與呼召信息',
            onTap: _askSermonPassage,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.palette_outlined,
            color: Colors.red,
            title: '活動海報設計提示',
            subtitle: '輸入活動名稱，生成色調、版面、AI 繪圖提示詞全套設計方案',
            onTap: _askPosterEvent,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.diversity_3_outlined,
            color: Colors.brown,
            title: '小組長牧養建議',
            subtitle: '輸入小組或部門名稱，生成小組健康評估與具體牧養策略',
            onTap: _askGroupName,
          ),
          const SizedBox(height: 24),
          _SectionDivider(label: '牧養文書'),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.mark_email_read_outlined,
            color: Colors.lightBlue,
            title: '新人歡迎信',
            subtitle: '輸入新來者姓名，生成溫暖個人化歡迎信（可列印或電郵發送）',
            onTap: _askWelcomeName,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.favorite_border,
            color: Colors.pinkAccent,
            title: '會友關懷離開信',
            subtitle: '輸入會友姓名，生成不施壓、維繫關係的溫柔關懷信',
            onTap: _askFarewellName,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.connect_without_contact_outlined,
            color: Colors.amber,
            title: '教牧週訊草稿',
            subtitle: '輸入週訊期間，自動整合紅燈案件、行動清單與牧者話語',
            onTap: _askNewsletterPeriod,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.child_care_outlined,
            color: Colors.lightGreen,
            title: '兒童主日學教案',
            subtitle: '輸入主日學主題，生成含遊戲、故事、手工的完整教案',
            onTap: _askSundaySchoolTopic,
          ),
          const SizedBox(height: 24),
          _SectionDivider(label: '組織管理'),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.event_note_outlined,
            color: Colors.teal,
            title: '部門會議議程',
            subtitle: '輸入部門名稱，生成含行動事項跟進與討論議題的完整會議議程',
            onTap: _askMeetingDept,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.calendar_month_outlined,
            color: Colors.deepPurple,
            title: '年度事工計劃',
            subtitle: '輸入事工部門，生成 12 個月活動計劃、預算概估與成效評估',
            onTap: _askMinistryDept,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.person_add_outlined,
            color: Colors.indigo,
            title: '志工招募文案',
            subtitle: '輸入服事崗位，生成海報文案、職責說明與 WhatsApp 分享版本',
            onTap: _askVolunteerRole,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.workspace_premium_outlined,
            color: Colors.orange,
            title: '感謝狀草稿',
            subtitle: '輸入姓名（選填事由），生成可列印的正式感謝狀',
            onTap: _askAppreciationTarget,
          ),
          const SizedBox(height: 24),
          _SectionDivider(label: '屬靈里程'),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.mail_outlined,
            color: Colors.deepPurple,
            title: '牧養禱告信',
            subtitle: '輸入會友姓名，生成結合關懷記錄的個人化禱告信',
            onTap: _askPrayerLetterName,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.water_outlined,
            color: Colors.blue,
            title: '受洗見證引導',
            subtitle: '輸入慕道友姓名，生成見證問卷、撰寫框架與受洗問答',
            onTap: _askBaptismName,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.how_to_reg_outlined,
            color: Colors.indigo,
            title: '長執就職感言',
            subtitle: '輸入長老或執事姓名，生成就職典禮感言草稿框架',
            onTap: _askElderName,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.celebration_outlined,
            color: Colors.green,
            title: '年終牧函草稿',
            subtitle: '輸入年份，自動整合年度數據生成全教會年終牧師信',
            onTap: _askYearEndYear,
          ),
          const SizedBox(height: 24),
          _SectionDivider(label: '外展宣教'),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.campaign_rounded,
            color: Colors.red,
            title: '佈道會邀請文案',
            subtitle: '輸入佈道會名稱，生成邀請卡、口頭話術與社群媒體文案套件',
            onTap: _askEvangelismEvent,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.sentiment_very_dissatisfied_outlined,
            color: Colors.grey,
            title: '喪禮安慰套件',
            subtitle: '輸入喪親者姓名，生成安慰信、追思禮拜程序與哀傷陪伴指引',
            onTap: _askFuneralName,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.church_outlined,
            color: Colors.purple,
            title: '人生里程碑禱告',
            subtitle: '輸入典禮類別（嬰兒奉獻/婚禮/金婚），生成完整典禮禱告詞框架',
            onTap: _askMilestoneOccasion,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.flight_outlined,
            color: Colors.teal,
            title: '宣教報告草稿',
            subtitle: '輸入宣教行動名稱，生成含恩典時刻、挑戰與跟進計劃的完整報告',
            onTap: _askMissionName,
          ),
          const SizedBox(height: 24),
          _SectionDivider(label: '典禮崇拜'),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.bar_chart_outlined,
            color: Colors.blueGrey,
            title: '教會年報摘要',
            subtitle: '輸入年份，自動整合會友與關懷數據，生成正式年報全文框架',
            onTap: _askAnnualReportYear,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.favorite_outlined,
            color: Colors.pink,
            title: '婚禮崇拜程序稿',
            subtitle: '輸入新人姓名，生成含司儀詞、婚誓、戒指禮、禱告的完整流程',
            onTap: _askWeddingCouple,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.child_friendly_outlined,
            color: Colors.lightBlue,
            title: '嬰兒奉獻典禮程序',
            subtitle: '輸入嬰兒名字，生成含牧者對話、奉獻禱告、會眾回應的完整程序稿',
            onTap: _askDedicationBaby,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.menu_book_outlined,
            color: Colors.brown,
            title: '多週查經課程設計',
            subtitle: '輸入查經系列主題，生成多週課程大綱（含觀察/詮釋/應用問題）',
            onTap: _askBibleSeriesTitle,
          ),
          const SizedBox(height: 24),
          _SectionDivider(label: '領袖發展'),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.follow_the_signs_outlined,
            color: Colors.deepOrange,
            title: '佈道後跟進計劃',
            subtitle: '輸入佈道會名稱，生成 72 小時黃金跟進到 3 個月栽培的完整路徑',
            onTap: _askPostEvangelismEvent,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.school_outlined,
            color: Colors.indigo,
            title: '小組長培訓大綱',
            subtitle: '輸入培訓時長，生成四大模組（身份/查經/牧養/倍增）完整培訓課程',
            onTap: _askLeaderTrainingDuration,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.sports_esports_outlined,
            color: Colors.purple,
            title: '青少年事工方案',
            subtitle: '輸入活動主題，生成含流程、信息大綱、遊戲設計與宣傳文案的完整方案',
            onTap: _askYouthTheme,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.gavel_outlined,
            color: Colors.brown,
            title: '長執會議議程',
            subtitle: '輸入會議日期，自動嵌入即時數據生成議程與決議追蹤表',
            onTap: _askElderBoardDate,
          ),
          const SizedBox(height: 24),
          _SectionDivider(label: '成長裝備'),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.assignment_outlined,
            color: Colors.teal,
            title: '小組長月報模板',
            subtitle: '輸入月份，生成含出席/靈命/關懷/外展的標準化月報填寫模板',
            onTap: _askMonthlyReportMonth,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.record_voice_over_outlined,
            color: Colors.deepOrange,
            title: '佈道訓練課程',
            subtitle: '輸入培訓形式，生成裝備會友自然分享信仰的完整訓練大綱',
            onTap: _askEvangelismTrainingFormat,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.directions_walk_outlined,
            color: Colors.green,
            title: '新人整合六個月計劃',
            subtitle: '輸入新人姓名，生成從訪客到肢體的 6 個月融入路徑圖',
            onTap: _askNewcomerName,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.mic_outlined,
            color: Colors.purple,
            title: '年度大會演講稿',
            subtitle: '輸入年份，生成整合即時數據的 AGM 口頭報告演講稿（含停頓提示）',
            onTap: _askAGMYear,
          ),
          const SizedBox(height: 24),
          _SectionDivider(label: '策略治理'),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.account_balance_outlined,
            color: Colors.green,
            title: '年度預算草案',
            subtitle: '輸入預算年度，生成收入/支出框架、財務健康指標與計算公式',
            onTap: _askBudgetYear,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.call_split_outlined,
            color: Colors.orange,
            title: '小組倍增計劃',
            subtitle: '輸入小組名稱，生成評估、培育、分植、復甦後支援的完整路徑',
            onTap: _askMultiplyGroupName,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.self_improvement_outlined,
            color: Colors.teal,
            title: '牧者靈修休假計劃',
            subtitle: '輸入休假時長，生成交接清單、靈修框架與復返後重融入計劃',
            onTap: _askSabbaticalDuration,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.warning_amber_outlined,
            color: Colors.red,
            title: '教會危機處理指引',
            subtitle: '輸入危機類型，生成評估、對內對外溝通、牧養恢復的四步驟指引',
            onTap: _askCrisisType,
          ),
          const SizedBox(height: 24),
          _SectionDivider(label: '靈命牧養'),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.people_alt_outlined,
            color: Colors.purple,
            title: '青少年事工年度計劃',
            subtitle: '輸入計劃年度，生成含月度行事曆、門徒路徑、外展策略的12個月計劃',
            onTap: _askYouthPlanYear,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.landscape_outlined,
            color: Colors.teal,
            title: '長執退修會議程',
            subtitle: '輸入退修時長，生成以異象更新和屬靈更新為核心的退修會框架',
            onTap: _askRetreatDuration,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.trending_up_outlined,
            color: Colors.green,
            title: '靈命成長追蹤計劃',
            subtitle: '輸入會友姓名，生成個人靈命評估、3個月目標與月度跟進框架',
            onTap: _askGrowthTrackingName,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.record_voice_over_outlined,
            color: Colors.indigo,
            title: '禱告文化建立計劃',
            subtitle: '輸入重點方向，生成從個人到全教會的禱告文化三階段建立計劃',
            onTap: _askPrayerCultureFocus,
          ),
          const SizedBox(height: 24),
          _SectionDivider(label: '異象拓展'),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.visibility_outlined,
            color: Colors.deepPurple,
            title: '教會異象宣言',
            subtitle: '輸入異象方向，生成使命/異象/核心價值/策略重點完整套件',
            onTap: _askVisionFocus,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.add_business_outlined,
            color: Colors.teal,
            title: '新堂會設立計劃',
            subtitle: '輸入地點，生成可行性評估、籌備期、開堂年的三階段完整框架',
            onTap: _askPlantingLocation,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.connecting_airports_outlined,
            color: Colors.blue,
            title: '短宣隊招募培訓',
            subtitle: '輸入目的地，生成招募公告、申請表、培訓課程與差遣典禮全套計劃',
            onTap: _askMissionDestination,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.swap_horiz_outlined,
            color: Colors.blueGrey,
            title: '轉會推薦信',
            subtitle: '輸入會友姓名（選填轉往教會），生成正式轉會推薦信',
            onTap: _askTransferMember,
          ),
          const SizedBox(height: 24),
          _SectionDivider(label: '傳承更新'),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.auto_stories_outlined,
            color: Colors.green,
            title: '年度全教會讀經計劃',
            subtitle: '輸入年份，生成3個難度版本的讀經計劃、記錄表與激勵機制',
            onTap: _askBibleReadingYear,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.cabin_outlined,
            color: Colors.orange,
            title: '青年營會完整方案',
            subtitle: '輸入營會主題，生成兩天一夜完整行程、兩篇信息大綱與後勤清單',
            onTap: _askYouthCampTheme,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.manage_accounts_outlined,
            color: Colors.indigo,
            title: '義工管理系統',
            subtitle: '輸入教會規模，生成招募/入職/關顧/記錄/退出五模組完整系統',
            onTap: _askChurchSizeForVolunteer,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.handshake_outlined,
            color: Colors.brown,
            title: '牧師交棒計劃',
            subtitle: '輸入交棒時間線，生成繼任者培育、過渡交接、新牧者支援完整框架',
            onTap: _askSuccessionTimeline,
          ),
          const SizedBox(height: 24),
          _SectionDivider(label: '數位家庭'),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.live_tv_outlined,
            color: Colors.red,
            title: '線上直播崇拜腳本',
            subtitle: '輸入講道題目，生成含技術指示、司儀台詞、互動提示的完整直播腳本',
            onTap: _askLivestreamSermon,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.family_restroom_outlined,
            color: Colors.orange,
            title: '家庭事工活動方案',
            subtitle: '輸入活動主題，生成親子分組學習、合一遊戲與家庭靈修的半天方案',
            onTap: _askFamilyMinistryTheme,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.calendar_view_month_outlined,
            color: Colors.pink,
            title: '社群媒體月計劃',
            subtitle: '輸入月份，生成FB/IG/WhatsApp三平台的4週內容日曆與高互動貼文範本',
            onTap: _askSocialMediaMonth,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.transfer_within_a_station_outlined,
            color: Colors.teal,
            title: '人生轉變關懷計劃',
            subtitle: '輸入會友姓名（選填轉變類型），生成搬家/轉職/退休等過渡期牧養計劃',
            onTap: _askLifeTransitionInput,
          ),
          const SizedBox(height: 24),
          _SectionDivider(label: '數位事工'),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.payment_outlined,
            color: Colors.green,
            title: '線上奉獻系統指南',
            subtitle: '輸入奉獻平台，生成設定步驟、推廣文案、財務治理與牧養考量全套指南',
            onTap: _askOnlineGivingPlatform,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.video_call_outlined,
            color: Colors.blue,
            title: '兒主線上課程設計',
            subtitle: '輸入主日學主題，生成針對Zoom線上教學優化的完整課程流程與技術指引',
            onTap: _askOnlineSundaySchoolTopic,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.videocam_outlined,
            color: Colors.red,
            title: '直播設備清單與設定',
            subtitle: '輸入預算範圍，生成設備採購清單、OBS設定步驟與義工培訓大綱',
            onTap: _askLivestreamBudget,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.groups_outlined,
            color: Colors.indigo,
            title: '線上小組引導手冊',
            subtitle: '輸入視訊平台，生成含技術技巧、互動方法、關係建立的可列印小冊子',
            onTap: _askOnlineGroupPlatform,
          ),
          const SizedBox(height: 24),
          _SectionDivider(label: '關懷裝備'),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.nights_stay_outlined,
            color: Colors.deepPurple,
            title: '禱告會主題與流程',
            subtitle: '輸入禱告主題，生成90分鐘完整流程、引導語範本與禱告記錄表',
            onTap: _askPrayerMeetingTheme,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.favorite_outlined,
            color: Colors.pink,
            title: '婚姻輔導課程大綱',
            subtitle: '輸入課程形式，生成5模組婚姻課程（溝通/愛語/財務/親密/更新）',
            onTap: _askMarriageCourseFormat,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.escalator_warning_outlined,
            color: Colors.orange,
            title: '兒童事工義工培訓手冊',
            subtitle: '輸入服事崗位，生成含兒童保護政策、職責清單、互動技巧的可列印手冊',
            onTap: _askChildrensVolunteerRole,
          ),
          const SizedBox(height: 12),
          _AiCard(
            icon: Icons.emergency_outlined,
            color: Colors.red,
            title: '緊急事工計劃',
            subtitle: '輸入緊急類型，生成事工持續運作、會眾關懷升級與社區外展的應急方案',
            onTap: _askEmergencyType,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI 回應僅供參考，牧者請自行判斷與跟進。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final care = globalCareController;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.smart_toy_outlined,
                color: Theme.of(context).colorScheme.primary, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('教會 AI 助手',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                  Text(
                    '目前 ${care.activeCount} 個活躍案件 · ${care.redCount} 件需緊急跟進',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: care.redCount > 0 ? Colors.red : null,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Section divider
// ============================================================================

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

// ============================================================================
// Reusable card widget
// ============================================================================

class _AiCard extends StatelessWidget {
  const _AiCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            )),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
