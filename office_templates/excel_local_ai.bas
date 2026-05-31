Attribute VB_Name = "ExcelLocalAI"
Option Explicit

' ==============================================================================
' Microsoft Excel / WPS Spreadsheets - Local AI Assistant Integration Module
' ==============================================================================

Sub LocalAI_ExcelFormula()
    Dim promptText As String
    Dim result As String
    Dim responseText As String
    
    promptText = ActiveCell.Value
    If Len(Trim(promptText)) = 0 Then
        MsgBox "請先在作用中單元格輸入自然語言公式描述 (如：加總A欄大於100的值)。", vbExclamation, "Excel AI 助理"
        Exit Sub
    End If
    
    result = CallLocalAI("excel", "formula", promptText)
    responseText = ParseJsonResponse(result)
    If Len(responseText) = 0 Then responseText = result
    
    ' 將 AI 產生的公式填入右側相鄰儲存格
    ActiveCell.Offset(0, 1).Value = responseText
End Sub

Sub LocalAI_AnalyzeSelectedTable()
    Dim rng As Range
    Dim csvData As String
    Dim result As String
    Dim responseText As String
    Dim ws As Worksheet

    Set rng = Selection
    If rng Is Nothing Then
        MsgBox "請先選取要分析的表格範圍。", vbExclamation, "Excel AI 助理"
        Exit Sub
    End If

    csvData = RangeToCsv(rng)
    result = CallLocalAI("excel", "analyze_table", csvData)
    responseText = ParseJsonResponse(result)
    If Len(responseText) = 0 Then responseText = result

    ' 自動新增工作表儲存分析報告
    Set ws = ActiveWorkbook.Worksheets.Add
    ws.Name = "AI分析結果_" & Format(Now, "hhmmss")
    
    ws.Range("A1").Value = "【AI 數據分析與趨勢評估報告】"
    ws.Range("A2").Value = responseText
    ws.Columns("A").AutoFit
End Sub

Sub LocalAI_ExcelMonthlyReport()
    Dim rng As Range
    Dim csvData As String
    Dim result As String
    Dim responseText As String
    Dim ws As Worksheet

    Set rng = Selection
    If rng Is Nothing Then
        MsgBox "請先選取月度報表數據範圍。", vbExclamation, "Excel AI 助理"
        Exit Sub
    End If

    csvData = RangeToCsv(rng)
    result = CallLocalAI("excel", "monthly_report", csvData)
    responseText = ParseJsonResponse(result)
    If Len(responseText) = 0 Then responseText = result

    ' 自動新增工作表儲存月報摘要
    Set ws = ActiveWorkbook.Worksheets.Add
    ws.Name = "AI月報摘要_" & Format(Now, "hhmmss")
    
    ws.Range("A1").Value = "【AI 財務/銷售月報摘要】"
    ws.Range("A2").Value = responseText
    ws.Columns("A").AutoFit
End Sub

' ==============================================================================
' 公用連線與 JSON 解析輔助函式
' ==============================================================================

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
    http.setRequestHeader "Content-Type", "application/json; charset=utf-8"
    http.setRequestHeader "Authorization", "Bearer YOUR_LOCAL_TOKEN"
    http.send body
    CallLocalAI = http.ResponseText
    Exit Function

ErrorHandler:
    CallLocalAI = "{""ok"":false,""result"":""連線錯誤：請確認生活APP/教會APP正在運作，且 Office Bridge 已啟動。""}"
End Function

Function JsonEscape(text As String) As String
    text = Replace(text, "\", "\\")
    text = Replace(text, """", "\""")
    text = Replace(text, vbCrLf, "\n")
    text = Replace(text, vbCr, "\n")
    text = Replace(text, vbLf, "\n")
    JsonEscape = text
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
        ParseJsonResponse = Replace(ParseJsonResponse, "\n", vbCrLf)
        ParseJsonResponse = Replace(ParseJsonResponse, "\""", """")
        ParseJsonResponse = Replace(ParseJsonResponse, "\\", "\")
    Else
        ParseJsonResponse = ""
    End If
End Function
