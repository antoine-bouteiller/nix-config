#!/usr/bin/env bash

TRACK_DIR=/tmp/claude_caffeinates

# Ensure the tracking directory exists
mkdir -p "$TRACK_DIR"

# Start caffeinate in the background, detached from Claude's hook stdio.
caffeinate -d -i </dev/null >/dev/null 2>&1 &
CAFF_PID=$!

# Create an empty file named after the Process ID
touch "$TRACK_DIR/${CAFF_PID}"

exit 0
