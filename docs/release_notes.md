# Release Notes

## v3.9.0 - Personal Hub 視覺化大升級

**這一版重點：**
- **Expense 支出視覺化**：每月總覽、類別圓餅圖、每日趨勢長條圖
- **Health 健康追蹤**：體重、步數、睡眠、心情趨勢圖 + 關鍵指標卡片
- **Hub 首頁**：左右並列顯示，更直觀專業
- **Settings 頁面**：API Key 狀態顯示 + 完整模型選擇
- **Vision Prompt**：大幅強化，多維度專業分析（消費、健康、資產）

### 📸 主要功能截圖
（已上傳 Hub 首頁、Expense、Health 截圖）

### 🔧 技術更新
- 整合 Plotly 互動圖表
- 自動建立 data/ 資料夾與範例資料
- 獨立 config.json 設定管理
- 更穩定的 Vision LLM Prompt 系統

### 📌 如何快速開始
1. Clone 本專案
2. `pip install -r requirements.txt`
3. `streamlit run main.py`（或你的入口檔案）
4. 前往 **Settings** 設定 API Key
5. 享受 Personal Hub 的完整體驗！

### 🎯 未來方向
- Telegram Bot 手機即時記帳
- 手動新增支出與 AI 理財建議
- PDF 掃描自動記帳

---



## 智讀館 v2.5.0 — 多語時代 (2026/05)

### 🌟 主要更新

**國際化與本地化**
- 建立完整 i18n 基礎設施（intl + ARB）
- 支援 **繁體中文（預設）**、**簡體中文**、**英文**
- Settings 頁新增語言切換器，可即時切換
- 所有核心畫面字串完整外抽（Personal Hub、Wealth、Health、Expense、Settings）

**外觀與體驗**
- 新增主題切換：深色模式 / 淺色模式 / 跟隨系統
- 優化多語言下的排版與顯示

**技術基礎**
- 重構字串管理，提升未來新增語言的效率
- 優化 ThemeMode 切換機制
- 維持高測試覆蓋率（398+ tests）

### 已知限制
- 日文與阿拉伯文尚未支援（後續版本將依使用者反饋評估）
- ChatScreen 與部分 Dialog / Toast 訊息仍待補完

## v2.2.0 — Personal Hub GA (2026-05-01)

**正式發布** — 智讀館從閱讀工具升級為**個人生活管家**。

### 主要亮點
- **名片管理**：鏡頭掃描 + OCR 自動解析 + RAG 搜尋
- **日常開支**：掃描發票 + 手動新增 + 月份切換 + 類別統計
- **健康管理**：體重、血壓、運動、睡眠記錄 + 統計
- **統一 Dashboard**：總覽三個模組 + 快速 AI 查詢
- **跨模組 RAG**：自然語言查詢「上次跟王經理吃飯花多少？」

### 技術里程碑
- VectorStore v3 + Collection 抽象層
- PersonalRagService 跨模組 RAG
- 完整本地化（所有資料不離裝置）

### 測試覆蓋
- 總測試數：357 個（全綠）
- 零 regression

### 下載
- Windows：`local_ai_chat_v2.2.0_windows_x64.zip`
- Android APK：`local_ai_chat_v2.2.0.apk`（稍後補上）

### 已知限制
- iOS / macOS 版將在 v2.3 補上
- 投資理財留待 v2.3

### 下一步
- v2.3：投資理財 + 健康管理進階功能

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
