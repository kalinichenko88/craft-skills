#!/usr/bin/env bash
# The hook hand-escapes rules.md into JSON. Both Claude Code and Codex drop
# context that does not parse, so the real file must come back byte for byte.

set -eu

root=$(cd "$(dirname "$0")/.." && pwd)

# Git for Windows checks out with core.autocrlf=true by default. bash reads a CR
# as part of the command, so that checkout must keep LF too: the hook, and every
# script the skills run.
crlf=$(mktemp -d)
trap 'rm -rf "$crlf"' EXIT
git -C "$root" -c core.autocrlf=true checkout-index -a --prefix="$crlf/"
if grep -rIl $'\r' "$crlf"; then
  echo "FAIL: a core.autocrlf=true checkout has CRLF in the files above"
  exit 1
fi
# A clone made before .gitattributes keeps rules.md in CRLF: an update rewrites
# only the files it changes. The hook must still give the rules.
cp "$root/hooks/rules.sh" "$crlf/hooks/"
sed 's/$/\r/' "$root/rules.md" >"$crlf/rules.md"
for part in 1 2; do
  [ "$("$crlf/hooks/rules.sh" SessionStart $part)" = "$("$root/hooks/rules.sh" SessionStart $part)" ] || {
    echo "FAIL: the hook does not give part $part of the rules from a CRLF rules.md"
    exit 1
  }
done
# NixOS has no /bin/bash: every script must find bash on PATH.
for script in $(git -C "$root" ls-files '*.sh'); do
  [ "$(head -1 "$root/$script")" = '#!/usr/bin/env bash' ] || {
    echo "FAIL: $script: the shebang must be #!/usr/bin/env bash"
    exit 1
  }
done
# Each script prints its usage from the call lines of its header (ADR 0001).
# shellcheck disable=SC2016 # the line as the scripts hold it
usage='sed -n "s/^#   ${0##*/}/usage: ${0##*/}/p" "$0" >&2'
for script in $(git -C "$root" ls-files 'skills/*/scripts/*.sh' '.claude/skills/*/scripts/*.sh'); do
  if ! grep -qF "$usage" "$root/$script" || ! grep -q "^#   ${script##*/}" "$root/$script"; then
    echo "FAIL: $script: usage must print the '#   ${script##*/}' lines of its header"
    exit 1
  fi
done

# hooks.json runs the hook once per part, and each part is one context. The
# two parts and the marker line between them rebuild rules.md (ADR 0004).
marker=$(grep '^<!-- rules.sh splits' "$root/rules.md") || {
  echo "FAIL: rules.md has no marker line where rules.sh splits it"
  exit 1
}
if "$root/hooks/rules.sh" SessionStart >/dev/null 2>&1; then
  echo "FAIL: the hook with no part gives output, not an error"
  exit 1
fi
for event in SessionStart SubagentStart; do
  for part in 1 2; do
    output=$("$root/hooks/rules.sh" "$event" $part)
    [ "$(jq -r .hookSpecificOutput.hookEventName <<<"$output")" = "$event" ] || {
      echo "FAIL: $event $part: wrong hookEventName"
      exit 1
    }
    # Claude Code moves additionalContext over 10,000 characters to a file and
    # shows only a 2,000-character preview.
    chars=$(jq -r '.hookSpecificOutput.additionalContext | length' <<<"$output")
    [ "$chars" -le 10000 ] || {
      echo "FAIL: $event $part: context is $chars characters, the cap is 10000"
      exit 1
    }
    jq -r .hookSpecificOutput.additionalContext <<<"$output" >"$crlf/part$part"
    # Each part is read on its own, after another plugin's context too.
    [ "$(head -1 "$crlf/part$part")" = "# Global instructions, part $part of 2" ] || {
      echo "FAIL: $event $part: the part does not start with its own heading"
      exit 1
    }
  done
  diff <(printf '%s\n\n%s\n\n%s\n' "$(<"$crlf/part1")" "$marker" "$(<"$crlf/part2")") \
    "$root/rules.md" || {
    echo "FAIL: $event: the two parts and the marker line differ from rules.md"
    exit 1
  }
  # hooks.json runs both parts under each event, from one group, so one
  # matcher gives both. The path is quoted: the plugin root can hold a space.
  cmds=$(jq -r --arg e "$event" '[.hooks[$e][] | [.hooks[].command |
    select(test("rules\\.sh"))] | select(length > 0)] |
    if length == 1 then .[0][] else "rules.sh in \(length) groups" end' \
    "$root/hooks/hooks.json" | sort | tr '\n' ',')
  # shellcheck disable=SC2016 # the variable as hooks.json holds it
  want=$(printf '"${CLAUDE_PLUGIN_ROOT}/hooks/rules.sh" %s %s,' "$event" 1 "$event" 2)
  [ "$cmds" = "$want" ] || {
    echo "FAIL: hooks.json: $event runs '$cmds', not '$want'"
    exit 1
  }
done
# A review subagent gets these rules too, as the loop above proves, and
# *Out-of-scope findings* tells it to file an issue without asking. One
# sentence must tell every read-only subagent, a review one included, to file
# nothing.
tr '\n' ' ' <"$root/rules.md" | grep -qE 'read-only subagent[^.]* review[^.]* files nothing' || {
  echo "FAIL: SubagentStart: no sentence tells a read-only review subagent to file nothing"
  exit 1
}
# A fix outside the task goes into its PR or into an issue by one scope: the
# task's module. Each place that draws that line names the module, and none
# keeps the three tests without it (#103).
for f in rules.md skills/github/filing.md skills/github/take-in.md \
  skills/github/SKILL.md skills/github/README.md; do
  text=$(tr -s '[:space:]' ' ' <"$root/$f")
  grep -qE "(same|task's) module" <<<"$text" || {
    echo "FAIL: $f: a fix goes into the task's PR with no module scope"
    exit 1
  }
  if grep -qi 'small, safe' <<<"$text"; then
    echo "FAIL: $f: a fix goes into the PR by size and safety alone, with no module"
    exit 1
  fi
done
# Sentences that must stay, word for word. Each line loses one leading #, so a
# phrase can span a script's comment lines.
# - superpowers' review skills start at the same moments as review-loop and
#   give other steps, and subagent-driven-development's per-task reviewer is a
#   review subagent too. The rules must say which skill wins, keep review-loop
#   out of the per-task review, and invoke review-loop after the last task: the
#   review there is not the first review of the change, so the trigger in
#   rules.md does not fire.
# - The checks of a spec and a plan are not a review of a change, so the
#   trigger above does not fire there. The steps live in review-loop, and only
#   this sentence starts it (#101).
# - architecture and review-loop file a debt issue through filing.md. With no
#   `debt` label in the repository, "never invent a new label" left it `bug` or
#   unlabelled (#133). Each place that gives the labels rule, for a new issue or
#   for a host, names the exception.
# - The GitHub section keeps the headings of its two rules that must fire with
#   no skill loaded (#151). With no GitHub remote, an agent that finds
#   something out of scope may never load the github skill, so rules.md keeps
#   the fallback too. The
#   ask for a plugin defect shows the text that filing.md writes, so its check
#   of the defect runs before the person is asked.
# - A zero count stops a fix, but an attacker can make the input of data loss
#   or a security hole: the rule for a person's report, in rules.md, and the
#   rule for a review finding, in review-loop, each name that exception (#151).
#   A project with no real source to sample has nothing to count: both rules
#   say that the count then stops nothing, and name the input of the test
#   (#161).
# - Run from another checkout, gh 2.103 removes the branch's linked worktree
#   and its local branch at the merge, with no check of Cleanup. The merge
#   runs in the checkout that holds the branch, and review-loop asks that
#   checkout, not the session's directory, whether there is a worktree (#176).
#   18 of 19 recorded sessions that moved into a worktree from the main
#   checkout did it with cd, and #173's session then read itself as one that
#   started there: it gave the person the commands of Cleanup. A session
#   leaves the way it came in, and only one that started there hands them
#   over (#195).
# - After a merge, #117, #205 and #213 still quoted the room left in rules.md,
#   and no citation of theirs showed it. *Finishing* gives the scout a
#   Decision line for each number that the PR changed, counted again in the
#   merged code, and the scout reads the title and the body against them
#   (#211). #220 changed rules.md, and its description gave no count: a
#   size that a check caps gets a Decision line anyway. 4 of 20 PRs merged
#   with the branch behind main, so the scout reads a new checkout of the
#   default branch, not the branch's worktree. A merge that fixes some
#   problems of an issue leaves it open.
#   tests/github_scout_eval.sh tests the scout, not these lines.
# - Another plugin's SubagentStart rule told Haiku subagents to reuse the
#   project's pattern and keep the work short. On an edit of an existing React
#   project, 5 of 10 invoked the conventions skills before the first write;
#   with "No pattern to copy …" after the conventions rule, 16 of 20 did. The
#   runs and their fixture are in the description of the PR that closes #196.
# - rules.md reaches the model in two parts, in either order (ADR 0004). The
#   read-only subagent of GitHub once pointed "above" to the Haiku subagents
#   of part 1, and without that word it read as every Haiku subagent. It
#   names the Explore subagent of part 1 instead.
# - take-in let the worktree be set up while the scout read the tracker. A
#   session called EnterWorktree while the scout ran, and Claude Code
#   refused every later Bash call of the scout (#268). Recorded sessions
#   show the same for a citations scout sent before the move. worktree.sh
#   can run beside the take-in scout; the move waits for each subagent.
# - The merge read no check of the pull request: 4 of 104 pull requests here
#   with checks merged before `check` ended, and an agent took `--admin`
#   right after a refusal of the ruleset, with no question (#309). The exit
#   code of `gh pr checks` cannot decide: a cancelled check gives 0, and a
#   pull request with no check gives 1. So the merge reads each bucket.
# - A settled ADR took no edit past its Status line, so 6 sentences of 3
#   ADRs that a later fact made false stayed false; on the two sentences of
#   ADR 0007, Sonnet gave the stale answers in 5 of 5 runs (#343). The skill
#   corrects such a sentence in place with a dated line under `## Updates`
#   that keeps the old words, and the lens accepts it.
# - The merge passed no `--subject`, so the squash commit took the PR title
#   as its subject: 29 of the last 30 merges here have the subject
#   "<PR title> (#<PR>)". A PR title follows the project's language, and a
#   commit message is English in every repository (#330). The merge gives an
#   English subject, with the number that /release reads.
# - take-in carried a duplicate's stack trace to the survivor as its first
#   lines in 3 of 5 Opus runs. With the trace copied as it is, each of 5 runs
#   wrote that comment through a heredoc in the shell, where a line of the
#   log can end the heredoc and run as a command (#296). The comment goes to
#   a new file outside the checkout through the file tool, so that no file
#   stays in the worktree, and gh reads it with --body-file.
# - A finding of a failure on an input that a check before the code refuses
#   got an issue from a review in a private tracker, with no look at the
#   check. With the check two callers above, 4 of 20 Opus runs filed it, each
#   after a look at the first caller alone; with the trace, 0 of 60 (#375).
#   Each fix of the reviews closed a case where two sentences gave one
#   finding two outcomes: a default, a nit, a trace that stops after a
#   check, and a Boy Scout fix or a declined finding on the Filed line.
# - A push that the repository refused did not stop `gh pr create`: 5 of 5
#   Opus runs put both in one command, after `git push … | tail -3;`. With
#   the push in a command of its own, 0 of 5 called it (#356).
# - After a failed check, the person's "merge anyway" read as the request
#   for `--admin`: 5 of 5 Opus runs merged with it, past a rule of the
#   branch, with no plain merge first (#327). The merge all the same is the
#   same `gh pr merge`, and a refusal goes back to the person.
while IFS='|' read -r f phrase; do
  sed 's/^#//' "$root/$f" | tr -s '[:space:]' ' ' | grep -qF "$phrase" || {
    echo "FAIL: $f: no \"$phrase\""
    exit 1
  }
done <<'EOF'
rules.md|`craft:review-loop` replaces `superpowers:requesting-code-review` and `superpowers:receiving-code-review`.
rules.md|. In `superpowers:subagent-driven-development`, the review after each task stays as that skill sets it, without `craft:review-loop`. Invoke review-loop after the last task, in place of the final review.
rules.md|In Claude Code, invoke it also in place of the builder check of `superpowers:brainstorming`, and after the self-review of `superpowers:writing-plans`.
skills/github/filing.md|On each path before the code, look for a check in code or in a script, as a schema or a validation, that refuses that input, or for a default that takes its place. When each path has one, and the failure is no data loss and no security hole, the finding is ruled out
skills/github/filing.md|When one path has none, or the trace stops on a path before it finds one, the finding is not ruled out: it is filed as below.
skills/github/filing.md|A finding that the Boy Scout check leaves, that is no nit, and that fails only on some input,
skills/review-loop/SKILL.md|After them, marked `not filed`, each finding outside the task that `craft:github` calls a nit or rules out.
skills/github/SKILL.md|A nit, or a failure that `filing.md` rules out: one line in the final report, no issue
skills/github/filing.md|Give it one line in the final report, with the `path:line` of each check or default.
skills/github/filing.md|The one exception is debt: a file or a folder to split,
skills/github/filing.md|create `debt` first: `gh label create debt --description "Structural debt to refactor" --color 5319e7`
skills/github/filing.md|For a debt finding, when the repository has no debt label, create `debt` first.
skills/github/filing.md|A debt finding keeps its debt label: when the repository has none, create `debt`
skills/github/scripts/add-finding.sh|A debt finding keeps its debt label: when the repository has none, create `debt`
skills/roadmap/triage.md|except `debt` for a debt issue
skills/roadmap/triage.md|when a row's label is `debt` and the repository has no debt label, create `debt`
skills/roadmap/planning.md|except `debt` for a debt issue
rules.md|**Out-of-scope findings become issues.**
rules.md|Where there is no GitHub remote or `gh auth status` fails, name the finding in the final report instead of filing it.
rules.md|**A defect in this plugin goes to its tracker, after the person says yes.**
rules.md|Unlike the rule above, ask the person first: show the text that the github skill's `filing.md` writes.
rules.md|For a report of data loss or a security hole, a zero count does not stop the fix. An attacker can make the input, so the test of that fix uses the input of the report.
skills/review-loop/SKILL.md|A zero count does not decline a finding of data loss or a security hole: an attacker can make the input, and the test of its fix uses the input of the finding.
rules.md|With no real source to sample, the count stops nothing, and the test uses the input of the report.
skills/review-loop/SKILL.md|With no real source to sample, the count declines nothing, and the test of the fix uses the input of the finding.
skills/github/SKILL.md|gh pr checks <PR> --json name,bucket,link --jq '.[] | select(.bucket != "pass" and .bucket != "skipping") | "\(.bucket) \(.name) \(.link)"'
skills/github/SKILL.md|The list decides, not the exit code of the watch: a cancelled check gives 0, and no check at all gives 1.
skills/github/SKILL.md|with `--subject` and `--body` in English, as every commit message is, also when the PR is in another language. `--subject` is the PR title in English, then ` (#<PR>)`
skills/github/SKILL.md|`gh pr merge --squash --delete-branch --subject --body`, in English: the PR title with ` (#<PR>)` and one bullet list for the whole branch
skills/github/SKILL.md|Add `--admin` or `--auto` only when the person asks for it: `--admin` merges past a red check, and `--auto` leaves the pull request open when the command ends.
skills/github/SKILL.md|or the merge all the same: run the same `gh pr merge`, with no new wait and no `--admin`.
skills/github/SKILL.md|Run the merge in the checkout that holds the branch, whatever directory the session is in: `(cd <path> && gh pr merge …)`, where `<path>` is what `git for-each-ref --format='%(worktreepath)' refs/heads/<branch>` prints.
skills/github/SKILL.md|`ExitWorktree` does nothing for a session that moved there in any other way, as with `cd` after `worktree.sh`: that session runs both commands itself, each with `git -C <the main checkout>`. Only a session that started in the worktree, as with `claude --worktree` or `codex --worktree`, cannot leave it: give the person the two commands below, to run after the session ends.
skills/review-loop/SKILL.md|1. Push the branch, in a command of its own. When the push succeeds and the branch has an open pull request, add the summary's lines to its `## Review`. When it succeeds and the branch has none, open the pull request
skills/review-loop/SKILL.md|When `git for-each-ref --format='%(worktreepath)' refs/heads/<branch>` prints nothing or the first path of `git worktree list`, the branch has no linked worktree
skills/github/SKILL.md|and a number that it changed, as a count or a size that an issue can quote.
skills/github/SKILL.md|Count again each number that the merged code holds: a description can be older than the last fix. When a check sets its limit, count it as that check counts it.
skills/github/SKILL.md|For each changed file with a size limit of its own, as a cap on its characters that a test sets, or on the `debt` list of a size check, add a decision with its new size and the check's limit, also when the description does not give them.
skills/github/SKILL.md|*Finishing* reads the merged code in a new checkout, outside every checkout. The branch's worktree is not the merged code when the default branch moved after the branch's last push.
skills/github/SKILL.md|git worktree add --detach <the mktemp path> origin/<the default branch>
skills/github/SKILL.md|Remove it when *Finishing* ends or stops, with `git worktree remove --force <the mktemp path>`.
skills/github/SKILL.md|A problem marked `Done in #<PR>.` needs no other correction, and an issue with a problem left in it stays open.
skills/github/scout.md|Then read the title and the whole body of each issue against them, the sentences with no citation too.
rules.md|`craft:react-conventions` too. A subagent invokes them itself. No pattern to copy and no rule to keep the work short skips these calls.
rules.md|A read-only subagent, as a review or an `Explore` subagent, files nothing, whatever the rules below say.
skills/github/take-in.md|While a subagent reads the file, you can run `worktree.sh` below:
skills/github/take-in.md|Claude Code: wait until each subagent that you sent returns. Then call `EnterWorktree`
skills/github/take-in.md|The survivor's comment never goes into a shell command: write it with the file tool to a new file outside the checkout, and post it with `--body-file`.
skills/github/take-in.md|gh issue comment 91 --body-file <file>
skills/architecture/SKILL.md|correct the sentence in place: in the change that makes it false; else in a later change, as its task or as a finding outside its task. Then add a line under `## Updates`, a heading right after the Status and Date lines: `- YYYY-MM-DD <source>: <section>. Was: "<the old words>".`
skills/review-loop/architecture-lens.md|The one exception is *A fact that changed* in *ADRs*: a sentence that is false now, corrected in place, with its line under `## Updates` that quotes the old words, and with the same decision.
EOF
# After a compaction Claude Code attaches each skill again, but counts 4
# characters a token against 5,000 tokens: it cuts the text past 20,000
# characters (ADR 0006). A file on the debt list waits for its split, and
# must not grow past its size there. A path that is gone leaves the list.
debt='skills/review-loop/SKILL.md 33556 #283'
for f in "$root"/skills/*/SKILL.md; do
  path=${f#"$root/"}
  chars=$(jq -Rs length "$f")
  cap=$(awk -v p="$path" '$1 == p { print $2 }' <<<"$debt")
  if [ -z "$cap" ]; then
    [ "$chars" -le 20000 ] || {
      echo "FAIL: $path has $chars characters, past the cap of 20000 (ADR 0006)"
      exit 1
    }
  elif [ "$chars" -le 20000 ]; then
    echo "FAIL: $path has $chars characters, within the cap of 20000: take it off the debt list"
    exit 1
  elif [ "$chars" -gt "$cap" ]; then
    echo "FAIL: $path has $chars characters, past its $cap on the debt list"
    exit 1
  fi
done
while read -r path _; do
  [ -f "$root/$path" ] || {
    echo "FAIL: $path is on the debt list of the SKILL.md cap, but does not exist"
    exit 1
  }
done <<<"$debt"

echo 'rules_test: ok'
