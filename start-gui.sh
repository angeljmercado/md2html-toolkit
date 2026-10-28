#!/bin/bash
# Start the drag-and-drop GUI (needs python3).
cd "$(dirname "$0")" && exec python3 gui.py "$@"
