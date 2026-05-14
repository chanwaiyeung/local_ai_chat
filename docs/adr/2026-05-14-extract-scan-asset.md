# ADR: Extract _scanAsset() from inline callback

Date: 2026-05-14
File: lib/screens/wealth_screen.dart

## Why
100-line inline onPressed callback in IconButton.filled was bloating
the build() method. Made the UI tree hard to scan, and blocked code
reuse for Contacts/Expense/Health which need similar scan flows.

## What
Extracted private method _scanAsset(). Pure refactor — behavior
identical to before. No controller/service/model changes.

## Verified
- flutter analyze: No issues found (full repo, 12.7s)
- flutter test wealth_screen_test: 13 passed
- flutter test (full): 409 passed, 4 skipped, 0 failed

## Next
Consider extracting to lib/utils/ai_scan_helper.dart when adding
Contacts/Expense scan flows, to share the dialog + loading + error
pattern across modules.

This refactor establishes the reference pattern for the upcoming
Contacts UI task (FAB + camera scan, mirroring wealth_screen).
