---
name: rebase-resolve
description: Drive an in-progress git rebase to completion with build-gated conflict resolution. Use only when the user explicitly asks for the rebase-resolve skill or says to run /rebase-resolve; do not use automatically.
---

# Resolve Rebase Conflicts

Drive an in-progress `git rebase` to completion. For each conflicted file, classify the conflict using the incoming commit's intent + the file's recent history; **auto-resolve high-confidence conflicts** (trivial whitespace / import / additive overlaps); **escalate to the user only on medium- or low-confidence cases** (semantic overlap, structural reshuffles, structured manifests, rename/delete). After every conflict in the current patch is resolved, run a full build, `git rebase --continue`, and loop.

The full-reactor build is the safety net for auto-resolutions: textually trivial conflicts can hide semantic divergence, and a green build is the line between "march on" and "stop and ask." If the build goes red after an auto-resolution, the loop halts and surfaces to the user — the agent does not silently retry or revert.

The user is engaged only when the classifier returns medium / low confidence, when a build fails, or when the rebase finishes. Most rebases should run end-to-end without intervention.

## MANDATORY: destructive-action invariants

**NEVER** run any of these without an explicit instruction from the user in the current turn:

- `git rebase --abort` — discards the in-flight rebase and any conflict resolutions already staged
- `git rebase --skip` — drops the commit being applied (loses work)
- `git reset --hard`, `git checkout .`, `git restore .` — overwrite working tree
- `rm -rf .git/rebase-merge` / `.git/rebase-apply` — same as `--abort` but silent
- `git commit --no-verify`, `git rebase ... --no-verify` — bypasses hooks

Approval to run the command does NOT extend to these. If a resolution is wrong, surface it; the user decides whether to back out.

**NEVER** add `Co-Authored-By: Claude …` or any other AI attribution to commits, including any commits this skill might end up creating (e.g., `git rebase --continue` re-creating the patch). Enforced by the shared `validate-no-ai-trailer.sh` hook.

## Step 1 — Detect rebase state

Run in parallel (one message, multiple Bash calls):

- `git rev-parse --git-dir` → locate the git dir
- `ls .git/rebase-merge .git/rebase-apply 2>/dev/null` → which rebase variant (or none)
- `git status --porcelain=v2 --branch` → branch state + unmerged paths
- `git diff --name-only --diff-filter=U` → conflicted files

Disambiguate:

| State                                                          | Action                                                                                                                          |
| -------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| No `.git/rebase-merge` or `.git/rebase-apply`, no `MERGE_HEAD` | Halt. Tell the user no rebase is in progress; suggest they run `git rebase <base>` first.                                       |
| `.git/MERGE_HEAD` exists but no rebase dir                     | Halt. This is a merge conflict, not a rebase conflict. This command does not handle merge conflicts; suggest manual resolution. |
| Rebase dir exists, **zero** unmerged files                     | Tell the user to run `git rebase --continue` themselves; nothing to resolve.                                                    |
| Rebase dir exists, unmerged files present                      | Proceed to Step 2.                                                                                                              |

## Step 2 — Snapshot the rebase context (read once, keep in scope)

Run in parallel:

- `cat .git/rebase-merge/msgnum .git/rebase-merge/end` → progress (e.g., "applying 3 of 7")
- `cat .git/rebase-merge/onto` → onto SHA
- `cat .git/rebase-merge/orig-head` → original HEAD before rebase started
- `git rebase --show-current-patch` → full patch of the commit currently being applied (its message + its diff)
- `git log --oneline -10` HEAD → recent commits already applied or on onto-branch

Build the dispatcher's working model:

- **Patch under application**: subject + body + the diff hunks per file
- **Conflicted files**: from `git diff --name-only --diff-filter=U`
- **Stage map per file**: `:1:` (merge base), `:2:` (HEAD = onto-branch side, "ours" in rebase nomenclature), `:3:` (incoming patch's side, "theirs" in rebase nomenclature)

> **Note on rebase orientation:** during `git rebase`, "ours" (`:2:`) is the _upstream_ you are rebasing onto, and "theirs" (`:3:`) is the work being replayed. This is the **opposite** of `git merge`. Use this orientation when reasoning about which side is the patch's intent.

## Step 3 — Resolve each conflicted file

For each conflicted file, in `git diff --name-only --diff-filter=U` order: gather context (3a), classify (3b), then take **either** the auto-resolve path (3c) **or** the escalate path (3d) — never both.

### 3a. Gather

- Read the working-tree file (with conflict markers)
- `git show :1:<file>` → base content
- `git show :2:<file>` → ours / onto-branch content
- `git show :3:<file>` → theirs / incoming-patch content
- The relevant hunks of the patch under application that touch this file (filter the Step 2 patch)
- `git log -5 --oneline -- <file>` → recent history of the file on the onto-branch (explains why ours diverged)

### 3b. Classify the conflict

For each hunk inside the file:

| Class              | Heuristic                                                                                                          | Default proposal                                         |
| ------------------ | ------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------- |
| `trivial`          | Whitespace, import sort order, comment-only — diff is non-semantic                                                 | Take the side that matches the project's style hooks     |
| `additive`         | Both sides add lines in the same region but the additions are unrelated (different identifiers, different imports) | Keep both, in source order                               |
| `semantic-overlap` | Both sides modify the same identifier / signature / value                                                          | Read the patch's commit message for intent; propose; ASK |
| `structural`       | Brace placement, method extraction, large block move                                                               | Always ASK — never auto-propose                          |

Confidence assignment:

- **high** — every hunk in the file is `trivial` or `additive`, the two sides do not modify any of the same source lines, and the file is not in either of the forced-low groups below.
- **medium** — predominantly `semantic-overlap` and the patch's commit message explicitly describes what is changing on those lines.
- **low** — anything else, including mixed `structural` hunks or unclear intent.

**Forced-low (always escalate, regardless of class):**

- **Rename / delete conflicts** — `git status` letters `DD`, `AU`, `UA`, `DU`, `UD`. Textual resolution does not apply; the user picks which side to keep, or whether to recover content from the deleted side.
- **Structured manifests** — `pom.xml`, `package.json`, `pnpm-lock.yaml`, `*.lock`, `Cargo.lock`, `go.sum`. Textual merge of dependency lists or version pins is dangerous. For lockfiles specifically, recommend regenerating from the resolved manifest (`pnpm install`, `./mvnw -N`, etc.) rather than textually merging.

### 3c. Auto-resolve path (high confidence only)

Apply the resolution silently via `Edit`:

- Strip the `<<<<<<<` / `=======` / `>>>>>>>` markers and emit the merged content per the classifier's default proposal (style-hook-conforming side for `trivial`; both sides in source order for `additive`).
- Leave the rest of the file untouched — the edit is scoped to the conflict regions only.
- Emit one log line per file: `auto-resolved <path>: <classification summary> · <hunk count> hunk(s)`.

No user prompt. The full-reactor build before `--continue` (Step 4) is the gate.

### 3d. Escalate path (medium / low / forced-low)

In one message, present:

1. The file path and a one-line summary of the conflict.
2. The classification + confidence (and the forced-low reason if applicable).
3. The proposed resolution as a unified diff against the current working-tree file (with conflict markers stripped). For rename/delete and lockfile cases, propose options instead of a single diff: e.g., "keep ours / keep theirs / restore from `:1:`" or "regenerate via `pnpm install`."
4. The reasoning — cite the patch's commit message for `semantic-overlap`, the recent log for `additive` overlaps the classifier downgraded, the file-type rule for forced-low.

Wait for the user. Acceptable replies: `yes` / `go` / `apply` / a corrected diff / pick-an-option / `skip — I'll do this one` / `abort`.

- On "yes" / pick-an-option: apply via `Edit` (preferred) or `Write` (only if the whole file is being replaced).
- On a corrected diff: apply the user's version verbatim.
- On "skip": leave the file with markers; record it for the Step 4 summary; the loop will halt before `--continue` so the user can finish manually.
- On "abort": stop the command. Do NOT run `git rebase --abort` — just exit. The user owns that decision.

## Step 4 — Stage & continue

After every conflicted file is resolved (or explicitly skipped):

1. **Resolution summary** (skip if zero auto-resolutions occurred — it's just noise). Print a single block:
   - `auto-resolved: N` — list each file with its classification.
   - `escalated: M` — list each file with its resolution outcome (applied / corrected / skipped).
   - The user can object inline before the build kicks off; default is to proceed.
2. **Skipped files halt the loop.** If any file was skipped in 3d, stop here and report — the user must finish those manually before `--continue` can proceed.
3. **Stage** — `git add` exactly the files that were resolved (do NOT use `git add -A` / `git add .` — only the files this turn touched, to avoid sweeping in unrelated working-tree edits).
4. **Full reactor build** before `--continue`: `./mvnw clean install` (Java-heavy patches) or `pnpm -r build` (TS-heavy). Skip if the patch touched only documentation or other non-compilable files.
5. **If green** — `git rebase --continue`. The rebase commit message defaults to the original; do NOT pass `-m` or amend.
6. **If red after auto-resolutions** — this is the safety-net trigger. Halt the loop, surface the build error tail, list which auto-resolved files most plausibly caused the failure (cross-reference the error trace against the auto-resolution log lines), and ask the user how to proceed. Do NOT auto-revert, do NOT silently retry, do NOT abort.

## Step 5 — Loop or finish

After `git rebase --continue`:

- If git stops at the next conflict, loop to Step 2 with the new patch context. **No user prompt at the loop boundary** — the user is engaged only on classifier escalations (Step 3d), build failures (Step 4.6), or final completion. The loop runs end-to-end as long as every conflict classifies high-confidence and every build stays green.
- If git reports `Successfully rebased and updated <ref>`, run `git status` and `git log --oneline -10` to confirm clean state. Report:
  - Number of commits replayed
  - Per replayed commit: `auto-resolved: N · escalated: M` and the file list for each
  - Final HEAD SHA + branch

## Guardrails (enforced every turn)

- **Auto-resolve only on high confidence.** Trivial / additive hunks with no overlapping line edits, file not in a forced-low group. Anything else escalates — including all `semantic-overlap`, all `structural`, all rename/delete conflicts, and all structured manifests / lockfiles.
- **Build is the safety net.** A green full-reactor build is the line between "march on" and "stop and ask." Build red after auto-resolutions halts the loop and surfaces to the user; never auto-revert, never silently retry, never abort the rebase.
- **Build-gate before every `--continue`.** Green ≠ semantically correct, but red is always a stop.
- **Atomic edits.** Use `Edit` to remove conflict markers and apply the resolution. Don't restructure the file beyond the conflict region.
- **Preserve the patch's commit message.** `git rebase --continue` reuses it; never override.
- **Respect destructive-action invariants** from the top of this file. When in doubt, ask.
