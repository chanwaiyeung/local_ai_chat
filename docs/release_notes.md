# Release Notes

## v2.4.0 — 投資理財 GA (2026-05-02)

**Phase 7 — 投資理財模組完成**，個人生活管家四個核心資料模組（開支 / 名片 / 健康 / 投資）全部上線。

### 主要亮點
- **投資理財模組**：
  - 多資產類別（現金 / 股票 / 基金 / 債券 / 加密貨幣 / 房地產 / 保險）
  - **多幣別獨立計算**（TWD / HKD / USD / CAD / JPY / CNY / EUR），不跨幣別亂加
  - **latest-per-asset 淨值語意**：同一資產多次估值，取最新值；不會被誤算成累加
  - **資產配置圓餅圖** + **淨值步階趨勢線**（按日期；新估值蓋掉舊估值）
  - 支援標籤、備註、自由選日期
- **跨模組 RAG 整合**：PersonalRagService 預設 collections 涵蓋 Expenses + Contacts + Health + Wealth；system prompt 同步更新；`_extractSearchText` 對 Health / Wealth 採專屬解碼路徑，embedding 品質回升。
- **Dashboard 第四列「投資淨值」**：分幣別顯示前兩大幣別總和。

### 技術里程碑
- WealthController 採 Pattern A（store.add / deleteById），與 ExpenseController 對齊
- WealthAssetType 常數類取代 raw String，杜絕 `Stock` vs `stock` 桶分裂
- WealthRecord 加上 `==` / `hashCode` / `assetKey` getter，list / Set / 測試斷言可靠
- WealthScreen 改為 TabBar [紀錄][配置]，徹底移除對 main.dart 全域單例的依賴

### 測試覆蓋
- 新增 `test/controllers/wealth_controller_test.dart`：覆蓋多幣別、latest-per-asset、淨值歷史、跨 instance 持久化、case-insensitive 搜尋
- 新增 `test/screens/wealth_screen_test.dart`：補齊投資理財 UI 回歸防線

### 已知限制
- 真實 embedding 還沒接到 wealth chunks（仍以 384-zero dummy 暫代）；跨模組 RAG 對 wealth 的語意檢索準確度需等 PersonalRagService.reindexAll 接 embedder 後才會優化
- iOS / macOS 版仍未發行，僅 Windows + Android 為支援平台

### 下一步
- v2.5：iOS / macOS 平台支援、長期回測報表、真實 embedding 全面 reindex

---

## v2.3.0 — 健康管理 + 跨模組 RAG 強化 (2026-04 → 2026-05 間)

**Phase 6 — Health 模組** 整合，並修復 Personal Hub 多模組共存問題。

### 主要亮點
- **健康紀錄模組**：體重 / 血壓 / 心率 / 步數 / 睡眠記錄 + 30 天統計卡 + 趨勢圖
- **PersonalRagService**：
  - `reindexCollection` / `reindexMissingEmbeddings` / `reindexAll`，把舊 dummy embedding 補成真實 embedding
  - `retrieveAcross` 跨 collection 合併排序
  - `answer` / `answerStream` 兩種 LLM 完成模式
  - 預設 collections 加入 `Health`
- **PersonalQueryScreen**：單輪流式 Q&A UI，hits 與生成答覆同畫面顯示

### 已知限制
- 投資理財留待 v2.4

### 下一步
- v2.4：投資理財模組

---

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
- Android APK：`local_ai_chat_v2.2.0.apk`

### 已知限制
- iOS / macOS 版仍未發行，僅 Windows + Android 為支援平台

### 下一步
- v2.3 已完成（健康管理 + 跨模組 RAG）
- v2.4 已完成（投資理財）
- v2.5：iOS / macOS 平台支援、長期回測報表

---

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
