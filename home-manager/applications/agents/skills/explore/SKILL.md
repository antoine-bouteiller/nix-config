---
name: explore
description: Explore several design solutions for a task and compare their trade-offs without implementing anything. Use when the user wants to weigh approaches before committing, asks to "explore options", "compare designs", or "what are my options" for a change.
---

# Explore design solutions

Lay out the viable ways to solve the task and compare them. You are exploring, not building — no code changes, no plan file.

## 1. Frame the problem

Read the request and the code it touches. State the goal, constraints, and what "good" means in one paragraph. If scope or acceptance is unclear, ask — don't assume.

## 2. Find the options

Identify 2–4 genuinely distinct approaches (not variations of one). For each, ground it in the real code it would touch (path:line). Drop any option that doesn't actually fit the constraints.

## 3. Compare

For each option give: how it works (2–3 lines), main trade-offs (complexity, blast radius, deps, reversibility), and when it's the right pick.

## 4. Recommend

Name the option you'd choose and why, in one paragraph. Do not implement.
