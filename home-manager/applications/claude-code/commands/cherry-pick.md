---
description: Cherry-pick a Linear ticket's merged work onto one or more target version branches and open MRs.
argument-hint: <linear-ticket-id> <version> [version...]
---

# Cherry-pick to versions

Cherry-pick the merge commit of a Linear ticket's MR onto one or more version branches, opening a new MR per target version.

## Inputs

- `$1` — Linear ticket ID (e.g. `ENG-1234`)
- `$2..$N` — one or more target versions (e.g. `v114`, `v115`, `latest`)

## Procedure

### 0. Preflight — verify tooling

Before doing anything else, confirm both integrations are usable. If either check fails, **STOP** and tell the user exactly what to fix.

**GitLab CLI (`glab`):**

```bash
command -v glab >/dev/null || echo "MISSING: install glab (https://gitlab.com/gitlab-org/cli)"
glab auth status
```

- `glab auth status` must report an authenticated host matching the current repo's GitLab remote.
- If unauthenticated, instruct the user to run `glab auth login`.
- Confirm the current repo resolves on GitLab: `glab repo view --output json | head -c 200` should not error.

**Linear MCP:**

- Confirm the Linear MCP server is connected (the system prompt lists `linear` under "Currently Connected Servers" in the 1MCP block).
- Probe with a cheap call, e.g. `mcp__1mcp__linear_1mcp_get_issue` for `$1`. If it returns an auth error or "not connected", instruct the user to run `/mcp` and reauthenticate Linear.

Only proceed once both checks pass.

### 1. Locate the source branch

Use the Linear MCP to fetch the ticket and find the linked branch.

- Fetch the ticket with `mcp__1mcp__linear_1mcp_get_issue` (use `$1`).
- Look for a linked Git branch on the ticket itself (`branchName` / attachments / linked PR-MR fields).
- If none, traverse:
  - **Parent ticket** — if the ticket has a parent, fetch it and look there.
  - **Child tickets** — list children and check each.
- If still nothing is found, **STOP** and ask the user for the branch name or MR URL. Do not proceed.

Also locate the **merge commit SHA** of the source MR (this is what gets cherry-picked, not individual commits — a single merge commit preserves the full change as one unit).

### 2. Determine the parent ticket for sub-issues

- If `$1` is **version-specific** (title or labels reference a version like `v114`, or it is itself a sub-issue of a generic ticket), use its **parent** as the anchor for new sub-tickets.
- Otherwise, use `$1` itself as the anchor.

### 3. Resolve target branches per version

Inspect tags to determine which version is the latest:

```bash
git fetch --tags --quiet
git tag --sort=-v:refname | head -20
```

For each requested version, map to a target branch:

| Requested version | Target branch |
| ----------------- | ------------- |
| Latest version (highest tag) | `develop` |
| Version immediately before latest | `preprod` (if it exists) |
| Any other version `vNNN` | `preprod_vNNN` |

If `preprod` does not exist for the previous version, fall back to the `preprod_vNNN` pattern for that version too. Verify each target branch exists on the remote before proceeding:

```bash
git ls-remote --heads origin <target-branch>
```

If a target branch is missing, **STOP** and ask the user.

### 4. Create a Linear sub-ticket per version

For each target version, create a sub-issue of the anchor ticket (from step 2) using `mcp__1mcp__linear_1mcp_save_issue`:

- Title: `<original title> [vNNN]` (or `[develop]` for the latest)
- Parent: anchor ticket ID
- Team / project / assignee: copy from anchor ticket
- Description: link back to the source ticket and source MR

Capture each new ticket's ID and branch name (Linear auto-generates `branchName` — use it for the cherry-pick branch).

### 5. Cherry-pick per version

For each `(version, target_branch, sub_ticket)`:

```bash
git fetch origin
git checkout -b <sub_ticket_branch> origin/<target_branch>
git cherry-pick -m 1 <merge_commit_sha>
```

Conflict handling:

- **Simple conflicts** (whitespace, imports, obvious context drift, non-overlapping hunks the tooling can resolve): resolve them, `git add` the files, `git cherry-pick --continue`.
- **Non-trivial conflicts** (overlapping logic, ambiguous intent, schema/migration conflicts, anything where the right resolution is not obvious): **STOP**, leave the working tree as-is, and ask the user how to resolve.
- Always record per-version whether a conflict occurred (even if simple).

Push and open the MR using the GitLab CLI (`glab`):

```bash
git push -u origin <sub_ticket_branch>
glab mr create \
  --source-branch <sub_ticket_branch> \
  --target-branch <target_branch> \
  --title "<sub-ticket title>" \
  --description "$(printf 'Cherry-pick of %s onto %s for %s.\n\nLinear: %s\nSource MR: %s\n' "<merge_commit_sha>" "<target_branch>" "<version>" "<sub_ticket_url>" "<source_mr_url>")" \
  --remove-source-branch \
  --squash-before-merge=false \
  --yes
```

- MR title mirrors the sub-ticket title.
- MR description links the sub-ticket and the source MR.
- Capture the MR URL from `glab` output for the final report.

### 6. Final report

Output:

1. **Source branch / merge commit** that was cherry-picked.
2. **Per-version table**: requested version → target branch → sub-ticket ID/URL → MR URL → conflict status (`none` / `resolved (review recommended)` / `unresolved — user input needed`).
3. **Explicit conflict warning**: if any version had conflicts (simple or otherwise), call it out clearly at the top of the output and tell the user to review those MRs before merging.
4. List of all MR URLs at the end, one per line, for easy copy-paste.

## Guardrails

- Never force-push.
- Never skip hooks (`--no-verify`).
- Do not invent a target branch — if the mapping is ambiguous, ask.
- Do not guess the merge commit — confirm via Linear/MR metadata.
- If the source ticket has no linked branch anywhere in its hierarchy, stop and ask.
