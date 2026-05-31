// lib/screens/church/church_workflow_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart';
import '../../models/office_ai_request.dart';
import '../../services/office_ai_service.dart';
import '../../widgets/office/office_prompt_card.dart';

class ChurchWorkflowScreen extends StatefulWidget {
  const ChurchWorkflowScreen({super.key});

  @override
  State<ChurchWorkflowScreen> createState() => _ChurchWorkflowScreenState();
}

class _ChurchWorkflowScreenState extends State<ChurchWorkflowScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final OfficeAiService _officeService;

  // Sandbox state
  String _selectedScenario = 'sermon';
  final TextEditingController _sandboxTextCtrl = TextEditingController();
  String _selectedTone = 'standard';
  String _selectedTarget = 'zh-TW';
  String _generatedResult = '';
  bool _isLoading = false;

  final Map<String, Map<String, String>> _scenarios = {
    'sermon': {
      'label': '講道整理 (Word)',
      'desc': '對主日講道文字進行摘要、結構化分段，並提煉核心生活實踐重點。',
      'app': 'word',
      'task': 'summarize_doc',
      'hint': '請在此貼上講道大綱、草稿或逐字稿段落...'
    },
    'bible': {
      'label': '查經教材 (Word / PPT)',
      'desc': '針對指定經文，自動產生查經討論問題、引導解答、及PPT簡報投影片結構。',
      'app': 'word',
      'task': 'meeting_notes',
      'hint': '請在此貼上小組查經經文 (如：羅馬書 12:1-8)...'
    },
    'offering': {
      'label': '奉獻報表 (Excel)',
      'desc': '分析奉獻表格CSV數據，評估趨勢、佔比分類並撰寫財務摘要。',
      'app': 'excel',
      'task': 'monthly_report',
      'hint': '日期,姓名,項目,金額\n2026/05/03,張小明,什一奉獻,5000\n2026/05/03,李阿花,主日奉獻,500'
    },
    'event': {
      'label': '活動簡報 (PowerPoint)',
      'desc': '將活動企劃案大綱，直接轉化為8張投影片的 JSON 簡報架構。',
      'app': 'ppt',
      'task': 'outline_presentation',
      'hint': '活動名稱：端午節社區關懷愛心發放\n目標：服務社區100戶弱勢家庭\n流程：破冰、詩歌、勉勵、發放物資、代禱。'
    },
    'email': {
      'label': '關懷郵件 (Outlook)',
      'desc': '根據會友的基本背景，草擬一封溫馨關懷的 Outlook 回信郵件。',
      'app': 'outlook',
      'task': 'draft_reply',
      'hint': '背景：陳長老最近因膝蓋手術住院，目前出院在家休養。請草擬一封探訪後的慰問信。'
    },
    'members': {
      'label': '會友名單 (Excel)',
      'desc': '分析會友名冊Excel表格，進行出席分組建議，並篩選出久未出席跟進提醒。',
      'app': 'excel',
      'task': 'analyze_table',
      'hint': '姓名,身分,出席頻率,小組\n林大維,會友,經常出席,迦南組\n王大明,非會友,久未出席,未加入'
    },
  };

  final Map<String, String> _tones = {
    'standard': '標準 (Standard)',
    'formal': '正式 (Formal)',
    'casual': '親切/口語 (Casual)',
    'bulletPoints': '列點整理 (Bullet Points)',
  };

  final Map<String, String> _targets = {
    'zh-TW': '繁體中文 (zh-TW)',
    'zh-CN': '簡體中文 (zh-CN)',
    'en-US': '英文 (en-US)',
  };

  // VBA macros custom coded for the 6 church scenarios
  late final Map<String, String> _churchMacros = {
    '講道整理 (Word VBA)': '''Sub LocalAI_ChurchSermonSummarize()
    Dim selectedText As String
    Dim result As String
    Dim responseText As String

    selectedText = Selection.Text
    If Len(Trim(selectedText)) = 0 Then
        MsgBox "請先選取要整理的講道文字範圍。", vbExclamation, "教會 AI 工作流"
        Exit Sub
    End If

    result = CallLocalAI("word", "summarize_doc", selectedText)
    responseText = ParseJsonResponse(result)
    If Len(responseText) = 0 Then responseText = result

    Selection.Collapse Direction:=wdCollapseEnd
    Selection.TypeParagraph
    Selection.TypeText "【AI 講道分段與摘要整理】" & vbCrLf & responseText
End Sub''',

    '查經教材 (Word / PPT VBA)': '''Sub LocalAI_ChurchBibleStudyQuestions()
    Dim selectedText As String
    Dim result As String
    Dim responseText As String

    selectedText = Selection.Text
    If Len(Trim(selectedText)) = 0 Then
        MsgBox "請先選取要設計的查經經文範圍。", vbExclamation, "教會 AI 工作流"
        Exit Sub
    End If

    result = CallLocalAI("word", "meeting_notes", selectedText)
    responseText = ParseJsonResponse(result)
    If Len(responseText) = 0 Then responseText = result

    Selection.Collapse Direction:=wdCollapseEnd
    Selection.TypeParagraph
    Selection.TypeText "【AI 小組查經教材與導讀】" & vbCrLf & responseText
End Sub''',

    '奉獻報表 (Excel VBA)': '''Sub LocalAI_ChurchOfferingReport()
    Dim rng As Range
    Set rng = Selection

    If rng Is Nothing Then
        MsgBox "請先選取奉獻數據表格範圍。", vbExclamation
        Exit Sub
    End If

    Dim csv As String
    csv = RangeToCsv(rng)

    Dim result As String
    result = CallLocalAI("excel", "monthly_report", csv)

    Dim responseText As String
    responseText = ParseJsonResponse(result)
    If Len(responseText) = 0 Then responseText = result

    Dim ws As Worksheet
    Set ws = ActiveWorkbook.Worksheets.Add
    ws.Name = "AI奉獻財務分析"

    ws.Range("A1").Value = "AI 奉獻月度趨勢分析報告"
    ws.Range("A2").Value = responseText
End Sub''',

    '活動簡報大綱 (PowerPoint VBA)': '''Sub LocalAI_ChurchEventSlides()
    Dim topicText As String
    Dim result As String
    Dim responseText As String
    
    topicText = InputBox("請輸入活動或聚會大綱：", "教會 AI 活動簡報生成")
    If Len(Trim(topicText)) = 0 Then Exit Sub
    
    result = CallLocalAI("ppt", "outline_presentation", topicText)
    responseText = ParseJsonResponse(result)
    
    MsgBox "簡報 JSON 結構已產生，可匯入 Office.js 套用。" & vbCrLf & responseText, vbInformation
End Sub''',

    '關懷郵件 (Outlook VBA)': '''Sub LocalAI_ChurchCareEmail()
    Dim mail As Outlook.MailItem

    If Application.ActiveExplorer.Selection.Count = 0 Then
        MsgBox "請先選取一封郵件或關懷背景檔案。", vbExclamation
        Exit Sub
    End If

    Set mail = Application.ActiveExplorer.Selection.Item(1)

    Dim result As String
    result = CallLocalAI("outlook", "draft_reply", mail.Body)

    Dim responseText As String
    responseText = ParseJsonResponse(result)
    If Len(responseText) = 0 Then responseText = result

    Dim reply As Outlook.MailItem
    Set reply = mail.Reply
    reply.Body = responseText & vbCrLf & vbCrLf & "----- 原始資訊 -----" & vbCrLf & mail.Body
    reply.Display
End Sub''',

    '會友名單分析 (Excel VBA)': '''Sub LocalAI_ChurchMemberListAnalysis()
    Dim rng As Range
    Set rng = Selection

    If rng Is Nothing Then
        MsgBox "請先選取會友出席名簿表格範圍。", vbExclamation
        Exit Sub
    End If

    Dim csv As String
    csv = RangeToCsv(rng)

    Dim result As String
    result = CallLocalAI("excel", "analyze_table", csv)

    Dim responseText As String
    responseText = ParseJsonResponse(result)
    If Len(responseText) = 0 Then responseText = result

    Dim ws As Worksheet
    Set ws = ActiveWorkbook.Worksheets.Add
    ws.Name = "AI會友出席分析"

    ws.Range("A1").Value = "會友出席與關懷提醒報告"
    ws.Range("A2").Value = responseText
End Sub''',

    'VBA 公用連線與 JSON 解析函式': '''Function CallLocalAI(appName As String, taskName As String, inputText As String) As String
    Dim http As Object
    Set http = CreateObject("WinHttp.WinHttpRequest.5.1")
    Dim url As String
    Dim body As String

    url = "http://127.0.0.1:61670/office/ask"
    body = "{""app"":""" & appName & """,""task"":""" & taskName & """,""text"":""" & JsonEscape(inputText) & """,""target"":""zh-TW""}"

    On Error GoTo ErrorHandler
    http.Open "POST", url, False
    http.setRequestHeader "Content-Type", "application/json"
    http.send body
    CallLocalAI = http.ResponseText
    Exit Function

ErrorHandler:
    CallLocalAI = "{""ok"":false,""result"":""連線錯誤：請確認生活APP/教會APP正在運作且 Office Bridge 已啟動。""}"
End Function

Function JsonEscape(text As String) As String
    text = Replace(text, "\\", "\\\\")
    text = Replace(text, """", "\\""")
    text = Replace(text, vbCrLf, "\\n")
    text = Replace(text, vbCr, "\\n")
    text = Replace(text, vbLf, "\\n")
    JsonEscape = text
End Function

Function RangeToCsv(rng As Range) As String
    Dim r As Long, c As Long
    Dim line As String
    Dim output As String

    For r = 1 To rng.Rows.Count
        line = ""
        For c = 1 To rng.Columns.Count
            line = line & """" & Replace(CStr(rng.Cells(r, c).Value), """", """""") & """"
            If c < rng.Columns.Count Then line = line & ","
        Next c
        output = output & line & vbCrLf
    Next r

    RangeToCsv = output
End Function

Function ParseJsonResponse(jsonStr As String) As String
    Dim resultKey As String
    Dim startIdx As Long
    Dim endIdx As Long
    
    If InStr(jsonStr, """ok"":true") = 0 And InStr(jsonStr, """ok"": true") = 0 Then
        ParseJsonResponse = ""
        Exit Function
    End If

    resultKey = """result"":"""
    startIdx = InStr(jsonStr, resultKey)
    If startIdx > 0 Then
        startIdx = startIdx + Len(resultKey)
        endIdx = InStr(startIdx, jsonStr, """")
        ParseJsonResponse = Mid(jsonStr, startIdx, endIdx - startIdx)
        ParseJsonResponse = Replace(ParseJsonResponse, "\\n", vbCrLf)
        ParseJsonResponse = Replace(ParseJsonResponse, "\\""", """")
        ParseJsonResponse = Replace(ParseJsonResponse, "\\\\", "\\")
      Else
        ParseJsonResponse = ""
    End If
End Function'''
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _officeService = OfficeAiService(generate: globalOllama.generate);
    _sandboxTextCtrl.text = _scenarios[_selectedScenario]!['hint']!;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sandboxTextCtrl.dispose();
    super.dispose();
  }

  Future<void> _runSandboxRequest() async {
    setState(() {
      _isLoading = true;
      _generatedResult = '';
    });

    final sc = _scenarios[_selectedScenario]!;
    final request = OfficeAiRequest(
      app: sc['app']!,
      task: sc['task']!,
      text: _sandboxTextCtrl.text,
      tone: _selectedTone,
      target: _selectedTarget,
    );

    try {
      final stream = _officeService.askStream(request);
      await for (final delta in stream) {
        if (!mounted) return;
        setState(() {
          _generatedResult += delta;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _generatedResult = '執行失敗，發生錯誤：\n$e';
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

  void _copyToClipboard(String content, String name) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已複製「$name」巨集程式碼到剪貼簿！')),
    );
  }

  // --- UI Tabs ---

  Widget _buildSandboxTab() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sc = _scenarios[_selectedScenario]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedScenario,
                    decoration: const InputDecoration(
                      labelText: '選擇教會 Office 工作流場景',
                      border: OutlineInputBorder(),
                    ),
                    items: _scenarios.entries.map((e) {
                      return DropdownMenuItem(value: e.key, child: Text(e.value['label']!));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedScenario = val;
                          _sandboxTextCtrl.text = _scenarios[val]!['hint']!;
                          _generatedResult = '';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    sc['desc']!,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedTone,
                  decoration: const InputDecoration(
                    labelText: '風格與語氣',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _tones.entries.map((e) {
                    return DropdownMenuItem(value: e.key, child: Text(e.value));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedTone = val);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedTarget,
                  decoration: const InputDecoration(
                    labelText: '目標語言',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _targets.entries.map((e) {
                    return DropdownMenuItem(value: e.key, child: Text(e.value));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedTarget = val);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '📝 輸入要分析或處理的文字 (模擬 VBA 選取文字)',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _sandboxTextCtrl,
            maxLines: 6,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
              filled: true,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _sandboxTextCtrl.clear();
                    _generatedResult = '';
                  });
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('清空'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _runSandboxRequest,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.flash_on, color: Colors.white),
                label: const Text(
                  '執行 AI 工作流',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          OfficePromptCard(
            title: '✨ AI 工作流輸出結果',
            content: _generatedResult,
            isLoading: _isLoading,
            onClear: () {
              setState(() {
                _generatedResult = '';
              });
            },
            appName: sc['app'],
            taskName: sc['label'],
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _churchMacros.length,
      itemBuilder: (context, i) {
        final key = _churchMacros.keys.elementAt(i);
        final code = _churchMacros[key]!;
        return Card(
          margin: const EdgeInsets.only(bottom: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        key,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _copyToClipboard(code, key),
                      icon: const Icon(Icons.copy, size: 14),
                      label: const Text('複製巨集'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: SingleChildScrollView(
                    child: Text(
                      code,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.greenAccent,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('教會 Office 工作流'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '工作流沙盒測試'),
            Tab(text: '教會 VBA 巨集工具箱'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSandboxTab(),
          _buildMacrosTab(),
        ],
      ),
    );
  }
}



