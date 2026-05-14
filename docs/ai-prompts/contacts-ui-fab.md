# Contacts UI — Add FAB + Camera Scan(對齊 Wealth pattern)

## Context
- Bug: `_ContactListScreen` 在 lib/screens/personal_hub_screen.dart line 769-794
  - 目前只有 AppBar + ListView,沒任何新增入口
  - 截圖驗證:畫面只顯示「No contacts yet」,連 FAB 都沒
- Reference pattern: lib/screens/wealth_screen.dart 的 _scanAsset() 與 FAB 結構
  - 見 docs/adr/2026-05-14-extract-scan-asset.md
- ContactController API: lib/controllers/contact_controller.dart 提供
  - controller.contacts (getter)
  - controller.contactCount (getter)
  - (確認 controller 有 add/save method,Spec 起手時要先 grep 一下)

## Required Changes (exhaustive — no other files allowed)

### Modify ONLY
- lib/screens/personal_hub_screen.dart
  - 在 _ContactListScreen 內加 FloatingActionButton.extended "+ Add Manually"
  - 在 _ContactListScreen 內加 bottomNavigationBar 含 IconButton.filled 相機
  - 把 _ContactListScreen 改成 StatefulWidget(因為要 manage scan/dialog state)
  - 加 private method _addContactManually() — 開啟 contact form dialog
  - 加 private method _scanContact() — 鏡像 wealth_screen._scanAsset()

## Reference: wealth_screen.dart pattern (line ~145)

  Future<void> _scanAsset() async {
    final settings = await AppSettingsService().load();
    final apiKey = settings.geminiApiKey?.trim();
    if (apiKey == null || apiKey.isEmpty) {
      // show snackbar 提示去 Settings 設 key
      return;
    }
    final picker = ImagePicker();
    final image = await showDialog<XFile?>(... 拍照 / 相簿 ...);
    if (image == null) return;
    showDialog(barrierDismissible: false, builder: ... loading ...);
    try {
      final visionService = VisionLLMService();
      final record = await visionService.scanContactFromImage(image.path, apiKey: apiKey);
      Navigator.pop(context);  // 關 loading
      if (record != null) {
        // 開 contact form dialog 預填
      } else {
        // snackbar 失敗訊息
      }
    } catch (e) {
      Navigator.pop(context);
      // snackbar error
    }
  }

## Hard constraints

1. NO changes to:
   - lib/controllers/** (ContactController API 不動,只用現有 method)
   - lib/services/** (除非 VisionLLMService 還沒 scanContactFromImage method,
     那情況下停下來,寫 docs/library_rebuild_requirements.md 給人類審查)
   - lib/models/** (Contact model 不動)
   - lib/main.dart
   - pubspec.yaml
   - windows/**
   - any test files
2. NO 改動 _ContactListScreen 以外的任何 class 在 personal_hub_screen.dart
   - 不要動 PersonalHubScreen
   - 不要動 _ModuleCardGrid / _DashboardCard / _DashboardRow 等
3. NO 新增 dependency
4. NO 改 ARB / l10n 檔(暫時用 hardcoded 中文,等下次統一在 i18n task 加 key)

## Acceptance criteria

1. Contacts 畫面右下角有 FAB "+ Add Manually"(中文 OK:「新增名片」)
2. Contacts 畫面有 bottomNavigationBar 含相機 icon(tooltip:「掃描名片」)
3. 點 FAB → 開啟 contact form dialog(如果 ContactFormDialog 不存在,
   就先用最簡單的 AlertDialog 含 name + phone + email,Phase 2 再做完整版)
4. 點相機 → 走 _scanContact 流程,鏡像 wealth_screen._scanAsset 邏輯
5. 即使 ContactController.add 還沒實作,UI 也要先做出來(call 後可以 toast「功能建設中」)
6. flutter analyze → No issues found!
7. flutter test → 全部維持綠(+409 ~4 或更多 pass)
8. git diff --stat 只顯示 1 個檔案: lib/screens/personal_hub_screen.dart
9. 開 app 跑一次,Contacts 畫面要看到 FAB + 相機 icon

## Required deliverables (在 reply 中提供)

1. Modified personal_hub_screen.dart 的完整 _ContactListScreen 段落
2. Output of: git diff --stat
3. Output of: flutter analyze
4. Output of: flutter test 2>&1 | Select-Object -Last 3
5. 截圖確認(或文字描述)Contacts 畫面有 FAB + 相機

## Do NOT

- Do not commit (人類會 review 後手動 commit)
- Do not push
- Do not run dart fix --apply
- Do not modify windows/flutter/generated_*
- Do not touch any other widget/class in personal_hub_screen.dart
- Do not "improve" anything outside scope (即使看到 code smell)
