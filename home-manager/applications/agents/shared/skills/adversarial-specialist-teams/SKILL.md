---
name: adversarial-specialist-teams
description: "Execute high-assurance tasks with two independent sub-agent teams: a first team of specialists that completes the mission and a second team that challenges the result, expands the guardrails, and forces iteration until the guardrails are satisfied. Use when the user asks for deep research, complex implementation, audits, migrations, designs, planning, or any mission where completeness, correctness, and adversarial review matter more than speed."
---

# Adversarial Specialist Teams

## Overview
Execute the user's mission with two distinct sub-agent teams using the Agent tool. Use one team to produce the result, use a separate team to attack it, and keep iterating until the guardrail register is green or an external blocker remains.

## Required Inputs
Collect or infer:
- `mission`: exact objective and expected deliverable
- `artifacts`: code paths, documents, datasets, tickets, URLs, or commands that define scope
- `constraints`: non-goals, allowed tools, write boundaries, safety rules, deadlines, and compliance limits
- `quality_bar`: what must be true for the task to count as complete
- `validation_surface`: tests, reproducible commands, citations, demos, or review checks

Resolve missing inputs from local context when possible. If a critical ambiguity remains and the wrong assumption would be costly, ask one focused question. Otherwise, state the assumption explicitly and proceed.

## Workflow

### 1. Frame the Mission
- Rewrite the request into objective, scope, deliverable, known unknowns, and likely failure modes.
- Decide what to do locally on the critical path before delegating.
- Decompose the mission into independent workstreams with minimal overlap.
- Open [guardrail-catalog.md](guardrail-catalog.md) before designing the teams.

### 2. Build the Guardrail Register First
- Start with every universal guardrail from the catalog.
- Add task-specific guardrails for the mission type.
- Add mission-specific guardrails for unique risks, stakeholders, or constraints.
- Record for each guardrail:
  - name
  - why it matters
  - how to verify it
  - current status: `red`, `yellow`, `green`, or `blocked`
  - current owner
- Treat unresolved assumptions as failing guardrails until proven safe.

### 3. Assemble the Execution Team
- Match the number and roles of sub-agents to the workstreams, not to a fixed template.
- Give each execution agent (spawned via the Agent tool):
  - a unique responsibility
  - the minimum artifacts needed
  - an explicit output contract
  - evidence requirements
  - clear ownership boundaries
- Prefer diversity of expertise over redundant passes.
- Use [delegation-templates.md](delegation-templates.md) to keep prompts concise.
- For execution agents that need to write code, use `mode: "auto"` in the Agent tool call.
- For research-only agents, use the default mode and tell them explicitly not to write code.

### 4. Run the Execution Team in Parallel
- Launch execution agents with disjoint scopes using **parallel Agent tool calls** in a single message whenever possible.
- Keep the main thread responsible for synthesis, coordination, and any immediate blocking work.
- Require each execution agent to return:
  - deliverable or findings
  - evidence
  - open questions
  - known risks
  - guardrails they believe remain unsatisfied

### 5. Synthesize the First Draft Locally
- Merge the execution team output into a single draft solution.
- Update the guardrail register against evidence, not optimism.
- Identify the weakest claims, thinnest evidence, and highest-risk omissions.
- Do not finalize after the first synthesis.

### 6. Assemble the Challenge Team
- Spawn a separate team via Agent tool calls to falsify the draft and the first team's assumptions.
- Keep the challenge team independent:
  - avoid giving them the intended answer
  - avoid telling them which conclusions to confirm
  - pass only the task-local context needed to attack the work
- Select challengers that cover distinct attack surfaces such as:
  - contradiction review
  - edge-case hunting
  - verification/testing
  - domain skepticism
  - constraint and guardrail compliance

### 7. Iterate Until the Guardrails Are Satisfied
- Convert every challenge into one of three outcomes:
  - fix implemented
  - guardrail added or tightened
  - external blocker recorded
- Send targeted follow-ups to the relevant agent (via SendMessage if it's still running, or spawn a new specialist) when the existing roles are insufficient.
- Re-run validation after every material change.
- Continue until every required guardrail is `green` or explicitly `blocked` by an external dependency.
- Optimize for correctness and completeness, not speed.

### 8. Finalize the Outcome
- Deliver the final result only after the register is closed.
- If any guardrail remains `blocked`, state that the mission stopped because of that blocker rather than implying completion.
- Include the final guardrail status and the material changes caused by the challenge team.

## Team Design Rules
- Size the teams to the task:
  - small, single-discipline, low-risk mission: `1-2` execution agents and `1` challenger
  - medium, multi-step, or medium-risk mission: `2-4` execution agents and `2` challengers
  - large, heterogeneous, or high-risk mission: `3-6` execution agents and `2-4` challengers
- Add an agent only when it has a distinct question, workstream, or write scope.
- Keep one integrator role in the main thread. Do not delegate all judgment.
- Avoid overlapping write ownership between execution agents. Use `isolation: "worktree"` when multiple agents need to write to the same repository.
- If the Agent tool is unavailable, say clearly that the two-team workflow cannot be executed fully. Do not pretend it ran.

## Evidence and Iteration Rules
- Prefer primary sources over summaries.
- Require concrete evidence appropriate to the task: file paths, line references, commands, tests, citations, data samples, or screenshots.
- Keep the challenge team independent from the execution team's framing when independence matters.
- Do not let the execution team serve as the only reviewer of its own work.
- Turn every major criticism into a fix, a test, or an explicit unresolved blocker.
- Update the guardrail register after every iteration so progress is measurable.

## Output Contract
When finishing, always include:
1. The mission outcome.
2. The team composition and why each role existed.
3. The final guardrail register with `green`, `yellow`, `red`, or `blocked` status.
4. The strongest challenges raised by the second team and how they were resolved.
5. The remaining residual risk, external blockers, or validation not run.

## Resources
- Use [guardrail-catalog.md](guardrail-catalog.md) to assemble the mission-specific guardrail register.
- Use [delegation-templates.md](delegation-templates.md) for reusable execution, challenge, and iteration prompts.

## Guardrails for This Skill
- Do not design the teams before defining the guardrail register.
- Do not stop at "looks good." Require testable closure.
- Do not hide failed or blocked guardrails inside narrative prose.
- Do not reuse the same framing for both teams when the point is independent challenge.
- Keep delegation prompts task-local, concise, and explicit about evidence requirements.
