Attribute VB_Name = "WordLocalAI"
Option Explicit

' ==============================================================================
' Microsoft Word / WPS Writer - Local AI Assistant Integration Module
' ==============================================================================

Sub LocalAI_WordSummarize()
    Dim selectedText As String
    Dim result As String
    Dim responseText As String

    selectedText = Selection.Text
    If Len(Trim(selectedText)) = 0 Then
        MsgBox "請先選取要摘要的文字。", vbExclamation, "Word AI 助理"
        Exit Sub
    End If

    result = CallLocalAI("word", "summarize_doc", selectedText)
    responseText = ParseJsonResponse(result)
    If Len(responseText) = 0 Then responseText = result

    Selection.Collapse Direction:=wdCollapseEnd
    Selection.TypeParagraph
    Selection.TypeText "【AI 摘要結果】" & vbCrLf & responseText
End Sub

Sub LocalAI_WordRewrite()
    Dim selectedText As String
    Dim result As String
    Dim responseText As String

    selectedText = Selection.Text
    If Len(Trim(selectedText)) = 0 Then
        MsgBox "請先選取要改寫語氣的文字。", vbExclamation, "Word AI 助理"
        Exit Sub
    End If

    result = CallLocalAI("word", "rewrite_tone", selectedText)
    responseText = ParseJsonResponse(result)
    If Len(responseText) = 0 Then responseText = result

    ' 直接用改寫後的文字替換原有選取範圍
    Selection.Text = responseText
End Sub

Sub LocalAI_WordMeetingNotes()
    Dim selectedText As String
    Dim result As String
    Dim responseText As String

    selectedText = Selection.Text
    If Len(Trim(selectedText)) = 0 Then
        MsgBox "請先選取會議逐字稿內容。", vbExclamation, "Word AI 助理"
        Exit Sub
    End If

    result = CallLocalAI("word", "meeting_notes", selectedText)
    responseText = ParseJsonResponse(result)
    If Len(responseText) = 0 Then responseText = result

    Selection.Collapse Direction:=wdCollapseEnd
    Selection.TypeParagraph
    Selection.TypeText "【AI 整理會議紀錄】" & vbCrLf & responseText
End Sub

' ==============================================================================
' 公用連線與 JSON 解析輔助函式
' ==============================================================================

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
