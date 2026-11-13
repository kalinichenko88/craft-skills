# 0011 A finding in the task's module that needs only a choice goes to the person as a question

- Status: accepted
- Level: feature
- Date: 2026-11-13

## Decision

We will ask the person about an out-of-scope finding that meets the Boy
Scout conditions of the same module, the size and the separable fix, and
that is not clear only because it needs a choice: between two or three ways
to fix it, or of what the product does there. The run asks only when the
code that it read gives each way and its cost, with no new search, run or
measurement. It asks at once, with the ways, the cost of each and a
recommendation, and waits for the answer. After the choice, the fix goes
into the pull request of the task, with its test and its review, and counts
in the total of the Boy Scout fixes. When the person says to file it, or
there is no person, as in a scripted run or one told not to ask questions,
the finding is an issue, as before. A finding in another module is an issue
still (PDR 0010).

## Rests on

- kalinichenko88/vaultmd#54: the review of the pull request of #53 found a
  refused push in Step 6 of the file that the task changed, with two ways to
  fix it. The run filed it. Asked why, it said that the choice was not hard
  and the fix was one instruction. The person must run a whole new session
  for it, and asked to decide such a choice together in the session (#401).
- Of the 82 issues that hold a filed out-of-scope finding in
  kalinichenko88/vaultmd and this tracker, 9 lay out a choice between ways.
  Both readers of the panel found 1 to 3 of them that the rule would take:
  vaultmd#54 surely; vaultmd#46 and #43 maybe. The others are in another
  module, larger than the task, or need a measurement first.
- 10 Opus runs of `claude -p` on a copy of kalinichenko88/vaultmd after the
  merge of #55, with the finding of #54 from round 1: on the text before
  #401, 5 of 5 filed it as an issue, each as "a design choice"; on the text
  of #401, 5 of 5 asked the person to choose, with the cost of each way and
  a recommendation. All 10 recommended the same way.

## Revisit when

Of the first 5 real questions by this rule, the person calls 2 not worth a
question, or answers 2 of them with "file it".

## Options considered

- The run decides the way itself and writes the reason in the pull request,
  as review-loop does for a trade-off inside the task: no question, and a
  scripted run can measure it; the person sees the choice only in the
  description, and asked to decide together.
- No change: each such finding costs a new session.
- A question that waits until the merge, while the work goes on: the
  summary, the pull request and a later session must carry it as open, and
  an answer after the review rounds starts a new count of rounds.
- A question at once, and a wait for the answer: chosen.

## Links

#401, PDR 0010, PDR 0004, `rules.md` *The Boy Scout Rule*,
`skills/github/filing.md`, `scenarios/github/filing.md`
