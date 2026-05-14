# Phase 2 收貨檢查清單

## 1. 檔案是否真的存在
Test-Path lib\widgets\library\library_book_card.dart
# 必須 True

Get-Item lib\widgets\library\library_book_card.dart | Select-Object Length
# 必須 > 0,且 line count 看起來合理(通常 50-150 行)

## 2. Restore Flutter generated noise(可能被 flutter analyze 重寫)
git restore windows/flutter/generated_plugin_registrant.cc 2>$null
git restore windows/flutter/generated_plugin_registrant.h 2>$null
git restore windows/flutter/generated_plugins.cmake 2>$null

## 3. Diff 範圍剛好兩個檔
git status --short
git diff --stat
# 期望:剛好 2 個檔(1 new + 1 modified)

## 4. 沒踩禁區
git diff --name-only | Select-String -Pattern "controllers/|services/|models/|main\.dart|pubspec|windows/|test/"
# 期望:空輸出

## 5. Analyzer + tests
flutter analyze
# 期望:No issues found!

flutter test test/library_screen_test.dart test/reader_screen_test.dart test/reading_mode_screen_test.dart -r expanded
# 期望:All tests passed!

flutter test 2>&1 | Select-Object -Last 3
# 期望:All tests passed! +409 ~4(或更高 ~4,只要 -0)

## 6. 視覺驗證(必做!)
flutter run -d windows
# 開到 Library screen 肉眼看 book card 跟之前一樣

## 7. 全綠才 commit
git add lib/widgets/library/library_book_card.dart lib/widgets/library/library_book_grid.dart
git commit -m "refactor(library): extract reusable LibraryBookCard widget"
