# Architecture Sandbox Report / 架構沙盤檢查報告

Generated: 2026-05-01 18:51:28 -07:00
Project: C:\dev\local_ai_chat
Export folder: C:\dev\local_ai_chat\source_text_exports\local_ai_chat_text_export_20260501_185127

## Verification / 驗證

- flutter analyze: PASS - No issues found!
- flutter test -r expanded: PASS - +365 ~4 All tests passed!
- Windows build verified in this session: PASS - build\windows\x64\runner\Release\local_ai_chat.exe
- Android APK verified in this session: PASS - build\app\outputs\flutter-apk\app-release.apk

## Framework Structure / 主要架構

Core folders are present and clear:

- lib/ : 67 files
- test/ : 48 files
- bin/ : 2 files
- docs/ : 25 files
- tool/ : 15 files
- android/ : 44 files
- web/ : 7 files
- windows/ : 65 files
- books/ : 2 files
- data/ : 1 files

Important source layout:

- lib/controllers/: app state/controllers including Reader, Personal Hub, Expense, Contact, Health, Wealth.
- lib/models/: typed domain models including Contact, Expense, HealthRecord, WealthRecord, OfficeCommand.
- lib/screens/: Flutter UI screens, including Library/Reader/PersonalHub/Expense/Health/Wealth.
- lib/services/: API, RAG, embedding, vector store, OCR, persistence, PersonalRag services.
- lib/server/: local Shelf API server and Ollama client.
- test/: unit/widget/integration tests grouped by controllers/models/screens/services.
- bin/: Dart CLI entry points for server/indexing.
- docs/: release notes and project documentation.
- tool/: verification and setup scripts.
- android/, windows/, web/: platform scaffolding.

## Path Clarity / 路徑清晰度

Status: GOOD.

- Production Dart code is under lib/.
- Tests are under test/.
- Server CLI entry points are under bin/.
- Platform files are under their normal Flutter folders.
- Analyzer excludes old handoff/backup/release/generated folders, so current flutter analyze is clean.

## Notes / 注意事項

The project root still contains legacy or generated artifacts that are not part of the clean source handoff. They were not included as source code unless they are deliberate text/config files.

Observed generated/legacy clutter candidates:

- .dart_tool
- after_valid_pdf_load_debug.png
- analyze.log
- build
- citation_after_show.png
- citation_click2.png
- citation_clicked_highlight.png
- citation_fast_screenshot.png
- citation_final_app_only.png
- citation_final_highlight.png
- citation_highlight_amp_fix.png
- citation_highlight_retry_release.png
- citation_immediate_highlight.png
- citation_session_release.png
- flutter_01.log
- flutter_02.log
- flutter_run_test.err.log
- flutter_run_test.out.log
- full_test_68.log
- handoff_exports
- lib_backup
- pq.err
- pq.out
- rag_citation_test.pdf
- rag_citation_test_valid.pdf
- rag_question_result.png
- rag_question_result_clipboard.png
- real_citation_click_result.png
- release_foreground.png
- release_front2.png
- release_reopen.png
- release_screenshot.png
- release_test_start.png
- release_v2.2.0
- release_v2.3.0
- test.log

Recommended for long-term cleanliness:

- Keep build/, .dart_tool/, release packages, old screenshots, and handoff backups out of analyzer/source exports.
- Keep release ZIP/APK artifacts in dedicated release_v* folders only.
- Avoid placing old root-level duplicates like api_server.dart / ollama_client.dart back into analyzer scope.

## Export Policy / 打包策略

This ZIP contains text-readable source/config/docs only.

Included as .txt mirror files:

- Dart source/tests
- YAML/JSON/Markdown/docs
- PowerShell/CMD/shell scripts
- Gradle/Kotlin/XML/properties/platform source text
- C/C++/header/platform runner text files

Excluded:

- build outputs, APK/EXE/DLL/PDB/LIB/JAR/BIN/DAT
- images/screenshots/PDFs/logs
- .git, .dart_tool, IDE folders, backup/handoff/release binary folders

Included file count: 249
