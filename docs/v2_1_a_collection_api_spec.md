# 智讀館 — v2.1-A Multi-Document Collection API Specification (DRAFT)

| Field | Value |
|---|---|
| Status | **DRAFT** — 多項設計決策待人工裁示（見 §11） |
| Author | Drafted in session preceding C: → D: physical migration |
| Companion docs | `docs/v2_schema_v3_spec.md`（v3 持久化基礎）、`docs/v2_namespace_alignment.md`、`docs/v2_test_rename_sprint.md`、`docs/v2_migration_to_d_drive.md` |
| Target version | v2.1.0 |
| Foundation | v2.0 GA（Schema v3 持久化已 lock，integration test +5 全綠 2026-04-30） |

## 1. Motivation

v2.0 的檢索 API 只支援兩種 doc-pool 形狀：

```dart
RagService.retrieve(query, docName: null)         // 全庫
RagService.retrieve(query, docName: 'a.pdf')      // 單一文件
```

但實際使用「智讀館」的場景常需要**邏輯分組的子集合**：

- 「我的論文集」（5-20 篇 PDF）
- 「Linux 命令參考」（man pages + 教學書）
- 「公司內部文件」（policies + handbooks）

目前要做這類檢索，呼叫端只能：
- 對每個 doc 各跑一次 retrieve，再人工合併（語義上不對 BM25——IDF 統計被打散）
- 或退回全庫檢索，讓不相關的 doc 噪音稀釋結果

v2.1-A 引入 `Collection` 概念：**一個由複數 `docName` 組成的邏輯群組**，可以做為 retrieve 的 scope。

## 2. Goals & Non-Goals

### Goals

- 在 v3 持久化基礎之上加 `Collection` 第一級概念，不破壞現有 single-doc / 全庫 retrieve 路徑
- BM25 統計量（IDF / avgDocLength）必須**以 collection 為範圍**計算，否則檢索品質會被全庫雜訊污染
- 利用 v3 已持久化的 `SparseIndexSnapshot` 達成 collection-level 增量更新，不重新 tokenize
- 與現有 `chat_screen.dart` UX 整合：使用者能在 UI 切換 collection scope

### Non-Goals (v2.1-A scope cut)

- **跨 collection 查詢**（例如「在『論文』和『教科書』兩個 collection 中找答案」）——v2.2 再考慮
- **Collection 階層**（巢狀 collection / 標籤）——KISS，留待產品數據驗證需求後再做
- **權限 / 共享**——智讀館目前是 single-user local app，不需要
- **跨機器同步**（collections 跟著 vector_store.json 一起持久化即可）

## 3. 使用情境

```dart
// 建立 collection
final research = await collectionStore.create(
  name: '研究論文',
  docNames: {'paper_a.pdf', 'paper_b.pdf', 'survey_2024.pdf'},
);

// 加入新文件（觸發增量更新而非全量重算）
await collectionStore.addDoc(research.id, 'paper_c.pdf');

// Collection-scoped retrieve
final hits = await ragService.retrieveInCollection(
  '注意力機制的演化',
  collection: research,
  k: 6,
  mode: RetrievalMode.hybrid,
);

// 列出所有 collection
final all = await collectionStore.list();

// 刪除（不刪 chunks，只刪 collection 本身）
await collectionStore.delete(research.id);
```

## 4. Data Model

### 4.1 `Collection` 類別

```dart
class Collection {
  Collection({
    required this.id,
    required this.name,
    required this.docNames,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 不可變唯一識別。建議用 UUID v4 而非 hash(docNames)，
  /// 因為 hash-based id 會在 docNames 變動時改變，
  /// UI 與 history 的引用會斷掉。
  final String id;

  /// 使用者可見的標籤，可重複可改名。
  final String name;

  /// Set 而非 List — 順序無語義，避免重複。
  final Set<String> docNames;

  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson();
  factory Collection.fromJson(Map<String, dynamic> j);
}
```

### 4.2 `CollectionSparseSnapshot`（增量快取，可選）

如果決定走 §8 Option C（per-collection precomputed snapshot），需要這個型別：

```dart
class CollectionSparseSnapshot {
  /// 對應的 collection.id
  final String collectionId;

  /// Collection 範圍內的 BM25 統計量（不是全庫的）
  final int docCount;
  final double avgDocLength;
  final Map<String, int> documentFrequency;

  /// 從上次計算到現在被加入/移除的 docNames（用於增量更新觸發）
  final Set<String> staleDocNames;

  /// 上次重建時間
  final DateTime computedAt;
}
```

## 5. Storage Schema 決策（待定）

兩個方向，請選一：

### Option A：**將 collections 併入 v4 schema**

把 `vector_store.json` schema 升到 v4，新增 `collections` 與（可選）`collectionSparseSnapshots` top-level 欄位：

```json
{
  "schemaVersion": 4,
  "embeddingModel": "bge-m3",
  "chunks": [...],
  "sparseIndex": {...},
  "collections": [
    {
      "id": "01HW...",
      "name": "研究論文",
      "docNames": ["paper_a.pdf", "paper_b.pdf"],
      "createdAt": "2026-04-30T...",
      "updatedAt": "2026-04-30T..."
    }
  ],
  "collectionSparseSnapshots": [...]   // 可選，見 §8 Option C
}
```

優點：所有 RAG 狀態在一個檔案、原子寫入保證、migration 沿用 `decodeSnapshot()` 模式。
缺點：collections 變動會觸發整份 vector_store.json 重寫（可能 10MB+）。

### Option B：**Collections 獨立檔案**

`vector_store.json` 維持 v3，另外開：

```
${getApplicationSupportDirectory()}/local_ai_chat/collections.json
${getApplicationSupportDirectory()}/local_ai_chat/collection_sparse/${collectionId}.json
```

優點：collections 寫入成本與 vector_store 解耦；單一 collection 的 sparse snapshot 各自獨立檔案，容易 invalidate。
缺點：兩份檔案的一致性需要應用層保證（例如 collections 引用了已被 `removeDoc()` 移除的 docName）。

**建議**：Option A 起手，Option B 等 collections 數量或 sparse snapshot 大小有實證壓力時再切。原因：v3 已經把整份 JSON atomic write 寫得很穩，不要過早分檔引入一致性 bug。

## 6. VectorStore API 增量

新增 method（不影響既有簽名）：

```dart
/// 取得 collection 內所有 chunks，按 docName 然後 chunkIndex 排序
List<DocChunk> chunksOfCollection(Set<String> docNames);

/// Collection-scoped dense retrieval
List<ScoredChunk> topKInCollection(
  List<double> query, {
  required Set<String> docNames,
  int k = 4,
});
```

兩者都是現有 `chunks` getter 上的 filter，**不需要改 schema、不需要改 save/load**。實作 ~10 行。

## 7. RagService API 增量

新增 method：

```dart
Future<List<ScoredChunk>> retrieveInCollection(
  String query, {
  required Collection collection,
  int k = 4,
  double minScore = 0.0,
  RetrievalMode mode = RetrievalMode.hybrid,
  RrfConfig rrfConfig = const RrfConfig(),
  // 與既有 retrieve() 保持一致的 advanced flags
  bool useQueryExpansion = false,
  bool detectAmbiguous = false,
  bool enableMultiHop = false,
  bool enableLongContext = false,
  bool enableDeepLongContext = false,
}) async;
```

內部實作要在 `retrieve()` 的 cosine + BM25 + RRF 三條路徑都加 collection 過濾。Multi-hop / long-context 兩個 advanced 路徑遞迴呼叫時要繼承 collection 約束。

## 8. BM25-in-Collection 演算法決策（**核心待定**）

這是 v2.1-A 最關鍵的設計選擇。三個選項，各有取捨：

### Option 8A：On-the-fly subset IDF 重算

```
查詢時：
  1. 從全庫 sparseIndex.termFrequency 過濾出 collection 內的 chunk IDs
  2. 重新統計 documentFrequency(term) over 這個子集合
  3. 用 |collection chunks| 作為 N，重算 IDF
  4. 套 BM25 公式
```

成本：每查詢 O(|collection_chunks| × avg_terms_per_chunk) ≈ O(collection_size × ~50)。
優點：IDF **完全準確**反映 collection 的詞彙分佈、無一致性 bug、**零額外儲存**。
缺點：每查詢有計算開銷。1000 chunks 的 collection 估測 < 5ms，2-5 萬 chunks 的 collection 估 50-200 ms。

### Option 8B：使用全庫 IDF，只過濾 chunks

```
查詢時：
  1. 過濾 chunks 為 collection 子集
  2. IDF 直接用全庫 sparseIndex.documentFrequency / docCount
  3. avgDocLength 也用全庫的
  4. 套 BM25 公式
```

成本：每查詢 O(|collection_chunks|)，幾乎是 8A 的 1/avg_terms 倍。
優點：最快、實作最簡單。
缺點：**IDF 被 collection 外的 docs 污染**——同一個 query term 在「論文集」可能很常見、在全庫卻罕見，會被誤判為高 IDF 高權重。檢索品質明顯不如 8A。

### Option 8C：Per-Collection precomputed `CollectionSparseSnapshot`（增量更新）

```
當 collection.docNames 變動：
  1. 從全庫 sparseIndex 取出新增/移除的 chunks 的 termFrequency
  2. 增量更新該 collection 的 documentFrequency / docCount / avgDocLength
  3. 持久化 CollectionSparseSnapshot
查詢時：
  1. 過濾 chunks 為 collection 子集
  2. 用 CollectionSparseSnapshot 的 IDF（與 8A 等價，但不重算）
  3. 套 BM25 公式
```

成本：建立/變動時 O(|delta_chunks|)，查詢時 O(|collection_chunks|)。
優點：查詢成本 = 8B 級別、品質 = 8A 級別、收編使用者「**增量更新**」的訴求。
缺點：實作複雜（要維護一致性：如果 chunk 從全庫被刪除，相關 collection 的 snapshot 也要失效）；增加 storage。

**建議**：

- v2.1-A **首發走 Option 8A**（最簡、品質最佳、無新 schema 風險）
- 若觀察到大型 collection（10k+ chunks）查詢 latency 不可接受，**v2.1-B 升級到 8C**
- **不**走 8B——品質不可妥協，這是智讀館的核心價值

## 9. 增量更新策略（建立在 Option 8A 之上）

即使選 8A（on-the-fly），仍可以在「**collection 成員變動**」時做點優化：

| 事件 | v2.1-A 處置 | v2.1-B（Option 8C 升級時） |
|---|---|---|
| `collection.addDoc(docName)` | 只更新 `collection.docNames` 與 `updatedAt`，不動其他 | 額外更新 CollectionSparseSnapshot delta |
| `collection.removeDoc(docName)` | 同上 | 同上 |
| `vectorStore.removeDoc(docName)` | 觸發**所有引用此 docName 的 collection** 移除該成員（cascade） | 同左 + 對應 snapshot 失效 |
| `vectorStore.replaceDoc(docName, newChunks)` | 不影響 collection 成員（仍是同一 docName），但新 chunks 自動進入 BM25 計算範圍 | 同左 + collection snapshot 部份失效（含此 docName 的條目） |
| `vectorStore.clear()` | 全部 collection 一併清空（cascade） | 同左 |

**Cascade 規則由 `VectorStore.removeDoc()` / `clear()` 主動觸發 `CollectionStore.onChunkRemoval()` callback**，避免應用層忘記同步而留下指向不存在 docName 的 dangling collection。

## 10. Migration 計畫

### 10A: Option A schema（v4 bump）路線

`decodeSnapshot()` 增加 5 種輸入形狀（在 v3 的 4 種之外）：

| # | 磁碟輸入 | 處置 |
|---|---|---|
| 1-4 | v3 的既有 4 種形狀 | 維持原行為 + `collections: []`（空集合） |
| 5 | `{ schemaVersion: 4, ..., collections: [...] }` | 直接使用 |

跑過一次 `save()` 後，所有 v3 檔案會被 in-place 升級到 v4。**不破壞 §8 Forbidden Changes**——v3 spec 的容錯邏輯全部保留，只是多了 v4 分支。

### 10B: Option B schema（獨立 collections.json）路線

不需要動 vector_store.json，但需要：
- 新增 `CollectionStore` 類別管理獨立檔案
- 啟動時若 collections.json 不存在 → 視為「沒有任何 collection」
- 任何 cascade 規則由 `RagService` 或 application 層協調 `VectorStore` 與 `CollectionStore`

## 11. ❗ 待人工裁示的開放決策

| # | 決策 | 預設方向（建議） |
|---|---|---|
| D1 | Schema A vs B | A（合一）——除非預計 collections 變動頻率 >> chunks 變動 |
| D2 | BM25 演算法 | 8A（on-the-fly subset IDF）——除非有性能實證需求 |
| D3 | Collection.id 來源 | UUID v4（不要 hash docNames，會在編輯時斷掉 history reference） |
| D4 | 同一 doc 是否可在多 collection | 是（最自然的 mental model） |
| D5 | 空 collection 行為 | `retrieveInCollection(empty)` 回 `[]`，不 throw |
| D6 | UI 整合範圍 | v2.1-A 先寫 backend + 1 個 settings 頁列表；chat screen 切換 scope 在 v2.1-B |
| D7 | Cascade 是否 sync | 是（同步觸發，不要 async event；避免並發查詢看到不一致狀態） |

請在開始 implementation 前對 D1-D7 給出明確選擇，我（或新 session 的 Claude）會根據選擇調整本 spec 後再動工。

## 12. Edge Cases

| 情境 | 預期行為 |
|---|---|
| Collection 引用了 vectorStore 沒有的 docName | retrieveInCollection 跳過該 docName，不 throw（log warning 即可） |
| Collection.docNames 為空 set | retrieveInCollection 回 `[]` |
| Collection.id 衝突（不應該發生） | 第二個 create 拋 `StateError` |
| 同一個 chunk 同時屬於多個 collection 的查詢 | 各自獨立計算 BM25 score，無 cross-talk |
| `collection.addDoc(...)` 後立即查詢 | 看到新成員（無 stale read，因為 8A 是即時計算） |
| Schema v2 升級時，collections 視為空集合 | 由 `decodeSnapshot()` 在 migration 階段補空 list |

## 13. 測試計畫

新增 `test/integration_v2_1_collection_test.dart`，目標 PASS clauses：

1. `create + addDoc + retrieveInCollection` 行為正確
2. BM25 IDF 在 collection 範圍內計算（與全庫 IDF 不同）—— 用構造好的 fixture 直接斷言 score
3. `vectorStore.removeDoc()` cascade 正確移除 collection 成員
4. Migration: 從 v3 載入無 collections 的檔案 → in-memory 為空 → save() 後磁碟成 v4 + `collections: []`
5. 並發保護：兩個查詢同時在 add/remove 之間穿插，不應該看到 inconsistent IDF
6. 空 collection / 不存在 docName / 重複 docName 等邊界

## 14. References

- v3 持久化基礎：`docs/v2_schema_v3_spec.md`
- 現有 BM25 實作：`lib/services/rag_service.dart:402-546`
  （`bm25Rank`、`buildSparseIndex`、`bm25RankWithIndex`）
- 現有 SparseIndexSnapshot：`lib/services/vector_store.dart:51-97`
- 既有 retrieve API：`lib/services/rag_service.dart:236-377`
- 整合測試模式（path_provider mock）：`test/integration_v3_persistence_test.dart`

## 15. Honest Notes

- **`onProgress` 名稱**：v3 sprint 收尾時 `_DeterministicEmbedder.embedAll()` 漏蓋 `onProgress` named param 是 Claude 寫測試時的疏失，由 Albert 在跑 `flutter test` 時發現並修補。不是 v2.1-A 的前置設計，但 v2.1-A 寫 collection 的 ingest 進度條時會大量用到這個 callback，所以「事後看起來像規劃」。這個誠實留給未來。
- **本 spec 為 DRAFT**，§11 七個決策未拍板前不要開始 implementation。新 session 的 Claude 應先針對 §11 與你討論，再產出 implementation plan。
