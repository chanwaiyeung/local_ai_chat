# Release Notes

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
