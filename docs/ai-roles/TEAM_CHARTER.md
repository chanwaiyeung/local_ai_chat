# AI Team Charter — local_ai_chat

## Organization

Human (Albert) - sole commit/push authority + dispatcher
- Claude Code - supervisor, validation, docs, specs
- Cursor - Life App implementer (agentic)
- ChatGPT - Life App spec advisor (web)
- Gemini - Church App spec advisor (web)
- Grok - Church App spec advisor (web)

## Module ownership

| Module | Implementer | Advisors | Validator |
|---|---|---|---|
| Life App | Cursor | ChatGPT | Claude Code |
| Church | hand-apply | Gemini + Grok | Claude Code |
| Cross-cutting | Albert only | Claude Code | Claude Code |

## Workflow per task

1. Albert + advisor write spec -> docs/ai-prompts/
2. Albert reviews, commits spec
3. Albert creates task branch: git checkout -b task/<name>
4. Implementer edits on branch
5. Implementer reports git diff --stat + analyze + test
6. Albert/Claude Code verifies output is REAL
7. Accept: commit + merge. Reject: git restore + retry.

## Cardinal rules

1. NO AI commits. Only Albert.
2. NO AI pushes. Only Albert.
3. NO AI modifies main.dart, pubspec, l10n, windows/
4. NO AI creates .bak in repo
5. NO AI works outside assigned module
6. NO secrets in any AI conversation, EVER

## Web AI policy (ChatGPT, Gemini, Grok)

Cannot read files / run commands / edit.
Claims of doing so = fabrication.
Verify with Claude Code (runs actual commands).

## Agentic AI policy (Cursor)

Can read/run/edit within declared WRITE scope.
Cannot commit, cannot push, cannot work off-branch.
Must report raw analyze + test output before declaring done.

## Conflict zones

- lib/screens/personal_hub_screen.dart (Life + Church nav)
  Cursor edits Life parts only.
- lib/main.dart - Albert only.

## Escalation

In doubt: STOP. Ask Albert.
Scope creep: STOP. Report.
Uncertain: SAY SO. Do not fabricate confidence.
