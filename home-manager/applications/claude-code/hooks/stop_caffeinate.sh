#!/bin/bash

TRACK_DIR=/tmp/claude_caffeinates

for pid_file in "$TRACK_DIR"/*; do
    # Check if it's an actual file (handles the case where directory is empty)
    if [ -f "$pid_file" ]; then

        # Atomically claim this file by renaming it
        if mv "$pid_file" "${pid_file}.claimed" 2>/dev/null; then

            # Extract the actual PID from the original filename
            PID=$(basename "$pid_file")

            # Kill the process silently
            if kill "$PID" 2>/dev/null; then
                # Clean up the claimed file
                rm -f "${pid_file}.claimed"

                # Exit immediately so we only kill ONE process
                exit 0
            fi

            # Clean up stale PID files and keep looking for a live process.
            rm -f "${pid_file}.claimed"
        fi
    fi
done

exit 0
