# Task: Church - Remove todo placeholders in Care Dashboard

## Scope
清理 care_dashboard_screen.dart 中的 `_todoVisit` 和 `_todoDetail` 佔位符，讓教會關懷儀表板的功能按鈕可正常運作。

## Files allowed to modify (WRITE list)
- lib/screens/church/care_dashboard_screen.dart

## Files read-only (READ list)
- lib/controllers/church/care_controller.dart
- lib/models/church/care_case.dart
- lib/screens/church/person_directory_screen.dart

## Files forbidden (NEVER TOUCH list)
- lib/main.dart
- lib/screens/personal_hub_screen.dart
- lib/services/**
- lib/l10n/**
- lib/models/person.dart
- Any file outside lib/screens/church/ and lib/widgets/church/

## Acceptance criteria
1. 完全移除 `_todoVisit()` 和 `_todoDetail()` 方法及其所有呼叫點
2. 「探訪記錄」與「個案詳情」按鈕接上正確導航（使用 Navigator.push 或 GoRouter 跳轉到對應畫面）
3. flutter analyze → No issues found!
4. git diff --stat 只顯示 **1 個檔案**
5. 畫面運行無 crash，按鈕可正常點擊

## Required deliverables
1. 修改後的相關方法（如 `_buildActionButtons()` 或 onPressed 區塊）的完整程式碼
2. git diff --stat 輸出
3. flutter analyze 輸出
4. 文字說明：點擊兩個按鈕後會跳轉到哪個畫面

## Do NOT
- Do not modify any Controller / Model
- Do not touch l10n or localization keys
- Do not create new files
- Do not touch any Personal Hub files
- Do not "順便" 重構其他區塊
- Do not run dart fix --apply
