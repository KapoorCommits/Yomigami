#!/bin/sh
set -eu
ROOT="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
export YOMIGAMI_APP="$ROOT/app"
export YOMIGAMI_HOME="$ROOT/build/test-data"
python3 "$ROOT/scripts/make_fixtures.py"
cd "$ROOT/build/macos/KOReader.app/Contents/koreader"
./luajit "$ROOT/tests/core.lua"
