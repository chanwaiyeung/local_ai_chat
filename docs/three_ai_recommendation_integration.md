# Three-AI Recommendation Integration

This document consolidates the overlapping recommendations from ChatGPT,
Claude, and Copilot-style reviews into one current engineering decision record.

## Current Baseline

Latest verified state:

- `flutter analyze`: pass
- `flutter test -r expanded`: 73 passed
- `flutter build windows --release`: pass

Current stage:

```text
v1.10.3 = retrieval hardening + activeDoc safety
```

## Integrated Decisions

### Accepted And Implemented

#### RAG ingest hardening

Accepted:

- batch embedding
- cancellation checks
- progress callback
- structured `IngestResult`
- no destructive replacement until new chunks are ready
- rollback on save failure

Implemented as:

- `RagService.ingestDetailed()`
- backwards-compatible `RagService.ingest()`
- `VectorStore.replaceDoc()`
- tests in `test/rag_service_test.dart`,
  `test/rag_ingest_cancel_test.dart`, and
  `test/rag_ingest_atomic_test.dart`

#### Retrieval quality and diagnostics

Accepted:

- hybrid retrieval with dense + BM25 + RRF
- `RetrievalMode` setting: dense / sparse / hybrid
- reset diagnostics on every retrieve call
- avoid embedding call when active document has no chunks
- fix BM25 over-expansion by expanding query terms only

Implemented as:

- `RagService.retrieve()`
- `RagSearchDiagnostics`
- `RetrievalMode` in `AppSettings`
- tests in `test/rag_service_test.dart`

#### Vector store persistence hardening

Accepted:

- schema v2 persistence
- embedding model tracking
- legacy snapshot support
- malformed chunk skip
- migration/normalization log
- atomic temp-file save

Implemented as:

- `VectorStore.decodeSnapshot()`
- `VectorStoreSnapshot.migratedFromLegacy`
- `VectorStore.save()`
- `VectorStore.load()`
- tests in `test/vector_store_test.dart`

#### Citation and DocViewer UX

Accepted:

- citation deep-link parsing
- DocViewer scroll-to-chunk
- temporary highlight
- separate logs for citation-open and library-open

Implemented as:

- `citation_parser.dart`
- `DocViewerScreen`
- `ChatScreen._openDocViewer()`
- tests in `test/citation_link_test.dart`

#### Embedding service performance

Accepted:

- use `/api/embed` batch endpoint when available
- fallback to legacy `/api/embeddings`
- cap fallback concurrency
- injectable HTTP client for tests

Implemented as:

- `EmbeddingService.embedAll()`
- tests in `test/embedding_service_test.dart`

## Explicitly Rejected

Do not apply older snippets that:

- replace current `VectorStore` with a temporary directory stub
- remove schema v2 fields
- remove migration compatibility
- remove `RetrievalMode`
- remove `lastDiagnostics`
- make `retrieve()` call embedding for a missing active document
- use dynamic `embedBatch` reflection instead of the current typed `embedAll()`
- change the public `ingest()` wrapper from `Future<int>` to `IngestResult`
  without updating all call sites and tests

Reason: those snippets are older than the currently tested code and would
regress production behavior.

## Deferred To v2.0

These are good ideas, but should not be mixed into v1.10.x hardening:

- persisted BM25 index / schema v3
- per-chunk embedding model metadata
- configurable BM25 / RRF weights
- domain-specific synonym config
- reranker support
- multi-file batch ingest queue
- quantitative dense vs sparse vs hybrid comparison

## Manual Gap

The only major unresolved item is process, not code:

```text
RAG quantitative baseline has not been manually run.
```

Use:

- `docs/eval_baseline_input.md`
- release app: `build\windows\x64\runner\Release\local_ai_chat.exe`

Do not update release notes with pass-rate claims until an exported snapshot
exists under `docs/eval_snapshots/`.

## Recommended Next Task For A New AI

Safe task:

```text
Run manual baseline evaluation, export JSON, then update release notes with
actual pass/fail/unsure counts.
```

Code task, if manual UI is unavailable:

```text
Add tests only. Do not change RAG retrieval behavior without a baseline.
```

## Verification Commands

Run from `C:\dev\local_ai_chat`:

```powershell
& "C:\src\flutter\flutter\bin\flutter.bat" analyze
& "C:\src\flutter\flutter\bin\flutter.bat" test -r expanded
& "C:\src\flutter\flutter\bin\flutter.bat" build windows --release
```
