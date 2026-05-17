# ADR: Retroactive acceptance of unauthorized AI work (Reader B005)

Date: 2026-05-16
Status: Accepted with conditions

## Context

An external AI (Gemini Antigravity) modified 6 files in the repo
without prior task spec authorization:

- lib/controllers/reader_controller.dart    (+2/-3)
- lib/screens/reader_screen.dart            (+22/-1)
- lib/widgets/book/book_form_dialog.dart    (+26/-16)
- pubspec.yaml                              (+2)        ← FORBIDDEN ZONE
- test/reader_controller_test.dart          (+8/-8)     ← FORBIDDEN ZONE
- test/reader_screen_test.dart              (+6)        ← FORBIDDEN ZONE

The AI was not given a task spec. It worked on main directly (not
a task branch). It modified files in declared FORBIDDEN ZONES
(pubspec.yaml, test/**).

## Decision

ACCEPT the changes despite the process violation, with explicit
documentation that the acceptance is retroactive and not precedent.

## Rationale for acceptance

1. Changes correctly fix audit bug B005 (hardcoded asset path)
2. Reader controller refactor uses proper dependency inversion
3. Tests were updated consistently with production code
4. assets/sample_page.jpg now exists, pubspec correctly declares
5. Bonus: book_form_dialog fix addresses a real Windows
   image_picker crash that was visible in console logs

## Rationale for not pretending it's OK

1. AI gave no notification of work in progress
2. AI did not work on a task branch (touched main)
3. AI changed pubspec.yaml (declared FORBIDDEN in
   docs/ai-roles/*.md)
4. AI changed test files (declared FORBIDDEN)
5. Running unattended in background — no human checkpoint
6. Previous session, the same tool fabricated audit reports
   with [cite: N] markers and empty files

## Conditions for this acceptance

1. Next violation of any kind by Gemini Antigravity = full reject,
   no review. No retroactive acceptance ever again.
2. Gemini Antigravity is removed from the trusted AI list in
   docs/ai-roles/.
3. The tool's background process is to be terminated and any
   IDE plugin uninstalled before next work session.
4. All future Reader / Book module work requires written spec
   in docs/ai-prompts/ before any AI begins.

## Files committed

Commit 1: Reader OCR DI (5 files)
Commit 2: Book form Windows fix (1 file)

## Audit trail

git diff was reviewed line-by-line by human (Albert).
flutter analyze: No issues found
flutter test: 409 passed / 4 skipped / 0 failed
