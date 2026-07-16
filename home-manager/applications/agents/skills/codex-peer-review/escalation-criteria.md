# Escalation Criteria

When to escalate disagreements for external research and authoritative resolution.

**Note:** This skill is intentionally agnostic about _how_ external research happens. Use whatever research capability is available to the host agent — web search, an MCP-provided research tool, documentation lookups, or any combination. Pick the best tool for the question, not a fixed one.

## Immediate Escalation (Skip Per-Issue Debate)

These trigger direct escalation to external research — they do not enter the per-issue state machine. The orchestrator detects these in the canonicalized issue table after Round 0 and routes them to arbitration in parallel with the normal debate.

| Category         | Examples                                 | Why Skip Discussion      |
| ---------------- | ---------------------------------------- | ------------------------ |
| Security         | Auth bypass, injection, secrets exposure | Risk too high for debate |
| Architecture     | Fundamental design conflicts             | Need expert judgment     |
| Breaking Changes | Backward compatibility disputes          | Impact too broad         |
| Performance      | Order-of-magnitude disagreements         | Need verification        |

**Rule:** If either AI flags a security concern, escalate immediately regardless of the other's opinion.

## Escalation After Per-Issue Debate

After the round cap, any issues still in `escalated` state become `deferred` and are presented as **Contested** in the verdict. If a contested issue is **high-severity**, also trigger external research to give the user a third opinion.

### 1. Contested high-severity issues

- Final state is `deferred`
- Severity is `high` or `critical`
- Both AIs maintained position with new evidence each round

### 2. Low Confidence, High Stakes

- Neither AI can provide strong evidence
- But the decision has significant consequences
- "We're both guessing on something important"

### 3. Novel Situation

- Neither AI has clear precedent to cite
- Project conventions don't cover this case
- Industry standards are ambiguous or conflicting

### 4. Factual Dispute

- Disagreement is about verifiable facts
- One AI might be working from outdated information
- External research can provide an authoritative answer

## Do NOT Escalate

Reserve external research for genuine disputes. Do not escalate:

| Category                  | Why Not                 | Resolution                   |
| ------------------------- | ----------------------- | ---------------------------- |
| Minor style disagreements | Not worth research time | Defer to project conventions |
| Documentation wording     | Subjective preference   | Defer to user context        |
| Test coverage thresholds  | Project-specific        | Use project standards        |
| Naming conventions        | Style guide territory   | Use project standards        |
| Formatting preferences    | Tooling handles this    | Use formatter config         |

## How to Conduct External Research

The peer review skill does not prescribe a research backend. The host agent should pick the best tool for the question — web search, MCP-provided research tools, vendor documentation, language/framework specs, or any combination thereof. Whatever tools are available, use them.

Two principles regardless of the tool you pick:

1. **Frame the question neutrally.** Do not bias the research toward either AI's position.
2. **Cite your sources.** Capture URLs, doc titles, or tool identifiers so the user can audit the ruling.

### Neutral question template

```
## Disagreement Context

Topic: [specific technical question]
Codebase: [language / framework / version]
Project context: [relevant constraints, conventions, scale]

Position A: [summary]
- Evidence: [key evidence]
- Reasoning: [technical reasoning]

Position B: [summary]
- Evidence: [key evidence]
- Reasoning: [technical reasoning]

Debate summary: [what was tried, why it didn't resolve]

Question: Which approach is correct for this situation and why?
What does authoritative documentation, current best practice, or
production experience say? Be direct and decisive — or, if both
approaches are defensible, explain the trade-offs explicitly.
```

Drop this into whatever research tool you have. The shape is the same regardless of backend.

### What to look for

Prioritize sources in roughly this order, regardless of which tool surfaced them:

1. Official language / framework documentation and RFCs
2. Vendor or maintainer engineering posts
3. Well-established engineering blogs (large companies with skin in the game)
4. Stack Overflow / GitHub issues with high engagement and recent activity
5. Anything else, treated with appropriate skepticism

A single authoritative source beats five blog posts.

## Handling External Research Response

### Accept as Authoritative

- For this specific case, the research ruling is final
- Do not re-litigate after receiving the response
- Apply the ruling to the verdict

### Document for Future

- Note the ruling in the final output
- Include source URLs / identifiers
- If a pattern emerges across reviews, consider proposing it as a project convention

### If Research is Inconclusive

If external research can't provide a clear answer:

1. Present both options to the user with trade-offs
2. Note the sources consulted and why they were inconclusive
3. Let the user make the final decision
4. Do not guess

## Escalation Flowchart

```
Issue surfaces in Round 0 canonical table
        |
        v
Security / architecture / breaking change?
        |
    Yes |  No
        |   |
        v   v
   ESCALATE   Enter per-issue debate
   in parallel       |
        |            v
        |       Round cap reached?
        |            |
        |        No  | Yes
        |        |   |
        |        v   v
        |    More    Any escalated → deferred
        |    rounds       |
        |                 v
        |       High-severity & deferred?
        |             |
        |         Yes | No
        |             |  |
        v             v  v
   Final synthesis   ESCALATE  Mark as
   includes          for       Contested
   research          arbitration in verdict
   findings
```
