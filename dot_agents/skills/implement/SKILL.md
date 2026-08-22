---
name: implement
description: "Implement a piece of work based on a plan, spec, or set of tickets."
disable-model-invocation: true
---

# Implement

Execute the work by dispatching one small, scoped subagent per task, reviewing each result, and
committing each coherent unit of work. You coordinate; subagents write code. Your context stays
clean for coordination.

## 1. Frame the work

Identify the target and read it, plus the code it touches:

- **A plan** (`.plan/<slug>.md`) — the task list is given. Set `status: in-progress`, create one todo
  per task, and read the spec it references when there is one.
- **A spec or tickets** — derive the task list yourself: ordered, each task one checkable outcome
  with one runnable verification. When the work exceeds roughly three tasks, stop and use
  `writing-plan` first.

Scan the task list once for contradictions — tasks that fight each other, or share a file in the
wrong order — and resolve them before dispatching. Done when every task names real paths and a
runnable check.

## 2. Dispatch one implementer per task

One task, one subagent, one dispatch at a time. Never run two implementers whose write paths
overlap.

The brief is the single source of requirements. It carries: the task's goal, exact
repository-relative paths, the change with its exact values and signatures, the behavior to
preserve, the verification command, and the interfaces or decisions from earlier tasks the task
cannot know. It carries nothing else — no session history, no prior-task summaries, no "read the
whole plan".

Instruct each implementer to work test-first (`tdd`) at the task's seams: failing test, minimal
code, refactor. It runs the task's verification and reports status, the diff summary, test output,
and concerns — it does not commit and does not spawn its own subagents.

Batch same-shape trivial edits — the same one-line change repeated across files — into one dispatch
reviewed as one unit.

Match the model to the task: cheap for mechanical single-file work with complete instructions,
standard for multi-file integration, most capable for design judgment and the final review.

## 3. Review each task

Run the task's verification yourself, then dispatch a fresh `reviewer` with the task diff and the
brief. Two verdicts are required: the change satisfies the task, and the code holds up. Approve
nothing missing either.

Feed findings back to the implementer that wrote the code, at most three rounds; escalate to a fresh
implementer on a stronger model after that. Never fix findings yourself — controller fixes skip
review and pollute your context. Minor findings go to the log for the final review, not into the
loop.

## 4. Commit and record

Commit whole units of work, not tasks. A commit is one **standalone** change: it states one intent,
leaves the tree building and its tests passing, and reads on its own in the log without the tasks
around it. Several approved tasks usually make one — a test task and the code that satisfies it, a
rename and its call sites; one large task can make several. Hold approved tasks until the unit is
whole, then commit it with a message following `../conventional-commit/SKILL.md`. Commit at the last
point the unit is whole: before the next task would mix a second intent in, before switching area,
and before finishing.

When the target is a plan, tick each task and any satisfied acceptance criteria as it is approved,
and append the outcome to `Log` at each commit — commit range, deviations, deferred findings. **The
plan is the state**: it, not your memory, is what survives compaction. Reread it after any
interruption and resume at the first unticked task, with any approved-but-uncommitted work still in
the worktree.

## 5. Finish

Run typecheck and the full test suite. Run the plan's final verification, tick the remaining
acceptance criteria, set `status: done`. Review the whole branch with `code-review` on the most
capable model, dispatch one fix wave for its findings, and report: what shipped, what was deferred,
and every ruling you made with what it costs if wrong.

## Rulings, not stalls

A running implementation does not wait on the user. Ambiguities, plan defects, and conflicts are
yours to decide — the spec binds, the plan argues from it, your judgment settles the rest. Record
each as `Ruling: <decision> — <why> — <cost if wrong>` in the plan's `Log` and keep going.

Stop and ask only for: an irreversible or destructive operation, a security-sensitive action, a side
effect outside this worktree (merge, push to a shared branch, publish), or a defect that leaves every
path forward a guess.
