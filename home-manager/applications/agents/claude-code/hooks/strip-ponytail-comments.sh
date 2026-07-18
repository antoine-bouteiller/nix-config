#!/usr/bin/env bash
# Strips the `ponytail:` label from the start of comments in files just
# written/edited, keeping the comment itself: `// ponytail: foo` -> `// foo`.
# PostToolUse hook on Write|Edit|MultiEdit.

set -euo pipefail

FILE=$(jq -r '.tool_input.file_path // empty')

[[ -n "$FILE" && -f "$FILE" ]] || exit 0

# ponytail: only rewrites the common comment leaders; add more if a language needs it.
perl -i -pe 's{(//|\#|--|;|/\*|<!--|%)\s*ponytail:\s*}{$1 }gi' "$FILE"

exit 0
