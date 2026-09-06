#!/bin/sh
set -eu
ROOT="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
export YOMIGAMI_APP="$ROOT/app"
export YOMIGAMI_HOME="${YOMIGAMI_HOME:-$ROOT/build/dev-data}"
export KO_HOME="$YOMIGAMI_HOME/runtime"
export YOMIGAMI_SOURCE_PORT=18787
export RAKUYOMI_TCP_PORT="$YOMIGAMI_SOURCE_PORT"
mkdir -p "$YOMIGAMI_HOME/library" "$KO_HOME" "$YOMIGAMI_HOME/sources"
ENGINE="$ROOT/build/source-macos/rakuyomi.koplugin/server"
RUNTIME="$ROOT/build/macos/KOReader.app/Contents/koreader"
if [ ! -x "$RUNTIME/luajit" ]; then echo 'Extract the macOS runtime first. See README.' >&2; exit 1; fi
if [ -x "$ENGINE" ] && [ "${YOMIGAMI_NO_ENGINE:-0}" != 1 ]; then
    "$ENGINE" "$YOMIGAMI_HOME/sources" >>"$YOMIGAMI_HOME/source.log" 2>&1 &
    ENGINE_PID=$!
    trap 'kill "$ENGINE_PID" 2>/dev/null || true' EXIT HUP INT TERM
fi
export EMULATE_READER_W="${EMULATE_READER_W:-600}"
export EMULATE_READER_H="${EMULATE_READER_H:-800}"
cd "$RUNTIME"
./luajit "$YOMIGAMI_APP/boot.lua"
