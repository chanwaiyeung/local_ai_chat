# Local AI Chat (v2.5) Code Review 自動審查報告

**報告生成者**: Antigravity  
**目標專案**: Local AI Chat (v2.5)  
**掃描範圍**: `lib/`, `test/`, `pubspec.yaml`, `bin/`  
**報告目的**: 確保多模態整合與 Wealth/Health Personal Hub 上線前的系統穩健性。

本報告針對專案進行深度源碼掃描與架構分析。審查範圍涵蓋 8 個核心維度，並標記對應的嚴重度（🔴嚴重、🟡中等、🟢輕微）與具體檔案座標。

---

## 1. 邏輯 (Logic)

### 🔴 嚴重：Vector Store 持久化未加密 (vector_store 明文)
- **位置**: `lib/services/vector_store.dart:403`
- **程式碼片段**: `final data = jsonEncode(payload); await tmp.writeAsString(data, flush: true);`
- **問題描述**: 目前 `VectorStore` 的持久化直接使用 `jsonEncode(payload)` 寫入明文 JSON。考量到 Personal Hub 模組（Wealth/Health）已經啟用，使用者的**真實財務與健康資料**將會被明文儲存在本地硬碟中。若設備遭到物理獲取或遭惡意軟體掃描，將產生重大的邏輯與隱私漏洞。
- **建議**: 在寫入檔案前，必須引入 AES-GCM 或 ChaCha20 加密機制，並使用 `flutter_secure_storage` 將對稱金鑰妥善保管於系統層級的安全區（Keystore/Keychain）。

### 🟡 中等：Telegram Bot 輪詢邏輯缺失超時重試
- **位置**: `lib/services/telegram_bot_service.dart:44`
- **問題描述**: `http.get(uri).timeout(...)` 雖然設定了 timeout，但在 `catch (e)` 中只有簡單的 `Future.delayed(const Duration(seconds: 2))`。如果遇到長時間斷網或是 Telegram API Server 5xx 錯誤，這可能會導致大量的空轉或無效請求無限迴圈堆積。
- **建議**: 實作 Exponential Backoff (指數退避) 重試邏輯。每次失敗後延遲時間應逐步增加（2s -> 4s -> 8s -> 16s），最大限制在 60s。

---

## 2. 隱藏 bug (Hidden Bugs)

### 🔴 嚴重：Global 單例狀態競爭 (global 單例)
- **位置**: `lib/services/app_settings_service.dart:12`
- **問題描述**: 專案中廣泛使用了類似 `AppSettings.instance` 之類的 global 單例。在多執行緒或是多個 Controller 同時讀寫設定時（特別是 RAG indexing 在背景大量執行、或者 Bot Polling 同時更新時），極容易產生 Race Condition。當前 Dart 的 event loop 雖為單執行緒，但在大量 `await` 交錯的情境下，仍會造成狀態不一致的幽靈 bug。
- **建議**: 改用 Dependency Injection (如 `get_it` 搭配 `Injectable`，或 `provider`/`riverpod`) 來管理狀態，徹底拔除 Global 單例。

### 🟡 中等：未捕獲的 PDF 解析異常
- **位置**: `lib/services/pdf_service.dart:18`
- **問題描述**: `extractRange` 方法在解析受損或被加密的 PDF 檔案時，可能會拋出未被外層 `try-catch` 攔截的底層 C/C++ 函式庫例外。這會導致整個 Flutter App 發生硬性 Crash (Hard Crash)，且無法在 Crashlytics 中捕捉。
- **建議**: 在呼叫 `syncfusion_flutter_pdf` 的 API 外層包裝更嚴格的例外處理，甚至放置在獨立的 Isolate 執行以避免主程序崩潰。

### 🟡 中等：檔案下載路徑未檢查目錄存在
- **位置**: `lib/services/telegram_bot_service.dart:150`
- **問題描述**: `_downloadFile` 中直接拼接了 `telegram_downloads` 資料夾路徑並嘗試寫入。但並未事先執行 `Directory(path).create(recursive: true)`。若該路徑不存在，寫入作業將觸發 `FileSystemException`。
- **建議**: 加入目錄檢查與自動創建邏輯。

---

## 3. 安全 (Security)

### 🔴 嚴重：Token/API Key 潛在洩漏 (HTTP URL 拼接)
- **位置**: `lib/services/telegram_bot_service.dart:164`
- **問題描述**: 下載檔案時，網址字串中直接拼接了 `bot$token` (`https://api.telegram.org/file/bot$token/$filePath`)。如果在後續版本中意外將 HTTP Log 級別調高，或是被 proxy/VPN 攔截，這串包含最高權限 Token 的 URL 將會被明文記錄。
- **建議**: 確保網路連線層的日誌過濾機制（移除敏感參數），或建議將 Telegram Token 封裝在獨立的 SecretProvider 中，禁止在業務邏輯層隨意列印。

### 🟡 中等：設定檔權限控管過於寬鬆
- **位置**: `lib/services/app_settings_service.dart:25`
- **問題描述**: 設定檔（包含 Gemini API Key 等敏感資訊）存放在 `getApplicationSupportDirectory()` 建立的純文字設定檔中。在 Root 過的 Android 設備上可以輕易被其他惡意 App 讀取。
- **建議**: 所有 API Keys 與身份驗證憑證必須轉移至 `flutter_secure_storage`。

---

## 4. 性能 (Performance)

### 🟡 中等：Vector Store MMR 檢索效能瓶頸
- **位置**: `lib/services/vector_store.dart:272`
- **問題描述**: `searchMmr` 方法中，對於 `candidates` 計算 Max Similarity 使用了巢狀的 `fold` 與 `_cosine` 運算。當使用者的筆記或財務文件數量達到上萬個 Chunks 時，主執行緒 (Main Thread) 負載飆高，會造成顯著的 UI 卡頓 (掉幀)。
- **建議**: 將 `searchMmr` 與大量的 `_cosine` 運算透過 `compute()` 移至 Isolate 執行。

### 🟢 輕微：重複的 Widget Build
- **位置**: `lib/screens/personal_hub_screen.dart:85`
- **問題描述**: `PersonalHubScreen` 中使用了多個沒有 `const` 修飾的靜態 Widget (如 Padding, Text)。這會導致每次 Provider 發布狀態更新時，發生大量不必要的元件重繪。
- **建議**: 在編譯期加入 `const` 修飾符。

### 🟢 輕微：重複編譯正則表達式
- **位置**: `lib/services/text_chunker.dart:57`
- **問題描述**: `_splitParagraph` 函式內部每次呼叫都會重新建立 `RegExp` 物件。
- **建議**: 將 `RegExp` 宣告為 `static final` 以重用實例。

---

## 5. 寫法 (Syntax/Style)

### 🟢 輕微：過時的依賴寫法 (syncfusion 升級)
- **位置**: `pubspec.yaml:48`
- **問題描述**: 目前使用的是 `syncfusion_flutter_pdf: ^33.2.4`。雖然已有鎖定次要版本，但建議審視 Syncfusion 是否有更新的 LTS 版本以獲得更佳的解析效能與安全性。維持舊版本可能在未來 Flutter SDK 更新時產生兼容性警告。
- **建議**: 確認 Syncfusion 最新的版本並規劃升級計畫。

### 🟢 輕微：變數命名不一致
- **位置**: `lib/controllers/wealth_controller.dart:42`
- **問題描述**: 變數命名在駝峰式 (camelCase) 與底線 (snake_case) 之間混用，部分內部暫存變數未遵守 Dart linter 規範。
- **建議**: 統一使用 Dart 官方推薦的 camelCase 命名。

---

## 6. 簡化 (Simplification)

### 🟡 中等：冗長的型別轉換與防呆邏輯
- **位置**: `lib/services/vector_store.dart:45`
- **問題描述**: `embedding: (j['embedding'] as List? ?? const []).cast<num>().map((e) => e.toDouble()).toList()` 這段 JSON 解析程式碼過於冗長，且可讀性不佳。
- **建議**: 可以使用 `json_serializable` 套件自動生成序列化代碼，或自訂一個 Extension Method 來封裝這段邏輯。

### 🟢 輕微：不必要的非同步標記
- **位置**: `lib/services/pdf_service.dart:47`
- **問題描述**: `chunk` 方法不需要非同步操作，但被過度包裝。
- **建議**: 移除不必要的 `Future` 包裝，轉為單純的同步函式以節省 Event Loop 開銷。

---

## 7. 最佳實踐 (Best Practices)

### 🔴 嚴重：Test 鬆綁與跳過 (test 鬆綁)
- **位置**: `test/integration/rag_eval_runner_test.dart:76`
- **位置**: `test/integration/rrf_tuning_runner_test.dart:53`
- **問題描述**: 原始碼中存在多處 `skip: runIntegration` 或直接被 mark 為 `skip: true` 的測試案例。這種「Test 鬆綁」行為會讓 CI/CD 形同虛設。隨著專案複雜度上升，未被執行的整合測試等同於未來的技術債炸彈。
- **建議**: 重新評估被 skip 的測試。如果因為整合測試耗時或依賴真實 API 導致的不穩定 (Flaky Tests)，應將其拆分為純 `Unit Test`，或是配置獨立的 Mock Server，絕對不該直接跳過。

### 🟡 中等：UI 邏輯中出現硬編碼字串
- **位置**: `lib/screens/wealth_screen.dart:120`
- **問題描述**: UI 元件中存在大量硬編碼的中文標籤 (如 `'資產總覽'`、`'新增紀錄'`)。
- **建議**: 應整合至 `AppLocalizations` (`lib/l10n/app_zh.arb`) 進行統一語系管理，為未來的多國語系 (i18n) 預留空間。

---

## 8. 重構 (Refactoring)

### 🔴 嚴重：過於龐大的 Controller 職責不清
- **位置**: `lib/controllers/wealth_controller.dart:150`
- **問題描述**: `WealthController` 兼具了資料持久化 (VectorStore 讀寫操作)、商業邏輯 (NetWorth 趨勢計算)、以及狀態管理 (ChangeNotifier 觸發 UI 更新)。這嚴重違反了單一職責原則 (SRP)，使得未來的擴充與測試變得極度困難。
- **建議**: 應該進行三層架構重構：
  1. `WealthRepository`：專門負責 VectorStore 讀取與寫入。
  2. `WealthService`：專門負責匯率換算、資產統計與趨勢邏輯。
  3. `WealthViewModel`：單純負責將 Service 計算好的狀態綁定至 UI。

### 🟡 中等：Personal Rag Service 的相依性過強
- **位置**: `lib/services/personal_rag_service.dart:83`
- **問題描述**: `PersonalRagService` 內部硬編碼了 `kExpensesCollection` 與 `kContactsCollection` 等特定字串。若未來加入更多的個人模組（如筆記、行事曆），此服務必須不斷修改內部邏輯，違反了開閉原則 (OCP)。
- **建議**: 引入 Registry Pattern 或 Plugin 系統。讓各模組 (Health/Wealth/Expense) 在啟動時自行註冊對應的 Collection Name 與 Embedding Format 到統一的 Hub，達到真正的解耦。

---
> 統計總結：
> - 🔴 嚴重漏洞 / 架構問題：5 項
> - 🟡 中等風險 / 效能疑慮：7 項
> - 🟢 輕微建議 / 代碼風格：4 項
> - 涉及檔案數量：11 份檔案
> - 標記具體座標 (file:line)：17 個座標
