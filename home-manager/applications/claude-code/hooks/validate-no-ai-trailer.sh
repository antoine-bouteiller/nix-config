#!/bin/bash
# Blocks `git commit` invocations whose message includes an AI-attribution
# trailer (e.g. `Co-Authored-By: Claude ...`, `Generated-By: Anthropic ...`).
# Called as a PreToolUse hook on the Bash tool.
#
# Canonical rule: .claude/rules/spec-implementation.md § "Commit format".
# Exit codes:
#   0 - clean (or non-commit command)
#   2 - AI attribution trailer detected; commit blocked

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[[ -z "$COMMAND" ]] && exit 0

# Only inspect `git commit` invocations. Skip `git status`, `git log`,
# `git add`, `git commit-tree` (plumbing), etc.
if ! grep -qE '(^|[ ;&|()`])git[[:space:]]+commit($|[[:space:]])' <<<"$COMMAND"; then
  exit 0
fi

# Search corpus = the raw command (captures -m string literals and heredoc
# bodies inline) plus the contents of any -F <path> / --file=<path> argument.
CORPUS="$COMMAND"

# -F <path>
while read -r path; do
  [[ -n "$path" && -f "$path" ]] && CORPUS+=$'\n'"$(cat "$path")"
done < <(echo "$COMMAND" | grep -oE '(^|[[:space:]])-F[[:space:]]+[^[:space:]]+' | awk '{print $NF}')

# --file=<path>
while read -r path; do
  [[ -n "$path" && -f "$path" ]] && CORPUS+=$'\n'"$(cat "$path")"
done < <(echo "$COMMAND" | grep -oE -- '--file=[^[:space:]]+' | sed 's/^--file=//')

# Match `Co-Authored-By:` / `Generated-By:` / `Generated-With:` trailers
# whose value cites Claude / Anthropic / noreply@anthropic.com / LLM / GPT.
PATTERN='(co-authored-by|generated-(by|with)):.*(claude|anthropic|noreply@anthropic\.com|llm|gpt)'

if grep -qiE "$PATTERN" <<<"$CORPUS"; then
  echo "Blocked: commit message contains an AI attribution trailer." >&2
  echo "Offending line(s):" >&2
  grep -niE "$PATTERN" <<<"$CORPUS" | sed 's/^/  /' >&2
  echo "" >&2
  echo "Phoenix forbids 'Co-Authored-By: Claude ...' and similar AI trailers." >&2
  echo "See .claude/rules/spec-implementation.md § 'Commit format'." >&2
  exit 2
fi

exit 0
