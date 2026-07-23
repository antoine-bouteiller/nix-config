---
description: Generate conventional commit with staged changes
name: conventional-commit
model: sonnet
disable-model-invocation: true
---

# Instructions

You are committing staged changes in the current git repository. Follow these rules exactly.

## Context Analysis

Run these commands to understand the current state:

- `git status --porcelain`
- `git diff --cached --name-only`
- `git diff --cached`
- `git log --oneline -5`

## MANDATORY: No AI attribution

**NEVER** include any of the following in the commit message, body, footer, or trailers:

- `Co-Authored-By` trailers mentioning Claude, Anthropic, or any AI
- Any mention of Claude, Anthropic, AI, or LLM anywhere in the commit
- Any `Signed-off-by`, `Generated-by`, or similar trailers referencing AI

Violating this rule makes the commit invalid. Double-check before executing.

## MANDATORY: Stop immediately if a pre-commit hook fails

If `git commit` fails because a **pre-commit hook** rejected it (lint, knip, type-check, prettier, tests, etc.):

- **STOP immediately.** Do not retry the commit.
- **Do NOT edit any source file** to get past the hook — no lint suppressions, no `knip: off`/`@knip/ignore` comments, no deleting exports, no `--fix`, no touching unrelated files.
- **Do NOT stage anything** (`git add` is still forbidden).
- Report the hook failure verbatim (the failing tool + its error output) and hand control back to the user.

Fixing hook failures is the user's call, not yours. Your job is only to compose the message and commit what is already staged.

## Your Task

1. Analyze **only the staged changes** (`git diff --cached`) to understand what was modified
2. **NEVER stage additional files.** Do not run `git add`. Only commit what the user has already staged.
3. If nothing is staged, inform the user and stop — do not stage files on their behalf
4. Generate a conventional commit message (feat, fix, docs, etc.) based solely on staged changes
5. Make the message descriptive but concise
6. Execute `git commit` with the generated message — **no Co-Authored-By or AI trailers**
7. If a pre-commit hook fails, follow the **Stop immediately** rule above — do not work around it
8. Return the commit hash and a short summary (or the hook failure if it was blocked)

# Conventional Commit Messages

See how [a minor change](#examples) to your commit message style can make a difference.

<pre>
git commit -m "<b><a href="#types">&lt;type&gt;</a></b></font>(<b><a href="#scopes">&lt;optional scope&gt;</a></b>): <b><a href="#description">&lt;description&gt;</a></b>" \
  -m"<b><a href="#body">&lt;optional body&gt;</a></b>" \
  -m"<b><a href="#footer">&lt;optional footer&gt;</a></b>"
</pre>

## Commit Message Formats

### General Commit

<pre>
<b><a href="#types">&lt;type&gt;</a></b></font>(<b><a href="#scopes">&lt;optional scope&gt;</a></b>): <b><a href="#description">&lt;description&gt;</a></b>
<sub>empty line as separator</sub>
<b><a href="#body">&lt;optional body&gt;</a></b>
<sub>empty line as separator</sub>
<b><a href="#footer">&lt;optional footer&gt;</a></b>
</pre>

### Initial Commit

```
chore: init
```

### Merge Commit

<pre>
Merge branch '<b>&lt;branch name&gt;</b>'
</pre>

<sup>Follows default git merge message</sup>

### Revert Commit

<pre>
Revert "<b>&lt;reverted commit subject line&gt;</b>"
</pre>

<sup>Follows default git revert message</sup>

### Types

- Changes relevant to the API or UI:
  - `feat` Commits that add, adjust or remove a new feature to the API or UI
  - `fix` Commits that fix an API or UI bug of a preceded `feat` commit
- `refactor` Commits that rewrite or restructure code without altering API or UI behavior
  - `perf` Commits are special type of `refactor` commits that specifically improve performance
- `style` Commits that address code style (e.g., white-space, formatting, missing semi-colons) and do not affect
  application behavior
- `test` Commits that add missing tests or correct existing ones
- `docs` Commits that exclusively affect documentation
- `build` Commits that affect build-related components such as build tools, dependencies, project version, CI/CD
  pipelines, ...
- `ops` Commits that affect operational components like infrastructure, deployment, backup, recovery procedures, ...
- `chore` Miscellaneous commits e.g. modifying `.gitignore`, ...
- `claude` Commits that affect `.claude/`

### Scopes

The `scope` provides additional contextual information.

- The scope is an **optional** part
- Allowed scopes vary and are typically defined by the specific project
- **Do not** use issue identifiers as scopes

### Breaking Changes Indicator

- A commit that introduce breaking changes **must** be indicated by an `!` before the `:` in the subject line e.g.
  `feat(api)!: remove status endpoint`
- Breaking changes **should** be described in the [commit footer section](#footer), if
  the [commit description](#description) isn't sufficiently informative

### Description

The `description` contains a concise description of the change.

- The description is a **mandatory** part
- Use the imperative, present tense: "change" not "changed" nor "changes"
  - Think of `This commit will...` or `This commit should...`
- **Do not** capitalize the first letter
- **Do not** end the description with a period (`.`)
- I case of breaking changes also see [breaking changes indicator](#breaking-changes-indicator)

### Body

The `body` should include the motivation for the change and contrast this with previous behavior.

- The body is an **optional** part
- Use the imperative, present tense: "change" not "changed" nor "changes"

### Footer

The `footer` should contain issue references and information about **Breaking Changes**

- The footer is an **optional** part, except if the commit introduce breaking changes
- _Optionally_ reference issue identifiers (e.g., `Closes #123`, `Fixes JIRA-456`)
- **Breaking Changes** **must** start with the word `BREAKING CHANGE:`
  - For a single line description just add a space after `BREAKING CHANGE:`
  - For a multi line description add two new lines after `BREAKING CHANGE:`

### Versioning

- **If** your next release contains commit with...
  - **Breaking Changes** incremented the **major version**
  - **API relevant changes** (`feat` or `fix`) incremented the **minor version**
- **Else** increment the **patch version**

### Examples

- ```
  feat: add email notifications on new direct messages
  ```
- ```
  feat(shopping cart): add the amazing button
  ```
- ```
  feat;: remove ticket list endpoint

  refers to JIRA-1337

  BREAKING CHANGE: ticket endpoints no longer supports list all entities.
  ```

- ```
  fix(shopping-cart): prevent order an empty shopping cart
  ```
- ```
  fix(api): fix wrong calculation of request body checksum
  ```
- ```
  fix: add missing parameter to service call

  The error occurred due to <reasons>.
  ```

- ```
  perf: decrease memory footprint for determine unique visitors by using HyperLogLog
  ```
- ```
  build: update dependencies
  ```
- ```
  build(release): bump version to 1.0.0
  ```
- ```
  refactor: implement fibonacci number calculation as recursion
  ```
- ```
  style: remove empty line
  ```
