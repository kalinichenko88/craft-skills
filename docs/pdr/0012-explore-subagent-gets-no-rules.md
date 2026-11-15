# 0012 An Explore subagent of Claude Code gets no rules

- Status: accepted
- Level: feature
- Date: 2026-11-15

## Decision

We will give an `Explore` subagent of Claude Code no part of `rules.md`. It
has no tool that edits a file, and it reports to the session that sent it.
`hooks/rules.sh` prints nothing on SubagentStart when the input of the hook
names that agent type. Each other subagent gets both parts, as each session
does: a `general-purpose` one, a `Plan` one, a custom one, and each subagent
of Codex. No short text takes the place of the rules.

A `Plan` subagent keeps the rules: it runs on the model of the session, and
the rules for the test of a bug fix and for the docs act in the plan that it
writes.

## Rests on

- The subagent transcripts of 14 days on one computer, to 2026-11-15: 508
  `Explore`, 3 `Plan` and 2,319 `general-purpose` of 2,839. No `Explore` or
  `Plan` one loaded a skill, and none ran a write of `gh`, a commit or a
  push. The same counter marks 494 `general-purpose` ones for a skill and
  62 for such a write. No prompt of the 508 asked the subagent to write to
  GitHub.
- Both readers of the panel estimate the cost of the rules for those
  subagents at 0.20 to 0.46 USD in 14 days: nearly all of them run on Haiku.
  So only a form with no text to keep is worth its cost.
- Claude Code starts an `Explore` subagent with no `CLAUDE.md` of the
  project (https://code.claude.com/docs/en/sub-agents).
- 32 Haiku runs of `claude -p` on a small shop with two bugs and a fake
  `gh`, each with one `Explore` subagent on Haiku. With a task that only
  searches, or that asks for the bugs of two folders, the subagent loaded no
  skill and wrote nothing to the tracker: 11 of 11 runs with the rules and
  11 of 11 with none. Told by its prompt to file each bug with
  `gh issue create`, it filed in 0 of 5 runs with the rules and in 1 of 5
  with none. The counter saw 5 writes in a run with a `general-purpose`
  subagent and the same prompt. With the `Explore` subagent on Opus and no
  rules, 5 of 5 more runs that asked for the bugs wrote nothing and loaded
  no skill.
- ADR 0009 admits a sentence only after a failure in 3 of 10 runs. No run
  gives one for a short text.

## Revisit when

A transcript of an `Explore` subagent shows a write of `gh`, a commit or a
push that its prompt did not ask for; or 10 of 100 subagents in the
transcripts of 14 days are `Plan`.

## Options considered

- A short text of at most 2,000 characters for the two types, as #414
  first asked: a second text to keep true beside `rules.md`, with no failing
  run for a sentence of it.
- No change: the milestone M5 asks for the cut, and each rule added to
  `rules.md` costs each `Explore` subagent too.
- No rules for `Explore` and `Plan`: a `Plan` subagent then plans a bug fix
  with no rule for its test, for a type that 3 of 2,839 subagents have.
- No rules for `Explore`, chosen in `hooks/rules.sh`: chosen.
- The same, chosen by a matcher in `hooks/hooks.json`: in a run of Claude
  Code 2.1.325, the entry with no matcher fired for an `Explore` subagent
  beside the entry with the matcher. A matcher with a look-ahead fired for
  each type but that one there, but the regex of Codex has no look-ahead,
  and a pattern with none must spell out each other string.

## Links

#414, ADR 0004, ADR 0009, ADR 0011, `hooks/rules.sh`,
`tests/hooks_scripts_test.sh`
