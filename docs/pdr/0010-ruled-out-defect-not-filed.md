# 0010 A failure that a check or a default in the code keeps its input from is not filed

- Status: accepted
- Level: feature
- Date: 2026-11-12

## Decision

We will not file an out-of-scope failure that shows only on an input that
a check in code or in a script refuses, or a default replaces, on every path
before the code, unless it is data loss or a security hole: real use does
not reach it, so it is no defect. The run traces the input back through
each caller to where it enters, and the final report names each check or
default by its `path:line` in one line (`skills/github/filing.md`). A step
of a skill's text is no such check. A finding whose worth is unclear gets
no worth check of its own and is filed as before, and a fix outside the
task's module stays out of the pull request.

## Rests on

- On 2026-11-12, 4 of the 33 issues closed as not planned in this tracker
  and in two private ones closed because the input never reaches the code,
  each within a day. Two of them were a trace: a schema refused the
  characters of the failure, or the caller always set a default. One of
  these two was filed from a review after #260, with no check of the
  schema (#375).
- Runs of `tests/github_filing_eval.sh 10 labelled`, with the check two
  callers above the failure: 4 of 20 runs filed it on the text before #375,
  and each of the 4 stopped at the first caller. With the trace, in three
  wordings of it, 0 of 40 filed it, and 40 of 40 named the check by its
  line, against 9 of 20 before. The defect and the nit got the same
  verdicts in all 60 runs. The false docstring reached the tracker in 59:
  the one run that left it off followed the label `(nit)` of the review, as
  the labelled runs of #260 did. With the check in the only caller, 0 of 10
  runs filed it before the trace.
- A model skips steps of a skill's text: #348 (1 of 1 run), #356 (4 of 5
  runs).
- 11 of the 33 closed as not worth it, and 59 of the 64 open findings of
  unclear worth in the two private trackers have a milestone: triage places
  them (PDR 0004).
- The person asked for no fix outside the module on 2026-11-12: the border
  of #103 holds.

## Revisit when

A finding that the trace ruled out turns out to be a defect that real use
reaches, or a tracker that uses craft closes two issues in a month because
their input never reaches the code.

## Options considered

- The four classes of #375, with a subagent of `craft:product` for a
  finding of unclear worth: 0 of the 43 open issues of 2026-11-12 would
  leave by its *Trivial* or *Ruled out* class as written, and the subagent
  goes against "Not in a subagent" and "The person decides".
- A trivial fix outside the module in the pull request of the task: the
  person said no; the module border of #103 holds.
- A step of a skill's text as the check that rules a case out: models skip
  such steps.
- No change: one such issue in the six days after #260.

## Links

#375, #260, #103, PDR 0004, `skills/github/filing.md`,
`scenarios/github/filing.md`
