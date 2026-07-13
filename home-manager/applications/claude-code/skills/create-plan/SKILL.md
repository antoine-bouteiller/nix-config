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

Read the format at `~/.claude/skills/plan/SKILL.md` and write `.plan/<slug>.md` to it. Break the work into
phased steps, each with one verifiable outcome. Done when the file exists and a reader could execute it
without asking you anything.

## 4. Hand off

Show the plan path and the step list. Do not implement — that is `implement-plan`'s job. Done when the user
has the plan and knows to run `implement-plan` to execute it.
