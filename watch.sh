#!/bin/bash

# Check if any arguments were passed
if [ "$#" -eq 0 ]; then
  echo "Usage: $0 command_to_run [args...]"
  exit 1
fi

# Capture the entire command as an array
COMMAND=("$@")

# Run the command every 5 seconds
while true; do
  clear  # This will clear the screen before each iteration (optional)

  echo "Executing: ${COMMAND[@]}"
  "${COMMAND[@]}"  # Execute the command with all arguments

  sleep 5  # Wait for 5 seconds before the next execution
done
