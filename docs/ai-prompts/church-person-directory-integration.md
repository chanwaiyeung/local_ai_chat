# Task: Church - Integrate Person Form Dialog into Person Directory Screen

## Scope
在 Person Directory 畫面中完整整合 PersonFormDialog，讓使用者可以：
- 點擊 FAB 新增人員
- 長按 ListTile 編輯現有人員

## Files allowed to modify (WRITE list)
- lib/screens/church/person_directory_screen.dart

## Files read-only (READ list)
- lib/widgets/church/person_form_dialog.dart
- lib/models/church/person.dart
- lib/controllers/church/person_controller.dart

## Files forbidden (NEVER TOUCH list)
- lib/main.dart
- lib/screens/personal_hub_screen.dart
- lib/services/**
- lib/l10n/**
- lib/models/person.dart (非 church/)
- Any file outside lib/screens/church/ and lib/widgets/church/

## Acceptance criteria
1. Person Directory Screen 右下角有 FloatingActionButton.extended「Add Person」
2. 點擊 FAB 呼叫 `PersonFormDialog`（新增模式）
3. ListTile 支援長按（onLongPress）開啟 `PersonFormDialog`（編輯模式，帶入現有資料）
4. 使用 `PersonController` 的方法處理新增/更新
5. flutter analyze → No issues found!
6. git diff --stat 只顯示 **1 個檔案**

## Required deliverables
1. 修改後的 `_PersonDirectoryScreenState` 中相關方法（FAB、onLongPress、dialog 呼叫）的完整程式碼區塊
2. git diff --stat 輸出
3. flutter analyze 輸出
4. 文字描述：新增與編輯人員的操作流程

## Do NOT
- Do not modify person_form_dialog.dart
- Do not touch l10n or localization keys
- Do not create new files
- Do not modify any controller or model
- Do not touch any non-church files
- Do not "順便" 重構其他畫面
- Do not run dart fix --apply
