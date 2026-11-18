#!/usr/bin/env bash
# Runs a command with a time limit: macOS has no timeout command, as GNU
# coreutils has. The command gets this script's stdin, stdout and stderr, and
# its exit code is the script's.
#
#   time-limit.sh <seconds> <command> [<arg>...]
#
# Past the limit, it stops the command and each process under it, says so on
# stderr and exits 124. When the script itself is stopped, as by SIGTERM, it
# stops them too. It exits 2 for a wrong call. A codex exec that hangs writes
# nothing and never exits: one ran for 7.5 hours (#313).
#
# Needs bash and pgrep.

set -euo pipefail

if [ $# -lt 2 ] || case $1 in '' | *[!0-9]*) true ;; *) false ;; esac; then
  sed -n "s/^#   ${0##*/}/usage: ${0##*/}/p" "$0" >&2
  exit 2
fi
limit=$1
shift

# tree <pid>: the process and each process under it. The whole tree is read
# before the kill: a stdio server under codex ends when codex ends, and the
# processes under it then move to PID 1.
tree() {
  local kid
  echo "$1"
  for kid in $(pgrep -P "$1"); do tree "$kid"; done
}
# bash 3.2 runs this trap with $? at 0 when set -u stops the script, so a run
# passes only when it set finished at its end. It stops a command that still
# runs: past the time limit, or when the script itself is stopped. The
# redirection keeps bash's line on the killed job off stderr.
clean() {
  local code=$?
  [ "$code" != 0 ] || [ -n "${finished:-}" ] || code=1
  [ -z "${pid:-}" ] || { tree "$pid" | xargs kill -KILL; wait "$pid"; } 2>/dev/null || true
  exit "$code"
}
finished=
pid=
trap clean EXIT

# A command started with & reads /dev/null unless its stdin is redirected.
"$@" <&0 &
pid=$!
waited=0
while kill -0 "$pid" 2>/dev/null && [ "$waited" -lt "$limit" ]; do
  sleep 1
  waited=$((waited + 1))
done
if kill -0 "$pid" 2>/dev/null; then
  echo "time-limit.sh: $1 ran past $limit seconds and was stopped" >&2
  exit 124
fi
status=0
wait "$pid" || status=$?
pid=
finished=1
[ "$status" = 0 ] || exit "$status"
