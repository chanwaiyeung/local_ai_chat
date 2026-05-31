import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'office_ai_screen.dart';

class OfficeToolboxScreen extends StatefulWidget {
  const OfficeToolboxScreen({super.key});

  @override
  State<OfficeToolboxScreen> createState() => _OfficeToolboxScreenState();
}

class _OfficeToolboxScreenState extends State<OfficeToolboxScreen> {
  bool _isServerRunning = false;
  bool _checkingHealth = false;

  final Map<String, String> _macros = {
    'Word / WPS Writer (文筆潤飾)': '''Sub PolishSelectedText()
    Dim selectedText As String
    Dim responseText As String
    Dim url As String
    Dim jsonPayload As String
    Dim http As Object
    
    selectedText = Selection.Text
    If Len(Trim(selectedText)) = 0 Then
        MsgBox "Please select some text first!", vbExclamation, "Local AI Bridge"
        Exit Sub
    End If
    
    selectedText = Replace(selectedText, "\\", "\\\\")
    selectedText = Replace(selectedText, """", "\\""")
    selectedText = Replace(selectedText, vbCrLf, "\\n")
    selectedText = Replace(selectedText, vbCr, "\\n")
    selectedText = Replace(selectedText, vbLf, "\\n")
    
    url = "http://127.0.0.1:61670/office/ask"
    jsonPayload = "{""app"":""word"",""task"":""polish"",""text"":""" & selectedText & """,""tone"":""formal"",""target"":""zh-TW""}"
    
    On Error GoTo ErrorHandler
    Set http = CreateObject("MSXML2.ServerXMLHTTP.6.0")
    http.Open "POST", url, False
    http.setRequestHeader "Content-Type", "application/json; charset=utf-8"
    http.send jsonPayload
    
    If http.Status = 200 Then
        responseText = ParseJsonResponse(http.responseText)
        If Len(responseText) > 0 Then
            Selection.Text = responseText
        Else
            MsgBox "Received empty response or request failed.", vbExclamation
        End If
    Else
        MsgBox "HTTP Error " & http.Status & ": " & http.responseText, vbCritical
    End If
    Exit Sub

ErrorHandler:
    MsgBox "Failed to connect to Local AI Server. Ensure the Flutter App is running.", vbCritical
End Sub''',

    'Word / WPS Writer (文章摘要)': '''Sub LocalAI_SummarizeSelection()
    Dim selectedText As String
    Dim result As String
    Dim responseText As String

    selectedText = Selection.Text
    If Len(Trim(selectedText)) = 0 Then
        MsgBox "請先選取要摘要的文字。", vbExclamation, "Local AI Bridge"
        Exit Sub
    End If

    result = CallLocalAI("word", "summarize", selectedText)
    
    ' Parse result from JSON
    responseText = ParseJsonResponse(result)
    If Len(responseText) = 0 Then
        responseText = result ' Fallback to raw response if parsing fails
    End If

    Selection.Collapse Direction:=wdCollapseEnd
    Selection.TypeParagraph
    Selection.TypeText "【AI 摘要】" & vbCrLf & responseText
End Sub

Function CallLocalAI(appName As String, taskName As String, inputText As String) As String
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
    CallLocalAI = "{""ok"":false,""result"":""連線錯誤：請確認 Flutter 應用程式已開啟。""}"
End Function

Function JsonEscape(text As String) As String
    text = Replace(text, "\\", "\\\\")
    text = Replace(text, """", "\\""")
    text = Replace(text, vbCrLf, "\\n")
    text = Replace(text, vbCr, "\\n")
    text = Replace(text, vbLf, "\\n")
    JsonEscape = text
End Function''',

    'Excel / WPS Spreadsheets (公式生成)': '''Sub GenerateExcelFormula()
    Dim promptText As String
    Dim responseText As String
    Dim url As String
    Dim jsonPayload As String
    Dim http As Object
    
    promptText = ActiveCell.Value
    If Len(Trim(promptText)) = 0 Then
        MsgBox "Please type a natural language formula description in the active cell first!", vbExclamation
        Exit Sub
    End If
    
    promptText = Replace(promptText, "\\", "\\\\")
    promptText = Replace(promptText, """", "\\""")
    
    url = "http://127.0.0.1:61670/office/ask"
    jsonPayload = "{""app"":""excel"",""task"":""formula"",""text"":""" & promptText & """,""tone"":""formula"",""target"":""zh-TW""}"
    
    On Error GoTo ErrorHandler
    Set http = CreateObject("MSXML2.ServerXMLHTTP.6.0")
    http.Open "POST", url, False
    http.setRequestHeader "Content-Type", "application/json; charset=utf-8"
    http.send jsonPayload
    
    If http.Status = 200 Then
        responseText = ParseJsonResponse(http.responseText)
        If Len(responseText) > 0 Then
            ActiveCell.Offset(0, 1).Value = responseText
        Else
            MsgBox "Failed to parse AI response.", vbExclamation
        End If
    Else
        MsgBox "Error " & http.Status & ": " & http.responseText, vbCritical
    End If
    Exit Sub

ErrorHandler:
    MsgBox "Connection error.", vbCritical
End Sub''',

    'Excel / WPS Spreadsheets (表格分析)': '''Sub LocalAI_AnalyzeSelectedTable()
    Dim rng As Range
    Set rng = Selection

    If rng Is Nothing Then
        MsgBox "請先選取要分析的表格範圍。"
        Exit Sub
    End If

    Dim csv As String
    csv = RangeToCsv(rng)

    Dim result As String
    result = CallLocalAI("excel", "analyze_table", csv)

    Dim responseText As String
    responseText = ParseJsonResponse(result)
    If Len(responseText) = 0 Then
        responseText = result
    End If

    Dim ws As Worksheet
    Set ws = ActiveWorkbook.Worksheets.Add
    ws.Name = "AI分析"

    ws.Range("A1").Value = "AI 分析結果"
    ws.Range("A2").Value = responseText
End Sub

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

Function CallLocalAI(appName As String, taskName As String, inputText As String) As String
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
    CallLocalAI = "{""ok"":false,""result"":""連線錯誤：請確認 Flutter 應用程式已開啟。""}"
End Function

Function JsonEscape(text As String) As String
    text = Replace(text, "\\", "\\\\")
    text = Replace(text, """", "\\""")
    text = Replace(text, vbCrLf, "\\n")
    text = Replace(text, vbCr, "\\n")
    text = Replace(text, vbLf, "\\n")
    JsonEscape = text
End Function''',

    'PowerPoint / WPS Presentation (大綱規劃)': '''Sub GenerateSlideOutline()
    Dim topicText As String
    Dim responseText As String
    Dim url As String
    Dim jsonPayload As String
    Dim http As Object
    
    topicText = InputBox("Enter slide deck topic:", "PowerPoint AI Outliner")
    If Len(Trim(topicText)) = 0 Then Exit Sub
    
    topicText = Replace(topicText, "\\", "\\\\")
    topicText = Replace(topicText, """", "\\""")
    
    url = "http://127.0.0.1:61670/office/ask"
    jsonPayload = "{""app"":""ppt"",""task"":""outline"",""text"":""" & topicText & """,""tone"":""bulletPoints"",""target"":""zh-TW""}"
    
    On Error GoTo ErrorHandler
    Set http = CreateObject("MSXML2.ServerXMLHTTP.6.0")
    http.Open "POST", url, False
    http.setRequestHeader "Content-Type", "application/json; charset=utf-8"
    http.send jsonPayload
    
    If http.Status = 200 Then
        responseText = ParseJsonResponse(http.responseText)
        MsgBox responseText, vbInformation, "AI Outliner Result"
    Else
        MsgBox "Error: " & http.Status, vbCritical
    End If
    Exit Sub

ErrorHandler:
    MsgBox "Connection error.", vbCritical
End Sub''',

    'PowerPoint Office.js (大綱轉投影片)': '''// JavaScript Add-in Code for PowerPoint (Office.js)
// Requirements: Build via Office Yeoman Generator (yo office) or link in a custom Web Add-in taskpane.

async function createSlidesFromOutline() {
  const outlineInput = document.getElementById("outline-input");
  const outlineText = outlineInput ? outlineInput.value : "";

  if (!outlineText || outlineText.trim() === "") {
    showNotification("Warning", "Please enter or paste an outline first!");
    return;
  }

  try {
    showLoading(true);

    const response = await fetch("http://127.0.0.1:61670/office/ask", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        app: "ppt",
        task: "outline",
        text: outlineText,
        tone: "professional",
        target: "zh-TW"
      })
    });

    if (response.ok) {
      const data = await response.json();
      if (data.ok && data.result) {
        let jsonText = data.result.trim();
        // Clean up markdown block wrapper if present
        if (jsonText.startsWith("```")) {
          jsonText = jsonText.replace(/^```(json)?\\n/, "").replace(/\\n```\$/, "");
        }

        const slidesData = JSON.parse(jsonText);
        if (Array.isArray(slidesData)) {
          await PowerPoint.run(async (context) => {
            for (let i = 0; i < slidesData.length; i++) {
              const slideData = slidesData[i];
              const title = slideData.title || ("Slide " + (i + 1));
              const bullets = slideData.bullets || [];
              const speakerNotes = slideData.speaker_notes || "";
              const suggestedVisual = slideData.suggested_visual || "";

              // Add a slide
              const slide = context.presentation.slides.add();

              // Add Title Text Box (typical position: left: 50, top: 50, width: 620, height: 80)
              const titleBox = slide.shapes.addTextBox(title, {
                left: 50,
                top: 50,
                width: 620,
                height: 80
              });
              titleBox.textFrame.textRange.font.bold = true;
              titleBox.textFrame.textRange.font.size = 36;
              titleBox.textFrame.textRange.font.color = "#333333";

              // Add Bullets Text Box (typical position: left: 50, top: 150, width: 620, height: 300)
              const bulletText = bullets.map(b => "• " + b).join("\\n");
              const bulletsBox = slide.shapes.addTextBox(bulletText, {
                left: 50,
                top: 150,
                width: 620,
                height: 300
              });
              bulletsBox.textFrame.textRange.font.size = 18;
              bulletsBox.textFrame.textRange.font.color = "#555555";

              // Since speaker notes API is not supported by Office.js PowerPoint API,
              // we display them along with the suggested visual at the bottom in an italic style
              let footerText = "";
              if (suggestedVisual) {
                footerText += "[Suggested Visual: " + suggestedVisual + "] ";
              }
              if (speakerNotes) {
                footerText += "\\n[Notes: " + speakerNotes + "]";
              }
              
              if (footerText.trim()) {
                const footerBox = slide.shapes.addTextBox(footerText.trim(), {
                  left: 50,
                  top: 460,
                  width: 620,
                  height: 60
                });
                footerBox.textFrame.textRange.font.italic = true;
                footerBox.textFrame.textRange.font.size = 12;
                footerBox.textFrame.textRange.font.color = "#777777";
              }
            }
            await context.sync();
          });
          showNotification("Success", "Created " + slidesData.length + " slides successfully!");
        } else {
          showNotification("Error", "Invalid JSON structure received from AI.");
        }
      } else {
        showNotification("Error", "No slides data returned from AI.");
      }
    } else {
      showNotification("HTTP Error", "Server returned status: " + response.status);
    }
  } catch (error) {
    showNotification("Error", "Failed to generate slides. Error: " + error.message);
    console.error("PPT generation error:", error);
  } finally {
    showLoading(false);
  }
}''',

    'Outlook Mail (信件三點摘要)': '''Sub SummarizeSelectedEmail()
    Dim objMail As Object
    Dim responseText As String
    Dim url As String
    Dim jsonPayload As String
    Dim http As Object
    Dim mailBody As String
    
    On Error Resume Next
    Set objMail = Application.ActiveExplorer.Selection.Item(1)
    On Error GoTo 0
    
    If objMail Is Nothing Then
        MsgBox "Please select an email first!", vbExclamation
        Exit Sub
    End If
    
    mailBody = objMail.Body
    If Len(mailBody) > 1000 Then mailBody = Left(mailBody, 1000)
    
    mailBody = Replace(mailBody, "\\", "\\\\")
    mailBody = Replace(mailBody, """", "\\""")
    mailBody = Replace(mailBody, vbCrLf, "\\n")
    mailBody = Replace(mailBody, vbLf, "\\n")
    
    url = "http://127.0.0.1:61670/office/ask"
    jsonPayload = "{""app"":""outlook"",""task"":""summarize"",""text"":""" & mailBody & """,""tone"":""bulletPoints"",""target"":""zh-TW""}"
    
    On Error GoTo ErrorHandler
    Set http = CreateObject("MSXML2.ServerXMLHTTP.6.0")
    http.Open "POST", url, False
    http.setRequestHeader "Content-Type", "application/json; charset=utf-8"
    http.send jsonPayload
    
    If http.Status = 200 Then
        responseText = ParseJsonResponse(http.responseText)
        MsgBox responseText, vbInformation, "AI Email Summary"
    Else
        MsgBox "Error " & http.Status, vbCritical
    End If
    Exit Sub

ErrorHandler:
    MsgBox "Connection error.", vbCritical
End Sub''',

    'Outlook Mail (草擬回信)': '''Sub LocalAI_DraftReply()
    Dim mail As Outlook.MailItem

    If Application.ActiveExplorer.Selection.Count = 0 Then
        MsgBox "請先選取一封郵件。", vbExclamation, "Local AI Bridge"
        Exit Sub
    End If

    Set mail = Application.ActiveExplorer.Selection.Item(1)

    Dim result As String
    result = CallLocalAI("outlook", "draft_reply", mail.Body)

    Dim responseText As String
    responseText = ParseJsonResponse(result)
    If Len(responseText) = 0 Then
        responseText = result
    End If

    Dim reply As Outlook.MailItem
    Set reply = mail.Reply
    reply.Body = responseText & vbCrLf & vbCrLf & "----- 原始郵件 -----" & vbCrLf & mail.Body
    reply.Display
End Sub

Function CallLocalAI(appName As String, taskName As String, inputText As String) As String
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
    CallLocalAI = "{""ok"":false,""result"":""連線錯誤：請確認 Flutter 應用程式已開啟。""}"
End Function

Function JsonEscape(text As String) As String
    text = Replace(text, "\\", "\\\\")
    text = Replace(text, """", "\\""")
    text = Replace(text, vbCrLf, "\\n")
    text = Replace(text, vbCr, "\\n")
    text = Replace(text, vbLf, "\\n")
    JsonEscape = text
End Function''',

    'VBA 公用 JSON 解析輔助函式': '''Function ParseJsonResponse(jsonStr As String) As String
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
    _checkServer();
  }

  Future<void> _checkServer() async {
    if (mounted) {
      setState(() {
        _checkingHealth = true;
      });
    }

    bool isRunning = false;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 1);
      final request = await client.getUrl(Uri.parse('http://127.0.0.1:61670/health'));
      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> json = jsonDecode(body) as Map<String, dynamic>;
        isRunning = json['status'] == 'ok';
      }
    } catch (_) {
      isRunning = false;
    }

    if (mounted) {
      setState(() {
        _isServerRunning = isRunning;
        _checkingHealth = false;
      });
    }
  }

  void _copyToClipboard(String content, String name) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已複製「$name」程式碼到剪貼簿！')),
    );
  }

  Widget _buildStatusHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: _isServerRunning
                ? [Colors.teal.shade700, Colors.green.shade500]
                : [Colors.blueGrey.shade800, Colors.grey.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.hub_outlined, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Local Office Bridge API',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_checkingHealth)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _checkServer,
                  )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isServerRunning ? Colors.green.shade900.withValues(alpha: 0.6) : Colors.red.shade900.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _isServerRunning ? Colors.green.shade300 : Colors.red.shade300, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isServerRunning ? Icons.check_circle : Icons.error_outline,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isServerRunning ? '伺服器運作中' : '伺服器未啟動',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '連接埠: 61670',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssistantsTab() {
    final List<Map<String, dynamic>> assistants = [
      {
        'title': 'Word / Writer 助理',
        'desc': '支援文采增強、冗詞刪除、信件改寫及拼字糾錯。選取欲調整的文字，一鍵快速替換。',
        'icon': Icons.description,
        'color': Colors.blue.shade700,
        'prompt': 'Polish the style/grammar',
        'app': 'word',
        'task': 'polish',
      },
      {
        'title': 'Excel / Sheets 助理',
        'desc': '將自然語言需求（例如「加總A欄大於100的值」）自動翻譯成標準 Excel / WPS 函數公式。',
        'icon': Icons.table_chart,
        'color': Colors.green.shade700,
        'prompt': 'Generate spreadsheet formulas',
        'app': 'excel',
        'task': 'formula',
      },
      {
        'title': 'PowerPoint / Slides 助理',
        'desc': '依據簡報主題，自動生成包含三張投影片的精簡結構大綱，省去排版規劃時間。',
        'icon': Icons.slideshow,
        'color': Colors.orange.shade700,
        'prompt': 'Create presentation outlines',
        'app': 'ppt',
        'task': 'outline',
      },
      {
        'title': 'Outlook / Mail 助理',
        'desc': '快速提煉長篇郵件正文，精煉為三點重要摘要，或基於簡短提示草擬正式回信。',
        'icon': Icons.mail,
        'color': Colors.cyan.shade700,
        'prompt': 'Email bullet points summary',
        'app': 'outlook',
        'task': 'summarize',
      },
      {
        'title': '教會文書助理',
        'desc': '輔助教會同工整理講道筆記摘要、活動企劃草案編修，以及代禱信公文用字格式潤飾。',
        'icon': Icons.church,
        'color': Colors.deepPurple.shade600,
        'prompt': 'Refine sermon notes and prayers',
        'app': 'church',
        'task': 'refine',
      },
      {
        'title': '生活文件助理',
        'desc': '優化個人履歷格式與專長敘述、校對租屋或買賣合約，以及對一般生活書信進行修飾。',
        'icon': Icons.assignment,
        'color': Colors.teal.shade700,
        'prompt': 'Resume polish & contract proof',
        'app': 'life',
        'task': 'polish',
      }
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: assistants.length,
      itemBuilder: (context, i) {
        final item = assistants[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OfficeAiScreen(
                    initialApp: item['app'] as String?,
                    initialTask: item['task'] as String?,
                  ),
                ),
              );
            },
            leading: CircleAvatar(
              backgroundColor: (item['color'] as Color).withValues(alpha: 0.1),
              child: Icon(item['icon'] as IconData?, color: item['color'] as Color?),
            ),
            title: Text(
              item['title'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(item['desc'] as String, style: const TextStyle(fontSize: 13, height: 1.4)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '預設指令: ${item['prompt']}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMacrosTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: _macros.length,
      itemBuilder: (context, i) {
        final key = _macros.keys.elementAt(i);
        final code = _macros[key]!;
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
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _copyToClipboard(code, key),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('複製程式碼'),
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

  Widget _buildGuideTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🚀 快速整合指南 (Setup Guide)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 24),
              _buildStepItem('步驟 1', '在 Flutter APP 中確保啟動 Local AI Server。可在「設定與狀態」分頁驗證是否正常運作。'),
              _buildStepItem('步驟 2', '開啟您的 Word、Excel、PPT 或 Outlook 應用程式（WPS 亦支援）。'),
              _buildStepItem('步驟 3', '按下組合鍵 Alt + F11 進入 VBA 編輯器，或是在選單中點選「開發工具」->「Visual Basic」。'),
              _buildStepItem('步驟 4', '在上方選單選擇「插入 (Insert)」->「模組 (Module)」，建立一個新模組。'),
              _buildStepItem('步驟 5', '切換至本工具箱的「VBA 部署」分頁，複製對應的助理巨集程式碼，並務必一同複製最下方的「ParseJsonResponse」輔助解析函式，貼入模組視窗中。'),
              _buildStepItem('步驟 6', '回到 Office 視窗中選取一段文字，按下 Alt + F8 執行該巨集，即可看到本機 AI 直接套用並將調整後的結果寫回您的文件中！'),
              const SizedBox(height: 16),
              const AlertBox(
                icon: Icons.info_outline,
                title: '提示',
                content: '若需要在區網內讓其他裝置（如手機版 WPS）存取，請至 App 系統設定開啟「區網分享 (LAN Mode)」功能，並以實際 IP (預設通訊埠 61670) 呼叫。',
              ),
              const SizedBox(height: 24),
              const Divider(height: 24),
              const Text(
                '🇨🇳 WPS Office 整合策略 (WPS Integration)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 24),
              _buildStepItem('步驟 1', '安裝並開啟 WPS Office（WPS Writer, Spreadsheets 或 Presentation）。'),
              _buildStepItem('步驟 2', '確認是否有「開發工具」選項及巨集功能。若選單中「巨集」按鈕為灰色無法點選，請先安裝「WPS VBA 增強元件 (WPS VBA Support Library)」來啟用。'),
              _buildStepItem('步驟 3', '點擊「開發工具」選單下的「Visual Basic」或按下組合鍵 Alt + F11 進入代碼編輯器。'),
              _buildStepItem('步驟 4', '在選單選擇「插入」->「模組」，貼上對應的 VBA 巨集，並同樣附上「ParseJsonResponse」等公用輔助函數。'),
              _buildStepItem('步驟 5', '回到 WPS 視窗，選取文件內容後，至「開發工具」點選「巨集 (Alt + F8)」執行剛剛貼入的指令碼，即可完成 Local AI API 連接！'),
              const SizedBox(height: 16),
              const AlertBox(
                icon: Icons.offline_bolt_outlined,
                title: '相容性提示',
                content: 'WPS Office 對於標準 VBA 自動化物件具有極高的相容性。建議先從 Writer（文字處理）與 Spreadsheets（公式生成與分析）的基本巨集起步，整合效果最為穩定。',
              ),
              const SizedBox(height: 24),
              const Divider(height: 24),
              const Text(
                '🏢 企業 / 家庭部署 6 步驟 (Deployment Steps)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 24),
              _buildStepItem('Step 1', '固定 Local AI Server 入口：建議使用固定連接埠（預設 http://127.0.0.1:61670），避免每次啟動動態產生 port，方便 VBA / Office.js 穩定連線。'),
              _buildStepItem('Step 2', '加入安全 Token 驗證：Office 巨集可於 Header 加上 Bearer Token 驗證，保護您的本機 AI 端點不被未授權的裝置呼叫。在 VBA 中加入：\n  http.setRequestHeader "Authorization", "Bearer YOUR_LOCAL_TOKEN"'),
              _buildStepItem('Step 3', '生活APP 設定頁整合：在系統設定中提供「Office Bridge」專屬設定區塊，支援切換啟用狀態、連接埠、API 安全權限 Token、預設語言、預設模型與各套軟體 (Word/Excel/PPT/Outlook/WPS) 獨立開關。'),
              _buildStepItem('Step 4', 'Prompt 模板集中管理：建議將複雜的 prompt 模板保留在生活APP 本機服務中進行統一調整，VBA 僅傳送輕量 JSON 請求（如 {"app": "word", "task": "summarize", "text": "..."}），避免日後維護需要在多台電腦修改巨集。'),
              _buildStepItem('Step 5', '歷史記錄監控：支援統計呼叫時間、來源應用程式、任務類型、輸入與輸出字數、使用模型及執行狀態。不預設儲存文件全文，保障家庭與企業內部隱私。'),
              _buildStepItem('Step 6', '資安隱私模式：\n  • Local Only：僅使用 Ollama 本機模型，敏感資料不外流。\n  • Ask Before Cloud：本機模型不敷使用時，彈出詢問是否發送至雲端。\n  • Cloud Allowed：啟用高效雲端模型 (如 Gemini)，並完整記錄存取歷程。'),
              const SizedBox(height: 24),
              const Divider(height: 24),
              const Text(
                '💡 常用 Prompt 速查表 (AI Prompts Reference)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 24),
              _buildPromptSection('📝 Microsoft Word / WPS Writer 常用指令', [
                '請將以下文章改寫成正式公文語氣，保留原意，刪除重複內容。',
                '請摘要以下文件，輸出：\n1. 核心重點\n2. 風險\n3. 待辦事項\n4. 可引用句子',
                '請比較以下兩段文字，指出差異、衝突與建議修正版。',
                '請把以下逐字稿整理成會議紀錄，包含決議、負責人、期限。',
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromptSection(String title, List<String> prompts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueAccent),
          ),
        ),
        ...prompts.map((prompt) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: Colors.grey.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(
                prompt,
                style: const TextStyle(fontSize: 13.5, height: 1.4),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: prompt));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已複製 Prompt 至剪貼簿！')),
                  );
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStepItem(String step, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blueAccent.shade100.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              step,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Office AI 工具箱'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.assistant_direction), text: '助理工具'),
              Tab(icon: Icon(Icons.code), text: '巨集與指令碼'),
              Tab(icon: Icon(Icons.help_outline), text: '整合指南'),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatusHeader(),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildAssistantsTab(),
                    _buildMacrosTab(),
                    _buildGuideTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AlertBox extends StatelessWidget {
  const AlertBox({
    super.key,
    required this.icon,
    required this.title,
    required this.content,
  });

  final IconData icon;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(color: Colors.blue.shade800, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


