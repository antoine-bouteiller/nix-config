# Discussion Protocol: Per-Issue Debate

The `blind-debate` mode resolves disagreements through a per-issue state machine, not free-form rounds. This file documents the mechanics in detail; SKILL.md has the high-level flow.

## Why per-issue, not per-round

The legacy protocol ran whole-conversation rounds with a top-level `resolved/unresolved` boolean. Two problems:

1. **Style disputes never converged.** "Use Result type" vs "use exceptions" is a project-convention question, not a debatable bug. The loop ran forever or escalated needlessly.
2. **High-severity findings got buried.** A critical security issue and a naming nit had the same weight in the convergence check.

Per-issue states fix both: each finding has its own lifecycle, style is dropped from the loop entirely, and convergence is derived from the table.

## State machine

```
proposed ──┬─► accepted   (terminal: ship as fix)
           ├─► rejected   (terminal: noise, both withdrew)
           ├─► merged     (terminal: dupe of another id)
           ├─► escalated  (carries to next round)
           └─► deferred   (terminal: contested, present both views)

escalated ──┬─► accepted
            ├─► rejected
            └─► deferred  (auto, if no new evidence in round 3)
```

Terminal states drop out of the debate. Convergence = no issues in `proposed` or `escalated`.

## Round structure

### Round 0 — blind pass

Both AIs receive the **identical prompt** with no knowledge of each other. Output: a `findings` JSONL block.

After the round, the orchestrator merges by content-hashed `id`:

```bash
jq -s '
  add
  | group_by(.id)
  | map({
      id: .[0].id,
      file: .[0].file,
      severity: .[0].severity,
      claim: .[0].claim,
      evidence: (map(.evidence) | unique | join(" || ")),
      category: .[0].category,
      source: (if length == 2 then "both" else .[0]._source end),
      status: "proposed"
    })
' /tmp/claude_findings.jsonl /tmp/codex_findings.jsonl > /tmp/canonical.json
```

Findings reported by **both** AIs get `source: "both"` and almost always become `accepted` in round 1 — that's the highest-confidence signal in the system.

### Round 1 — first debate

Each side sees the canonical issue table and emits stances:

```jsonl
{"id":"a1b2","stance":"accept","reasoning":"Confirmed by reading handler.go:42"}
{"id":"c3d4","stance":"defend","reasoning":"This is intentional per ADR-007"}
{"id":"e5f6","stance":"dismiss","reasoning":"Codex is wrong — there's a guard at line 38"}
```

Stances:

| Stance    | Meaning                                 | Required                                             |
| --------- | --------------------------------------- | ---------------------------------------------------- |
| `accept`  | I agree with the issue (mine or theirs) | reasoning                                            |
| `concede` | I withdraw an issue I previously raised | reasoning                                            |
| `defend`  | I maintain this issue                   | reasoning; new_evidence required from round 3 onward |
| `dismiss` | The other AI's claim is wrong           | reasoning, ideally counter-evidence                  |

After both sides respond, the orchestrator transitions states:

| Claude → | Codex → | Result                                                     |
| -------- | ------- | ---------------------------------------------------------- |
| accept   | accept  | **accepted**                                               |
| accept   | defend  | **accepted** (Claude conceded the point Codex was raising) |
| concede  | dismiss | **rejected** (both withdrew)                               |
| dismiss  | concede | **rejected**                                               |
| defend   | defend  | **escalated** (carry forward)                              |
| defend   | dismiss | **escalated** (real disagreement)                          |
| dismiss  | defend  | **escalated**                                              |
| concede  | accept  | **accepted**                                               |

### Round 2 — second debate

Same as round 1, but operates only on `escalated` issues. Each side may include `new_evidence`. New issues raised in round 2 are valid (start as `proposed`) but must clear the lens checks.

### Round 3 — final (only if cap extended)

Same as round 2, but `escalated` issues without `new_evidence` auto-transition to `deferred`.

After round 3, all remaining `escalated` and `proposed` issues become `deferred` and are presented to the user as Contested.

## Lens enforcement

Both lenses (Critic and Defender, see SKILL.md) apply in every round, including the debate rounds.

**Critic lens in debate:** if you're emitting `defend`, your reasoning must contain a concrete failure mode, exploit path, or test case — not "I still think this is risky."

**Defender lens in debate:** before emitting `defend`, check whether an existing test, invariant, or comment already addresses the concern. If yes, switch to `concede`.

## Session resume

Each side's Codex calls use `codex exec resume <session_id>` if a session ID was extracted from the round 0 JSONL. This is a **latency optimization** — round prompts re-inject the canonical issue table either way, so a session-store error degrades speed but not correctness.

```bash
SESSION_ID=$(jq -r 'select(.type=="thread.started") | .thread_id' /tmp/codex_round0.jsonl | head -1)

if [ -n "$SESSION_ID" ]; then
  CODEX_CMD="codex exec --profile peer-review --sandbox read-only resume $SESSION_ID"
else
  CODEX_CMD="codex exec --profile peer-review --sandbox read-only"
fi
```

## Anti-patterns

### Round-level synthesis

"After both sides responded, I averaged their views and called it resolved." — No. Convergence is mechanical: issues transition states, the table is checked. There is no LLM judging the LLMs.

### Re-asserting as new evidence

A `defend` in round 3 that says "as I argued before, this is risky" is not new evidence. The orchestrator should detect repeated reasoning (substring match against prior round) and auto-defer.

### Style disputes in the loop

`severity: style` issues bypass the debate entirely. They land in the "Style notes" section of the verdict, derived from the project's formatter / linter / convention, not from AI consensus.

### Promoting issues mid-debate

An issue raised as `severity: low` in round 0 cannot become `severity: critical` in round 2 unless **new evidence** justifies the upgrade. Otherwise it's a goalpost move.

## Example

### Round 0 (blind)

Claude finds:

```jsonl
{"id":"a1","file":"auth.ts:45","severity":"high","claim":"JWT validated without checking exp claim","evidence":"Test: forge token with exp=1, server accepts","category":"security"}
{"id":"b2","file":"auth.ts:120","severity":"low","claim":"Variable name 'tmp' is unclear","evidence":"-","category":"style"}
```

Codex finds:

```jsonl
{"id":"a1","file":"auth.ts:45","severity":"critical","claim":"JWT exp not validated","evidence":"verify() call lacks exp check","category":"security"}
{"id":"c3","file":"db.ts:88","severity":"medium","claim":"Connection pool not closed on error path","evidence":"Try block at line 80 has no finally; pool.acquire on error leaks","category":"correctness"}
```

### Canonicalization

```
a1: source=both, severity=critical (max of high/critical), status=proposed
b2: source=claude, severity=style → DROPPED FROM DEBATE, surface as style note
c3: source=codex, severity=medium, status=proposed
```

### Round 1 stances

Claude:

```jsonl
{"id":"a1","stance":"accept","reasoning":"Already in my findings"}
{"id":"c3","stance":"accept","reasoning":"Verified — finally block missing"}
```

Codex:

```jsonl
{"id":"a1","stance":"accept","reasoning":"Already in my findings"}
{"id":"c3","stance":"accept","reasoning":"My finding, reaffirmed"}
```

### Final state

```
a1: accepted, severity=critical → CRITICAL verdict
c3: accepted, severity=medium → IMPORTANT verdict
b2: style note
```

Convergence after round 1. No further debate needed. Total Codex calls: 4 (2 blind + 2 round-1 stances).

## When discussion fails

If after round 2 (or extended round 3) issues remain in `escalated`:

1. They become `deferred` and are presented as **Contested** in the verdict
2. The user sees both views and decides
3. **High-severity contested issues should also trigger external research** — pick the best research tool available; see escalation-criteria.md

## Reference

- Main protocol and prompt templates: SKILL.md
- When to skip the debate entirely: escalation-criteria.md
- Anti-patterns and recovery: common-mistakes.md
