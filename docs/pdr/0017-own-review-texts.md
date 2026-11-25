# 0017 The plugin reviews with its own texts, in every host

- Status: accepted
- Level: project
- Date: 2026-11-25

## Decision

We will review a change with texts of the plugin. A round of
`craft:review-loop` is one reader with `skills/review-loop/code-lens.md`, and
the security review is one reader with `security-lens.md`, in Claude Code and
in ZCode alike. No step of the skill runs `/code-review`, `/security-review`
or the review command of another host as its reviewer. In Claude Code, Codex
reads the whole branch once with the same lens, at each level of a code
review. A session in Codex reviews with `/review` until a run of its own
(#498).

## Rests on

- ZCode has no review command. In the one task that ran in two hosts, the
  reviewer that the agent wrote there missed the defect that `/code-review
  high` found in Claude Code (#466).
- The person decided on 2026-11-24, against the verdict of the panel of
  `craft:product`: the plugin must not depend on a command of a host, and
  each rule of its review must be its own, so that the person can read it,
  measure it and change it. The text of the built-in `/code-review` has no
  open licence, and no public file holds it.
- The measure, on Opus at `high`, with `tests/review_loop_reader_eval.sh`:
  the runs whose report names a known defect, added up over the defects of a
  case, and over each pass of the lens: its first text, and the final one,
  which has the table of levels more. One pass is three runs.

  | Case | `/code-review high` or `/security-review` | The lens of the plugin |
  | --- | --- | --- |
  | A check that stands in for another, in a private repository (#466) | 3 of 3 | 8 of 9 |
  | The same shape, written by hand, public (`swap`) | 1 of 3; the prompt of `codex-review.sh` before this work, on Opus: 0 of 3 | 6 of 6 |
  | PR #9: the retry of a write (#91) | 0 of 3 | 6 of 6 |
  | PR #9: a branch in a fork (#90) | 0 of 3 | 0 of 6; Codex with the lens: 2 of 2 |
  | PR #289, five defects (#290) | 5 of 15 in one pass | 47 of 105 in seven passes: 5 to 9 of 15 a pass |
  | PR #426, six wrong results of one function | 24 to 25 of 36 in six runs: 4.1 a run | 42 of 90 in 15 runs: 2.8 a run |
  | Four pull requests of a private repository, seven defects, no text tuned on them | 10 of 21 | 8 to 9 of 21 in the first pass and 11 to 15 in the last, by reading: the statements of two of the defects were not at hand |
  | Three holes, and three things that are no hole (`holes`) | 9 of 9, noise 0 of 9 | 18 of 18, noise 0 of 18 |

- On PR #426 the lens names fewer of the six forms than the built-in command
  did: 2.8 a run against 4.1. Each of the six has a count of zero in the
  commands of 30 days of local sessions, so *The findings* of the review
  loop declines each of them. The lens named one of the four defects of #427
  in 2 of 15 runs, and the built-in command in none. On 2026-11-25 the
  person saw the counts of the first passes, the lens 20 of 36 and the
  built-in 24 to 25 of 36, and decided to go on.
- Three runs tell apart only a large effect: the same text named 9, 5 and 5
  of the 15 chances of PR #289 in three passes. So the table compares sums.
- Inside the loop of rounds, `tests/review_loop_eval.sh` passed in 3 of 3
  runs and, at the stop after round 3, in 3 of 3: each round was a reader
  with the code lens, and no run used a review command of the host.
- A second model finds what the first does not: no reader on Opus named #90
  in more than 20 runs, and Codex named #90 and #91 in 2 of 2 runs, with the
  lens and with its prompt before it.
- In ZCode itself, on GLM-5.4, the main session sent one subagent with the
  four lines of the prompt, and each of six reports was whole: the case
  `swap` in 2 of 2 runs, the #466 case in 2 of 2, and two of the six forms
  of PR #426 in each of two runs. A run took 8 to 17 minutes on the small
  cases and 55 and 78 minutes on PR #426. The final text named the case
  `swap` in 2 of 2 more runs.
- A run of the code lens at `high` costs $1.1 to $1.8 and 4 to 6 minutes on
  Opus; at `low` $0.45 and one minute; at `xhigh` about $2.9 and 13 minutes.
  A run of the security lens costs $0.35, where `/security-review` cost
  $0.73 to $1.00 on the same case.
- One user asked for craft in ZCode (`docs/research/2026-11-16-zcode-third-host.md`).

## Revisit when

The lens names fewer confirmed defects than the review command of a host on
three new cases; or a text of the plugin cannot be kept at the level of a
host's command for its cost.

## Options considered

- The plugin's own text in every host, and no step names a built-in command
  as a reviewer: chosen by the person.
- The plugin's own text in every host, and the built-in command as one more
  read where the host has one: it keeps the dependency that the person wants
  gone.
- The built-in command where the host has one, and the plugin's text where
  it has none: the advice of both readers of the panel, a Fable agent and
  Codex. Their ground: no measured basis to replace the built-in command,
  and one user. Two review systems to measure and to keep, and the rules of
  the larger one stay closed.

## Links

#466, #498, #499, #427, M7 · The skills work in ZCode, ADR 0013,
`docs/superpowers/specs/2026-11-24-own-review-texts-design.md`,
`docs/research/2026-11-16-zcode-third-host.md`
