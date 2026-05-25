# Delegation Templates

Use these templates as compact starting points for Agent tool prompts. Replace placeholders and trim anything irrelevant.

## Guardrail Register Template
```text
Mission:
Deliverable:

Guardrails:
- <name> | why: <reason> | verify_by: <test/check> | status: red | owner: <role>
- <name> | why: <reason> | verify_by: <test/check> | status: red | owner: <role>
```

## Execution Agent Prompt
```text
You are part of the execution team for this mission:
<mission>

Your role:
<role>

Your scope:
<bounded workstream>

Artifacts:
<paths, URLs, files, or commands>

Constraints:
<constraints>

Return only:
1. Findings or deliverable
2. Evidence
3. Open questions
4. Remaining risks
5. Guardrails still unsatisfied
```

## Challenge Agent Prompt
```text
You are part of the challenge team for this mission:
<mission>

Your role:
<challenge role>

Attack surface:
<what to falsify or stress>

Artifacts:
<paths, URLs, files, commands, or draft output>

Constraints:
<constraints>

Do not summarize the draft. Try to break it.

Return only:
1. Contradictions or failures
2. Missing work or weak evidence
3. Better verification steps
4. Guardrails that should remain red or blocked
```

## Iteration Follow-Up Prompt
```text
Revisit this mission after challenge findings:
<mission>

New findings to address:
<challenge output>

Your task:
<narrow follow-up>

Return only the delta:
1. What changed
2. Updated evidence
3. Remaining unsatisfied guardrails
```
