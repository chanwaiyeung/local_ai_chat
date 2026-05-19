# Task: Church - Implement Visit Log Dialog

## Scope
為教會模組實作完整的 Visit Log Dialog，讓關懷人員可以記錄探訪紀錄（支援新增與編輯）。

## Files allowed to modify (WRITE list)
- lib/widgets/church/visit_log_dialog.dart (如果不存在則允許建立)
- lib/screens/church/person_directory_screen.dart (只修改呼叫部分，可選)
- lib/screens/church/care_dashboard_screen.dart (只修改呼叫部分，可選)

## Files read-only (READ list)
- lib/models/church/visit_log.dart
- lib/controllers/church/care_controller.dart
- lib/models/church/care_case.dart
- lib/widgets/church/person_form_dialog.dart

## Files forbidden (NEVER TOUCH list)
- lib/main.dart
- lib/screens/personal_hub_screen.dart
- lib/services/**
- lib/l10n/**
- lib/models/person.dart
- Any file outside lib/screens/church/ and lib/widgets/church/

## Acceptance criteria
1. 建立 `VisitLogDialog` widget（支援新增與編輯模式）
2. 包含以下欄位（全英文標籤）：
   - Visit Date (使用 showDatePicker)
   - Person / Care Case (下拉或自動帶入)
   - Visit Type (e.g. Home Visit, Hospital Visit, Phone Call)
   - Notes / Summary (多行，必填)
   - Next Follow-up Date (可選)
3. 表單驗證（Notes 必填）
4. 點擊 Save 呼叫 Controller 的適當方法
5. flutter analyze → No issues found!
6. git diff --stat 只顯示允許的 1~2 個檔案

## Required deliverables
1. `lib/widgets/church/visit_log_dialog.dart` 的完整程式碼（如果新建）
2. 修改後的呼叫點程式碼片段（例如在 person_directory_screen.dart 或 care_dashboard_screen.dart）
3. git diff --stat 輸出
4. flutter analyze 輸出
5. 使用說明：如何從人員或個案畫面開啟 Visit Log Dialog

## Do NOT
- Do not touch l10n or localization keys
- Do not modify any Controller / Model
- Do not add new dependencies
- Do not run dart fix --apply
- Do not "順便" 重構其他畫面
- Do not touch Personal Hub files
