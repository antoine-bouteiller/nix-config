---
name: publish-draft-review
description:
  Create unpublished inline DRAFT review comments on a GitLab merge request diff via the
  GitLab API. Use when a code review has produced findings that should be attached to exact
  diff lines as drafts (not published) so the human can review and submit them in one batch.
  Carries a ready-to-post dataset for Phoenix MR !145 (View360 view-based rework).
---

# Publish Draft Review

Posts inline **draft notes** (unpublished review comments) onto a GitLab MR diff, anchored to
exact file:line positions. Drafts are visible only to the author until the GitLab "Submit review"
button (or the `bulk_publish` endpoint) is pressed — nothing is published by this skill.

## Hard-won mechanism (read before posting — these footguns cost real time)

1. **Use a JSON request body via `--input <FILE>`, never `-f "position[...]"`.**
   `glab api -f` flattens form fields and the nested `position` object comes back **null** — the
   note is created but as a *general* (non-inline) draft. The position object MUST be sent as a
   JSON body.
2. **`--input -` (stdin) is unreliable here. Use a real file path.** Piping the JSON into
   `glab api --input -` inside a function/heredoc produced empty bodies / parse errors. Writing
   the payload to a file and passing the path works every time.
3. **This environment's shell PATH is minimal.** `jq`, `mktemp`, `rm`, sometimes `python3` are
   "command not found". Call binaries by absolute path: `jq` at `/run/current-system/sw/bin/jq`,
   `glab` at `/run/current-system/sw/bin/glab` (verify with `command -v` first). Avoid
   `mktemp`/`rm`/`cp` — write payload files with the **Write tool** instead.
4. **Anchor only to lines that appear inside a diff hunk.** GitLab cannot attach a comment to a
   line outside the diff. Prefer **added** lines (prefixed `+`): their position needs only
   `new_path` + `new_line`. For **context** lines you must also supply `old_line` (compute by
   walking the hunk headers). If the line you want is outside any hunk, anchor to the nearest
   added line and reference the real line in the comment text.
5. **Get `diff_refs` from the MR, not from local git.** `base_sha` / `start_sha` / `head_sha`
   come from `GET projects/:id/merge_requests/:iid`. (For !145 the `base_sha` happened to equal
   the local merge-base, but do not assume that in general.)

## Generic workflow

```bash
JQ=/run/current-system/sw/bin/jq
GLAB=/run/current-system/sw/bin/glab

# 1. Identify the MR + diff refs
$GLAB mr view                                   # MR number for current branch
$GLAB api "projects/:id/merge_requests/<IID>" | $JQ '{project_id, diff_refs, sha}'

# 2. For each finding, write a payload JSON FILE (use the Write tool, not shell heredocs):
#    { "note": "...markdown...",
#      "position": { base_sha, start_sha, head_sha, position_type:"text",
#                    old_path, new_path, new_line } }
#    old_path == new_path for added/context lines. Add "old_line" for context lines.

# 3. POST each as a draft note:
$GLAB api --method POST "projects/<PID>/merge_requests/<IID>/draft_notes" \
  --header "Content-Type: application/json" --input "/path/to/payload.json" \
  | $JQ -r 'if .id then "OK draft \(.id) @ \(.position.new_path):\(.position.new_line)" else "FAIL \(tostring)" end'

# 4. Verify (look for non-null line_code = correctly anchored inline):
$GLAB api "projects/<PID>/merge_requests/<IID>/draft_notes" \
  | $JQ -r '.[]|"\(.id) \(.position.new_path):\(.position.new_line) line_code=\(.line_code)"'

# 5. (Only when the human says so) publish all drafts at once:
# $GLAB api --method POST "projects/<PID>/merge_requests/<IID>/draft_notes/bulk_publish"

# Delete a stray draft:
# $GLAB api --method DELETE "projects/<PID>/merge_requests/<IID>/draft_notes/<NOTE_ID>"
```

## Ready-to-post dataset — Phoenix MR !145 (View360 view-based rework)

- **MR**: `!145` — "Draft: PHX-50: Switch from book row to entity/view level on view360"
  (https://pelilab.pelico.tech/data-platform/phoenix/-/merge_requests/145)
- **project_id**: `397`   **merge_request_iid**: `145`
- **diff_refs** (all three): `base_sha` = `start_sha` = `3fc68defe5dbbd6e380ad46549595708e80fa230`,
  `head_sha` = `46c00adfc79da7cd3523c515c64dcc83b86e7d0d`
- Payloads colocated in `payloads/` next to this file (`finding1.json` … `finding6.json`),
  already encoding the correct positions and `diff_refs`.

| File | File:Line (head) | Severity | Topic |
| ---- | ---------------- | -------- | ----- |
| `payloads/finding1.json` | `ViewResource.java:109` | Improvement | Union-backed view → uncaught `UnsupportedOperationException` becomes HTTP 500 not 4xx; catch it → 400/422 or validate at boot |
| `payloads/finding2.json` | `ViewResource.java:98`  | Improvement | `Long.parseLong` forces numeric ids while `ViewRow.id`/`Row.id()` are `String` — UUID/string PKs would always 400 |
| `payloads/finding3.json` | `ViewResource.java:120` | Improvement | Duplicate-id warn branch (page size 2 → log.warn → return first) is untested |
| `payloads/finding4.json` | `Typography.tsx:51`     | Improvement | Shared DS link-color behavior change bundled in; `kind="link"` now skips color class — affects every link app-wide |
| `payloads/finding5.json` | `View360Container.tsx:51` | Nitpick | `header` shape inconsistent — `isLoading` branch omits `tags` that the other branches set |
| `payloads/finding6.json` | `useViewData.ts:32`     | Nitpick | `rowId!` non-null assertion vs. project's type-guard preference; `isNotNullOrUndefined` already imported |

> **Status note:** these six drafts were already created in the originating session
> (draft ids 41798–41803). Before re-posting from `payloads/`, list existing draft_notes first to
> avoid duplicates; delete the old ones or skip re-posting as appropriate.

### One-shot publish-from-dataset

```bash
JQ=/run/current-system/sw/bin/jq
GLAB=/run/current-system/sw/bin/glab
SKILL_DIR="$HOME/.claude/skills/publish-draft-review"
for n in 1 2 3 4 5 6; do
  $GLAB api --method POST "projects/397/merge_requests/145/draft_notes" \
    --header "Content-Type: application/json" --input "$SKILL_DIR/payloads/finding$n.json" \
    | $JQ -r 'if .id then "OK finding'"$n"' -> draft \(.id) @ \(.position.new_path):\(.position.new_line)" else "FAIL finding'"$n"' -> \(tostring)" end'
done
```

If line numbers have drifted because the branch was rebased/amended, re-derive `head_sha` from the
MR and recompute `new_line` for each anchor against the new diff before posting.
