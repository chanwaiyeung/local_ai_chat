# Task: Church - Create Unified ChurchHubScreen v2.0 (Independent Hub)

## Scope
建立獨立的 `ChurchHubScreen`，作為教會模組的**統一入口**，讓牧者、長執、部門同工與會友能在同一平台上互通、協作、彼此相顧。

## Files allowed to modify (WRITE list)
- lib/screens/church/church_hub_screen.dart          ← 新增此檔案（主要）
- lib/screens/personal_hub_screen.dart               ← 只修改「教會」卡片的 onTap 導航

## Files read-only (READ list)
- lib/screens/church/care_dashboard_screen.dart
- lib/screens/church/person_directory_screen.dart
- lib/screens/church/person_history_screen.dart
- lib/controllers/church/care_controller.dart
- lib/controllers/church/person_controller.dart

## Files forbidden (NEVER TOUCH list)
- lib/main.dart
- lib/services/**
- lib/l10n/**
- lib/models/person.dart (core)
- Any file outside lib/screens/church/ and lib/widgets/church/

## Acceptance criteria
1. 新增 `ChurchHubScreen`（AppBar 標題「教會」）
2. 頂部顯示 4 格統計卡片（進行中案件、需立即跟進、會友人數、久未出席）
3. GridView 或 Tab 呈現主要功能入口：
   - 關懷追蹤 → CareDashboardScreen
   - 會友通訊錄 → PersonDirectoryScreen
   - 探訪歷史 → PersonHistoryScreen
4. PersonalHubScreen 中的「教會」卡片改成導航到 `ChurchHubScreen`
5. flutter analyze → No issues found!
6. git diff --stat 只顯示 **最多 2 個檔案**
7. App 運行無 crash，導航正常

## Required deliverables
1. `lib/screens/church/church_hub_screen.dart` 完整程式碼
2. `personal_hub_screen.dart` 中教會卡片的修改片段
3. git diff --stat 輸出
4. flutter analyze 輸出
5. 操作流程文字說明（牧者如何使用）

## Do NOT
- Do not modify any Controller / Model
- Do not touch l10n or localization keys
- Do not create files outside church/ directory
- Do not "順便" 重構其他畫面
- Do not run dart fix --apply
- Do not change any non-church files except the one allowed in personal_hub_screen.dart
