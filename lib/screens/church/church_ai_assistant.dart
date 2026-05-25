// lib/screens/church/church_ai_assistant.dart
//
// ChurchAiAssistant v2.5 — 24 quick AI functions for pastoral team.
//
// v1  (4 cards): 生成探訪摘要 / 整理代禱事項 / 講道PPT大綱 / 會友近況查詢
// v2.1(+ 4 cards): 小組討論問題 / 活動文案海報 / 財務報告草稿 / 牧養行動建議
// v2.2(+ 4 cards): 主日週報草稿 / 講道重點摘要 / 活動海報設計提示 / 小組長牧養建議
// v2.3(+ 4 cards): 新人歡迎信 / 會友關懷離開信 / 牧養週訊 / 兒童主日學教案
// v2.4(+ 4 cards): 部門會議議程 / 年度事工計劃 / 志工招募文案 / 感謝狀草稿
// v2.5(+ 4 cards): 牧養禱告信 / 受洗見證引導 / 長執就職感言 / 年終牧函
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
