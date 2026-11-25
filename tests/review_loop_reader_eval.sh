#!/usr/bin/env bash
# Sends the reader of a review, with a lens file of skills/review-loop/ and
# the prompt that the review loop gives it, to changes with known defects, at
# model opus. It counts the runs whose report names each defect:
#
#   pr9 #91: 3 of 3, was 3
#   pr9: 3 of 6, floor 0, 0 failed reads, 11 findings a run, ran the list 3 of 3
#   below: pr289
#   lost: pr9 #91
#
# The cases and their defects are the lines of
# tests/fixtures/review_loop_reader/cases.tsv, which says what a line holds.
# READER_LOCAL names a folder with a cases.tsv of more cases, as the cases of
# a private repository, which stay outside this one. A report that
# report-check.sh refuses is a failed read, and names no defect. "below:"
# names a case under its floor, and "lost:" a defect that 2 or 3 runs of the
# last recorded pass named and that no run names now. It exits 1 on either.
#
# With --codex, Codex reads each case in the place of Claude, in its read-only
# sandbox and with the person's Codex config. With --check, it calls no model:
# it counts the reports <case>-<n>.txt of the folder, with the cases.tsv of
# that folder when it has one.
#
# It calls the model, so it costs tokens and is not part of `make check`: run
# it by hand, alone, before and after each change to code-lens.md or
# security-lens.md. A case from a commit needs the full history of this
# repository.
#
# Usage: tests/review_loop_reader_eval.sh [--codex] [--check <dir>] [runs of each case, default 3]
# Environment: READER_CASES (names, default: each case), READER_LEVEL (low,
# medium, high or xhigh; default high), READER_LOCAL.

set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
skill=$root/skills/review-loop
usage() {
  echo "usage: $0 [--codex] [--check <dir>] [runs of each case, at least 1]" >&2
  exit 2
}
reader=claude check=
[ "${1:-}" != --codex ] || { reader=codex; shift; }
if [ "${1:-}" = --check ]; then
  [ -d "${2:-}" ] || usage
  check=$2
  shift 2
fi
runs=${1:-3}
# An argument too many, as `3 --codex`, must not start paid runs.
[ "$#" -le 1 ] && [ "$runs" -ge 1 ] 2>/dev/null || usage
level=${READER_LEVEL:-high}
case $level in low | medium | high | xhigh) ;; *) usage ;; esac

tsvs=("$root/tests/fixtures/review_loop_reader/cases.tsv")
[ -z "${READER_LOCAL:-}" ] || tsvs+=("$READER_LOCAL/cases.tsv")
[ -z "$check" ] || [ ! -f "$check/cases.tsv" ] || tsvs=("$check/cases.tsv")
for file in "${tsvs[@]}"; do
  [ -f "$file" ] || { echo "$0: no file $file" >&2; exit 2; }
done
# rows <kind> <case>: the lines of that kind for the case.
rows() { awk -F '\t' -v kind="$1" -v kase="$2" '$1 == kind && $2 == kase' "${tsvs[@]}"; }
cases=${READER_CASES:-$(awk -F '\t' '$1 == "case" { print $2 }' "${tsvs[@]}")}
for kase in $cases; do
  [ -n "$(rows case "$kase")" ] || { echo "$0: no case $kase" >&2; exit 2; }
done

# origin <case>: "commit <sha>", "repo <dir>" or "trees <dir>". A path is
# read from the folder of the cases.tsv that holds the case.
origin() {
  local source dir file
  source=$(rows case "$1" | cut -f3)
  if printf '%s' "$source" | grep -qE '^[0-9a-f]{40}$'; then
    echo "commit $source"
    return
  fi
  dir=$source
  for file in "${tsvs[@]}"; do
    case $source in /*) break ;; esac
    [ -z "$(awk -F '\t' -v kase="$1" '$1 == "case" && $2 == kase' "$file")" ] || dir=$(cd "$(dirname "$file")" && pwd)/$source
  done
  if [ -e "$dir/.git" ]; then
    echo "repo $dir"
  elif [ -d "$dir/main" ] && [ -d "$dir/review" ]; then
    echo "trees $dir"
  else
    return 1
  fi
}

commit() {
  git -C "$1" add -A
  git -C "$1" -c user.name=eval -c user.email=eval@example.com -c commit.gpgsign=false commit -qm "$2"
}

# fixture <case> <dir>: a repository whose branch main is the base of the
# change, and whose branch review, checked out, is the change.
fixture() {
  local from source
  from=$(origin "$1")
  source=${from#* }
  case $from in
    commit*)
      git init -q -b main "$2"
      git -C "$2" fetch -q "$root" "$source"
      git -C "$2" update-ref refs/heads/review FETCH_HEAD
      git -C "$2" update-ref refs/heads/main 'FETCH_HEAD^'
      git -C "$2" checkout -q review
      ;;
    repo*)
      cp -R "$source" "$2"
      git -C "$2" checkout -q review
      ;;
    trees*)
      git init -q -b main "$2"
      cp -R "$source/main/." "$2"
      commit "$2" 'the base'
      git -C "$2" checkout -qb review
      git -C "$2" rm -rq .
      cp -R "$source/review/." "$2"
      commit "$2" 'the change'
      ;;
  esac
}

# run <case> <run>: the report goes to <case>-<run>.txt, and <case>-<run>.list
# says that the reader ran worklist.sh. The installed copy of the plugin is
# turned off, so the rules come from this checkout. The reader may read, and
# run git and worklist.sh: it has no tool that writes, and no subagent.
run() {
  local work=$logs/$1-$2 lens prompt
  lens=$(rows case "$1" | cut -f4)
  fixture "$1" "$work"
  prompt="Read $skill/$lens and do what it says.
Range: $(git -C "$work" rev-parse main)..$(git -C "$work" rev-parse review)
Tree: $work"
  [ "$lens" = security-lens.md ] || prompt="$prompt
Level: $level"
  : >"$work.txt"
  if [ "$reader" = codex ]; then
    bash "$skill/scripts/time-limit.sh" 1200 codex exec -s read-only --ephemeral -C "$work" -o "$work.txt" "$prompt
You are one reviewer that another agent runs: start no skill, change no file, and file nothing." </dev/null >"$work.log" 2>&1 || true
    # The log holds the lens, which names the script with <base>: a call has a commit.
    ! grep -qE 'worklist\.sh[^<]{0,3}[0-9a-f]{7}' "$work.log" || : >"$work.list"
    return
  fi
  printf '%s\n' "$prompt" >"$work.prompt"
  (cd "$work" && claude -p --model opus --effort "$level" --output-format stream-json --verbose \
    --settings '{"enabledPlugins":{"craft@kalinichenko":false,"kalinichenko@kalinichenko":false},"language":"English"}' \
    --plugin-dir "$root" --add-dir "$skill" \
    --allowedTools 'Bash(git:*)' "Bash(bash $skill/scripts/worklist.sh:*)" Read Grep Glob \
    --disallowedTools Agent ListAgents Edit Write NotebookEdit ReportFindings \
    --permission-mode default <"$work.prompt") >"$work.jsonl" 2>"$work.err" || true
  # The text of a session that ends in an error is no report.
  jq -r 'select(.type == "result" and .is_error != true) | .result // empty' "$work.jsonl" >"$work.txt" 2>/dev/null || true
  ! jq -es 'any(.[]; .type == "assistant" and any(.message.content[]?; .type == "tool_use" and .name == "Bash" and (.input.command | test("worklist\\.sh"))))' \
    "$work.jsonl" >/dev/null 2>&1 || : >"$work.list"
}

# score <dir>: the count of each case that has a report in the folder. It
# returns 1 when a case is below its floor or a defect is lost.
score() {
  local dir=$1 kase files file n failed sum mean whole found defect place how was named total defects floor line below='' lost=''
  for kase in $cases; do
    files=("$dir/$kase"-[0-9]*.txt)
    [ -e "${files[0]}" ] || continue
    n=${#files[@]} failed=0 sum=0 whole=''
    for file in "${files[@]}"; do
      if found=$(bash "$skill/scripts/report-check.sh" "$file"); then
        found=${found#ok: }
        sum=$((sum + ${found% findings}))
        whole="$whole$file
"
      else
        failed=$((failed + 1))
      fi
    done
    total=0 defects=0
    while IFS=$'\t' read -r _ _ defect place how was; do
      named=0
      for file in "${files[@]}"; do
        # A failed read names no defect.
        case $whole in *"$file
"*) ;; *) continue ;; esac
        ! grep -E ' [|] .* [|] ' "$file" | grep -iE -e "$place" | grep -qiE -e "$how" || named=$((named + 1))
      done
      echo "$kase $defect: $named of $n, was $was"
      total=$((total + named)) defects=$((defects + 1))
      [ "$named" -gt 0 ] || [ "$was" -lt 2 ] || lost="${lost}lost: $kase $defect
"
    done < <(rows defect "$kase")
    floor=$(($(rows case "$kase" | cut -f5) * n / 3))
    mean=0
    [ "$n" -eq "$failed" ] || mean=$((sum / (n - failed)))
    line="$kase: $total of $((defects * n)), floor $floor, $failed failed reads, $mean findings a run"
    [ -n "$check" ] || line="$line, ran the list $(find "$dir" -maxdepth 1 -name "$kase-[0-9]*.list" | grep -c . || true) of $n"
    echo "$line"
    [ "$total" -ge "$floor" ] || below="${below}below: $kase
"
  done
  printf '%s%s' "$below" "$lost"
  [ -z "$below$lost" ]
}

if [ -n "$check" ]; then
  score "$check"
  exit
fi
# An error of the shell inside the count must not go on to a paid run.
[ -z "$check" ] || exit 1

# Each check of a case comes before the first paid run.
[ "$reader" = claude ] || codex login status >/dev/null 2>&1 || { echo "$0: codex is not installed or not logged in" >&2; exit 2; }
for kase in $cases; do
  from=$(origin "$kase") || { echo "$0: the case $kase has no commit, no repository and no folder of two trees" >&2; exit 2; }
  case $from in
    commit*)
      git -C "$root" cat-file -e "${from#* }^^{commit}" 2>/dev/null ||
        { echo "$0: the case $kase needs the full history of this repository" >&2; exit 2; }
      ;;
    repo*)
      # A tool of an earlier run can leave its findings in the tree.
      git -C "${from#* }" rev-parse -q --verify main >/dev/null && git -C "${from#* }" rev-parse -q --verify review >/dev/null &&
        [ -z "$(git -C "${from#* }" status --porcelain)" ] ||
        { echo "$0: the repository of the case $kase needs the branches main and review, and no file that is not committed" >&2; exit 2; }
      ;;
  esac
done

logs=$(mktemp -d)
for i in $(seq "$runs"); do
  for kase in $cases; do
    run "$kase" "$i" &
  done
  wait
done
failed=0
score "$logs" || failed=1
for kase in $cases; do
  for i in $(seq "$runs"); do
    echo "== $kase-$i"
    grep . "$logs/$kase-$i.txt" || echo 'no report'
  done
done
echo "Logs: $logs"
exit "$failed"
