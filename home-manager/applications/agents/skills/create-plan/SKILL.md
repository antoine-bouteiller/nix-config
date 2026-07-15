---
name: create-plan
description: Research a task and write a phased plan to .plan/<slug>.md without implementing it. Use when the user wants to plan a feature or change before building, asks to "make a plan", or when a task is large enough to design before touching code. Replaces built-in plan mode.
---

# Create a plan

Produce a written plan and stop before implementing. You are designing, not building.

## 1. Understand the task

Read the request and the code it touches. Resolve every ambiguity now: if scope, approach, or acceptance
is unclear, ask the user — never assume. Done when you can state the goal and acceptance in one paragraph
with no open questions.

## 2. Research

Find the files, patterns, and constraints the change depends on. Done when every step you're about to write
names the real code it acts on (path:line), not a guess.

## 3. Write the file

Write `.plan/<slug>.md` in the format below. Break the work into phased steps, each with one verifiable
outcome. Done when the file exists and a reader could execute it without asking you anything.

## 4. Hand off

Show the plan path and the step list. Do not implement — that is `implement-plan`'s job. Done when the user
has the plan and knows to run `implement-plan` to execute it.

## Plan file format

The single source of truth for how plans live on disk. `implement-plan` builds on this.

### Location

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

### Template

```markdown
# <Title>

**Status:** in-progress
**Goal:** <one paragraph — what and why>

## Context

- <relevant files as path:line, constraints, decisions already made>

## Steps

- [ ] <imperative step, one verifiable outcome>
- [ ] <…>

## Detailed implementation

<per-step concrete detail: exact commands, diffs or code sketches against real
paths, and the verification for each step. An implementer should be able to
execute from this section alone.>

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

### Rules

- One step = one checkable outcome. A step you can't tell done-from-not-done is vague — sharpen or split it.
- `## Detailed implementation` carries the how: real commands, code sketches, diffs. In the folder
  shape it lives in the phase files instead of the master.
- `Status:` stays `in-progress` until every step is `[x]`, then `done`. In the folder shape, status
  lives only in the master `index.md`.
- **The file is the state.** Tick `- [ ]` → `- [x]` the moment a step's outcome holds, and append a Log line
  for any decision or deviation. Anything true about the plan that isn't written down is lost when the session ends.
