#!/bin/bash

TRACK_DIR=/tmp/claude_caffeinates

if [ ! -d "$TRACK_DIR" ]; then
    exit 0
fi

for pid_file in "$TRACK_DIR"/*; do
    # Check if it's an actual file (handles the case where directory is empty)
    if [ -f "$pid_file" ]; then

        # Atomically claim this file by renaming it
        if mv "$pid_file" "${pid_file}.claimed" 2>/dev/null; then

            # Extract the actual PID from the original filename
            PID=$(basename "$pid_file")

            # Only kill PIDs that still point at caffeinate. A stale PID file may
            # otherwise refer to a different process after PID reuse.
            COMMAND=$(ps -p "$PID" -o comm= 2>/dev/null)
            case "$COMMAND" in
                caffeinate|*/caffeinate)
                    kill "$PID" 2>/dev/null
                    ;;
            esac

            # Clean up handled and stale PID files and keep draining the queue.
            rm -f "${pid_file}.claimed"
        fi
    fi
done

exit 0
