# Final AI Work Integration Status

This file consolidates the work produced across the recent AI review/debug
rounds. It is the current source of truth for what has been implemented,
verified, rejected, and still pending.

## Current Stage

```text
v1.10.4 code hardening: complete
v1.10.4 quantitative release lock: complete from user-provided baseline snapshot
v2.0: not started
```

## Automated Verification

Latest expected validation:

```text
flutter analyze: pass, 0 issues
flutter test -r expanded: 79 tests passed
flutter build windows --release: success
```

## Implemented In Code

### RAG Retrieval

- `RetrievalMode`: dense / sparse / hybrid.
- Hybrid retrieval uses semantic search + BM25 + RRF.
- BM25 expands query terms only; document TF/DF uses original document terms.
- `RagService.retrieve()` resets `lastDiagnostics` on every call.
- Empty store returns empty hits with empty diagnostics.
- Missing `activeDoc` returns empty hits without calling embedding.
- Regression tests cover sparse no-embedding, empty diagnostics, missing activeDoc,
  hybrid diagnostics, and BM25 expansion isolation.

### Ingest Safety

- `RagService.ingest()` remains a backwards-compatible `Future<int>` wrapper.
- `RagService.ingestDetailed()` returns `IngestResult`.
- Ingest supports:
  - batch embedding via `EmbeddingService.embedAll()`
  - progress callback
  - cancellation
  - rollback-safe document replacement through `VectorStore.replaceDoc()`
- Tests cover cancellation and rollback on save failure.

### Vector Store

- Current schema: v2.
- Stores `embeddingModel`.
- Supports legacy list snapshots.
- Supports accidental PowerShell `chunks.value` wrapper shape.
- Skips malformed chunk entries instead of dropping the whole store.
- Logs and normalizes legacy/malformed snapshots back to schema v2.
- Uses atomic temp-file save.

### Embedding Service

- Uses Ollama `/api/embed` batch endpoint when available.
- Falls back to legacy `/api/embeddings`.
- Legacy fallback uses bounded parallelism.
- HTTP client is injectable for tests.
- Tests cover batch, fallback, wrong shape, concurrency cap, and server errors.

### Citation / DocViewer

- Markdown citation links are parsed through `citation_parser.dart`.
- DocViewer supports initial chunk index, scroll, and highlight.
- Citation opens and library opens have separate debug logs.
- Widget regression test covers initial chunk highlight.

### UI / Maintainability

- `RagChatController` now owns embedding-service and RAG-service rebuilding
  decisions while `ChatScreen` keeps UI state and logging.
- Ingest batch size increased from 1 to 4 for better `/api/embed` throughput.
- Cantonese/Chinese conversational stopwords were expanded for keyword
  extraction.
- Chat UI widgets extracted:
  - `chat_app_bar.dart`
  - `chat_app_bar_actions.dart`
  - `chat_session_drawer.dart`
  - `chat_input_bar.dart`
  - `chat_message_bubble.dart`
  - `chat_ingest_status_bar.dart`
  - `chat_library_sheet.dart`
  - `rag_context_banner.dart`
  - `top_k_picker.dart`
- RAG evaluation UI widgets extracted:
  - `rag_eval_editor.dart`
  - `rag_eval_record_card.dart`
- `chat_screen_refactor_plan.md` documents future behavior-preserving
  controller extraction.

## Implemented As Documentation / Guardrails

- `ai_patch_reconciliation_ingest.md`
  - Explains why older full-file ingest/vector-store snippets must not be
    applied.
- `three_ai_recommendation_integration.md`
  - Consolidates accepted/rejected/deferred recommendations.
- `v1_10_4_release_lock.md`
  - Defines the gate for release commit/tag.
- `eval_baseline_input.md`
  - Provides the 13-case manual baseline input set.

## Explicitly Rejected Older Patch Paths

Do not apply patches that:

- replace `VectorStore` with a temp-directory stub
- remove schema v2
- remove legacy/malformed snapshot recovery
- remove `RetrievalMode`
- remove diagnostics reset
- call embedding when selected activeDoc has no chunks
- replace typed `EmbeddingService.embedAll()` with dynamic `embedBatch` probing
- change `RagService.ingest()` from `Future<int>` without updating all call
  sites/tests

## Baseline Snapshot

The baseline snapshot exists at:

```text
docs/eval_snapshots/eval_baseline_v1.10_bgem3_hybrid_2026-04-28.json
```

Summary:

```text
Embedding: bge-m3
Retrieval: hybrid
Documents: README.txt + DOSBox 0.74 Manual.txt
Cases: 13
Result: 12 PASS / 1 PARTIAL / 0 FAIL
Score: 12.5 / 13
Pass rate: 96.2%
```

Next required action: commit and tag `v1.10.4`, then create the v2.0 branch.

## Validation Commands

```powershell
& "C:\src\flutter\flutter\bin\flutter.bat" analyze
& "C:\src\flutter\flutter\bin\flutter.bat" test -r expanded
& "C:\src\flutter\flutter\bin\flutter.bat" build windows --release
```
