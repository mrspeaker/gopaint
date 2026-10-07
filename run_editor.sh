#!/bin/bash
# Opens this project in the Godot editor. Set GODOT_BIN to override the Godot path.
# Extra arguments are passed to Godot, for example --verbose.
set -e
cd "$(dirname "$0")"
GODOT_BIN="${GODOT_BIN:-$(command -v godot)}"
exec "$GODOT_BIN" --editor --path . "$@"
