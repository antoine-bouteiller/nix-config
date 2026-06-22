# System & Workflow Directives

## ⚠️ Critical Rules

1. **Do not make assumptions:** Never start an implementation if anything is unclear. If you need more information, always ask the user for clarification first.
2. **Code quality:** Always run lint and format after finishing a task.

## RTK - Rust Token Killer

RTK optimizes terminal outputs to save tokens. Standard commands (e.g., git status) are automatically hooked—just run them normally.

### Bypassing RTK

If an output is truncated by the hook and you need the raw, unfiltered information, use the proxy:

```bash
rtk proxy <cmd>       # Execute raw command without filtering (for debugging)
```
