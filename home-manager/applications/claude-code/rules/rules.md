---
globs: [".claude/rules/*.md", "CLAUDE.md", ".claude/CLAUDE.md", "CLAUDE.local.md"]
---

## Writing and maintaining Claude Code rules

### Instruction budget

LLMs reliably follow ~150–200 instructions. Claude Code's system prompt consumes ~50, leaving ~100–150 for CLAUDE.md,
rules, and user messages combined. Every low-value rule dilutes compliance on high-value ones.

- Target **under 200 lines** per CLAUDE.md file
- One topic per rule file in `.claude/rules/`
- Before adding a rule, apply the acid test: **would removing this cause Claude to make mistakes?** If not, cut it.

### What belongs in a rule

Include:

- Build/run/test commands Claude cannot guess from code
- Style choices that differ from language defaults
- Architectural constraints and design patterns specific to this project
- Gotchas and non-obvious environment quirks
- Repo etiquette (commit conventions, CODEOWNERS, branch policies)

Exclude:

- Anything Claude can infer by reading code (standard patterns, obvious structure)
- Standard language conventions (already baked into the model)
- Detailed API docs — link to them instead
- Frequently changing information (versions, sprint details)
- File-by-file codebase descriptions
- Self-evident practices ("write clean code", "use meaningful names")

### Rule format

- **Imperative, specific, concise.** "Use 2-space indentation" not "We prefer to use 2-space indentation."
- **One topic per file.** Name files descriptively: `java.md`, `docker-java.md`, `spec.md`.
- **Markdown structure.** Use headers, bullets, tables, code blocks — not paragraphs of prose.
- **State the why** when non-obvious. Arbitrary-looking rules without rationale get ignored.
- **Include counterexamples** for rules where the wrong approach looks reasonable.
- **Use emphasis sparingly.** Reserve IMPORTANT/MUST/NEVER for genuinely critical constraints — overuse trains Claude to
  ignore emphasis.

### Scoping with `globs` frontmatter

Rules without `globs` load unconditionally at launch and consume the instruction budget for every conversation. Scope
rules to relevant files when they don't apply everywhere:

```yaml
---
globs: ["*.spec.md"]
---
```

- Glob-scoped rules load only when Claude reads a matching file
- Use standard glob syntax: `**/*.ts`, `src/**/*.{ts,tsx}`, `services/*/docker/Dockerfile`
- Prefer scoped rules over global ones to preserve the instruction budget

### Enforcement tiers

Choose the right mechanism for each constraint:

| Mechanism                           | Compliance           | Use for                                                 |
| ----------------------------------- | -------------------- | ------------------------------------------------------- |
| Rules (`.claude/rules/`, CLAUDE.md) | Advisory (~80%)      | Architectural guidance, judgment calls, design patterns |
| Hooks (`settings.json`)             | Deterministic (100%) | Linting, formatting, test gates, file guards            |
| Settings (`settings.json`)          | Enforced (100%)      | Permissions, tool restrictions, file access             |

If a linter can catch it, don't write a rule — configure the linter and add a hook. Rules are for things that require
judgment.

### Anti-patterns

- **Redundant rules.** Don't restate what the model already knows (language syntax, common idioms).
- **Contradicting rules.** When rules across files conflict, Claude picks one arbitrarily. Audit for overlaps.
- **Aspirational platitudes.** "Follow best practices" wastes budget. Be concrete or remove it.
- **Global rules for local concerns.** A Dockerfile convention shouldn't load when editing TypeScript. Use `globs`.
- **Rules as documentation.** Rules instruct Claude; docs inform humans. Don't merge the two.

### Maintenance

- When Claude makes a recurring mistake, add a targeted rule to prevent it.
- When a rule no longer causes observable benefit, remove it.
- Periodically audit the total rule count — prune anything Claude follows without being told.
- Check into git and review in PRs like code.
