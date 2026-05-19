# Task: Church - Add onLongPress edit support to Person Directory

## ⚠️ Context: existing state (READ BEFORE editing)

`lib/screens/church/person_directory_screen.dart` 已經有以下實作 —
**這些一律不可改動**：

- `_openForm({Person? existing, String? defaultType})` 已正確開啟
  PersonFormDialog (line ~43-56)
- **2 個 FAB** (heroTag: `memberFab` + `seekerFab`) 已 wire 到
  `_openForm(defaultType: PersonType.member)` 和
  `_openForm(defaultType: PersonType.seeker)`
- `PersonController.savePerson` / `deletePerson` 已透過 `_openForm` 使用
- `ListTile.onTap` → `_openForm(existing: ...)` 已實作編輯模式
- AppBar title「會友通訊錄」、所有中文 label、Filter chips
- `_PersonRow` / `_Filter` / `_AttendanceBadge` 三個 private widget classes

## Scope (what's MISSING — 唯一要做的事)

**新增** `ListTile.onLongPress` 觸發編輯，**與 `onTap` 並存**（不取代）。
這樣 user 可以：
- Tap → 開啟編輯 (原有行為，保留)
- Long press → 開啟編輯 (新增行為)

Tap-or-longpress 都能編輯，給 user 兩種輸入方式。

## Files allowed to modify (WRITE list)

- `lib/screens/church/person_directory_screen.dart`

## Files read-only (READ list)

- `lib/widgets/church/person_form_dialog.dart`
- `lib/models/church/person.dart`
- `lib/controllers/church/person_controller.dart`
- `docs/ai-roles/cursor-life-app.md` (你的 Hard rules)

## Files forbidden (NEVER TOUCH list)

- `lib/main.dart`
- `lib/screens/personal_hub_screen.dart`
- `lib/services/**`
- `lib/l10n/**`
- `lib/models/person.dart` (非 church/)
- Any file outside `lib/screens/church/`

## ⛔ HARD CONSTRAINTS (前次失敗的點，這次禁止重犯)

1. **保留** 現有 2 個 FAB structure (`memberFab` + `seekerFab` 在 Row 裡)。
   **不可** 合併、不可改成單一 FAB、不可改 label、不可改 heroTag。
2. **保留** 所有中文 label（「新增會友」「新增非會友」「會友通訊錄」
   filter chip labels、_emptyState 文字等）。Church module 是
   hardcoded Chinese，**不可**插入英文 UI string。
3. **保留** `ListTile.onTap` → `_openForm(existing: ...)`。
   **不可** 取代、不可刪除。tap 必須繼續能開啟編輯。
4. `_PersonRow` class 必須**同時擁有** `onTap` AND `onLongPress` 兩個
   `VoidCallback` fields，**兩者都呼叫** `_openForm(existing: persons[i])`。
5. 不要 import 新 package，不要新增 helper class、helper method。

## Acceptance criteria

1. `_PersonRow` constructor signature:
   ```dart
   const _PersonRow({
     required this.person,
     required this.onTap,
     required this.onLongPress,
   });
   ```
2. `_PersonRow` fields:
   ```dart
   final Person person;
   final VoidCallback onTap;
   final VoidCallback onLongPress;
   ```
3. `ListTile` in `_PersonRow.build`：**同時** 設定 `onTap: onTap` 和
   `onLongPress: onLongPress`。
4. `ListView.itemBuilder` 傳入 `_PersonRow` 時同時 wire 兩個 callback，
   兩者都呼叫 `_openForm(existing: persons[i])`：
   ```dart
   _PersonRow(
     person: persons[i],
     onTap: () => _openForm(existing: persons[i]),
     onLongPress: () => _openForm(existing: persons[i]),
   )
   ```
5. FAB section (`floatingActionButton: Row(...)`) 在 diff 中 **0 變動**。
6. AppBar title 在 diff 中 **0 變動**（仍為「會友通訊錄」）。
7. `_openForm` method body 在 diff 中 **0 變動**。
8. `_Filter` / `_AttendanceBadge` 兩個 class 在 diff 中 **0 變動**。
9. `flutter analyze` → `No issues found!`
10. `flutter test 2>&1 | Select-Object -Last 3` → `All tests passed!`
11. `git diff --stat` 只顯示 1 個檔: `lib/screens/church/person_directory_screen.dart`
12. **Diff 行數 ≤ 50 lines** (Church cap per cursor-life-app.md Hard rule #3)
    預期實際 diff 應該 ≤ 10 行（只動 `_PersonRow` constructor、fields、
    ListTile prop、itemBuilder callsite）

## Required workflow (依序執行)

```powershell
# Pre-flight: 確認在 main，working tree 乾淨
git checkout main
git status --short        # 必須完全空 — 如果有 M / ?? 停手告訴 Albert

# 切到 task branch (branch 已存在，不用 -b)
git checkout task/church-person-directory-integration

# Fast-forward 到 main (取得最新 spec + charter)
git merge --ff-only main
git log -1 --oneline      # 應該顯示最新 spec commit

# 改動 lib/screens/church/person_directory_screen.dart
# 預期動 4-10 行: _PersonRow constructor、fields、ListTile props、itemBuilder
# 改完後驗證 (RAW output 必須貼給 Albert)
flutter analyze
flutter test 2>&1 | Select-Object -Last 3
git diff --stat
git diff lib/screens/church/person_directory_screen.dart
```

## Required deliverables (報告給 Albert)

1. `git diff --stat` raw output
2. `flutter analyze` 完整 raw output
3. `flutter test 2>&1 | Select-Object -Last 3` raw output
4. `git diff lib/screens/church/person_directory_screen.dart` 完整 raw
   output（讓 Albert 對照所有 Acceptance criteria）
5. 一段中性描述：onTap 與 onLongPress 並存的目的，**no grandiose
   language** (no 「完美」「輝煌」「達到 100 分」等)

## Do NOT

- Do not modify `person_form_dialog.dart`
- Do not touch l10n or localization keys
- Do not create new files
- Do not modify any controller or model
- Do not touch any non-church files
- Do not「順便」refactor `_emptyState`、`_Filter`、`_AttendanceBadge`
- Do not run `dart fix --apply`
- Do not change FAB count, FAB labels, or AppBar title
- Do not **replace** `onTap` with `onLongPress` — **both must coexist**
- Do not commit (Albert reviews and commits)
- Do not work on main branch (use task branch per Hard rule #2)
- Do not use English UI strings in Church module
