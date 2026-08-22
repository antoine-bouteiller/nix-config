# Folder plans

The multi-file shape of [`writing-plan`](SKILL.md), for a plan whose phase detail would make one file
hard to execute. `.plan/<slug>/` holds `index.md` plus one file per independently verifiable phase
(`01-tooling.md`, …).

`index.md` follows the plan schema and is the only status and checkbox authority — it alone owns
status, acceptance criteria, task checkboxes, final verification, open questions, and the log. Its
`## Implementation` collapses each task to one line pointing at the phase file with the detail:

```markdown
- [ ] **T-001** <optional `[P]` marker> <task outcome; satisfies AC-001> — see `01-phase.md#t-001-task-title`
```

Each phase file carries task detail only, with no status and no checkboxes:

```markdown
# Phase 1 — <independently verifiable outcome>

**Plan:** `index.md`
**Phase dependencies:** None | <earlier phase names>

## T-001 — <task title>

- **Acceptance:** AC-001
- ... (remaining task fields as in the schema)
```

Rules on top of the single-file rules:

- Split only at independently verifiable phase boundaries.
- Task IDs are globally unique across phase files, and each block has exactly one matching `index.md`
  entry.
- Phase files never duplicate the mutable state `index.md` owns.
