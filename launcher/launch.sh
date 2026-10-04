#!/bin/sh
set -eu
ROOT="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"
exec >>"$ROOT/launcher.log" 2>&1
printf "Yomigami launch: %s\n" "$(date)"
export YOMIGAMI_APP="$ROOT/app"
export YOMIGAMI_HOME="$ROOT/data"
export KO_HOME="$YOMIGAMI_HOME/runtime"
export KOREADER_DIR="$ROOT/runtime"
export YOMIGAMI_SOURCE_PORT=18787
export RAKUYOMI_TCP_PORT="$YOMIGAMI_SOURCE_PORT"
LOCK=/var/tmp/yomigami.lock
if ! mkdir "$LOCK" 2>/dev/null; then
    OLD_PID="$(cat "$LOCK/pid" 2>/dev/null || true)"
    case "$OLD_PID" in
        ''|*[!0-9]*) OLD_PID='' ;;
    esac
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        OLD_CMD="$(tr '\000' ' ' <"/proc/$OLD_PID/cmdline" 2>/dev/null || true)"
        case "$OLD_CMD" in
            *"$ROOT/launch.sh"*) echo "Yomigami launcher already running: $OLD_PID"; exit 0 ;;
        esac
    fi
    rm -f "$LOCK/pid"
    rmdir "$LOCK" 2>/dev/null || exit 1
    mkdir "$LOCK" || exit 1
fi
printf '%s\n' "$$" >"$LOCK/pid"
ENGINE_PID=''
cleanup() {
    if [ -n "$ENGINE_PID" ]; then kill "$ENGINE_PID" 2>/dev/null || true; fi
    rm -f "$LOCK/pid"; rmdir "$LOCK" 2>/dev/null || true
}
trap cleanup EXIT HUP INT TERM
mkdir -p "$YOMIGAMI_HOME/library" "$KO_HOME" "$YOMIGAMI_HOME/sources"
# Offline books remain usable if the optional source engine fails.
if [ -x "$ROOT/engine/server" ]; then
    "$ROOT/engine/server" "$YOMIGAMI_HOME/sources" >>"$YOMIGAMI_HOME/source.log" 2>&1 &
    ENGINE_PID=$!
fi
"$ROOT/runtime/yomigami-runtime.sh" "$@"
