#!/usr/bin/env bash
# Checks the report of a review reader, in the form that the lens files of
# this skill ask for: one line for each finding, then a last line "count: N".
#
#   report-check.sh <report file>
#
# For a whole report it prints "ok: <N> findings" and exits 0. For a report
# that the reader cut or did not make, it prints "failed read: <reason>" and
# exits 1: the last line is no count line, a line says "read: none", or the
# count is not the number of finding lines. A finding line has " | " at least
# twice, and ":<digits>", as in path:line, in its first or its second field.
# It exits 2 for a wrong call, as a file that does not exist.
#
# Needs bash and awk.

set -euo pipefail

[ $# -eq 1 ] || {
  sed -n "s/^#   ${0##*/}/usage: ${0##*/}/p" "$0" >&2
  exit 2
}
[ -f "$1" ] || {
  echo "report-check.sh: no file $1" >&2
  exit 2
}

awk -F ' [|] ' '
  /^[[:space:]]*$/ { next }
  { last = $0 }
  /^[-* ]*read: none/ { none = 1 }
  NF >= 3 && ($1 ~ /:[0-9]+/ || $2 ~ /:[0-9]+/) { found++ }
  END {
    if (last !~ /^count: [0-9]+[[:space:]]*$/) { print "failed read: no count line"; exit 1 }
    if (none) { print "failed read: read: none"; exit 1 }
    sub(/^count: /, "", last)
    if (last + 0 != found + 0) {
      print "failed read: count says " (last + 0) ", the report has " (found + 0) " finding lines"
      exit 1
    }
    print "ok: " (found + 0) " findings"
  }' "$1"
