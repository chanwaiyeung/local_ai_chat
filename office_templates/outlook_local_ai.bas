Attribute VB_Name = "OutlookLocalAI"
Option Explicit

' ==============================================================================
' Microsoft Outlook - Local AI Assistant Integration Module
' ==============================================================================

Sub LocalAI_OutlookDraftReply()
    Dim mail As Outlook.MailItem
    Dim reply As Outlook.MailItem
    Dim result As String
    Dim responseText As String

    If Application.ActiveExplorer.Selection.Count = 0 Then
        MsgBox "請先選取一封郵件。", vbExclamation, "Outlook AI 助理"
        Exit Sub
    End If

    Set mail = Application.ActiveExplorer.Selection.Item(1)
    
    result = CallLocalAI("outlook", "draft_reply", mail.Body)
    responseText = ParseJsonResponse(result)
    If Len(responseText) = 0 Then responseText = result

    ' 建立回信草稿
    Set reply = mail.Reply
    reply.Body = responseText & vbCrLf & vbCrLf & "----- 原始郵件 -----" & vbCrLf & mail.Body
    reply.Display
End Sub

Sub LocalAI_OutlookSummarizeEmail()
    Dim mail As Outlook.MailItem
    Dim result As String
    Dim responseText As String

    If Application.ActiveExplorer.Selection.Count = 0 Then
        MsgBox "請先選取一封郵件。", vbExclamation, "Outlook AI 助理"
        Exit Sub
    End If

    Set mail = Application.ActiveExplorer.Selection.Item(1)
    
    result = CallLocalAI("outlook", "summarize_email", mail.Body)
    responseText = ParseJsonResponse(result)
    If Len(responseText) = 0 Then responseText = result

    ' 以彈出視窗呈現信件摘要
    MsgBox responseText, vbInformation, "AI 郵件摘要結果"
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
