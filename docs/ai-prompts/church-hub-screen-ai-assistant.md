# Task: Church - Add AI Assistant to ChurchHubScreen v2.0

## Scope
在 ChurchHubScreen 右下角新增「AI 助手」FloatingActionButton，點擊後提供快速 AI 功能，幫助牧者、長執、部門同工大幅減輕工作量。

## Files allowed to modify (WRITE list)
- lib/screens/church/church_hub_screen.dart          ← 新增 AI 按鈕與呼叫
- lib/screens/church/church_ai_assistant.dart        ← 新增此檔案（AI 助手畫面）

## Files read-only (READ list)
- lib/controllers/church/care_controller.dart
- lib/controllers/church/person_controller.dart
- lib/screens/church/care_dashboard_screen.dart
- lib/screens/church/person_directory_screen.dart

## Files forbidden (NEVER TOUCH list)
- lib/main.dart
- lib/services/**
- lib/l10n/**
- lib/models/person.dart
- Any file outside lib/screens/church/ and lib/widgets/church/

## Acceptance criteria
1. ChurchHubScreen 右下角有 FloatingActionButton.extended「AI 助手」
2. 點擊後開啟 ChurchAiAssistant（BottomSheet 或新頁面）
3. 提供至少 4 個快速 AI 功能：
   - 生成探訪摘要
   - 整理代禱事項
   - 產生講道 PPT 大綱
   - 會友近況查詢
4. flutter analyze → No issues found!
5. git diff --stat 只顯示最多 2 個檔案
6. App 運行無 crash

## Required deliverables
1. lib/screens/church/church_ai_assistant.dart 完整程式碼
2. church_hub_screen.dart 中 AI 按鈕的修改片段
3. git diff --stat 輸出
4. flutter analyze 輸出
5. 操作流程文字說明

## Do NOT
- Do not modify any Controller / Model
- Do not touch l10n keys
- Do not create files outside church/ directory
- Do not "順便" 重構其他畫面
- Do not run dart fix --apply
