// lib/screens/church/church_documents_screen.dart

import 'package:flutter/material.dart';

import '../../controllers/church/care_controller.dart';
import '../../controllers/church/person_controller.dart';
import '../../main.dart';
import '../../models/church/care_case.dart';
import '../../models/church/person.dart';
import '../../models/church/visit_log.dart';
import '../../widgets/office/office_prompt_card.dart';

enum ActiveTool {
  none,
  sermonSummary,
  bibleQuestions,
  careSummary,
  memberProfile,
  bulletinDraft,
  eventProposal,
  pptOutline,
  careEmail,
}

class ChurchDocumentsScreen extends StatefulWidget {
  final CareController careController;
  final PersonController personController;

  const ChurchDocumentsScreen({
    super.key,
    required this.careController,
    required this.personController,
  });

  @override
  State<ChurchDocumentsScreen> createState() => _ChurchDocumentsScreenState();
}

class _ChurchDocumentsScreenState extends State<ChurchDocumentsScreen> {
  ActiveTool _activeTool = ActiveTool.none;
  bool _isLoading = false;
  String _generatedResult = '';

  // Controllers for various inputs
  final TextEditingController _transcriptController = TextEditingController();
  final TextEditingController _biblePassageController = TextEditingController();
  final TextEditingController _customInstructionsController = TextEditingController();

  // For weekly bulletin
  final TextEditingController _sermonTitleController = TextEditingController();
  final TextEditingController _sermonScriptureController = TextEditingController();
  final TextEditingController _announcementsController = TextEditingController();
  final TextEditingController _prayersController = TextEditingController();

  // For event proposal
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _eventThemeController = TextEditingController();
  final TextEditingController _eventTargetController = TextEditingController();
  final TextEditingController _eventLocationController = TextEditingController();

  // Selected dropdown values
  String? _selectedCaseId;
  String? _selectedPersonId;

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    if (!widget.careController.isLoaded) widget.careController.loadAll();
    if (!widget.personController.isLoaded) widget.personController.loadAll();
    _transcriptController.addListener(_onTextChanged);
    _biblePassageController.addListener(_onTextChanged);
    _sermonTitleController.addListener(_onTextChanged);
    _eventNameController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _transcriptController.removeListener(_onTextChanged);
    _biblePassageController.removeListener(_onTextChanged);
    _sermonTitleController.removeListener(_onTextChanged);
    _eventNameController.removeListener(_onTextChanged);
    _transcriptController.dispose();
    _biblePassageController.dispose();
    _customInstructionsController.dispose();
    _sermonTitleController.dispose();
    _sermonScriptureController.dispose();
    _announcementsController.dispose();
    _prayersController.dispose();
    _eventNameController.dispose();
    _eventThemeController.dispose();
    _eventTargetController.dispose();
    _eventLocationController.dispose();
    super.dispose();
  }

  void _clearState() {
    setState(() {
      _generatedResult = '';
      _isLoading = false;
      _transcriptController.clear();
      _biblePassageController.clear();
      _customInstructionsController.clear();
      _sermonTitleController.clear();
      _sermonScriptureController.clear();
      _announcementsController.clear();
      _prayersController.clear();
      _eventNameController.clear();
      _eventThemeController.clear();
      _eventTargetController.clear();
      _eventLocationController.clear();
      _selectedCaseId = null;
      _selectedPersonId = null;
    });
  }

  // --- Prompts Builders ---

  String _buildSermonSummaryPrompt() {
    final text = _transcriptController.text.trim();
    final custom = _customInstructionsController.text.trim();
    return '''
你是本機教會 AI 文書助理。
請針對以下講道逐字稿進行摘要與整理。
報告應包含：
1. 講道核心摘要 (約 300 字)
2. 3-5 個主要神學與生活應用重點
3. 本次講道所引用或提及的聖經經文

${custom.isNotEmpty ? "同工特別指示：\n$custom\n" : ""}
講道逐字稿內容：
$text
''';
  }

  String _buildBibleQuestionsPrompt() {
    final passage = _biblePassageController.text.trim();
    final custom = _customInstructionsController.text.trim();
    return '''
你是本機教會 AI 文書助理。
請針對以下經文或查經主題，設計一份適合小組查經討論的教案：
1. 提供 3-5 個啟發性的討論問題（包含經文觀察、經文解釋與個人生活應用問題）
2. 為帶領者提供簡要的引導指南與參考神學經文背景說明

查經目標範圍：
$passage

${custom.isNotEmpty ? "同工特別指示：\n$custom\n" : ""}
''';
  }

  String _buildCareSummaryPrompt() {
    final caseObj = widget.careController.findCase(_selectedCaseId ?? '');
    if (caseObj == null) return '';

    final visits = widget.careController.visitsForCase(caseObj.id);
    final custom = _customInstructionsController.text.trim();

    final buf = StringBuffer();
    buf.writeln('你是本機教會 AI 文書助理。');
    buf.writeln('請根據以下提供的關懷個案背景與歷次探訪紀錄，整理撰寫一份詳細的「關懷個案進度摘要報告」。');
    buf.writeln('報告應包含：');
    buf.writeln('1. 個案基本狀況與關懷起因');
    buf.writeln('2. 歷次探訪摘要與互動變化趨勢');
    buf.writeln('3. 牧長與關懷同工跟進的後續具體代禱事項與建議');
    buf.writeln();
    if (custom.isNotEmpty) {
      buf.writeln('同工特別指示：\n$custom\n');
    }
    buf.writeln('【關懷個案基本資訊】');
    buf.writeln('- 會友姓名: ${caseObj.memberName}');
    buf.writeln('- 電話: ${caseObj.memberPhone}');
    buf.writeln('- 身分: ${CaseType.label(caseObj.caseType)}');
    buf.writeln('- 關懷緣由: ${caseObj.reason}');
    buf.writeln('- 優先程度: ${CareUrgency.label(caseObj.urgency)}優先');
    buf.writeln('- 案件狀態: ${CareStatus.label(caseObj.status)}');
    buf.writeln('- 建立時間: ${caseObj.createdAt.toIso8601String().substring(0, 10)}');
    if (caseObj.notes.isNotEmpty) {
      buf.writeln('- 起始備註: ${caseObj.notes}');
    }
    buf.writeln();
    buf.writeln('【歷次探訪關懷紀錄 (共 ${visits.length} 筆)】');
    if (visits.isEmpty) {
      buf.writeln('尚無探訪歷史紀錄。');
    } else {
      for (final v in visits) {
        buf.writeln('- 探訪日期: ${v.visitDate.toIso8601String().substring(0, 10)}');
        buf.writeln('  探訪同工: ${v.visitedBy}');
        buf.writeln('  方式: ${VisitMethod.label(v.method)}');
        buf.writeln('  探訪摘要: ${v.summary}');
        buf.writeln('  狀況: ${MemberCondition.label(v.condition)}');
        buf.writeln();
      }
    }
    return buf.toString();
  }

  String _buildMemberProfilePrompt() {
    final person = widget.personController.findPerson(_selectedPersonId ?? '');
    if (person == null) return '';

    final cases = widget.careController.casesForPerson(person.name);
    final custom = _customInstructionsController.text.trim();

    final buf = StringBuffer();
    buf.writeln('你是本機教會 AI 文書助理。');
    buf.writeln('請根據以下提供的會友/非會友基本通訊錄資料及關懷歷史，產生一份「會友個人概況摘要」。');
    buf.writeln('內容需結構化呈現，包括：');
    buf.writeln('1. 基本資料與出席狀況');
    buf.writeln('2. 教會生命歷程與參與服事/小組情形');
    buf.writeln('3. 歷史關懷個案記錄摘要');
    buf.writeln();
    if (custom.isNotEmpty) {
      buf.writeln('同工特別指示：\n$custom\n');
    }
    buf.writeln('【基本資料】');
    buf.writeln('- 姓名: ${person.name}');
    buf.writeln('- 電話: ${person.phone}');
    buf.writeln('- 身分屬性: ${PersonType.label(person.personType)}');
    buf.writeln('- 出席崇拜頻率: ${AttendanceStatus.label(person.attendance)}');
    buf.writeln('- 所屬小組: ${person.smallGroup.isEmpty ? "未加入" : person.smallGroup}');
    buf.writeln('- 主日學參與: ${person.sundaySchool.isEmpty ? "無" : person.sundaySchool}');
    if (person.birthday != null) {
      buf.writeln('- 生日: ${person.birthday!.toIso8601String().substring(0, 10)}');
    }
    if (person.baptismDate != null) {
      buf.writeln('- 洗禮日期: ${person.baptismDate!.toIso8601String().substring(0, 10)}');
    }
    if (person.joinDate != null) {
      buf.writeln('- 加入教會日期: ${person.joinDate!.toIso8601String().substring(0, 10)}');
    }
    if (person.notes.isNotEmpty) {
      buf.writeln('- 備註資訊: ${person.notes}');
    }
    buf.writeln();
    buf.writeln('【歷史關懷案件紀錄 (共 ${cases.length} 個關懷案件)】');
    if (cases.isEmpty) {
      buf.writeln('尚無關懷個案紀錄。');
    } else {
      for (final c in cases) {
        buf.writeln('- 案件緣由: ${c.reason} (${CareStatus.label(c.status)})');
        buf.writeln('  優先程度: ${CareUrgency.label(c.urgency)}優先');
        buf.writeln('  建立時間: ${c.createdAt.toIso8601String().substring(0, 10)}');
        if (c.notes.isNotEmpty) {
          buf.writeln('  備註: ${c.notes}');
        }
        buf.writeln();
      }
    }
    return buf.toString();
  }

  String _buildBulletinDraftPrompt() {
    final title = _sermonTitleController.text.trim();
    final scripture = _sermonScriptureController.text.trim();
    final announces = _announcementsController.text.trim();
    final prayers = _prayersController.text.trim();
    final custom = _customInstructionsController.text.trim();

    return '''
你是本機教會 AI 文書助理。
請將以下提供的講道與報告資訊，整理草擬成一份正式、排版精美的「教會週報草稿」。
週報草稿需包含：
1. 本週主日訊息看板 (包含講題、經文與大綱草案)
2. 代禱與宣教消息 (列出所有提供之代禱項目，並進行通順語句修飾)
3. 行政報告與公告事項 (格式化條列，口吻需正式、客氣)

週報資訊來源：
- 講道題目: $title
- 宣讀經文: $scripture
- 報告與公告事項:
$announces
- 代禱事項:
$prayers

${custom.isNotEmpty ? "同工特別指示：\n$custom\n" : ""}
''';
  }

  String _buildEventProposalPrompt() {
    final name = _eventNameController.text.trim();
    final theme = _eventThemeController.text.trim();
    final target = _eventTargetController.text.trim();
    final location = _eventLocationController.text.trim();
    final custom = _customInstructionsController.text.trim();

    return '''
你是本機教會 AI 文書助理。
請幫我規劃一份教會活動企劃書草案。
企劃細節：
- 活動名稱: $name
- 主題與主要目標: $theme
- 目標對象: $target
- 時間與地點: $location

企劃書應包含以下 Markdown 結構：
1. 活動宗旨與異象說明
2. 活動大綱與流程規劃 (時間線)
3. 同工配置與預算預估建議

${custom.isNotEmpty ? "同工特別指示：\n$custom\n" : ""}
''';
  }

  String _buildPptOutlinePrompt() {
    final text = _transcriptController.text.trim();
    final custom = _customInstructionsController.text.trim();

    return '''
你是本機教會 AI 文書助理。
請把以下內容轉成 8 張 PowerPoint 敬拜 / 查經簡報大綱的 JSON array。
每張投影片包含：
- title (投影片標題)
- bullets (投影片要點，JSON 字串陣列)
- speaker_notes (演講者備忘錄)
- suggested_visual (建議視覺效果)

請務必僅輸出一個合法的 JSON array 格式，不要包含任何 markdown 標記（如 ```json）或額外的解釋說明文字。

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
$text

${custom.isNotEmpty ? "同工特別指示：\n$custom\n" : ""}
''';
  }

  String _buildCareEmailPrompt() {
    final caseObj = widget.careController.findCase(_selectedCaseId ?? '');
    final custom = _customInstructionsController.text.trim();

    final buf = StringBuffer();
    buf.writeln('你是本機教會 AI 文書助理。');
    buf.writeln('請根據以下提供的關懷個案背景，草擬一封關懷慰問的 Outlook 郵件。');
    buf.writeln('語氣需要親切、溫暖、充滿牧養關懷，並在信中適度引用 1 節合適的勉勵聖經經文。');
    buf.writeln();
    if (custom.isNotEmpty) {
      buf.writeln('同工特別指示（如特定語氣或期望）：\n$custom\n');
    }
    if (caseObj != null) {
      buf.writeln('【個案基本背景】');
      buf.writeln('- 會友姓名: ${caseObj.memberName}');
      buf.writeln('- 關懷緣由: ${caseObj.reason}');
      if (caseObj.notes.isNotEmpty) {
        buf.writeln('- 背景備註: ${caseObj.notes}');
      }
    }
    return buf.toString();
  }

  // --- Generation Logic ---

  Future<void> _startGeneration() async {
    setState(() {
      _isLoading = true;
      _generatedResult = '';
    });

    String prompt = '';

    switch (_activeTool) {
      case ActiveTool.sermonSummary:
        prompt = _buildSermonSummaryPrompt();
        break;
      case ActiveTool.bibleQuestions:
        prompt = _buildBibleQuestionsPrompt();
        break;
      case ActiveTool.careSummary:
        prompt = _buildCareSummaryPrompt();
        break;
      case ActiveTool.memberProfile:
        prompt = _buildMemberProfilePrompt();
        break;
      case ActiveTool.bulletinDraft:
        prompt = _buildBulletinDraftPrompt();
        break;
      case ActiveTool.eventProposal:
        prompt = _buildEventProposalPrompt();
        break;
      case ActiveTool.pptOutline:
        prompt = _buildPptOutlinePrompt();
        break;
      case ActiveTool.careEmail:
        prompt = _buildCareEmailPrompt();
        break;
      default:
        break;
    }

    if (prompt.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final stream = globalOllama.generate(prompt);
      await for (final token in stream) {
        if (!mounted) return;
        setState(() {
          _generatedResult += token;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _generatedResult = '生成失敗，發生錯誤：\n$e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- UI Builders ---

  Widget _buildGridCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridMode() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.0,
      children: [
        _buildGridCard(
          title: '講道逐字稿摘要',
          subtitle: '產生講道大綱與要點摘要',
          icon: Icons.summarize_outlined,
          color: Colors.blue,
          onTap: () => setState(() => _activeTool = ActiveTool.sermonSummary),
        ),
        _buildGridCard(
          title: '小組查經問題生成',
          subtitle: '設計經文討論與引導教材',
          icon: Icons.help_outline,
          color: Colors.green,
          onTap: () => setState(() => _activeTool = ActiveTool.bibleQuestions),
        ),
        _buildGridCard(
          title: '關懷紀錄整理',
          subtitle: '整合歷次探訪紀錄為摘要報告',
          icon: Icons.volunteer_activism_outlined,
          color: Colors.deepPurple,
          onTap: () => setState(() => _activeTool = ActiveTool.careSummary),
        ),
        _buildGridCard(
          title: '會友資料摘要',
          subtitle: '匯總通訊錄與關懷背景概況',
          icon: Icons.contact_page_outlined,
          color: Colors.teal,
          onTap: () => setState(() => _activeTool = ActiveTool.memberProfile),
        ),
        _buildGridCard(
          title: '教會週報草稿',
          subtitle: '草擬本週講道與行政报告週報',
          icon: Icons.newspaper_outlined,
          color: Colors.orange,
          onTap: () => setState(() => _activeTool = ActiveTool.bulletinDraft),
        ),
        _buildGridCard(
          title: '活動企劃書',
          subtitle: '規劃教會大中小型企劃流程',
          icon: Icons.event_note_outlined,
          color: Colors.pink,
          onTap: () => setState(() => _activeTool = ActiveTool.eventProposal),
        ),
        _buildGridCard(
          title: 'PPT 敬拜/查經大綱',
          subtitle: '規劃並輸出投影片 JSON 大綱',
          icon: Icons.slideshow_outlined,
          color: Colors.redAccent,
          onTap: () => setState(() => _activeTool = ActiveTool.pptOutline),
        ),
        _buildGridCard(
          title: 'Outlook 關懷郵件草稿',
          subtitle: '撰寫溫暖關懷的代禱信與郵件',
          icon: Icons.mail_outline,
          color: Colors.indigo,
          onTap: () => setState(() => _activeTool = ActiveTool.careEmail),
        ),
      ],
    );
  }

  Widget _buildToolConfigHeader() {
    String title = '';
    String desc = '';
    Widget customInputs = const SizedBox.shrink();

    switch (_activeTool) {
      case ActiveTool.sermonSummary:
        title = '講道逐字稿摘要';
        desc = '請在下方貼上主日講道逐字稿或筆記，AI 將自動進行分段、提煉核心神學點與生活實踐。';
        customInputs = TextField(
          controller: _transcriptController,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: '貼上講道逐字稿或筆記',
            border: OutlineInputBorder(),
          ),
        );
        break;
      case ActiveTool.bibleQuestions:
        title = '小組查經問題生成';
        desc = '請輸入您小組查經的經文範圍或核心主題，系統將產生 3-5 個討論問題與帶領指南。';
        customInputs = TextField(
          controller: _biblePassageController,
          decoration: const InputDecoration(
            labelText: '輸入經文範圍 (如：創世記1:1-5)',
            border: OutlineInputBorder(),
          ),
        );
        break;
      case ActiveTool.careSummary:
        title = '關懷紀錄整理';
        desc = '選擇進行中的關懷案件，系統將自動串接該個案的所有歷史探訪紀錄，並整理出關懷評估報告。';
        final cases = widget.careController.activeCases;
        customInputs = DropdownButtonFormField<String>(
          initialValue: _selectedCaseId,
          decoration: const InputDecoration(
            labelText: '選擇進行中關懷個案',
            border: OutlineInputBorder(),
          ),
          items: cases.map((c) {
            return DropdownMenuItem(
              value: c.id,
              child: Text('${c.memberName} (${c.reason})'),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedCaseId = val;
            });
          },
        );
        break;
      case ActiveTool.memberProfile:
        title = '會友資料摘要';
        desc = '選擇通訊錄中的會友，系統將彙整其 demography 屬性、小組服事參與、以及歷年關懷紀錄。';
        final people = widget.personController.allPersons;
        customInputs = DropdownButtonFormField<String>(
          initialValue: _selectedPersonId,
          decoration: const InputDecoration(
            labelText: '選擇會友',
            border: OutlineInputBorder(),
          ),
          items: people.map((p) {
            return DropdownMenuItem(
              value: p.id,
              child: Text('${p.name} (${p.phone})'),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedPersonId = val;
            });
          },
        );
        break;
      case ActiveTool.bulletinDraft:
        title = '教會週報草稿';
        desc = '填寫本週主日相關資訊，系統將自動排版為 Markdown 格式的週報宣傳文稿。';
        customInputs = Column(
          children: [
            TextField(
              controller: _sermonTitleController,
              decoration: const InputDecoration(
                labelText: '本週講道題目',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sermonScriptureController,
              decoration: const InputDecoration(
                labelText: '宣讀經文 (如：詩篇23篇)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _announcementsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '行政公告事項 (一行一條)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _prayersController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '本週代禱事項 (一行一條)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        );
        break;
      case ActiveTool.eventProposal:
        title = '活動企劃書';
        desc = '填寫活動關鍵資訊，AI 將規劃出包含宗主異象、活動日程與預算配置的活動企劃書大綱。';
        customInputs = Column(
          children: [
            TextField(
              controller: _eventNameController,
              decoration: const InputDecoration(
                labelText: '活動/聚會名稱',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _eventThemeController,
              decoration: const InputDecoration(
                labelText: '主旨與核心目標',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _eventTargetController,
                    decoration: const InputDecoration(
                      labelText: '目標對象',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _eventLocationController,
                    decoration: const InputDecoration(
                      labelText: '時間地點',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
        break;
      case ActiveTool.pptOutline:
        title = 'PPT 敬拜/查經簡報大綱';
        desc = '輸入詩歌歌詞或查經段落，AI 將產生一組結構化 JSON Outline 投影片。';
        customInputs = TextField(
          controller: _transcriptController,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: '貼上詩歌歌詞、程序或大綱內容',
            border: OutlineInputBorder(),
          ),
        );
        break;
      case ActiveTool.careEmail:
        title = 'Outlook 關懷郵件草稿';
        desc = '選擇關懷個案，並加上期望的關懷重點，AI 將為您草擬一封溫馨的關懷慰問郵件。';
        final cases = widget.careController.activeCases;
        customInputs = DropdownButtonFormField<String>(
          initialValue: _selectedCaseId,
          decoration: const InputDecoration(
            labelText: '選擇關懷個案背景',
            border: OutlineInputBorder(),
          ),
          items: cases.map((c) {
            return DropdownMenuItem(
              value: c.id,
              child: Text('${c.memberName} (${c.reason})'),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedCaseId = val;
            });
          },
        );
        break;
      default:
        break;
    }

    // Determine if generation is allowed based on input validation
    bool isGenerateAllowed = true;
    if (_activeTool == ActiveTool.sermonSummary && _transcriptController.text.trim().isEmpty) isGenerateAllowed = false;
    if (_activeTool == ActiveTool.bibleQuestions && _biblePassageController.text.trim().isEmpty) isGenerateAllowed = false;
    if (_activeTool == ActiveTool.careSummary && _selectedCaseId == null) isGenerateAllowed = false;
    if (_activeTool == ActiveTool.memberProfile && _selectedPersonId == null) isGenerateAllowed = false;
    if (_activeTool == ActiveTool.bulletinDraft && _sermonTitleController.text.trim().isEmpty) isGenerateAllowed = false;
    if (_activeTool == ActiveTool.eventProposal && _eventNameController.text.trim().isEmpty) isGenerateAllowed = false;
    if (_activeTool == ActiveTool.pptOutline && _transcriptController.text.trim().isEmpty) isGenerateAllowed = false;
    if (_activeTool == ActiveTool.careEmail && _selectedCaseId == null) isGenerateAllowed = false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() => _activeTool = ActiveTool.none);
                _clearState();
              },
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(desc, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 16),
        if (customInputs != const SizedBox.shrink()) ...[
          customInputs,
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _customInstructionsController,
          decoration: const InputDecoration(
            labelText: '同工額外指示 (如：使用溫和親切的語氣、字數限制、引導特定經文)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: (_isLoading || !isGenerateAllowed) ? null : _startGeneration,
                icon: const Icon(Icons.auto_awesome),
                label: Text(_isLoading ? '生成中...' : '開始產生文件'),
              ),
            ),
          ],
        ),
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildPaperPreview() {
    if (_generatedResult.isEmpty && !_isLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        alignment: Alignment.center,
        child: Text(
          '尚未產生報告內容。\n請調整上方參數並點選「開始產生文件」。',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, height: 1.4),
        ),
      );
    }

    return OfficePromptCard(
      title: '📄 生成結果預覽 (Paper Preview)',
      content: _generatedResult,
      isLoading: _isLoading,
      onClear: () {
        setState(() {
          _generatedResult = '';
        });
      },
      appName: 'church',
      taskName: '教會文書助理',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('教會文書助理'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_activeTool == ActiveTool.none)
              _buildGridMode()
            else ...[
              _buildToolConfigHeader(),
              _buildPaperPreview(),
            ],
          ],
        ),
      ),
    );
  }
}



