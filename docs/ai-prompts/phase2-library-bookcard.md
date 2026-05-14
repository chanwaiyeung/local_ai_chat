# Phase 2 — Library BookCard 抽出

## Context
- Repo: Flutter app at C:\dev\local_ai_chat
- Current branch: feature/library-rebuild (or main, confirm before starting)
- Branch state must be clean before you start (git status = "nothing to commit")
- Phase 1 has shipped: library grid container extracted
- Phase 2 is NOT done until concrete files exist (see Acceptance below)

## Required Changes (exhaustive — no other files allowed)

### New file
- lib/widgets/library/library_book_card.dart
  - Extracts reusable LibraryBookCard widget
  - Owns: cover image, title text, status badge, tap/long-press handlers
  - Pure presentational — accepts Book model + callbacks, no controller access

### Modified file
- lib/widgets/library/library_book_grid.dart
  - Replace inline book tile rendering with LibraryBookCard(...) instances
  - Behavior identical to before

## Hard constraints

1. NO changes outside the two files above
2. NO changes to:
   - lib/controllers/**
   - lib/services/**
   - lib/models/**
   - lib/main.dart
   - pubspec.yaml
   - windows/** (especially generated_plugin_registrant.*)
   - any test files (existing tests must keep passing as-is)
3. NO behavior changes — refactor only, pixel-equivalent UI
4. NO new dependencies

## Acceptance criteria (Phase 2 is incomplete without ALL of these)

1. File lib/widgets/library/library_book_card.dart exists with LibraryBookCard class
2. library_book_grid.dart imports and uses LibraryBookCard
3. flutter analyze → No issues found!
4. flutter test test/library_screen_test.dart test/reader_screen_test.dart test/reading_mode_screen_test.dart → all pass
5. git diff --stat shows EXACTLY 2 files changed: 1 new + 1 modified
   (any other file in the diff = task incomplete, retry)

## Required deliverables (paste in your reply)

1. Full content of lib/widgets/library/library_book_card.dart
2. Diff or full content of modified lib/widgets/library/library_book_grid.dart
3. Output of: git diff --stat
4. Output of: flutter analyze
5. Output of: flutter test test/library_screen_test.dart

## Do NOT

- Do not commit
- Do not push
- Do not run dart fix --apply
- Do not modify windows/flutter/generated_* even if Flutter regenerates them
- Do not create scratch / debug files in repo root
