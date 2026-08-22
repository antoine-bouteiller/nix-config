---
name: writing-plan
description: Plan a change before building — a phased task list at .plan/<slug>.md where every task has one goal and one runnable validation. Use when asked to make or update a plan, or when a change is large enough to design before touching code. Replaces built-in plan mode.
---

# Writing a plan

Produce an implementation-ready plan and stop before implementing. You are designing, not building.

A plan is a working document: an ordered task list where every task has one clear goal and one
runnable validation. It records **how**. Durable design intent belongs in a spec (`writing-spec`).

**Editing an existing plan:** skip to step 4, keep IDs stable and append new ones, record every
change in `Log`, then rerun the readiness gate.

## 1. Understand the task

Read the request and the code it touches. Identify the in-scope outcomes, non-goals, acceptance
criteria, constraints, assumptions, and material unknowns. Ask the user about anything that could
change architecture, scope, data, security, or verification; never silently invent it. Done when the
goal and acceptance criteria are unambiguous and every assumption is bounded and user-confirmed.

## 2. Research

Trace the current behavior end to end. Record existing code with `path:line` evidence, affected
callers and interfaces, project instructions, applicable tests and checks, and the narrowest correct
change point. Inspect the concrete symbols, signatures, data flow, invariants, failure paths, and
test fixtures each task must preserve or alter. Done when every task names real code and runnable
verification rather than guesses.

## 3. Decide

For each non-obvious implementation choice, record `Decision / Rationale / Alternatives rejected`.
Justify every new dependency, abstraction, or layer and explain why the simpler option is
insufficient. Skip ceremonial decision records for obvious local edits. Done when an implementer
does not need to choose an approach.

## 4. Write the file

Write `.plan/<slug>.md` in the format below, with `status: draft`. Use the single-file shape by
default and split only when independently verifiable phases contain too much detail for one readable
file. Done when a reader could execute every task without asking for missing detail.

## 5. Validate readiness

Apply the readiness gate below. Fix every failure before handoff, then change status to `ready` and
append that event to the log. Do not hand off a plan with unresolved material questions.

## 6. Hand off

Report the plan path, acceptance summary, ordered task list, and verification commands. Do not
implement — `implement` executes the plan, one reviewed subagent task per commit. Done when the user
has a `ready` plan and knows how to execute and verify it.

## Plan file format

### Location

Plans live in `.plan/` at the repo root, where `<slug>` is a short kebab-case name from the goal
(e.g. `add-oauth-login`). Create `.plan/` if absent. `.plan/` is a working directory, not a
deliverable — leave it out of commits unless the user says otherwise.

Two shapes:

- **Single file** — `.plan/<slug>.md`. The default; use it whenever one file remains readable.
- **Folder** — `.plan/<slug>/` with `index.md` plus one file per phase. Use only when phase detail
  would make one file difficult to execute; read [`FOLDER-PLANS.md`](FOLDER-PLANS.md) before writing
  one.

Do not generate separate specs, research notes, data models, contracts, quickstarts, task files,
progress JSON, or other companion artifacts unless the user explicitly requests them. The one
exception is a visual artifact under § Visuals.

### Schema

```markdown
---
title: <Change name>
status: draft | ready | in-progress | blocked | done
author: <git config user.name>
date: <YYYY-MM-DD>
related: [] # repo-root-relative paths; the spec this plan implements, when there is one
---

## Problem

<one to three paragraphs: the required outcome and why it matters>

- **G-001:** <goal — the outcome that makes this change worth shipping>

## Scope

### In scope

- <observable capability this plan covers>

### Non-goals

- **NG-001:** <explicitly excluded work, and one clause on why>

## Context

- **Current behavior:** <what exists today, with `path:line` evidence, including affected callers
  and interfaces>

## Acceptance criteria

- [ ] **AC-001:** <observable, testable outcome>

## Implementation

### Phase 1 — <independently verifiable outcome>

**Phase dependencies:** None | <earlier phase names>

- [ ] **T-001** <optional `[P]` marker> <imperative task with one checkable outcome>
  - **Acceptance:** AC-001
  - **Dependencies:** None | T-NNN, ...
  - **Paths:** <exact repository-relative paths; mark new paths `new`>
  - **Change:** <specific symbols/sections and behavior to add, alter, or remove>
  - **Implementation details:**
    - **<concern>:** <one implementation behavior, boundary, invariant, or failure rule>
    - **<concern>:** <another concern; use one short inline sentence instead when there is only one>
  - **Code example:** <short representative signature, data shape, call, query, or pseudocode; `None`
    only when the change is mechanical>
  - **Preserve:** <important behavior or `None`>
  - **Verify:** `<runnable command or concrete manual scenario>`
  - **Expected:** <observable success result>

## Final verification

- `<command or scenario>` → <expected result and acceptance IDs covered>

## Decisions

### KD-001 — <implementation decision title>

- **Decision:** <chosen approach>
- **Rationale:** <why>
- **Alternatives rejected:** <credible option and concrete reason; or `None`>

## Assumptions

- <reasonable default chosen because the request did not specify it, or a dependency taken as given>

## Constraints

- <external rule the change must respect; or `None`>

## Open questions

<material questions that block execution, or `None`>

## Log

- <YYYY-MM-DD> Plan created with status `draft`.
- <YYYY-MM-DD> Readiness gate passed; status changed to `ready`.
```

Required sections appear exactly once and in the order shown; write `None` rather than deleting one.
IDs are `PREFIX-NNN`, sequential within their namespace (`G`, `NG`, `AC`, `T`, `KD`), never
renumbered — append new ones and record the amendment in `Log`. Every referenced ID must exist.

### Task detail example

Match the repository's language and conventions. Show the contract and difficult branch, not a full
implementation:

````markdown
- [ ] **T-002** Add bounded retry handling to the existing sync client
  - **Acceptance:** AC-002
  - **Dependencies:** T-001
  - **Paths:** `src/sync/client.ts`, `src/sync/client.test.ts`
  - **Change:** Extend `SyncClient.push` and its tests; keep retry policy inside the existing client.
  - **Implementation details:**
    - **Attempt budget:** Attempt once plus at most `maxRetries`.
    - **Retry boundary:** Retry only `429` and `5xx`; return the final `SyncError` unchanged after the
      budget is exhausted.
    - **Timing:** Honor `Retry-After` before exponential backoff; inject the existing `sleep` seam so
      tests use no wall-clock delay.
  - **Code example:**

    ```ts
    push(batch: EventBatch, options?: { maxRetries?: number }): Promise<PushResult>
    // 400 -> return immediately; 503 -> sleep -> retry; exhausted -> return final SyncError
    ```

  - **Preserve:** Authentication headers and the current `PushResult` error contract.
  - **Verify:** `npm test -- src/sync/client.test.ts`
  - **Expected:** Retry, non-retryable, and exhausted-budget cases pass without real timers (AC-002).
````

Use this level of detail for non-trivial logic. For data work, show the migration/query shape and
rollback boundary; for APIs, show request, response, and error examples; for UI, show state and event
transitions. Keep examples short enough that implementation still happens in code.

### Visuals

When a task's target shape is hard to state in prose, show it — read
`../choosing-visuals/SKILL.md` to pick the view. Plan mockups live beside the plan as
`.plan/<slug>-<description>.html`.

### Rules

- New plans begin as `draft`; handoff is allowed only after the readiness gate passes and status
  becomes `ready`. Before implementation begins, change status to `in-progress`. Log the reason for
  every `blocked` transition. Change status to `done` only after every task and acceptance criterion
  is checked and final verification succeeds.
- Every acceptance criterion describes observable behavior or an inspectable artifact, not an
  implementation action, and is referenced by at least one task and by final verification.
- Every task has one checkable outcome, references at least one acceptance criterion, names exact
  repository-relative paths, and includes dependencies, implementation details, verification, and
  its expected result.
- Keep implementation details **scannable**. A single concern may be one short inline sentence. When
  a task has multiple concerns, put `Implementation details` on its own line and use nested bullets
  with bold leading labels such as `**Data flow:**`, `**Failure:**`, or `**Boundary:**`; keep one
  concern per bullet. Split ordered work into numbered nested steps. Never compress independent
  behaviors, paths, invariants, and failure rules into one paragraph.
- Omit `[P]` unless a task has no incomplete dependency and its write paths do not overlap another
  parallel task. Encode shared-file and API ordering through task dependencies.
- Existing-code references use `path:line`. Label new paths `new` and identify the existing parent or
  module that will own them.
- Include a compact code example for each non-trivial contract, algorithm, data shape, or integration
  boundary. Prefer signatures, representative calls, queries, and pseudocode over complete bodies.
- Record only decisions that materially affect implementation. Explicitly justify added
  dependencies, abstractions, or layers.
- Final verification covers every `AC-NNN` ID. Build-only checks are insufficient when runtime or
  user-visible behavior is affected.
- Single-file plans remain the default.
- **The plan is the state.** Tick tasks and acceptance criteria only when their stated evidence
  exists. Append every scope, decision, status, or implementation deviation to `Log`.

### Readiness gate

Before changing status from `draft` to `ready`, confirm:

- [ ] Every required section is present, and no `TODO`, `TBD`, or placeholder remains.
- [ ] `Open questions` is `None`, and every assumption is written down and user-confirmed where
      material.
- [ ] Every task names exact paths, dependencies, concrete implementation details, runnable
      verification, and expected results; non-trivial behavior has a representative code example.
- [ ] Every multi-concern `Implementation details` block uses labeled nested bullets (or numbered
      nested steps for an ordered procedure); no monolithic implementation paragraph remains.
- [ ] Task dependencies are existing earlier tasks, never self-references, and agree with phase
      ordering; the resulting task and phase dependency graphs are acyclic.
- [ ] Every goal is served by at least one task, every acceptance criterion maps to at least one
      task, and final verification covers every acceptance criterion, including runtime or
      user-visible checks where applicable.
- [ ] Every `[P]` task is free of incomplete dependencies and write-path conflicts.
- [ ] In a folder plan, every index task link and phase task block have exactly one matching
      counterpart.
- [ ] Every existing-code reference resolves, and each new path is labeled and attached to an
      existing owner.
- [ ] New dependencies, abstractions, and layers are necessary and justified.
- [ ] IDs are sequential, unrenumbered, and every reference resolves.

If any check fails, keep status `draft` or mark it `blocked`, resolve the issue, and rerun the gate.
