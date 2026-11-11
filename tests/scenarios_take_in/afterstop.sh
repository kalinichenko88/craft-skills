#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034,SC2154,SC2329 # sourced: the helpers and values are in scenarios_take_in.sh and scenarios_checks_test.sh
afterstop_case() { line afterstop 2 'A text after a stop that names the task again' '#91' 'It runs somewhere else.' '#91'; }
afterstop_given() { inprogress_given; }
# The outcomes of A task in progress, on the part of the run after the second
# text of the person.
afterstop_check() {
  local t f
  answered "$where"
  [ "$(grep -c '^person' "$d.events")" -ge 2 ] ||
    { echo "$0: $d has no second text of the person: the Given of its scenario does not hold" >&2; return 2; }
  t=$(mktemp -d)
  for f in state.json branches workspace work given.workspace given.branches given.work; do [ ! -f "$d.$f" ] || cp "$d.$f" "$t/run.$f"; done
  awk '/^person/ { p++; next } p >= 2' "$d.events" >"$t/run.events"
  d=$t/run
  read_run
  inprogress_check
  rm -rf "$t"
}
afterstop_copies() { :; }
