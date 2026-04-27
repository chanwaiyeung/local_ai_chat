# AI 語音圖書館 (local_ai_chat)

本地優先嘅 AI 對話應用，支援：
- 連接本地 Ollama 模型（離線、不上傳任何資料）
- 載入 PDF / TXT / Markdown 文件，自動建立向量索引（RAG）
- Windows 語音輸入
- 對話匯出為 Markdown
- 文件片段預覽 / 搜尋 / 揀選

---

## 一、前置安裝

### 1. Flutter SDK

到官方網站下載並安裝 Flutter（建議 3.16 或以上）：
<https://docs.flutter.dev/get-started/install/windows>

安裝完成後執行：

```powershell
flutter --version
flutter doctor
```

確保 `Windows`、`Visual Studio` 兩項冇 X（語音輸入需要 Windows 桌面 build chain）。

### 2. Visual Studio (Desktop development with C++)

執行 `flutter run -d windows` 一定要有 Visual Studio 2022 + 「Desktop development with C++」工作負載。`flutter doctor` 會提示。

### 3. Ollama

到 <https://ollama.com> 下載 Windows 版安裝。安裝後 Ollama 會自動以背景服務方式啟動。

確認服務啟動：

```powershell
ollama list
```

如果無回應，手動啟動：

```powershell
ollama serve
```

---

## 二、下載模型

最少要兩個：一個對話模型 + 一個 embedding 模型（俾 RAG 用）。

### 對話模型（揀其中一個）

```powershell
# 細小快速，2GB RAM 可跑（推薦低配機）
ollama pull gemma2:2b

# 中文較佳，需要 ~5GB RAM
ollama pull qwen2.5:7b

# 細小但中文唔錯，~3GB RAM
ollama pull llama3.2:3b
```

> 程式碼預設 `qwen2.5:7b`。如果未下載，App 會自動切換到第一個已下載嘅模型，亦可以喺 App AppBar 嘅下拉選單即時切換。

### Embedding 模型（必須）

```powershell
ollama pull nomic-embed-text
```

如果想中文檢索更準（但體積較大）：

```powershell
ollama pull bge-m3
```

要切換 embedding 模型，改 `lib/screens/chat_screen.dart` 入面 `_embedModel` 預設值。

---

## 三、執行 App

```powershell
cd local_ai_chat
flutter pub get
flutter run -d windows
```

第一次 build 可能要 1-3 分鐘（編譯原生 plugin）。之後 hot reload 會快好多。

---

## 四、使用流程

1. 啟動 App，AppBar 右上下拉應該見到已下載嘅模型
2. 按 📎 載入一份 PDF / TXT / MD（建議先試細份）
3. 等「索引完成」提示出現
4. 喺底下輸入問題，或按 🎙 用語音輸入
5. 答案會串流顯示，末尾自動列出引用片段
6. 工具列：
   - ✨ 開關 RAG（純聊天 vs 文件問答）
   - 📚 文件庫（預覽切塊、設定 Top-K、揀文件）
   - ⋮ → 匯出對話為 Markdown / 清除對話

---

## 五、常見問題

### Q1：跑起 App 後話「連接 Ollama 失敗」

**原因：** Ollama 服務未啟動。

**解決：**

```powershell
ollama serve
```

如果仍然失敗，確認 `http://localhost:11434` 喺瀏覽器打得開（會見到 `Ollama is running`）。

### Q2：模型下拉選單係空、或者答唔到嘢

**原因：** 未下載任何模型。

**解決：**

```powershell
ollama pull gemma2:2b
ollama pull nomic-embed-text
```

下載完返到 App 按 AppBar 嘅 🔄（或者重開）就會見到。

### Q3：PDF 載入後抽唔到文字 / 答案提到「文件似乎係空白」

**原因：** 該 PDF 係**掃瞄版**（即每一頁都係圖片，唔係真嘅文字），需要 OCR 先可以讀。

**目前限制：** 本 App **唔支援 OCR**。可以做嘅解決方法：

- 用其他工具（例如 Adobe Acrobat、ABBYY FineReader、或 macOS 預覽程式）將 PDF 做 OCR 後再上載
- 或者自己用 Python `pytesseract` / `paddleocr` 預先抽出文字，存成 `.txt` 再上載

如未來會內建 OCR，會用 Tesseract 或 PaddleOCR，但目前唔在 v1.0 範圍內。

### Q4：建立索引好慢

**原因：** Embedding 模型逐個片段算向量，CPU-only 機器一份 100 頁 PDF 可能要 1-3 分鐘。

**解決：**

- 確認 Ollama 用緊 GPU：`ollama ps` 應該見到 `processor` 顯示 `100% GPU`
- 用更細嘅 embedding 模型：`nomic-embed-text` 已經係細模型；如再嫌慢，可以自己改 `chunk maxChars` 到 1500 減少片段數量
- 第一次索引完之後會持久化到 `%APPDATA%/local_ai_chat/vector_store.json`，重啟 App 會自動載入毋須重做

### Q5：終端機出現 `file_picker` warning（例如 `MissingPluginException` 或 dart pad 相關訊息）

**原因：** `file_picker` 8.x 喺 Flutter desktop 啟動時偶有警告訊息（特別係第一次選檔案前），但實際功能正常。

**處理：** 可以忽略。實測：選檔案、儲存對話 dialog 都運作正常。如果擔心，可以喺發布前 `flutter clean && flutter pub get` 重 build。

### Q6：對話愈嚟愈多之後，AI 開始「失憶」或者答非所問

**原因：** v1.0 未啟用對話記憶壓縮（避免本地模型 RAM 唔夠時做雙重推理而 timeout）。當對話歷史接近模型 context window（通常 4K-8K tokens），早期訊息會被截斷。

**解決：**

- 工具列 ⋮ → 清除對話，重新開始一輪
- 或者用更大 context window 嘅模型（例如 `qwen2.5:7b` 預設 32K）
- v1.x 之後可能再加返自動壓縮，但需要更穩定嘅本地推理基建

### Q7：語音輸入按咗冇反應

**原因：**

- Windows 設定未開啟線上語音辨識
- 麥克風被其他 App 佔用
- 系統語音語言唔啱（預設 `zh-HK`，如系統只裝咗 `zh-CN` 會失敗）

**解決：**

1. 設定 → 時間和語言 → 語音 → 開啟「線上語音辨識」
2. 確保已下載中文語音套件
3. 必要時改 `lib/services/speech_service.dart` 嘅 `localeId` 預設值（`zh-CN` / `en-US`）

---

## 六、專案結構

```
local_ai_chat/
├── pubspec.yaml
├── README.md
└── lib/
    ├── main.dart
    ├── models/
    │   └── message.dart
    ├── services/
    │   ├── ollama_service.dart       # Ollama HTTP 客戶端（聊天 / 串流）
    │   ├── embedding_service.dart    # Ollama embedding API
    │   ├── vector_store.dart         # In-memory 向量庫 + JSON 持久化
    │   ├── rag_service.dart          # 智能切塊 / 檢索
    │   ├── pdf_service.dart          # PDF 文字抽取（Syncfusion）
    │   ├── speech_service.dart       # Windows 語音輸入
    │   └── export_service.dart       # 對話匯出 Markdown
    └── screens/
        ├── chat_screen.dart          # 主聊天介面
        └── doc_viewer_screen.dart    # 文件預覽 / 搜尋 / 揀片段
```

---

## 七、版本

**v1.0** — 穩定基線
- 本地 Ollama 對話（串流回覆）
- PDF / TXT / MD 文件 RAG
- 文件預覽同片段揀選
- Windows 語音輸入
- 對話匯出 Markdown

**已知限制：**
- 唔支援掃瞄版 PDF（無 OCR）
- 對話記憶不會自動壓縮
- 對話歷史不持久化（重啟即清）
- 只測試過 Windows 桌面，未測 macOS / Linux

---

## 八、隱私

所有對話、文件、向量都只係儲存喺**本機**（`%APPDATA%/local_ai_chat/`），唔會上傳任何雲端。Ollama 亦係完全離線運行。
