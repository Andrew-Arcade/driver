#!/bin/bash
QUEUE="/tmp/andrewarcade-queue"

while [ -s "$QUEUE" ]; do
    cmd=$(head -1 "$QUEUE")
    sed -i '1d' "$QUEUE"
    echo "Running: $cmd"
    eval "$cmd"
done
