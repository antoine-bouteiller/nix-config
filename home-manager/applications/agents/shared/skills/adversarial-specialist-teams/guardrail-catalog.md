# Guardrail Catalog

Use this file to build the mission-specific guardrail register before spawning teams. Include every universal guardrail, then add the sections that match the task. A guardrail is only useful if it can be verified.

## Universal Guardrails
- Goal alignment: Confirm the work actually answers the user's mission and deliverable shape.
- Scope completeness: Confirm the work covers all explicitly requested parts and any implied essentials.
- Evidence quality: Prefer primary sources and make evidence traceable.
- Internal consistency: Check that claims, calculations, code, and conclusions do not contradict each other.
- Constraint compliance: Confirm the work respects tool limits, permissions, deadlines, policies, and non-goals.
- Assumption visibility: Surface assumptions explicitly instead of burying them.
- Reproducibility: Leave a verifier able to reproduce the important result with the stated artifacts or commands.
- Residual risk disclosure: State what remains uncertain, blocked, or unverified.

## Research and Factual Tasks
- Source freshness: Verify time-sensitive claims against up-to-date sources.
- Citation accuracy: Confirm each cited source supports the exact claim being made.
- Counterevidence coverage: Search for credible disagreement and either resolve or report it.
- Terminology precision: Define ambiguous terms, units, dates, and entity names.
- Coverage breadth: Confirm the answer does not rely on one narrow source or one missing perspective.

## Code and Implementation Tasks
- Behavioral correctness: Confirm the implementation satisfies the requested behavior and edge cases.
- Regression protection: Add or update tests for the changed behavior.
- Static quality: Run the relevant formatter, linter, type checker, or build checks.
- Ownership safety: Avoid overwriting unrelated user changes or conflicting write scopes.
- Interface compatibility: Confirm APIs, configs, schemas, and callers still line up.
- Security and safety: Check auth, secret handling, injection, permissions, and unsafe defaults.
- Migration safety: For schema or data changes, confirm forward path, backfill needs, and rollback story.

## Data and Analysis Tasks
- Query correctness: Validate joins, filters, and time windows against the business question.
- Definition stability: Confirm metric definitions, units, and denominators are explicit.
- Sample integrity: Detect sampling bias, null handling issues, duplicates, and missing segments.
- Calculation auditability: Make formulas and transformations inspectable.
- Sensitivity awareness: Note results that could flip under a different assumption or cut of the data.

## Writing, Planning, and Design Tasks
- Audience fit: Match the tone, detail, and format to the intended consumer.
- Decision usefulness: Make recommendations actionable rather than descriptive only.
- Dependency clarity: Show prerequisites, sequencing, and external dependencies.
- Tradeoff honesty: State what the proposal optimizes for and what it gives up.
- Traceability: Tie major recommendations back to requirements or evidence.

## Operations and Change Management Tasks
- Blast radius awareness: Identify affected systems, users, and rollback boundaries.
- Idempotence and retry safety: Check whether reruns create duplication or damage.
- Observability: Ensure logs, metrics, alerts, or other checks exist for the change.
- Permission boundary: Confirm the workflow does not exceed allowed credentials or environments.
- Rollback readiness: Know how to stop or reverse the change if validation fails.

## Missing-Work Detectors
- Ask what could still be false even if the main draft seems plausible.
- Ask which stakeholder, environment, or edge case has not been represented yet.
- Ask whether the strongest possible challenger would say the work is incomplete, stale, or under-tested.
- Ask whether any key claim lacks a direct verification path.
- Ask whether a different specialist would decompose the mission differently.
