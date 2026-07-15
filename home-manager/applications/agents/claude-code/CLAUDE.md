# System & Workflow Directives

## ⚠️ Critical Rules

1. **Do not make assumptions:** Never start an implementation if anything is unclear. If you need more information, always ask the user for clarification first.
2. **Code quality:** Always run lint and format after finishing a task.
3. **Search:** For any file search or grep in the current git-indexed directory, use fff tools.
4. **Naming:** Always use fully qualified names when naming a var

## Tools

You have access to various CLIs:

- `glab` — GitLab
- `gh` — GitHub
- `sonar` — SonarQube
- `agent-browser` — headless browser you can interact with

## RTK — Rust Token Killer

RTK optimizes terminal outputs to save tokens. Standard commands (e.g. `git status`) are automatically hooked — just run them normally.

### Bypassing RTK

If an output is truncated by the hook and you need the raw, unfiltered information, use the proxy:

```bash
rtk proxy <cmd>       # Execute raw command without filtering (for debugging)
```
