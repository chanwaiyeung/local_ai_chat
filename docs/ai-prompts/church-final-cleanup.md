# Task: Church - Final Cleanup & Test (Overall Module)

## Scope
對 Church 模組進行最終清理與驗證，讓整個模組達到可穩定使用的狀態。

## Files allowed to modify (WRITE list)
- lib/screens/church/person_directory_screen.dart
- lib/screens/church/care_dashboard_screen.dart
- lib/widgets/church/visit_log_dialog.dart
- lib/widgets/church/person_form_dialog.dart (minimal fix only if needed)

## Files read-only (READ list)
- lib/controllers/church/*
- lib/models/church/*
- lib/screens/church/person_history_screen.dart
- lib/screens/church/case_detail_screen.dart

## Files forbidden (NEVER TOUCH list)
- lib/main.dart
- lib/screens/personal_hub_screen.dart
- lib/services/**
- lib/l10n/**
- lib/models/person.dart
- Any non-church files

## Acceptance criteria
1. 所有 Church 相關畫面運行無 crash
2. FAB、新增、編輯、探訪記錄功能可正常操作
3. flutter analyze → No issues found!
4. git diff --stat 只顯示允許的 1~3 個檔案

## Required deliverables
1. 清理後的相關程式碼片段（如果有最小調整）
2. git diff --stat 輸出
3. flutter analyze 輸出
4. flutter test 2>&1 | Select-Object -Last 3 輸出
5. 整體 Church 模組可用性文字總結

## Do NOT
- Do not touch l10n or localization keys
- Do not modify any controller or model unless absolutely necessary
- Do not touch Personal Hub files
- Do not "順便" 重構非 Church 模組
- Do not run dart fix --apply
