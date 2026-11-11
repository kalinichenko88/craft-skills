#!/usr/bin/env bash
# A fake gh over one JSON tracker, for the evals that run craft in
# `claude -p`: it answers the reads, applies the writes to the JSON, and logs
# each call to <tracker>.calls, where <tracker> is the path of the JSON
# without .state.json. An eval puts a gh first on PATH that runs this file
# with the path of its tracker before the arguments of the call:
#
#   fake_gh.sh <tracker>.state.json <gh arguments>...
#
# The JSON holds all that differs from one eval to another:
#
#   me, repo     the login, and the repository as owner/name
#   issues       each with number, title, body, state, assignees and labels
#                as lists of names, and comments as {author, body}; it can
#                have stateReason, milestone (a title), linked (the names of
#                its linked branches on the origin), duplicateOf (a number)
#                and repo, when it is in another repository than repo
#   labels       the names that `gh label list` gives
#   visibility   PUBLIC or PRIVATE
#   prs          the pull requests that `gh pr list` and `gh pr view --json`
#                give, none if absent: each with number, title, state, author
#                as {login}, headRefName (a branch on the origin) and closes,
#                the numbers of the issues it closes
#   origin       the bare origin where `gh issue develop` makes a branch
#   workspace    the checkout of the eval, whose worktrees the log reads
#   down         true: each call but --version fails with a 502
#
# Each write adds "<command> <number>" to .log, as "comment 91": the
# order of the writes. The entry ends in " +changes" when a worktree of the
# workspace has a changed file or a commit past main at that moment: the
# write came after the work started.
#
# Needs bash, jq and git.

# shellcheck disable=SC2016 # the single-quoted $ are jq's
state=$1
shift
printf '%s\n' "$*" >>"${state%.state.json}.calls"
args=("$@") jqf='' fields='' search='' list_state=open num='' n='' want=''
for ((i = 0; i < $#; i++)); do
  a=${args[i]}
  case $a in
    --jq | -q) jqf=${args[i + 1]} ;;
    --json) fields=${args[i + 1]} ;;
    --search | -S) search=${args[i + 1]} ;;
    --state | -s) list_state=${args[i + 1]} ;;
    --repo | -R) want=${args[i + 1]} ;;
    n=*) n=${a#n=} ;;
  esac
done
for a in "${args[@]:2}"; do
  case $a in
    */issues/*) num=${a##*/issues/} num=${num%%[!0-9]*} want=${a#*://*/} want=${want%%/issues/*} && break ;;
    \#[0-9]* | [0-9]*) num=${a#\#} && break ;;
  esac
done
case $* in --version | *' --help' | *' -h') echo 'gh version 2.98.0'; exit 0 ;; esac
if [ "$(jq -r '.down // false' "$state")" = true ]; then
  echo 'HTTP 502: Bad Gateway (https://api.github.com/graphql)' >&2
  exit 1
fi
me=$(jq -r .me "$state") repo=$(jq -r .repo "$state")
want=${want:-$repo}
out() { if [ -n "$jqf" ]; then jq -r "$jqf" <<<"$1"; else printf '%s\n' "$1"; fi; }
pick() { jq -c --arg f "$fields" "$1"' | . as $i | if $f == "" then . else reduce ($f | split(","))[] as $k ({}; .[$k] = $i[$k]) end'; }
save() { local t; t=$(jq "$@" "$state") && printf '%s\n' "$t" >"$state"; }
logged() { # logged <command> <number>
  local e="$1 $2" ws t
  ws=$(jq -r '.workspace // empty' "$state")
  if [ -n "$ws" ] && git -C "$ws" worktree list --porcelain | sed -n 's/^worktree //p' |
    while read -r t; do git -C "$t" status --porcelain; git -C "$t" log --oneline main..HEAD; done | grep -q .; then
    e="$e +changes"
  fi
  save --arg e "$e" '.log += [$e]'
}
issues() { # the issues of the repository that a URL or --repo names, or of repo
  jq --arg repo "$repo" --arg want "$want" '[.issues[] | select((.repo // $repo) == $want)
    | {number, title, body, state, stateReason: (.stateReason // null),
    url: "https://github.com/\($want)/issues/\(.number)", assignees: [.assignees[] | {login: .}],
    labels: [.labels[] | {name: .}], milestone: (if .milestone then {title: .milestone} else null end),
    comments: [.comments[] | {author: {login: .author}, body}]}]' "$state"
}
value() { # value <flag ...>: the argument after the first of the flags
  for ((i = 0; i < ${#args[@]}; i++)); do
    for f in "$@"; do [ "${args[i]}" != "$f" ] || { echo "${args[i + 1]}"; return; }; done
  done
}
labels() { # labels <flag ...>: each argument after one of the flags, as a JSON list
  for ((i = 0; i < ${#args[@]}; i++)); do
    for f in "$@"; do [ "${args[i]}" != "$f" ] || tr ',' '\n' <<<"${args[i + 1]}"; done
  done | jq -Rsc 'split("\n") | map(select(length > 0))'
}
text() { # text: the body that --body or --body-file gives
  local f
  f=$(value --body-file -F)
  if [ "$f" = - ]; then cat; elif [ -n "$f" ]; then cat "$f"; else value --body -b; fi
}
comment() { # comment <number> <body>
  save --argjson n "$1" --arg me "$me" --arg b "$2" '(.issues[] | select(.number == $n) | .comments) += [{author: $me, body: $b}]'
  logged comment "$1"
}
case "$1 $2" in
  'api repos/{owner}/{repo}') out "$(jq -c '{full_name: .repo, default_branch: "main", visibility: (.visibility | ascii_downcase)}' "$state")" ;;
  'api user') out "$(jq -c '{login: .me}' "$state")" ;;
  'api graphql')
    [ -n "$n" ] || n=$(grep -oE 'issue\(number: *[0-9]+' <<<"$*" | grep -oE '[0-9]+$' || true)
    if [[ $* == *'issue(number:'* ]] && [ -n "$n" ]; then # the check of take-in-check.sh and worktree.sh
      origin=$(jq -r .origin "$state")
      linked=$(jq -r --argjson n "$n" '.issues[] | select(.number == $n) | (.linked // [])[]' "$state" |
        while read -r b; do
          oid=$(git -C "$origin" rev-parse "refs/heads/$b") ahead=$(git -C "$origin" rev-list --count "main..refs/heads/$b")
          jq -nc --arg b "$b" --arg oid "$oid" --argjson ahead "$ahead" --arg repo "$repo" '{ref: {name: $b,
            repository: {nameWithOwner: $repo}, target: {oid: $oid, committedDate: "2026-11-03T00:00:00Z"}, compare: {behindBy: $ahead}}}'
        done | jq -sc .)
      closing=$(jq -c --argjson n "$n" '(.prs // [])[] | select(any(.closes[]; . == $n))' "$state" |
        while read -r p; do
          oid=$(git -C "$origin" rev-parse "refs/heads/$(jq -r .headRefName <<<"$p")")
          jq -c --arg oid "$oid" --arg repo "$repo" '{number, state, author, headRefName, headRefOid: $oid,
            headRepository: {nameWithOwner: $repo}}' <<<"$p"
        done | jq -sc .)
      out "$(jq -c --argjson n "$n" --argjson linked "$linked" --argjson closing "$closing" '. as $s
        | ($s.issues[] | select(.number == $n)) as $i
        | {data: {viewer: {login: $s.me}, repository: {nameWithOwner: $s.repo, defaultBranchRef: {name: "main"},
          issue: {state: $i.state, assignees: {nodes: [$i.assignees[] | {login: .}]}, linkedBranches: {nodes: $linked},
            closedByPullRequestsReferences: {nodes: $closing}}}}}' "$state")"
    elif [[ $* == *issueOrPullRequest* ]]; then # the entries of collect.sh, with no timeline, of issues only
      nums=$(grep -oE 'n[0-9]+: issueOrPullRequest' <<<"$*" | grep -oE '^n[0-9]+' | tr -d n | jq -sc .)
      out "$(jq -c --argjson nums "$nums" '. as $s | {data: {viewer: {login: .me}, repository: (reduce
        (.issues[] | select(.number | IN($nums[]))) as $i ({}; .["n\($i.number)"] = {__typename: "Issue",
          number: $i.number, title: $i.title, state: $i.state, stateReason: ($i.stateReason // null), body: $i.body,
          repository: {nameWithOwner: $s.repo}, labels: {nodes: [$i.labels[] | {name: .}]},
          assignees: {nodes: [$i.assignees[] | {login: .}]}, linkedBranches: {nodes: [($i.linked // [])[] | {ref: {name: .}}]},
          closedByPullRequestsReferences: {nodes: [($s.prs // [])[] | select(any(.closes[]; . == $i.number))
            | {number, state, author}]}, timelineItems: {totalCount: 0, nodes: []},
          comments: {totalCount: ($i.comments | length), nodes: [$i.comments[] | {author: {login: .author}, body}]},
          duplicateOf: (if $i.duplicateOf then {number: $i.duplicateOf, repository: {nameWithOwner: $s.repo}} else null end)}))}}' "$state")"
    else
      echo "fake gh: no answer for: $*" >&2
      exit 1
    fi
    ;;
  'issue view')
    if ! issues | jq -e --argjson n "$num" 'any(.[]; .number == $n)' >/dev/null; then
      echo "GraphQL: Could not resolve to an issue or pull request with the number of $num. (repository.issue)" >&2
      exit 1
    elif [ -n "$fields" ]; then
      out "$(issues | jq -c --argjson n "$num" '.[] | select(.number == $n)' | pick .)"
    else
      issues | jq -r --argjson n "$num" '.[] | select(.number == $n)
        | "title:\t\(.title)\nstate:\t\(.state)\nassignees:\t\([.assignees[].login] | join(", "))\nlabels:\t\([.labels[].name] | join(", "))\nmilestone:\t\(.milestone.title // "")\n--\n\(.body)\n",
          (.comments[] | "-- \(.author.login)\n\(.body)\n")'
    fi
    ;;
  'issue list')
    out "$(issues | jq -c --arg s "$list_state" --arg q "$search" '[.[] | select($s == "all" or (.state | ascii_downcase) == $s)
      | select($q == "" or ((.title + " " + .body) | ascii_downcase | contains($q | ascii_downcase)))]' | pick '.[]' | jq -sc .)"
    ;;
  'issue create')
    num=$(jq '[.issues[].number] | max + 1' "$state")
    save --argjson n "$num" --arg t "$(value --title -t)" --arg b "$(text)" --arg m "$(value --milestone -m)" \
      --argjson l "$(labels --label -l)" --arg me "$me" --arg a "$(value --assignee -a)" \
      '.issues += [{number: $n, title: $t, body: $b, state: "OPEN", labels: $l, comments: [],
        assignees: (if $a == "" then [] elif $a == "@me" then [$me] else [$a] end),
        milestone: (if $m == "" then null else $m end)}]'
    logged create "$num"
    echo "https://github.com/$repo/issues/$num"
    ;;
  'issue edit')
    t=$(value --title -t) b=$(text) who=$(value --add-assignee)
    [ "$who" != @me ] || who=$me
    [ -z "$t" ] || save --argjson n "$num" --arg t "$t" '(.issues[] | select(.number == $n) | .title) = $t'
    [ -z "$b" ] || save --argjson n "$num" --arg b "$b" '(.issues[] | select(.number == $n) | .body) = $b'
    [ -z "$who" ] || save --argjson n "$num" --arg who "$who" '(.issues[] | select(.number == $n) | .assignees) |= (. + [$who] | unique)'
    save --argjson n "$num" --argjson l "$(labels --add-label)" '(.issues[] | select(.number == $n) | .labels) |= (. + $l | unique)'
    logged edit "$num"
    echo "https://github.com/$repo/issues/$num"
    ;;
  'issue comment')
    comment "$num" "$(text)"
    echo "https://github.com/$repo/issues/$num#issuecomment-1"
    ;;
  'issue close')
    dup=$(value --duplicate-of) reason=$(value --reason -r) c=$(value --comment -c)
    dup=${dup##*/} dup=${dup#\#}
    [ -z "$c" ] || comment "$num" "$c"
    save --argjson n "$num" --arg dup "$dup" --arg r "$reason" '(.issues[] | select(.number == $n)) |= (.state = "CLOSED"
      | .stateReason = (if $dup != "" or $r == "duplicate" then "DUPLICATE" elif $r == "not planned" then "NOT_PLANNED" else "COMPLETED" end)
      | .duplicateOf = (if $dup == "" then null else ($dup | tonumber) end))'
    logged close "$num"
    echo "✓ Closed issue $repo#$num"
    ;;
  'issue develop')
    if [[ $* == *--list* ]]; then
      jq -r --argjson n "$num" --arg repo "$repo" '.issues[] | select(.number == $n) | (.linked // [])[] | "\(.)\thttps://github.com/\($repo)/tree/\(.)"' "$state"
    else
      b=$(value --name)
      git -C "$(jq -r .origin "$state")" branch "$b" main
      save --argjson n "$num" --arg b "$b" '(.issues[] | select(.number == $n) | .linked) += [$b]'
      logged develop "$num"
      echo "github.com/$repo/tree/$b"
      [[ $* != *--checkout* ]] || { git fetch -q origin "$b" && git checkout -q -b "$b" "origin/$b"; }
    fi
    ;;
  'pr list') out "$(jq -c '.prs // []' "$state")" ;;
  'pr view') # with --json only
    pr=$(jq -c --argjson n "$num" '(.prs // [])[] | select(.number == $n)' "$state")
    [ -n "$pr" ] || { echo "GraphQL: Could not resolve to a PullRequest with the number of $num. (repository.pullRequest)" >&2; exit 1; }
    out "$(pick . <<<"$pr")"
    ;;
  'repo view') out "$(jq -c '{nameWithOwner: .repo, visibility, defaultBranchRef: {name: "main"}}' "$state")" ;;
  'label list') out "$(jq -c '[.labels[] | {name: .}]' "$state")" ;;
  'auth status') echo "github.com: Logged in to github.com account $me" ;;
  *) echo "fake gh: no answer for: $*" >&2; exit 1 ;;
esac
