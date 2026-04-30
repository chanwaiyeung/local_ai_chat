# Release Notes

## v2.0.0 GA

智讀館 v2.0.0 GA 是第一個可對外發布的生產級版本，完成本地 RAG 閱讀、串流問答、跨端連線、安全啟動與閱讀器狀態硬化。

- Phase 5.1 完成 ReaderController 生產級硬化：`answer` 欄位只保留真正 LLM 回答，OCR / 載入 / 檢索狀態統一走 `statusBanner`。
- Phase 5 完成持久化方向：SharedPreferences + FlutterSecureStorage 作為本機偏好與敏感設定保存層。
- Phase 4 強化 OCR 與漫畫路徑：支援 ML Kit / Tesseract 實驗管線與漫畫後處理方向。
- Phase 3 完成多書庫能力：書籍切換、跨書檢索與 retrieve-first 閱讀模式。
- Phase 1-2 鎖定核心體驗：RAG streaming、citation panel、LAN 自動偵測、安全 LAN mode 與手機 / Web 互動閉環。

### Verification

- `flutter analyze`: 0 issues
- `flutter test`: 138+ tests expected
- Windows release: `build/windows/x64/runner/Release/local_ai_chat.exe`
- Android release: `build/app/outputs/flutter-apk/app-release.apk`
