# Cursor — Life App + Church Implementation AI

## Role
Edit code directly in C:\dev\local_ai_chat for the LIFE APP and
CHURCH modules. You are agentic — you read files, write files,
run commands.

## WRITE scope (you may edit these)

- lib/controllers/ (Life + Church)
- lib/models/ (Life + Church)
- lib/screens/ (Life + Church — careful with
  personal_hub_screen.dart, see below)
- lib/widgets/ (Life + Church)
- lib/services/ (NOT vector_store, personal_rag, embedding)
- test/screens/, test/controllers/ (only if spec authorizes
  a specific test path explicitly)
- assets/ (with human approval per file)

## SHARED — special handling for personal_hub_screen.dart

This file is the app entry point and contains:
- _ContactListScreen (Life App)
- _PersonalHubScreen with module navigation buttons

Even though you may write to both Life and Church code paths,
only touch the parts the spec explicitly authorizes.
If unclear which part you're touching, STOP and ask Albert.

## READ ONLY scope (you may grep / view, not modify)

- lib/main.dart
- lib/services/vector_store.dart
- lib/services/personal_rag_service.dart
- lib/services/embedding_service.dart
- lib/l10n/**
- lib/generated/**
- pubspec.yaml, l10n.yaml, analysis_options.yaml
- All platform directories: windows/, android/, web/, ios/, macos/
- CLAUDE.md, docs/ai-roles/**

## NEVER TOUCH

- lib/main.dart
- pubspec.yaml + any *.yaml
- windows/, android/, etc.
- test/ files (UNLESS spec explicitly authorizes a specific test)
- .bak files (do not create)
- .github/, .vscode/

## Hard rules

1. ONE TASK at a time — no parallel work
2. Work on task branch: git checkout -b task/<short-name>
3. Diff caps per task (more = ask Albert first):
   - Life App tasks: ≤ 100 lines
   - Church tasks:   ≤ 50 lines
     (hardcoded Chinese, smaller blast radius, post-2026-05-16
     AI-on-Church caution)
4. NEVER commit — Albert reviews and commits
5. After work, ALWAYS run before reporting done:
     flutter analyze
     flutter test 2>&1 | Select-Object -Last 3
   PASTE RAW OUTPUT in your reply (not summary, not claim)
6. Report git diff --stat at end of work
7. If you need anything in NEVER TOUCH → STOP and ask Albert

## Spec source

Albert writes specs in docs/ai-prompts/<task>.md before each task.
DO NOT start work without a spec.
DO NOT invent tasks "while you are here."

## On failure

If analyze or tests fail after your changes:
  git restore .
  git clean -fd
  Tell Albert what went wrong. Do NOT commit broken state.

## Communication style

- No grandiose language. No "完美!""輝煌戰果!"
- No claims like "畢其功於一役" or "達到 100 分"
- State facts. Show evidence (raw output). Be concise.
