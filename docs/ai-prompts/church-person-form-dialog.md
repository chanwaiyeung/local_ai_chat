# Task: Church - Implement Complete Person Form Dialog

## Scope
為教會模組實作完整、可重用的 Person Form Dialog（新增 / 編輯聯絡人），替換目前任何簡易 AlertDialog。

## Files allowed to modify (WRITE list)
- lib/widgets/church/person_form_dialog.dart     (如果不存在則允許建立)
- lib/screens/church/person_directory_screen.dart (只修改呼叫 dialog 的部分)

## Files read-only (READ list)
- lib/models/church/person.dart
- lib/controllers/church/person_controller.dart
- lib/screens/church/care_dashboard_screen.dart

## Files forbidden (NEVER TOUCH list)
- lib/main.dart
- lib/screens/personal_hub_screen.dart
- lib/services/**
- lib/l10n/**
- lib/models/person.dart (非 church/)
- Any file outside lib/screens/church/ and lib/widgets/church/

## Acceptance criteria
1. 建立/完善 `PersonFormDialog` widget（支援新增與編輯模式）
2. 包含以下欄位（全英文標籤）：
   - Full Name*（必填）
   - Phone
   - Email
   - Industry
   - Position / Title
   - Date (使用 showDatePicker)
   - Notes / Remarks (多行)
3. 表單驗證（姓名必填）
4. 點擊 Save 呼叫 `PersonController` 的適當方法（add 或 update）
5. flutter analyze → No issues found!
6. git diff --stat 只顯示允許的 1~2 個檔案

## Required deliverables
1. `lib/widgets/church/person_form_dialog.dart` 的完整程式碼（如果新建）
2. 修改後的呼叫點程式碼片段（例如在 person_directory_screen.dart）
3. git diff --stat 輸出
4. flutter analyze 輸出
5. 使用說明：如何從目錄畫面開啟此 dialog

## Do NOT
- Do not touch l10n or localization keys
- Do not modify any non-church files
- Do not add new dependencies to pubspec.yaml
- Do not run dart fix --apply
- Do not "順便" 重構其他畫面
