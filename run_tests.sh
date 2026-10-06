#!/bin/bash
# Runs all gdUnit4 tests headless. Set GODOT_BIN to override the Godot path.
set -e
cd "$(dirname "$0")"
export GODOT_BIN="${GODOT_BIN:-$(command -v godot)}"

# Import resources and register class names on a fresh checkout.
"$GODOT_BIN" --headless --path . --import > /dev/null 2>&1 || true

# With no arguments, run every suite in res://test.
if [ $# -eq 0 ]; then set -- -a res://test; fi
./addons/gdUnit4/runtest.sh --headless --ignoreHeadlessMode "$@"
