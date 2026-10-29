#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
# SIGTERM is handled by the app delegate so an active recording is flushed.
if pgrep -x Ausfallrekorder >/dev/null; then
  pkill -TERM -x Ausfallrekorder
  for attempt in 1 2 3 4 5; do
    pgrep -x Ausfallrekorder >/dev/null || break
    sleep 1
  done
  if pgrep -x Ausfallrekorder >/dev/null; then
    printf 'Die laufende App bitte zuerst beenden.\n' >&2
    exit 1
  fi
fi
sh scripts/build-macos.sh
open -n dist/Ausfallrekorder.app
if [ "${1:-}" = --verify ]; then
  sleep 1
  pgrep -x Ausfallrekorder >/dev/null
fi
