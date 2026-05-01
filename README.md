## 🚀 v2.2.0 — Personal Hub GA

**智讀館** 從閱讀工具升級為**個人生活管家**！

### 主要功能
- **名片管理**：鏡頭掃描 + OCR 自動解析 + RAG 搜尋
- **日常開支**：掃描發票 + 自動分類 + 月統計
- **跨模組 RAG**：自然語言查詢「上次跟王經理吃飯花多少？」
- **統一 Dashboard**：總覽 + 快速查詢

### 下載
- Windows：`local_ai_chat_v2.2.0_windows_x64.zip`
- Android：`local_ai_chat_v2.2.0.apk`

### 下一步
- v2.3：健康管理 + 投資理財
- v2.4：macOS 完整支援

---

# 智讀館 (AI Library)

## v2.0.0 GA Highlights

- Production-ready local-first RAG reader with streaming answers and citations.
- Safe server defaults: loopback bind, explicit LAN mode, required token for LAN.
- Reader state hardened: `answer` stays pure LLM output; status uses `statusBanner`.
- Multi-format library: TXT / Markdown / EPUB / PDF plus experimental OCR / CBZ.
- Verified release target: 0 analyze issues and 138+ passing tests.

A local-first reading companion. Drop your books into a folder, run one
command, and a small Flutter app on your phone or browser can answer
questions about them — grounded in the actual text, with citations,
without sending anything to the cloud.

```
┌──────────────┐    LAN     ┌──────────────┐         ┌──────────────┐
│ Mobile / Web │  ───────►  │ Local Server │  ────►  │   Ollama     │
│   Flutter    │            │   shelf+SSE  │         │  bge-m3 +    │
│   ApiClient  │  ◄───────  │   ApiServer  │  ◄────  │ llama3.1:8b  │
└──────────────┘   stream   └──────────────┘         └──────────────┘
                                  │
                                  ▼
                         data/vectors.ndjson
                         (RAG vector index)
```

## Features

- **Multi-format**: `.txt`, `.md`, `.epub`, `.pdf` (via `pdftotext`), and
  `.cbz` / `.png` / `.jpg` / `.webp` (via `tesseract` OCR for manga).
- **Real RAG**: bge-m3 embeddings + cosine retrieval + grounded LLM with
  numeric citations `[1]` `[2]`.
- **Streaming**: Server-Sent Events; the answer types out as the model
  generates.
- **Citations panel**: tap to expand, see which chunks the LLM used,
  similarity score per chunk.
- **Language helper**: tap any term in the answer for a Traditional
  Chinese explanation with example sentence.
- **TTS**: Mandarin text-to-speech via `flutter_tts`.
- **Local-only**: no cloud calls. The whole pipeline runs on your laptop.

## Quick start (Windows)

```cmd
REM 1. Install Flutter SDK + Ollama + Tesseract (each is idempotent)
tool\install_flutter.cmd
tool\install_ollama.cmd
tool\install_tesseract.cmd

REM 2. Pull the LLM and embedding models (~6 GB total)
ollama pull llama3.1:8b
ollama pull bge-m3

REM 3. Sanity-check: 60+ tests, all green
tool\verify.cmd

REM 4. Drop your books into books\ then index them
copy "%USERPROFILE%\Downloads\some_book.epub" books\
dart run bin\index.dart books\

REM 5. Run the app (server starts automatically on desktop)
flutter run -d windows
REM   or:  flutter run -d chrome
```

By default the embedded server binds to `127.0.0.1` only, so nothing on
your LAN can reach it. To let a phone connect, opt in explicitly:

```cmd
flutter run -d windows ^
  --dart-define=AI_LIB_LAN=true ^
  --dart-define=AI_LIB_TOKEN=your-secret
```

Without `AI_LIB_TOKEN`, `AI_LIB_LAN=true` refuses to start — by design.
Loopback-only is the safe default; LAN exposure is always paired with
auth.

The app opens, lists your indexed books, and lets you ask questions
about each one. The first `/query` takes 10–30 seconds (model warm-up);
subsequent queries are immediate.

## HTTP API

| Endpoint                         | Method | Notes                              |
|----------------------------------|--------|------------------------------------|
| `/health`                        | GET    | No auth                            |
| `/docs`                          | GET    | List indexed doc names             |
| `/docs/<docName>/chunks`         | GET    | All chunks of one doc, in order    |
| `/query`                         | POST   | Retrieve + LLM answer, single shot |
| `/query/stream`                  | POST   | Same as `/query` but SSE-streamed  |
| `/rag/retrieve`                  | POST   | Pure retrieval, no LLM call        |

All endpoints except `/health` require `Authorization: Bearer <token>`
when `AI_LIB_TOKEN` is set.

## Adding more books

```cmd
copy "%USERPROFILE%\Downloads\new_book.epub" books\
dart run bin\index.dart books\new_book.epub
```

`bin\index.dart` is idempotent: running it again on the same file
re-chunks and re-embeds in place.

## Configuration (env vars)

| Variable        | Default                       | What it controls                        |
|-----------------|-------------------------------|-----------------------------------------|
| `AI_LIB_TOKEN`  | _(unset → server is open)_    | Bearer token required by HTTP API       |
| `AI_LIB_INDEX`  | `data/vectors.ndjson`         | Where the vector index is persisted     |
| `OLLAMA_URL`    | `http://localhost:11434`      | Ollama daemon URL                       |
| `OLLAMA_MODEL`  | `llama3.1:8b`                 | Generation model                        |
| `EMBED_MODEL`   | `bge-m3`                      | Embedding model                         |
| `OCR_LANGS`     | `chi_tra+eng`                 | Tesseract language packs (e.g. `+jpn`)  |
| `PORT`          | `8080`                        | HTTP server port                        |

## Project layout

```
bin/
  index.dart            CLI: walks files/dirs, builds vector index
  server.dart           CLI: headless server entry (no Flutter UI)

lib/
  main.dart             Flutter app entry; auto-starts server on desktop
  server/
    api_server.dart     /health, /docs, /query, /query/stream (SSE)
    ollama_client.dart  Streaming client for Ollama /api/generate
  services/
    document_loader.dart   Format dispatch (txt/md/epub/pdf/image/cbz)
    text_chunker.dart      Paragraph + sentence + hard split, CJK-aware
    embedding_service.dart Ollama /api/embeddings client (test-injectable)
    vector_store.dart      NDJSON-backed cosine similarity store
    rag_service.dart       Indexing + retrieval glue
    api_client.dart        Mobile-side ReaderApi (HTTP + SSE)
    tts_service.dart       flutter_tts wrapper (test-friendly)
    ocr_service.dart       Mobile-side OCR (tesseract on desktop)
    language_learning_service.dart  Vocab explainer

  screens/
    library_screen.dart   Book list + LAN IP override dialog
    reader_screen.dart    Q&A + streaming + citations + TTS

test/                   60+ tests (unit, widget, integration)
tool/                   .cmd / .ps1 / .sh installers and verifiers
books/                  Drop your documents here
data/vectors.ndjson     Persisted RAG index (created by bin/index.dart)
```

## Verification

```cmd
tool\verify.cmd          REM flutter pub get + analyze + test
tool\smoke_test.cmd      REM full E2E: starts server, hits /health /docs /query
```

`smoke_test.cmd` requires `ollama serve` already running with the LLM
model pulled. See `VERIFICATION.md` for the full operational guide.

## Stack

- **Frontend**: Flutter (Material 3, runs on Windows / macOS / Linux /
  Android / iOS / Web).
- **Server**: Pure Dart `shelf` + `shelf_router` + `shelf_cors_headers`.
  No Flutter dependency in the server path — it can run via
  `dart run bin/server.dart`.
- **LLM**: Ollama (default `llama3.1:8b`). Swap by setting
  `OLLAMA_MODEL`. `OllamaClient` uses `dart:io HttpClient` with
  `autoUncompress=false` to avoid streaming buffering.
- **Embeddings**: bge-m3 via Ollama `/api/embeddings`. 1024-dim.
- **Vector store**: NDJSON file + in-memory cosine search. Atomic
  rewrites via tmp+rename. Tested at ~10K chunks.
- **OCR**: shells out to `tesseract` (Tesseract OCR Engine). PDF text
  extraction shells out to `pdftotext` (Poppler).
- **Auth**: optional Bearer token (`AI_LIB_TOKEN`); CORS open by design
  so the mobile webview can connect.

## Compatibility note

This repository is the new `ai_library_server` implementation. Its
`VectorStore` persists embeddings as a simple NDJSON file
(`data/vectors.ndjson`) and does cosine/MMR search in memory. It is **not**
the older `local_ai_chat` v2.0 schema-v3 persisted BM25 store. Treat migration
from v2.0 as a separate import/export task.

## Roadmap

| Phase | Status | Description                                         |
|-------|:------:|-----------------------------------------------------|
| 1     | ✅     | Local AI Server + RAG + mobile UI                   |
| 2     | ✅     | Streaming + citations + TTS + multi-format          |
| 3     | ✅     | Language learning helper (vocab + example)          |
| 4     | 🟡     | OCR (server batch ✅, mobile photo 🟡)              |
| 5     | ⏸     | AI Glasses (immersive reading)                      |

## License

Private project — not yet licensed for redistribution.
