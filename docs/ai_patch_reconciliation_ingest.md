# AI Patch Reconciliation: Ingest / VectorStore

This note reconciles older AI-generated ingest/vector-store snippets with the
current codebase. Do not paste older full-file snippets over the current files.

For the broader cross-AI decision record, see:

- `docs/three_ai_recommendation_integration.md`

## Current Accepted Implementation

### `lib/services/rag_service.dart`

The current implementation is newer than the older snippets:

- `ingest()` remains a backwards-compatible wrapper returning `int`.
- `ingestDetailed()` returns `IngestResult`.
- `ingestDetailed()` supports:
  - batch embedding through `EmbeddingService.embedAll()`
  - `cancelCheck`
  - `onProgress`
  - atomic document replacement through `VectorStore.replaceDoc()`
  - rollback on save failure
- `retrieve()` supports `RetrievalMode`:
  - `dense`
  - `sparse`
  - `hybrid`
- `retrieve()` resets `lastDiagnostics` on every call.
- Empty store or missing active document returns empty results without calling
  embedding.
- BM25 expands query terms only. Document TF/DF uses original document terms.

### `lib/services/vector_store.dart`

The current implementation is newer than the older stub:

- schema v2 persistence
- `embeddingModel` tracking
- atomic temp-file save
- `VectorStoreSnapshot.migratedFromLegacy`
- legacy list snapshot support
- accidental PowerShell `chunks.value` shape support
- malformed chunk entries are skipped instead of dropping the whole store
- legacy/malformed load is normalized back to schema v2
- `replaceDoc()` restores the previous in-memory chunks if save fails

## Do Not Apply

Do not replace current files with snippets that introduce:

- a temporary `Directory.systemTemp.createTempSync('vector_store_')` store
- `supportsTransaction` stubs as the main persistence path
- a `VectorStore` without schema v2 support
- a `RagService.retrieve()` without `RetrievalMode`
- a `retrieve()` that leaves stale `lastDiagnostics`
- a `retrieve()` that calls embedding when the selected `docName` has no chunks
- a `RagService.ingest()` that returns `IngestResult` and removes the current
  backwards-compatible `Future<int> ingest()` wrapper
- dynamic `embedBatch` probing instead of the current typed
  `EmbeddingService.embedAll()` path
- `VectorStore.addAllForDoc()`, `markDocComplete()`, `swapDocVersion()`, or
  `cleanupTempVersions()` as required runtime APIs unless a future schema v3
  design explicitly adopts them

Those snippets were useful as early design sketches, but they are now older
than the tested codebase.

## Why The Older Full-File Patch Is Unsafe

The older patch suggests replacing both `vector_store.dart` and
`rag_service.dart` wholesale. That would regress current behavior:

- schema v2 load/save would be lost
- malformed chunk recovery would be lost
- legacy snapshot migration logging would be lost
- `RetrievalMode` would be lost
- diagnostics reset on empty/missing-doc retrieval would be lost
- sparse mode no-embedding behavior would be lost
- current 79-test release lock would no longer describe the codebase

If future work needs versioned document commits, implement it as a schema v3
design on top of the current `VectorStore.replaceDoc()` behavior, not by
replacing the store with temporary-directory stubs.

## Tests Covering The Current Behavior

- `test/rag_service_test.dart`
  - BM25 query expansion isolation
  - retrieval mode dense/sparse/hybrid
  - sparse retrieval does not call embedding
  - hybrid diagnostics
  - empty-store diagnostics reset
  - missing active-doc avoids embedding call
  - ingest cancellation
  - ingest rollback on save failure
- `test/vector_store_test.dart`
  - schema v2 snapshot
  - legacy list snapshot
  - malformed PowerShell `chunks.value` shape
  - malformed chunk skip
- `test/embedding_service_test.dart`
  - `/api/embed` batch endpoint
  - `/api/embeddings` fallback
  - wrong-shape fallback
  - legacy fallback concurrency cap
  - server error handling

## Validation Commands

Run from `C:\dev\local_ai_chat`:

```powershell
& "C:\src\flutter\flutter\bin\flutter.bat" analyze
& "C:\src\flutter\flutter\bin\flutter.bat" test -r expanded
& "C:\src\flutter\flutter\bin\flutter.bat" build windows --release
```

## Remaining Manual Gap

The quantitative RAG baseline still requires manual Windows UI execution.
Use:

- `docs/eval_baseline_input.md`
- release app at `build\windows\x64\runner\Release\local_ai_chat.exe`

Do not write pass-rate claims into release notes until the exported evaluation
snapshot actually exists.
