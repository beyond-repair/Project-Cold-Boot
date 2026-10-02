#!/usr/bin/env bash
# Headless smoke for Project Cold Boot vertical slice (GameState + resource load).
# Requires Godot 4.2+ on PATH as `godot`, or set GODOT=/path/to/godot.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_BIN="${GODOT:-godot}"
if ! command -v "$GODOT_BIN" >/dev/null 2>&1 && [[ ! -x "$GODOT_BIN" ]]; then
  echo "error: Godot 4.2+ not found. Install from https://godotengine.org and set GODOT=..." >&2
  exit 127
fi
exec "$GODOT_BIN" --headless --path "$ROOT/godot" -s res://tools/smoke_test.gd "$@"
