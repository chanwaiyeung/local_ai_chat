# 智讀館 RAG Engine — Schema v3 Specification

| Field | Value |
|---|---|
| Version | 3 |
| Status | Implemented in `lib/services/vector_store.dart`, wired in `lib/screens/chat_screen.dart:107` |
| Last verified | 2026-04-30 (post B-tail v2.0 promotion sweep) |
| Owner | RAG / Persistence layer |

## 1. Purpose

v1.x 的持久化只保存 dense embeddings，每次冷啟動都需要重新 tokenize 全庫並計算 BM25 統計量
（`chunkLengths` / `documentFrequency` / `termFrequency`）。當文檔規模成長後，這個重建成本
會在啟動時造成可感知的延遲。

Schema v3 將 BM25 sparse index 連同 chunks 一起持久化到 `vector_store.json`，啟動時直接讀檔
還原索引，跳過全庫 tokenize，達成「秒級冷啟動」。

## 2. 持久化路徑

實際檔案路徑由 `VectorStore._file()` 決定（`vector_store.dart:213-218`）：

```
${getApplicationSupportDirectory()}/local_ai_chat/vector_store.json
```

平台對應：

| OS | 解析路徑 |
|---|---|
| Windows | `C:\Users\<user>\AppData\Roaming\<bundle>\local_ai_chat\vector_store.json` |
| macOS | `~/Library/Containers/<bundle>/Data/Library/Application Support/local_ai_chat/vector_store.json` |
| Linux | `~/.local/share/<bundle>/local_ai_chat/vector_store.json` |

### 重要注意事項

- **不在專案資料夾內**。移動 `local_ai_chat/` 專案目錄不會帶動真實的 vector store 檔案。
  測試「全新冷啟動」狀態請手動刪除上述檔案。
- **headless Dart 不可用**。`getApplicationSupportDirectory()` 來自 `path_provider` package，
  依賴 Flutter binding。`bin/server.dart` 與 `bin/index.dart` 編譯雖通過，但 runtime 會
  throw `MissingPluginException`。此議題列入 v2.1 模組化重構待辦。

## 3. 檔案格式

**v3 是單一 JSON 文件，不是 NDJSON。** 寫入由 `VectorStore.save()` 處理
（`vector_store.dart:220-235`）：

1. 將完整 in-memory state 編碼為 JSON：
   `{ schemaVersion, embeddingModel, chunks[], sparseIndex? }`
2. 寫入 `vector_store.json.tmp`，`flush: true`
3. 若已存在 `vector_store.json` 則先 delete
4. `tmp.rename()` 為最終檔名（atomic 檔名置換，避免崩潰留下半寫狀態）

`sparseIndex` 為可選欄位——`save()` 只在 `_sparseIndex != null` 時才寫入
（`vector_store.dart:227`）。

## 4. 完整 JSON 範例

下面是「2 個 chunk、1 份文件」的最小 v3 payload：

```json
{
  "schemaVersion": 3,
  "embeddingModel": "bge-m3",
  "chunks": [
    {
      "id": "rag_concepts.md_0",
      "docName": "rag_concepts.md",
      "chunkIndex": 0,
      "text": "RAG combines retrieval with generation. Dense embeddings encode semantic meaning.",
      "embedding": [0.0124, -0.0381, 0.0072, "... 1024 dims total ..."]
    },
    {
      "id": "rag_concepts.md_1",
      "docName": "rag_concepts.md",
      "chunkIndex": 1,
      "text": "BM25 is a lexical retrieval algorithm. It scores documents by term frequency and inverse document frequency.",
      "embedding": [-0.0203, 0.0517, 0.0011, "... 1024 dims total ..."]
    }
  ],
  "sparseIndex": {
    "docCount": 2,
    "avgDocLength": 18.5,
    "chunkLengths": {
      "rag_concepts.md_0": 17,
      "rag_concepts.md_1": 20
    },
    "documentFrequency": {
      "rag": 2,
      "retrieval": 2,
      "dense": 1,
      "embedding": 1,
      "bm25": 1,
      "lexical": 1,
      "score": 1
    },
    "termFrequency": {
      "rag_concepts.md_0": {
        "rag": 1,
        "retrieval": 1,
        "dense": 1,
        "embedding": 1
      },
      "rag_concepts.md_1": {
        "bm25": 2,
        "lexical": 1,
        "retrieval": 1,
        "score": 1,
        "rag": 1
      }
    }
  }
}
```

## 5. 欄位規格

### Top-level

| Field | Type | Required | Semantics |
|---|---|---|---|
| `schemaVersion` | `int` | yes (v3+) | 版本標記，固定為 `3`。讀取時若 `< 3` 或缺失則觸發 migration |
| `embeddingModel` | `String?` | no | 產生 embeddings 的模型識別字（如 `bge-m3`）。日後可用於偵測模型升級需重建索引 |
| `chunks` | `List<DocChunk>` | yes | Dense embedding 索引主體 |
| `sparseIndex` | `SparseIndexSnapshot?` | no | BM25 持久化統計，缺失時 load 階段可選擇透過 `sparseIndexBuilder` 即時重建 |

### `chunks[]` element（`DocChunk`，`vector_store.dart:10-43`）

| Field | Type | Semantics |
|---|---|---|
| `id` | `String` | 唯一鍵，格式為 `${docName}_${chunkIndex}`。`sparseIndex.termFrequency` 與 `chunkLengths` 都用此 key |
| `docName` | `String` | 來源文件名 |
| `chunkIndex` | `int` | 在該文件內的順序 |
| `text` | `String` | 切塊原文 |
| `embedding` | `List<double>` | Dense vector（dimension 由 `embeddingModel` 決定） |

### `sparseIndex`（`SparseIndexSnapshot`，`vector_store.dart:51-97`）

| Field | Type | BM25 用途 |
|---|---|---|
| `docCount` | `int` | IDF 公式中的 N |
| `avgDocLength` | `double` | Length normalization 中的 avgdl |
| `chunkLengths` | `Map<String, int>` | 每個 chunk 的 token 數量（key = `chunk.id`） |
| `documentFrequency` | `Map<String, int>` | 每個 term 出現在多少 chunk 內（df） |
| `termFrequency` | `Map<String, Map<String, int>>` | 巢狀：`{chunk_id: {term: count}}`，提供 tf |

BM25 評分使用 `RagService.bm25RankWithIndex()`（`rag_service.dart:499-546`），公式參數
`k1 = 1.2`、`b = 0.75`。若 `sparseIndex` 為 null，會 fallback 到
`bm25Rank()`（`rag_service.dart:402-457`），即時 tokenize + 計算，較慢。

## 6. Read Path: `decodeSnapshot()` Migration Matrix

`decodeSnapshot()`（`vector_store.dart:266-318`）必須處理 4 種磁碟形狀，全部自動正規化為 v3
in-memory state，並在後續 `save()` 時以 v3 格式回寫：

| # | 磁碟輸入 | 處置 | 旗標 |
|---|---|---|---|
| 1 | `[ {...}, {...} ]`（純 List，最早期 ai_library_server lite NDJSON 殘餘） | 視為 chunks 陣列，無 `embeddingModel`、無 `sparseIndex` | `migratedFromLegacy=true`、`needsSparseIndexMigration=true` |
| 2 | `{ schemaVersion: 1\|2, ..., chunks: [...] }`（v2 風格） | 解析 chunks，沿用 `embeddingModel`，若有 `sparseIndex` 則保留 | `needsSparseIndexMigration = (schemaVersion < 3 \|\| sparseIndex == null)` |
| 3 | `{ ..., chunks: { value: [...] } }`（PowerShell `ConvertTo-Json` 包裝產生的 wrapper 形狀） | 從 `chunks.value` 解出實際 array | `migratedFromLegacy=true`、`needsSparseIndexMigration=true` |
| 4 | `{ schemaVersion: 3, ..., sparseIndex: {...} }`（正規 v3） | 直接使用 | 無 |

`load()`（`vector_store.dart:237-264`）後續處置：

```
1. decodeSnapshot() 給出 VectorStoreSnapshot {
     embeddingModel, chunks, sparseIndex?,
     needsSparseIndexMigration, migratedFromLegacy
   }
2. 套用到 in-memory state
3. 若 needsSparseIndexMigration && chunks 非空 && 呼叫端有傳入 sparseIndexBuilder：
     → 用 sparseIndexBuilder(chunks) 即時重建 SparseIndexSnapshot
4. 若 (migratedFromLegacy || needsSparseIndexMigration)：
     → 寫 DebugLogService 日誌
     → 立即呼叫 save() 把 v3 payload 回寫磁碟（in-place upgrade）
5. 任何 jsonDecode/decodeSnapshot 例外 → 視為「檔案損壞當冇」（line 261-263）
```

## 7. Wire-Up Requirements

Migration 自動重建只在呼叫端傳入 `sparseIndexBuilder` 時生效。以下是當前 active 程式碼的
連線狀況：

| 入口 | `load()` 呼叫形式 | sparseIndexBuilder 已連線？ |
|---|---|---|
| `lib/screens/chat_screen.dart:107` | `_store.load(sparseIndexBuilder: RagService.buildSparseIndex)` | yes |
| `lib/main.dart:60` | `await store.load();` | no |
| `bin/index.dart:41` | `await store.load();` | no（而且 path_provider runtime 失效） |
| `bin/server.dart:41` | `await store.load();` | no（同上） |

**結論**：Flutter app 主要互動路徑（chat screen）已正確連線。`lib/main.dart` 和 `bin/`
的 entrypoint 雖然編譯通過，但缺 builder 連線；不過這條路徑本來就有 path_provider
runtime 問題，需要 v2.1 一併處理。

每次 ingest 後的 sparse index 重新計算與持久化由 `RagService.ingestDetailed()`
（`rag_service.dart:151-233`）處理：

```dart
await store.replaceDoc(
  docName,
  nextChunks,
  sparseIndex: buildSparseIndex(indexedChunks),
);
```

`buildSparseIndex()`（`rag_service.dart:459-497`）即為 `SparseIndexBuilder` typedef
所要求的函式形狀：`SparseIndexSnapshot Function(List<DocChunk>)`。

## 8. Forbidden Changes（防退化清單）

下列變更**不得**在未經明確架構討論前套用，否則會破壞 v3 的容錯能力或啟動效能：

1. **不得移除 `decodeSnapshot()` 的 4 條 migration 分支**——尤其是 PowerShell wrapper
   `chunks.value` 那條，這是過往實際遇到的資料污染樣態。
2. **不得移除 `_decodeChunks()` 的 try/catch 略過 malformed 行為**
   （`vector_store.dart:320-334`）。少數 chunk 損壞不應該讓整個 vector store 載入失敗。
3. **不得改變 `save()` 的 atomic temp-rename 流程**——直接 `writeAsString(file.path)`
   會在崩潰時留下半寫檔案。
4. **不得移除 `replaceDoc()` 的 try/rollback 區塊**（`vector_store.dart:159-179`）。
   失敗時必須回退到 previous state。
5. **不得讓 `add()` / `addAll()` / `removeDoc()` 不再清空 `_sparseIndex`**
   （目前 line 132、137、156 都有 `_sparseIndex = null`）。否則修改後的 chunks 會
   配上過期的 BM25 索引，造成檢索結果錯亂。
6. **不得在 ingest 路徑（`ingestDetailed`）跳過 `buildSparseIndex(indexedChunks)`**
   ——會讓持久化檔案的 sparse index 與實際 chunks 不一致。
7. **不得把 schemaVersion 寫死成小於 3**——`save()` 必須維持輸出 v3。

## 9. 已知 Limitations / 後續工作

| # | 議題 | 計畫處置 |
|---|---|---|
| L1 | `bin/server.dart` headless 環境 path_provider runtime 失效 | v2.1 模組化重構：抽出 `StorageBackend` interface，Flutter 端用 path_provider，headless 端用顯式檔路徑 |
| L2 | `embeddingModel` 升級偵測未實作 | 載入時若 `embeddingModel` 與當前 `EmbeddingService.model` 不一致應該警告或強制重 ingest，目前只記錄 |
| L3 | 整份 JSON 一次寫入，大型書庫（10k+ chunks）寫入時會有可感知延遲 | v2.2 之後考慮分段寫入或 SQLite backend |
| L4 | 13 個 test 檔案仍引用舊的 `Chunk` 型別 | 已封存，待獨立的 test rename sprint 處理 |

## 10. References

| 檔案 | 行 | 內容 |
|---|---|---|
| `lib/services/vector_store.dart` | 10-43 | `DocChunk` 類別 |
| `lib/services/vector_store.dart` | 51-97 | `SparseIndexSnapshot` 類別 + `toJson` / `fromJson` |
| `lib/services/vector_store.dart` | 99-100 | `SparseIndexBuilder` typedef |
| `lib/services/vector_store.dart` | 102-116 | `VectorStoreSnapshot` 包裝（含 migration flags） |
| `lib/services/vector_store.dart` | 119-198 | `VectorStore` 主體（in-memory state + getters + mutators） |
| `lib/services/vector_store.dart` | 213-218 | `_file()` — 持久化路徑解析 |
| `lib/services/vector_store.dart` | 220-235 | `save()` — atomic write |
| `lib/services/vector_store.dart` | 237-264 | `load()` — read + migration trigger |
| `lib/services/vector_store.dart` | 266-318 | `decodeSnapshot()` — 4-shape migration matrix |
| `lib/services/vector_store.dart` | 320-334 | `_decodeChunks()` — 跳過 malformed 容錯 |
| `lib/services/rag_service.dart` | 79 | `RagService.lastDiagnostics` 欄位（per-query trace，**不是**持久化目標） |
| `lib/services/rag_service.dart` | 218-222 | `replaceDoc(..., sparseIndex: buildSparseIndex(...))` ingest persistence |
| `lib/services/rag_service.dart` | 459-497 | `buildSparseIndex()` — 即 `SparseIndexBuilder` 實作 |
| `lib/services/rag_service.dart` | 499-546 | `bm25RankWithIndex()` — 使用持久化 sparse index 的快速路徑 |
| `lib/screens/chat_screen.dart` | 107 | `_store.load(sparseIndexBuilder: RagService.buildSparseIndex)` 連線點 |

## 11. 概念校正紀錄

本規格書取代並修正下列過往討論中常見的誤解：

- **「v3 是 NDJSON 格式」** — 錯。v3 是單一 JSON 文件。NDJSON 是被淘汰的
  ai_library_server lite 格式。
- **「TF/IDF 數據儲存在 `RagService.lastDiagnostics`」** — 錯。`lastDiagnostics` 是
  `RagSearchDiagnostics`（per-query trace，含 `semanticHits` / `keywordHits` /
  `fusedHits`），每次 `retrieve()` 重置，不持久化。TF/IDF 統計在
  `VectorStore.sparseIndex` 上，型別為 `SparseIndexSnapshot`。
- **「需要設計 Schema v3」** — 錯。v2.0 promotion 已完整實作 v3。當前任務是
  documentation + regression test（A1-A4），不是 design。
