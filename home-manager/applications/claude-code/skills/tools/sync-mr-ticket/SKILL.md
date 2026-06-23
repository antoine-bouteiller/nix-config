---
name: sync-mr-ticket
description:
  Update a GitLab merge request's title + description and the Linear ticket linked to it,
  auto-discovering both from the current git branch. Use when the user asks to "update the
  MR", "update the MR and ticket", "sync the MR description", or after rewriting commits /
  finishing a feature. The MR is found by branch (never assume the !N), and the Linear
  ticket key is derived from the branch name (e.g. phx-118-… → PHX-118).
allowed-tools: Bash, Read, Grep
---

# Sync MR + Linear ticket

Updates the MR title/description and the linked Linear ticket for the **current branch**.
Discover everything from the branch — never hardcode an MR number or ticket ID.

## Steps

### 1. Discover the branch and MR

```bash
branch=$(git rev-parse --abbrev-ref HEAD)
glab mr list --source-branch "$branch"   # → the !N (iid). Bail if 0 or >1.
```

There may be **several open MRs**; only the one whose source branch matches is yours. Do not
trust an MR number from earlier context — re-resolve it from the branch every time.

### 2. Write the description

Summarize the actual change, concisely. For multi-module work, one bullet per module:

```
Add <feature>, end-to-end.

- **core-api**: …
- **app-builtins**: …
- **service-bootstrap**: …

Spec: `doc/architecture/specs/<stem>.spec.mdx` (if spec-driven)
```

Keep it tight — bullets over prose. Do **not** include the MR link in either the MR or the
ticket (GitLab/Linear auto-link). No AI attribution.

### 3. Update the MR

```bash
glab mr update <iid> \
  --title "<type(scope): concise title>" \
  --description "$(cat /tmp/mr-desc.md)"
```

Match the repo's commit-type convention for the title (e.g. `spec(...)`, `feat(...)`).

### 4. Derive the Linear ticket key

The branch is prefixed with the ticket: `phx-118-add-entity-column-filter` → `PHX-118`.

```bash
echo "$branch" | grep -oiE '^[a-z]+-[0-9]+' | tr '[:lower:]' '[:upper:]'
```

If the branch has no ticket prefix, ask the user for the ticket ID.

### 5. Update the Linear ticket

Linear writes go through the **claude.ai Linear** MCP, which is OAuth-gated. If its
issue-update tool isn't available, the user must run `/mcp` → select **claude.ai Linear** →
authenticate (the Pelico Context Layer connection is read-only and does **not** cover this).

Once connected:
- Fetch the ticket by its key first, so you preserve any existing context above the
  implementation summary instead of clobbering it.
- Update the **description** to match the implemented scope (same body as the MR, minus the
  MR link — Linear auto-links the branch/MR).

## Notes

- Re-resolve MR and ticket from the branch on every run — they are the source of truth.
- Confirm with the user before changing ticket **status** (only update description unless asked).
