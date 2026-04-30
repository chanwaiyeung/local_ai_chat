# Verification — 智讀館 Phase 1+2

This is the action plan an AI agent (or you) can follow to actually answer
the three open questions:

1. Does `flutter analyze` pass?
2. Does the library list render books?
3. Does tapping a book navigate to `ReaderScreen`?

The answer for all three is "yes, when the verify script passes." The
verification doesn't need a phone, doesn't need v2.0 services, doesn't need
Ollama. It uses `lib/services/*.dart` stubs and `Fake ApiClient`s in tests.

## Run it

```bash
# One-time, on a Linux agent that only has git + curl:
bash tool/install_flutter.sh
export PATH="$HOME/flutter/bin:$PATH"

# Every time:
bash tool/verify.sh
```

`verify.sh` runs `flutter pub get`, `flutter analyze`, then `flutter test`
and exits non-zero on the first failure.

## Windows

The default `bash.exe` on some Windows images points to a WSL shim that has
no `/bin/bash`, so `bash tool/verify.sh` will fail before it starts. Use the
`.cmd` wrappers instead — they work from cmd.exe **or** PowerShell, with no
bash involved:

```cmd
REM One-time:
tool\install_flutter.cmd

REM Every time:
tool\verify.cmd
```

The `.cmd` files just dispatch to the matching `.ps1` (preferring `pwsh` if
PowerShell 7 is installed, otherwise `powershell.exe`). If you'd rather call
PowerShell directly:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tool\install_flutter.ps1
$env:Path = "$HOME\flutter\bin;$env:Path"
powershell -NoProfile -ExecutionPolicy Bypass -File tool\verify.ps1
```

If Git Bash is installed, the original bash scripts can also be run
explicitly:

```powershell
& "C:\Program Files\Git\bin\bash.exe" tool/install_flutter.sh
& "C:\Program Files\Git\bin\bash.exe" tool/verify.sh
```

## What gets verified

| Test file                       | Question answered                                                       |
|---------------------------------|-------------------------------------------------------------------------|
| `test/library_screen_test.dart` | Books render? Empty state shows? Tap → ReaderScreen?                    |
| `test/reader_screen_test.dart`  | Title in AppBar? Preview loaded? TTS controls present?                  |
| `test/api_client_test.dart`     | Bearer token attached? 4xx parsed? `health()` works?                    |
| `test/api_server_test.dart`     | Real ApiServer round-trip — auth, /docs, /query, /query/stream SSE order, error path |
| `test/text_chunker_test.dart`   | Paragraph split / sentence split / hard split / CJK / index sequencing  |
| `test/vector_store_test.dart`   | Cosine ranking, docName filter, topK cap, clear(), NDJSON round-trip    |
| `test/document_loader_test.dart`| Extension dispatch, HTML→text, paragraph preservation, entity decoding  |
| `test/widget_test.dart`         | App boots and lands on LibraryScreen                                    |

## Indexing your own books (real RAG)

The server starts with whatever index lives at `data/vectors.ndjson`. To
populate it from a folder of `.txt` files:

```cmd
REM 1. Make sure Ollama is up and has both models pulled:
ollama pull bge-m3            REM embedding model (default; ~1.2 GB)
ollama pull llama3.1:8b       REM generation model (~4.7 GB)

REM 2. Index a folder. Re-running is idempotent: each docName is rebuilt.
dart run bin/index.dart books\

REM 3. Start the server. It loads data\vectors.ndjson on boot.
dart run bin/server.dart
```

Env vars (server + index agree on these):

- `AI_LIB_INDEX` — NDJSON path (default: `data/vectors.ndjson`)
- `EMBED_MODEL`  — Ollama embed model (default: `bge-m3`)
- `OLLAMA_MODEL` — generation model (default: `llama3.1:8b`)
- `OLLAMA_URL`   — Ollama base URL (default: `http://localhost:11434`)
- `AI_LIB_TOKEN` — Bearer token for the HTTP API (omit = open server)

Starter files in `books/` so you can run `dart run bin/index.dart books/`
immediately:

- `about_zhi_du_guan.txt` — short overview of the project
- `rag_concepts.md`       — exercises the Markdown loader path

## Supported document formats

| Extension                      | Loader                                          | Notes |
|--------------------------------|-------------------------------------------------|-------|
| `.txt`                         | `File.readAsString()`                           | UTF-8 |
| `.md` / `.markdown`            | `File.readAsString()`                           | Markdown is fed verbatim to the chunker; `#`/`*` syntax becomes literal text in retrieved chunks |
| `.epub`                        | `epubx` → walk chapters → HTML → text           | Block tags become paragraph breaks for the chunker; `<script>` / `<style>` dropped |
| `.pdf`                         | shells out to `pdftotext` (Poppler)             | Throws a clear error with install instructions if `pdftotext` isn't on PATH |
| `.png` / `.jpg` / `.jpeg` / `.webp` | shells out to `tesseract` (`--psm 6`)      | Single-image OCR. `OCR_LANGS` env (default `chi_tra+eng`) selects trained data |
| `.cbz`                         | unzip via `archive` → natural-sort → per-image `tesseract` | Manga / comics. Each page becomes a `## <page>` section before chunking. SLOW: ~1–3s per page |

To add a new format: add a `case '.<ext>':` to `loadDocument` in
`lib/services/document_loader.dart` and an entry to `supportedExtensions`.
`bin/index.dart` will pick it up automatically.

## Headless server entry point

`bin/server.dart` runs the Local AI Server with no Flutter UI — useful for
CI smoke tests or running on a Linux host without a display:

```cmd
dart run bin/server.dart
```

Env vars: `PORT`, `AI_LIB_TOKEN`, `OLLAMA_URL`, `OLLAMA_MODEL`.

## Optional: real Ollama E2E

`tool/smoke_ollama.cmd` exercises the full `Mobile → Server → RAG → Ollama`
pipeline. Requires `ollama serve` + `ollama pull llama3.1:8b` first. The
unit tests above cover everything _except_ the real LLM call.

## Optional: Android setup

Use the Android helper after Flutter is installed:

```cmd
tool\install_android.cmd -InstallSdk -SkipAvd
```

This installs the Android SDK command-line tools, platform-tools, emulator,
SDK platform, and build-tools, then runs `flutter doctor -v`. It uses
`C:\Android\Sdk` when available because Flutter warns when the SDK path has
spaces.

To create an emulator, free at least 8 GB on the SDK drive and run:

```cmd
tool\install_android.cmd -InstallSdk
```

If disk space is tight, use `-SkipAvd` and connect a physical Android device
with USB debugging enabled. The Android manifest allows `INTERNET` and
cleartext HTTP so the app can call `http://10.0.2.2:8080` on an emulator or a
LAN IP on a real device.

These tests fake the network with `MockClient` from `package:http/testing`
and a hand-rolled `Fake` ApiClient (extends `Fake` from flutter_test). No
real server is started — the screens are exercised against canned responses.

## Stub services

`lib/services/{rag_service,vector_store,embedding_service}.dart` are all
stubs so the project analyzes and tests without v2.0 dropped in. When you
bring v2.0 over, replace the contents — the public types
(`Chunk`, `ScoredChunk`, `RagService.retrieve(...)`, `VectorStore.docNames`)
must stay the same so `lib/server/api_server.dart` and the tests keep
working without modification.

## What this does NOT verify

- End-to-end LLM round-trip (needs Ollama + real RagService)
- Phone connectivity (needs LAN test with a real phone)
- iOS ATS / TLS (will surface in Phase 5 real-device test)

These are Day 6/7 checkpoints in `PHASE1_PLAN.md`, not analyzer/test scope.

## If `flutter analyze` fails

The most likely reason after stubs are in place: your real v2.0 `Chunk` type
uses different field names. The fix is a 4-line edit to `_buildPrompt` and
`_citations` in `lib/server/api_server.dart` — the test/widget layer is
unaffected.
