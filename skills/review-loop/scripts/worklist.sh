#!/usr/bin/env bash
# Prints each place where a range removes or replaces lines of code, as a
# numbered list for a review reader: the file and the line, the old lines and
# the new ones. A place that only adds lines is not on the list, and neither
# is a file of data, as a document, a lock file or a fixture.
#
#   worklist.sh <base> <head>
#
# Run it from the tree. An item shows at most 12 lines of each side. The list
# stops before 24,000 characters, and its last line then says how many places
# it left out. It exits 0 for an empty list too, and 2 for a wrong call, as
# an argument that is not a commit.
#
# Needs bash, git and awk.

set -euo pipefail

[ $# -eq 2 ] || {
  sed -n "s/^#   ${0##*/}/usage: ${0##*/}/p" "$0" >&2
  exit 2
}
base=$(git rev-parse -q --verify "$1^{commit}") || {
  echo "worklist.sh: $1 is not a commit" >&2
  exit 2
}
head=$(git rev-parse -q --verify "$2^{commit}") || {
  echo "worklist.sh: $2 is not a commit" >&2
  exit 2
}

# The flags give one form of the diff, whatever the person's git config says:
# no colour, no external diff tool, and the prefixes a/ and b/. The pathspecs
# leave out what is data.
git -c core.quotePath=false diff --no-color --no-ext-diff -U0 -M --src-prefix=a/ --dst-prefix=b/ \
  "$base" "$head" -- . \
  ':(exclude)*.md' ':(exclude)*.txt' ':(exclude)*.json' ':(exclude)*.lock' ':(exclude)*.snap' \
  ':(exclude)*.svg' ':(exclude)*.csv' ':(exclude,glob)**/go.sum' \
  ':(exclude,glob)**/fixtures/**' ':(exclude,glob)**/testdata/**' ':(exclude,glob)**/vendor/**' \
  ':(exclude,glob)**/node_modules/**' ':(exclude,glob)**/__snapshots__/**' |
  awk '
    # flush: the hunk that just ended is one item, when it removed a line.
    function flush(   i, s) {
      if (no > 0) {
        if (gone) s = "   The whole file is deleted (" no " lines).\n"
        else {
          s = "   old:\n"
          for (i = 1; i <= no && i <= 12; i++) s = s "       " old[i] "\n"
          if (no > 12) s = s "       ... " (no - 12) " more lines\n"
          if (nn == 0) s = s "   new: nothing\n"
          else {
            s = s "   new:\n"
            for (i = 1; i <= nn && i <= 12; i++) s = s "       " new[i] "\n"
            if (nn > 12) s = s "       ... " (nn - 12) " more lines\n"
          }
        }
        s = (n + 1) ". `" (gone ? oldf : f) ":" at "`\n" s
        if (full || size + length(s) > 23900) { full = 1; left++ }
        else { n++; size += length(s); printf "%s", s }
      }
      no = 0; nn = 0
    }
    # The header of a file ends at its first hunk: after it, a line that
    # starts with "--- " is a removed line.
    /^diff --git /    { flush(); header = 1; gone = 0; next }
    header && /^--- / { oldf = substr($0, 7); sub(/\t$/, "", oldf); next }
    header && /^\+\+\+ / { f = substr($0, 7); sub(/\t$/, "", f); gone = ($0 == "+++ /dev/null"); next }
    /^@@ /            { flush(); header = 0; at = gone ? $2 : $3; sub(/^[-+]/, "", at); sub(/,.*/, "", at); next }
    header            { next }
    /^-/              { old[++no] = substr($0, 2); next }
    /^\+/             { new[++nn] = substr($0, 2); next }
    END               { flush(); if (left) print "... " left " more places, not listed" }
  '
