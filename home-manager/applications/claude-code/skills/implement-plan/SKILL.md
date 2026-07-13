---
name: implement-plan
description: Load a plan from .plan/ and execute it, ticking steps and logging progress as you go. Use when the user wants to continue, resume, or execute a plan, or says "keep going on the plan". Pairs with create-plan.
---

# Resume a plan

## 1. Load the plan

Read the format at `~/.claude/skills/plan/SKILL.md`. Find the plan in `.plan/`: if one file, use it; if
several are `in-progress`, ask which. Read it fully — Context, Steps, and Log. Done when you know the goal
and the first unchecked step.

## 2. Execute the next step

Do the first `- [ ]` step, following the plan's Context and the repo's conventions. Done when the step's
outcome actually holds — verified, not assumed.

## 3. Record it

Tick the step `- [x]` and append a Log line for anything you decided or changed against the plan. Done when
the file reflects reality. **The file is the state** — if it's not written down, it's lost.

## 4. Loop or stop

Repeat 2–3 until every step is `[x]`, then set `Status: done`. Stop early and report if a step is blocked or
the plan no longer matches the code. Done when the plan is `done` or you've handed a blocker back to the user.
