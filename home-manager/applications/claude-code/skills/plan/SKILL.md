---
name: plan
description: Shared plan-file format and .plan/ conventions. Internal helper for create-plan and resume-plan, not invoked on its own.
disable-model-invocation: true
hidden: true
---

# Plan file format

The single source of truth for how plans live on disk. `create-plan` and `resume-plan` both build on this.

## Location

Plans live in `.plan/` at the repo root, where `<slug>` is a short kebab-case name from the goal
(e.g. `add-oauth-login`). Create `.plan/` if absent. `.plan/` is a working directory, not a
deliverable — leave it out of commits unless the user says otherwise.

Two shapes:

- **Single file** — `.plan/<slug>.md`. The default; use it for anything one file can hold.
- **Folder** — `.plan/<slug>/` with a master `index.md` plus one file per phase
  (`.plan/<slug>/01-tooling.md`, …). Use when the plan is large enough that per-phase detail would
  bloat a single file. The master `index.md` is the source of truth for status and the step list;
  each `## Steps` entry points at the phase file that spells out how (`see 01-tooling.md`). Phase
  files hold the detail; they don't track status — the master does.

## Template

```markdown
# <Title>

**Status:** in-progress
**Goal:** <one paragraph — what and why>

## Context

- <relevant files as path:line, constraints, decisions already made>

## Steps

- [ ] <imperative step, one verifiable outcome>
- [ ] <…>

## Log

- <YYYY-MM-DD> <what changed / what was decided>
```

For the folder shape, the master `index.md` uses the same template; its `## Steps` entries name the
phase file that carries the detail:

```markdown
## Steps

- [ ] Swap the Vite plugin and deps so `vp dev` boots Solid — see `01-tooling.md`
- [ ] Port router + root shell to SolidJS — see `02-router.md`
```

## Rules

- One step = one checkable outcome. A step you can't tell done-from-not-done is vague — sharpen or split it.
- `Status:` stays `in-progress` until every step is `[x]`, then `done`. In the folder shape, status
  lives only in the master `index.md`.
- **The file is the state.** Tick `- [ ]` → `- [x]` the moment a step's outcome holds, and append a Log line
  for any decision or deviation. Anything true about the plan that isn't written down is lost when the session ends.
