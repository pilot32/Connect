---
description: Review recent work and update AGENTS.md (and FEATURES.md/ENTITIES.md if needed) to reflect what's been completed
---

Your job is to keep this project's context files accurate for future LLM agents and teammates — not to write new product docs from scratch.

## 1. Gather what actually changed

Run, and read the output carefully:
- `git status`
- `git diff` (unstaged) and `git diff --staged` (staged)
- `git log -15 --oneline` for recent commit history, and `git diff <last-reviewed-commit-or-N-commits-ago>...HEAD` if useful for a fuller picture
- If there's an open plan/task list in context, note it too

Focus on: files that went from empty stub → implemented, new files/folders created, new dependencies actually installed (check `node_modules`/`.dart_tool` or lockfiles, not just manifest declarations), routes/controllers/screens/services that now have real logic, and any product-scope decisions embedded in commit messages or code comments.

## 2. Update AGENTS.md

Edit `AGENTS.md` at the project root:
- In the backend/frontend folder trees, change any file annotated `(empty stub)` that now has real implementation — replace the annotation with a short one-line description of what it does (not a full docstring, one line).
- Update the "Current MVP scope" section only if actual product scope changed (not just implementation progress).
- Update "Key conventions" if a new pattern was introduced (e.g. a new shared utility convention, a new folder category) — but don't invent conventions that aren't actually followed yet.
- Do NOT remove the "empty stub" framing for files that are still genuinely empty.
- Keep the file scannable — this is a quick-orientation doc, not exhaustive documentation. Prefer one-line updates over paragraphs.

## 3. Update FEATURES.md and ENTITIES.md only if relevant

- **FEATURES.md**: if a backlog item was implemented, move it out of the backlog (delete the line, or note it shipped — don't leave completed work listed as "backlog"). If new feature ideas surfaced during the work (e.g. a TODO comment, a deferred edge case), add them to the appropriate phase.
- **ENTITIES.md**: if the Prisma schema or Dart model classes changed (new entity, new field, new relationship), update the corresponding entity table and the relationships diagram to match reality. If you're not sure the schema is final, say so inline rather than presenting it as settled.

Skip either file entirely if nothing relevant changed — don't pad these files with restatements of unrelated work.

## 4. Report back

After editing, give a short summary (a few bullets) of what was updated and why — not a full diff dump. If nothing needed updating, say so plainly rather than making cosmetic edits to justify the run.
