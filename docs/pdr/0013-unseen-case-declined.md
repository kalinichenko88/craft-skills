# 0013 A review agent's guess about a case that the text of a skill does not name is declined until a run shows the failure

- Status: accepted
- Level: feature
- Date: 2026-11-16

## Decision

We will decline, in review-loop, a finding of a review subagent,
`/code-review`, `/review` or Codex whose only proof is its guess of what a
model does in a case that the text of a skill or a prompt does not name,
unless a run or a real session outside the review has already shown a wrong
result there, or the case is data loss or a security hole. A person's
review comment is no such finding: it is judged as any other. The finding
gets no edit and starts no round: it goes to the **Declined** line of the
summary with "no failing run" as its reason. The loop makes no run for it.
A finding with other proof, as a false fact, a conflict between two rules
or a command that fails, is judged as before. The review of text still
reports such a case: the loop declines it, and the **Declined** line of
the pull request records it. The 10 runs
and the 3 of 10 of ADR 0009 stay with each edit of this repository's own
texts, inside the loop too.

## Rests on

- `tests/review_loop_text_eval.sh 10 case` on the text before #417: 9 of
  10 Opus sessions added the case to the skill with no run of a model,
  each at about $0.36. On `08357b3`, the rule that #417 merges: 0 of 10,
  and none started a run of `claude`. With a note that a session wrote
  wrong on the case as the evidence (`seen`), 5 of 5 added the case on
  `15afc55` and on `08357b3`, and a wrong path (`fact`) was fixed in 5 of 5
  on both.
- A person's review comment that names the case (`person`): the text of
  `0ea7cd8`, which said nothing of a person, declined it for "no failing
  run" in 1 of 10 runs; `ba4038c`, which said that it is a request,
  `e5ecab0` and `08357b3`, in 0 of 10 each.
- Of the late-round defects in the text fixes of three merged pull requests,
  6 of 13 from round 2 on are a case that the text leaves out (the Fable
  reader of #417's panel).
- A run of 10 inside a loop is about 20 runs and 2 fixtures a pull request,
  the loop waits for each batch, and an eval beside a review loaded the
  skill in 12 of 30 runs, against 28 of 30 alone
  (`.claude/rules/evals.md`). The runs need cases that someone wrote:
  `claude plugin eval` runs the cases of a plugin, and most skills and
  prompts of a project have none.
- Of two gaps that a review found and that were measured, one failed in 0
  of 10 runs (#186) and one in 9 of 10 (#260): a decline loses a real gap
  about as often as it stops a sentence that no run needs.

## Revisit when

A gap that a review reported and the loop declined fails in at least 3 of
10 runs later, twice; or a person asks for a declined case to be run and
added twice in one month.

## Options considered

- The declined cases of a pull request go to one issue, with a run as its
  first step: about 2 such cases a pull request, about 34 issues in 19 days
  against 24 open in `Later`.
- 10 runs of the case inside the loop before the edit, as #417 first asked:
  about 20 runs a pull request, and no way for a user with no harness.
- No change: the loop goes on adding a sentence for each case that a round
  names.
- The review of text reports no case that the text does not name: that
  ban conflicts with its kinds Rule, Command and False, and drops the
  exception for data loss (round 1 of #417).

## Links

#417, ADR 0009, ADR 0006, #186, #260, #283, `skills/review-loop/SKILL.md`,
`skills/review-loop/docs-lens.md`, `scenarios/review-loop/review.md`
