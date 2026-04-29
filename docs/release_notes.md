# Release Notes

## v2.0.0 — General Availability (2026-04-28)

**Status**: Released.

### Summary

- Based on v2.0-rc1.
- No release blockers.
- Dataset v2 (45 cases): **100.0%**.
- Original 13 cases: 12 PASS / 1 PARTIAL / 0 FAIL.
- Tests: 101 passed, 4 skipped.

### Key Features

- Persisted BM25 with schema v3.
- Hybrid retrieval (dense + BM25 + RRF).
- Auto Evaluation Runner.
- Ambiguous Query Handling (experimental).
- Multi-hop Reasoning (experimental).
- Long Context Optimization (experimental).

### Validation

- `flutter analyze`: PASS.
- `flutter test -r expanded`: 101 passed.
- Windows release build: PASS.

This is the first General Availability release of v2.0.

## v2.0 RC1 — Production Ready Candidate (2026-04-28)

Status: Release Candidate.

### Highlights

- Dataset v2 (45 cases): **100.0%** pass rate.
- Original 13 cases: 12 PASS / 1 PARTIAL / 0 FAIL.
- All experimental features reviewed and documented.
- No release blockers.

### Promoted to Default (Recommended)

- Persisted BM25 with schema v3.
- Auto Evaluation Runner.
- Ambiguous Query Handling.
- Multi-hop Reasoning.
- Long Context Optimization.

### Experimental (Not yet promoted)

- Query Expansion.
- RRF Grid Tuning.

### Validation

- `flutter analyze`: PASS.
- `flutter test -r expanded`: 101 passed.
- Integration tests: PASS.
- Windows release build: PASS.

## v2.0 RC — Production Readiness Lock

Status: Production Ready Candidate.

### Summary

- Dataset v2 (45 cases): 100.0%.
- Original 13 cases: 12 PASS / 1 PARTIAL / 0 FAIL.
- Tests: 100+ passed.
- Release blockers: None.

### Recommended for Production Default

- Persisted BM25 (schema v3).
- Auto Evaluation Runner.
- Ambiguous Query Handling.
- Multi-hop Reasoning.
- Long Context Optimization.

### Experimental (Not Promoted)

- Query Expansion.
- RRF Grid Tuning.

### Validation

- `flutter analyze`: PASS.
- `flutter test -r expanded`: PASS.
- Integration tests: PASS.
- Windows release build: PASS.

## v2.0 Phase 1 — Persisted BM25 Index

Status: accepted.

### Phase 3A — Query Expansion Experimental Evaluation

Status: evaluated, not merged to default.

- Added experimental sparse-query expansion behind `useQueryExpansion`.
- Deterministic synonym-based query expansion for BM25.
- Production default remains unchanged: `useQueryExpansion = false`.
- Result: 12 PASS / 1 PARTIAL / 0 FAIL, pass rate 96.2%.
- Difference vs baseline: 0%.
- Regression: none.
- Decision: do not change production default because improvement is below the
  2% threshold.

### Phase 3B — RRF Weight Tuning Evaluation

Status: evaluated, not merged to default.

- Added offline RRF tuning runner (`test/eval/rrf_tuning_runner.dart`).
- Grid search completed (rrfK, denseWeight, sparseWeight).
- Best config:
- rankConstant: 60
- semanticWeight: 0.3
- keywordWeight: 0.7
- Result: 96.2% pass rate.
- Difference vs baseline: 0%.
- Regression: None.
- Decision: Do not change production default.

### Phase 1.2 Automated Evaluation Runner

- Added reusable 13-case RAG evaluation cases under `test/eval/`.
- Added `RagEvalRunner` for automated snapshot generation, summary scoring,
  follow-up case handling, and v1.10.4 comparison metadata.
- Added an integration-tagged baseline test:
  `test/integration/rag_eval_runner_test.dart`.
- Integration execution is opt-in with `RUN_RAG_EVAL_INTEGRATION=1` so normal
  CI does not depend on a local Ollama server or user vector store.
- Automated snapshot:
  `docs/eval_snapshots/eval_v2_persisted_bm25_auto_2026-04-28.json`.
- Automated result: 12 PASS / 1 PARTIAL / 0 FAIL, 96.2%.

### Added

- `VectorStore` schema v3 with `SparseIndexSnapshot`.
- Persisted BM25 index storing term frequency, document frequency, and chunk
  lengths.
- `RagService.buildSparseIndex()` and `RagService.bm25RankWithIndex()`.
- Automatic v2/legacy migration path through sparse-index rebuild on load.
- Runtime fallback to dynamic BM25 when no persisted sparse index is available.
- Regression coverage for schema v3 decode, migration flags, indexed BM25
  ranking, persisted sparse retrieval, and rollback behavior.

### Validation

- `flutter analyze`: pass, 0 issues.
- `flutter test -r expanded`: pass, 85 tests.
- `flutter build windows --release`: pass.

### Quantitative Baseline Comparison

- v1.10.4 dynamic BM25: 12 PASS / 1 PARTIAL / 0 FAIL, 96.2%.
- v2.0 persisted BM25: 12 PASS / 1 PARTIAL / 0 FAIL, 96.2%.
- Difference: identical observed results; no regression and no ranking
  improvement.
- Snapshot:
  `docs/eval_snapshots/eval_v2_persisted_bm25_2026-04-28.json`.

### Conclusion

Persisted BM25 is functionally equivalent to the v1.10.4 dynamic baseline for
the locked 13-case evaluation set and is safe to accept.

## v1.10.4 — Baseline and Regression Hardening

Status: accepted.

### Added

- Regression tests for active document safety.
- Regression tests for diagnostics reset behavior.
- Regression widget test for DocViewer initial chunk highlight.
- ChatScreen refactor plan for behavior-preserving controller extraction.
- `RagChatController` for embedding/RAG service rebuild decisions.
- Quantitative baseline snapshot:
  `docs/eval_snapshots/eval_baseline_v1.10_bgem3_hybrid_2026-04-28.json`.

### Changed

- Library active document selection now also passes through activeDoc
  normalization, matching bootstrap and document-removal behavior.
- Ingest batch size increased from 1 to 4.
- Keyword extraction stopwords now include common Cantonese/Chinese question
  filler terms.

### Validation

- `flutter analyze`: pass, 0 issues.
- `flutter test -r expanded`: pass, 79 tests.
- `flutter build windows --release`: pass.

### Quantitative Baseline

- Snapshot: `docs/eval_snapshots/eval_baseline_v1.10_bgem3_hybrid_2026-04-28.json`
- Embedding: `bge-m3`
- Retrieval mode: `hybrid`
- Documents:
  - `README.txt`
  - `DOSBox 0.74 Manual.txt`
- Cases: 13
- Result: 12 PASS / 1 PARTIAL / 0 FAIL
- Score: 12.5 / 13
- Pass rate: 96.2%

### Known Minor Issue

- The MacOS follow-up case is marked PARTIAL because the source document mainly
  covers Windows configuration, so MacOS-specific grounding is limited.

## v1.10 — RAG Polish, Ingest Safety, Retrieval Modes

Status: release candidate.

### Added

- `RetrievalMode` with `dense`, `sparse`, and `hybrid` modes.
- Settings UI for retrieval mode selection.
- `IngestResult` for explicit ingest `success`, `cancelled`, and `failed` states.
- `RagService.ingestDetailed()` for structured ingest results.
- `VectorStore.replaceDoc()` with in-memory rollback if persistence fails.
- Batch embedding path through Ollama `/api/embed`, with legacy `/api/embeddings` fallback.
- Citation tap logging even when the link has no chunk index.
- DocViewer scroll/highlight logging for success and failure cases.
- Smaller chat UI widgets:
  - `chat_app_bar.dart`
  - `chat_app_bar_actions.dart`
  - `chat_session_drawer.dart`
  - `chat_input_bar.dart`
  - `chat_message_bubble.dart`
  - `chat_ingest_status_bar.dart`
  - `chat_library_sheet.dart`
  - `rag_context_banner.dart`
  - `top_k_picker.dart`

### Changed

- BM25 synonym expansion now only expands query terms. Document TF/DF uses original document terms to avoid inflated synonym scores.
- `chat_screen.dart` reduced from roughly 1481 lines to about 950-1180 lines depending on local export point, with UI responsibilities extracted.
- RAG retrieve logs now include retrieval mode and diagnostics.
- AppBar callback surface is grouped through `ChatAppBarActions`.

### Fixed

- BM25 TF/DF universe mismatch.
- Save failure during document replacement no longer leaves the in-memory vector store half-replaced.
- Cancelled ingest preserves the previous document index.
- Citation links without a chunk index are now visible in debug logs as `chunkIndex=none`.

### Validation

- `flutter analyze`: pass, 0 issues.
- `flutter test -r expanded`: pass, 59+ tests.
- `flutter build windows --release`: pass.

### Quantitative Baseline

Superseded by the v1.10.4 quantitative baseline. The v1.10.4 snapshot is the
current release baseline for future retrieval comparisons:

```text
Embedding: bge-m3
Retrieval mode: hybrid
Documents: README.txt, DOSBox 0.74 Manual.txt
Cases: 13
Result: 12 PASS / 1 PARTIAL / 0 FAIL
Pass rate: 96.2%
Snapshot: docs/eval_snapshots/eval_baseline_v1.10_bgem3_hybrid_2026-04-28.json
```

## v1.9.0 RC

Status: accepted as the first production-ready RAG release candidate.

### Verified

- RAG main pipeline:
  - embedding settings
  - document ingest
  - vector store rebuild
  - retrieve
  - citation generation
  - DocViewer citation highlight
- Embedding model persistence.
- Vector store schema v2:
  - `schemaVersion`
  - `embeddingModel`
  - `chunks`
- Vector store embedding model mismatch safeguard.
- Session persistence.
- Release debug observability through `rag_debug.log`.

### Important Logs

Expected successful ingest:

```text
RAG ingest: done doc=README.txt embeddingModel=bge-m3 chunks=4 ...
```

Expected successful retrieve:

```text
RAG retrieve: start ... embeddingModel=bge-m3 doc=README.txt ...
RAG retrieve: done hits=4 ...
```
