# Release Notes

## v1.9.0 RC

Status: release candidate accepted.

### Verified

- RAG main pipeline is working:
  - embedding settings
  - document ingest
  - vector store rebuild
  - retrieve
  - citation generation
  - DocViewer citation highlight
- Embedding model persistence is working.
- `bge-m3` is installed and active.
- `app_settings.json` persists the selected embedding model.
- Vector store schema v2 is working:
  - `schemaVersion`
  - `embeddingModel`
  - `chunks`
- Vector store embedding model mismatch safeguard is in place.
- Session persistence is working:
  - README Q&A remains after restart.
  - `activeDoc` remains `README.txt`.
- Release debug observability is working through `rag_debug.log`.

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

### Not Changed

- RAG retrieval algorithm behavior.
- Citation parser format.
- Markdown code block rendering.
- RAG Evaluation export schema.

### Next

- Create a git tag named `v1.9.0` once the project is in a git repository.
- Start the `v2.0` branch.
- Recommended first v2 feature: hybrid search.
