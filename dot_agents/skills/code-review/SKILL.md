---
name: code-review
allowed-tools: Bash(git:*), Bash(gh:*), Bash(glab:*)
description: Review a merge request for security, performance, architecture, style, and improvements
---

# Merge Request Review

## Context

- Target branch: !`git rev-parse --abbrev-ref HEAD`
- MR diff stats: !`git diff --stat origin/main...HEAD 2>/dev/null || git diff --stat main...HEAD 2>/dev/null || echo "no diff available - provide branch or use gh/glab"`
- Changed files: !`git diff --name-only origin/main...HEAD 2>/dev/null || git diff --name-only main...HEAD 2>/dev/null || echo "no diff available"`
- Recent commits on branch: !`git log --oneline origin/main...HEAD 2>/dev/null || git log --oneline main...HEAD 2>/dev/null || echo "no commits diff available"`

## Your Task

Perform a thorough code review of the merge request changes. If the context above shows "no diff available", ask the user which branch or MR to review, or use `gh pr diff` / `glab mr diff` to get the changes.

**Review process:**

1. **Gather the full diff** — read every changed file in its entirety (not just the diff hunks) so you understand the surrounding context.
2. **Detect the stack** — identify languages, frameworks, and the project's existing conventions (look at neighbouring files, lint configs, CLAUDE.md, contributing docs). Judge the diff against _this project's_ patterns, not a generic ideal.
3. **For each changed file**, apply the five review categories below **in priority order**. Backend, frontend, infra, and config files all get reviewed — use the subsections that apply to each file's stack.
4. **Produce a structured review report** (format described at the end). Completion criterion: every changed file has been read in full and checked against every applicable category.

---

## Review Categories (by priority)

### P1 — Security (CRITICAL)

Check every changed line at trust boundaries:

#### Injection

- SQL built via string concatenation/interpolation — must use parameterized queries or a query builder; identifiers must be quoted/escaped through the library
- Command execution (`exec`, `spawn`, `ProcessBuilder`, shell strings) with user-supplied input
- Template/expression injection (server-side templates, `eval`, dynamic imports from user input)

#### XSS & Frontend Injection

- `innerHTML`, `dangerouslySetInnerHTML`, `v-html`, `document.write` with unsanitized data
- User input reflected into URLs, attributes, or inline event handlers
- `javascript:` / `data:` URLs from user input in `href`/`src`
- Missing output encoding when rendering untrusted content

#### Path Traversal & File Handling

- Paths built from user input without canonicalization/validation
- File operations escaping the expected directory; unchecked symlink following
- Unrestricted file upload (type, size, destination)

#### Credentials & Secrets

- Secrets, tokens, passwords logged, hardcoded, or committed
- Secrets in config without env/secret-manager indirection
- Sensitive data leaking into frontend bundles, client-side state, localStorage, or URLs
- Missing redaction in logs / serialized output

#### AuthN & AuthZ

- Endpoints or routes missing authentication checks
- Missing role/permission/ownership validation (IDOR: acting on IDs without ownership check)
- Authorization enforced only client-side (hidden buttons ≠ security)
- Token validation bypasses; insecure session/cookie flags (`HttpOnly`, `Secure`, `SameSite`)

#### Untrusted Data

- Unsafe deserialization of untrusted input (polymorphic typing, pickle, `eval`-based parsing)
- Missing validation at system boundaries (request bodies, query params, headers, file content, env vars, postMessage origins)
- SSRF: URLs fetched server-side from user input without allow-listing

#### Network & Transport

- Trust-all TLS patterns, disabled certificate validation
- HTTP for sensitive endpoints; CORS misconfiguration (wildcard origin + credentials)
- Missing CSRF protection on state-changing requests

### P2 — Performance

#### General

- O(n²) loops where a map/set gives O(n); repeated work a single pass covers
- Large allocations or expensive construction (regex compilation, clients, parsers) inside hot loops
- Missing resource cleanup (connections, file handles, streams, subscriptions) — use the language's scoped-resource idiom
- Expensive computation repeated without memoization/caching where the project already caches

#### Backend

- N+1 query patterns; missing batching for bulk operations
- Connection/statement/result leaks; missing pooling where the project pools
- Blocking calls in async/reactive/virtual-thread contexts
- Race conditions: check-then-act without atomicity; missing backpressure on unbounded queues
- Unbuffered I/O; loading whole files when streaming suffices

#### Frontend

- Unnecessary re-renders: unstable deps/props (inline objects/lambdas in hot paths), missing memoization where the framework expects it (`useMemo`/`computed`/`OnPush` — per the project's framework)
- Effects with wrong/missing dependencies; state updates in render loops
- Fetch waterfalls where requests could be parallel; missing request deduplication/caching the project's data layer provides
- Large lists rendered without virtualization/pagination
- Bundle bloat: heavy dependency added for something a few lines cover; missing lazy loading for large routes/components
- Layout thrash: repeated DOM reads/writes interleaved; animations of layout properties instead of transform/opacity
- Memory leaks: listeners, intervals, subscriptions not cleaned up on unmount/dispose

### P3 — Architecture & Correctness

Judge against the project's established patterns, discovered in step 2:

- New code follows the project's existing structure: DI/wiring style, module/layer boundaries, folder conventions
- Code sits in the right layer — no business logic in controllers/components, no UI concerns in the domain layer
- No circular dependencies; cross-module communication through the existing interfaces
- Error handling matches the project's convention; no swallowed exceptions/rejections; errors at boundaries surfaced or logged, not silently dropped
- API changes are backward compatible or the break is intentional and flagged
- Frontend: state lives at the right level (server cache vs global store vs local state — per the project's stack); components stay presentational where the codebase separates container/presentation; no prop drilling where the project has an established context/store; data fetching follows the project's data layer, not ad-hoc `fetch` calls
- Duplication of an existing utility/helper the codebase already has
- Reuse over reinvention: prefer the project's existing patterns, then stdlib/platform, before new abstractions or dependencies

### P4 — Code Style

Conformance with _this project's_ standards (lint config, formatter, neighbouring code):

- Formatting matches the project formatter — flag only if no formatter runs in CI
- Naming follows the codebase's conventions (casing, prefixes, test naming)
- Idiomatic use of the language/framework version the project targets (modern syntax the codebase already uses)
- Types: no new `any`/unchecked casts where the project is strictly typed; null contracts consistent with the codebase
- Imports: no unused; ordering per project convention
- Tests follow the project's structure (given/when/then or equivalent), naming, and fixtures; new logic has tests where the project tests comparable code
- Frontend: semantic HTML over div soup; interactive elements are real `<button>`/`<a>`; images have alt text; form inputs have labels; keyboard focus not broken — accessibility basics are style-level, missing them on new UI is a finding
- No hardcoded user-facing strings if the project has i18n

### P5 — Minor Improvements

Nice-to-have, non-blocking:

- Typos in comments, log messages, UI copy, or identifiers
- Missing or outdated doc comments on public API
- Opportunity to extract a reusable function/constant/component
- Log level appropriateness; leftover debug output (`console.log`, commented-out code)
- Test coverage gaps for edge cases
- Dead code or unused parameters introduced by the MR
- More descriptive naming

---

## Output Format

Produce the review as a structured report using this format:

```
## MR Review: <short summary of what the MR does>

### Overview
<1-3 sentences describing the MR's purpose and scope>

### P1 — Security
<findings or "No issues found.">

### P2 — Performance
<findings or "No issues found.">

### P3 — Architecture & Correctness
<findings or "No issues found.">

### P4 — Code Style
<findings or "No issues found.">

### P5 — Minor Improvements
<findings or "No suggestions.">

### Verdict
<One of: APPROVE, APPROVE WITH COMMENTS, REQUEST CHANGES>
<1-2 sentence rationale>
```

**For each finding**, use this format:

```
- **[severity]** `file/path.ext:line` — description of the issue
  > suggestion or fix
```

Where severity is: `blocker`, `critical`, `major`, `minor`, `info`

**Severity mapping:**

- P1 findings are `blocker` or `critical`
- P2 findings are `critical` or `major`
- P3 findings are `major` or `minor`
- P4 findings are `minor`
- P5 findings are `info`

**Verdict rules:**

- Any `blocker` or `critical` → REQUEST CHANGES
- Only `major` or below → APPROVE WITH COMMENTS
- Only `minor` / `info` → APPROVE
- Nothing found → APPROVE
