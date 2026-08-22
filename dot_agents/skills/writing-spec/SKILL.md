---
name: writing-spec
description: Write or amend a design spec at <slug>.spec.md — problem, key design decisions, principles, non-goals, caveats, components, detailed design, as one file or an umbrella tree of per-component leaves. Use when asked to spec out a feature, architecture, or technical choice, to split a spec across components, or to amend an existing spec. Precedes writing-plan.
---

# Writing a spec

Produce a spec that records **design intent**: the problem, the decisions taken and why, and the
shape of the solution. It is a committed document a future reader uses to understand the design —
not a task list. `writing-plan` turns an accepted spec into an executable plan; do not do its job.

**Editing an existing spec:** skip to step 4, amend in place per the rules below — keep IDs stable,
set `status: amended`, append a `## Changelog` row — then rerun the quality gate.

## 1. Capture the intent

Restate the feature in one paragraph: the problem, who has it, why now. If the user gave a bare
feature name with no problem behind it, ask what it solves before writing anything. Done when you
can name the goals that make this worth building.

## 2. Ground it in the repo

Read the code, docs, and existing specs the feature touches, then write **greenfield**: the spec
describes the designed system as it stands once built, in present tense, as though nothing preceded
it. Grounding shapes the design — which modules exist, which contracts hold, what is feasible — and
then disappears from the prose. Cite `path:line` for a component the design keeps, an external
contract it must satisfy, or a constraint a reader would otherwise doubt. Stay read-only. Done when
the design fits the repo and reads as its own complete account.

## 3. Resolve the shape and confirm the path

Pick single spec or umbrella tree per the shape rules below, derive `<slug>`, and resolve the
location, following the repo's convention when it has one. **Always confirm the shape and path with
the user before writing** — inference is a guess. If the path exists, stop and refuse to overwrite.
Done when the user has approved a shape and an unused path.

## 4. Draft the spec

Write the file with `status: draft`. Fill it from what you know; record every reasonable default you
chose under `## 6. Caveats`. Put choices with no reasonable default — ones that would change scope,
security, or user experience — in `## 9. Open Questions` rather than guessing. Every `[KD-N]` gets a
rationale. For each component, specify concrete types, API contracts, state transitions, invariants,
failure behavior, and integration boundaries wherever they affect correctness. Include compact code
examples for non-trivial contracts and flows. For an umbrella tree, write the umbrella first, then
each leaf, respecting section ownership. Done when a reader who has never seen the codebase
understands what is being built, why it is built that way, and the contracts an implementation must
satisfy.

## 5. Resolve open questions

Present each `[OQ-N]` as one numbered question with 2–4 concrete candidate answers and the
implication of each, using `AskUserQuestion` when available. Ask them together, then fold each
answer into the relevant section. Done when only questions the user chose to defer remain.

## 6. Validate against the quality gate

Apply the gate below. Fix every failure and re-check, up to three passes; if something still fails,
leave it in `## 9. Open Questions` and say so plainly rather than declaring the spec ready. Once it
passes, set `status: review`. Done when the gate passes or the gaps are explicit.

## 7. Hand off

Report the spec path, the goals, the key design decisions, and anything still open. Recommend
`writing-plan` as the next step, and say plainly that acceptance is the user's call — you do not set
`status: accepted` yourself. Do not implement, and do not commit unless asked.

## Spec file format

### Location

One spec, one file.

- **Single-module spec** — colocate: `<module-dir>/<slug>.spec.md`.
- **Cross-cutting spec** — `doc/architecture/specs/<slug>.spec.md`, or the repo's existing spec
  directory when it has one.

`<slug>` is kebab-case, 2–4 words (`event-store`, `add-oauth-login`). Follow the repo's existing
convention over these defaults. Never overwrite an existing spec — refuse and let the user choose.

### Shape: single spec or umbrella tree

An **umbrella** is a spec carrying `kind: umbrella` that holds the shared design for the sibling leaf
specs in its directory; each leaf holds one component's detailed design.

Write a tree when any holds: three or more components with non-trivial detailed design, one
component's §8 heading past ~200 lines, or components that different people or parallel agents will
build. Stay single otherwise — under ~300 lines, one component, or components too coupled to
separate. "This is one write-path, a tree buys nothing" is a successful outcome.

Layout — exactly one umbrella per directory, leaves colocated beside it:

```text
<module-dir>/spec/
├── <area>.spec.md          # kind: umbrella
├── <component-a>.spec.md   # leaf, parent-spec: the umbrella
└── <sub-area>/
    ├── <sub-area>.spec.md  # sub-umbrella: kind: umbrella + parent-spec: <area>.spec.md
    └── <leaf-b>.spec.md
```

Keep each umbrella to **6 leaves or fewer**; group cohesive leaves under a sub-umbrella beyond that.
One leaf owns one disjoint write-path — a leaf spanning several modules is too large, a leaf with no
distinct verification surface folds into a neighbour.

**Section ownership.** The umbrella owns §2 goals, §4 principles, §5 non-goals, the §7 inventory and
execution order, and any tree-wide `[KD-N]` / `[C-N]`; its §8 stays a pointer table to the leaves. A
leaf owns its component's §8 plus its own `[KD-N]`, `[C-N]`, and any leaf-scoped `[PI-N]` / `[NG-N]`
that cites the umbrella item it refines. Goals stay umbrella-level. When a leaf supersedes umbrella
design, amend the umbrella in the same change: annotate the item (`superseded by <leaf>:[KD-N]`) and
add a changelog row.

**Links.** `parent-spec:` is the structural up-link and the only field carrying it — leaf to its
colocated umbrella, sub-umbrella to the umbrella above. `related:` stays informational. The downward
direction is implicit: `kind: umbrella` plus the §7 inventory plus colocation.

Do not generate companion artifacts (research notes, checklists, task lists, progress files) unless
the user asks. The quality gate is applied, not written to disk.

### Template

Include every section heading; write `N/A` when a section does not apply. Section 1 is the
frontmatter and needs no heading.

```markdown
---
title: <Feature or component name>
kind: umbrella # umbrella specs only; leaves and single specs omit this field
status: draft | review | accepted | implemented | amended
author: <git config user.name>
date: <YYYY-MM-DD>
parent-spec: # repo-root-relative path to the umbrella above; omit on a top umbrella or single spec
related: [] # repo-root-relative paths to peer specs, ADRs, or docs; informational only
---

## 2. Problem Statement

<2–4 sentences: what problem this solves, why now, who is affected. Business context and
motivation, not implementation detail.>

- `[G-1]` <goal>
- `[G-2]` <goal>

## 3. Key Design Decisions

| Decision             | Choice         | Rationale                          |
| -------------------- | -------------- | ---------------------------------- |
| `[KD-1]` Persistence | Event sourcing | Audit trail required by compliance |

## 4. Principles & Intents

Guiding constraints that shape every subsequent detail; tiebreakers when the design is ambiguous.

- `[PI-1]` <principle — short name, then one clause of meaning>

## 5. Non-Goals

- `[NG-1]` <explicitly excluded capability>

## 6. Caveats

Known limitations, assumptions about external systems, constraints implementers must know.

- `[C-1]` <caveat>

## 7. High-Level Components

Optional diagram (Mermaid or ASCII), then the inventory:

| Component   | Module type | Responsibility | Public API surface         |
| ----------- | ----------- | -------------- | -------------------------- |
| Event Store | Java lib    | Persist events | `EventStore`, `EventQuery` |

An umbrella adds the leaf execution order, one row per leaf:

| Leaf        | Depends on         | Rationale                  |
| ----------- | ------------------ | -------------------------- |
| transport   | —                  | Foundation                 |
| remote-sync | transport `[KD-2]` | Needs the framing contract |

## 8. Detailed Design

Give each component in §7 its own subsection. Include whichever dimensions carry real design
content, with enough precision to implement the contract without inventing behavior:

- **Ownership and boundaries** — owning module, dependencies, and what remains private
- **Data model / types** — fields, types, required/optional rules, defaults, and invariants
- **API surface** — exact public signatures, events, configuration, request/response shapes
- **Control and data flow** — call sequence, state transitions, transactions, concurrency
- **Error handling** — named failure modes, propagation, retries, recovery, and user-visible outcome
- **Persistence and migration** — schema, indexes, consistency, compatibility, and rollback boundary
- **Security and observability** — trust boundaries, authorization, sensitive data, logs, and metrics
- **Examples** — short code, payload, query, or pseudocode examples for non-trivial contracts and
  edge cases

## 9. Open Questions

- `[OQ-1]` <unresolved item needing a human decision> — owner: @name
```

### Detailed-design example

Adapt syntax to the repository. Examples pin down contracts and difficult branches; they are not
complete implementations:

````markdown
### 8.1 Sync Client

`SyncClient` owns retry policy; callers submit a batch once and receive one final result. The client
attempts the request once plus `maxRetries`, retries only `429` and `5xx`, honors `Retry-After`, and
returns the final structured error unchanged when the budget is exhausted.

```ts
type PushResult = { ok: true; accepted: number } | { ok: false; error: SyncError };

interface SyncClient {
  push(batch: EventBatch, options?: { maxRetries?: number }): Promise<PushResult>;
}
```

The injected `Clock.sleep(ms)` is the retry timing boundary, so tests and callers never depend on
real timers. A `400` returns immediately; a `503` waits and retries; cancellation interrupts both
the request and any pending wait.

```text
push(batch) -> POST /events -> 503 -> sleep(backoff) -> POST /events -> PushResult
```
````

Use similarly concrete examples for serialized payloads, database constraints and queries, CLI
invocations, component state transitions, or protocol exchanges. Include normal, boundary, and
failure cases when their contracts differ.

### Visuals

§7 and §8 carry the design's shape; show it rather than describing it — read
`../choosing-visuals/SKILL.md` to pick the view.

### Rules

- `[PREFIX-N]` IDs are sequential within their section, starting at 1: `[G-N]` §2, `[KD-N]` §3,
  `[PI-N]` §4, `[NG-N]` §5, `[C-N]` §6, `[OQ-N]` §9. Never renumber an existing ID; append new ones,
  and sub-version amended items (`[KD-3.1]`). Every referenced ID must exist.
- Record design intent and its rationale — not implementation steps, schedules, or task breakdowns.
  Sequencing belongs in a plan (`writing-plan`).
- Stay greenfield: describe the end state. Which code is added, replaced, deleted, kept, or migrated
  is the plan's judgement, derived by reading the design against the repo — a spec that carries
  deltas decides it twice and goes stale on the first refactor. An amendment is the one place a spec
  speaks of change, and only in its `## Changelog` row.
- Every decision states a rationale. A `[KD-N]` without a reason is a defect.
- Cite existing behavior with `path:line`. Cross-links are repo-root-relative.
- Keep §8 implementation-ready but bounded: specify contracts, invariants, flows, and failure
  behavior; illustrate non-trivial details with small code examples rather than complete bodies.
- New specs start at `draft` and reach `review` only through the quality gate. Only the user sets
  `accepted`.
- Specs are living documents — amend in place, never as a separate amendment file. Set
  `status: amended` and append a `## Changelog` row:

  ```markdown
  ## Changelog

  | Date       | Amendment         | Sections affected | Reason                             |
  | ---------- | ----------------- | ----------------- | ---------------------------------- |
  | 2026-03-15 | Add caching layer | 7, 8.3            | Performance results from load test |
  ```

- Do not invent numbered items the user did not ask for. Propose them and let the user authorize.

### Quality gate

Before moving `draft` → `review`, confirm:

- [ ] Every section heading is present, and no `TBD` or `TODO` placeholder remains outside §9.
- [ ] Every goal in §2 is addressed by something in §3–§8.
- [ ] Every `[KD-N]` states a real rationale, not a restatement of the choice.
- [ ] §7 lists every component §8 details, and §8 details every component §7 lists.
- [ ] Each non-trivial component defines its concrete contracts, invariants, flows, and failure
      behavior, with representative code examples wherever prose would leave implementation choices.
- [ ] Tree: every §7 row has a leaf and every leaf a §7 row; every leaf's `parent-spec:` resolves to
      its directory's umbrella; each section sits at the level that owns it.
- [ ] Every `path:line` citation resolves, and every cross-link points at an existing file.
- [ ] Every statement reads greenfield: the built design in present tense, with no current-state
      narration, before/after comparison, or migration wording.
- [ ] Names carry design intent (`the render pipeline`), not authorship history (`the new pipeline`).
- [ ] IDs are sequential, unrenumbered, and every reference resolves.

If a check fails, stay `draft`, fix it, rerun the gate.
