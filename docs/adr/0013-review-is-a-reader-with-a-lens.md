# 0013 A review is one reader with a lens file of the plugin, and the lens holds the levels

- Status: accepted
- Date: 2026-11-25

## Context

A round of `craft:review-loop` was `/code-review <level> <range>` in Claude
Code and `/review` in Codex, and the security review was `/security-review`
in a subagent. ZCode has no such command: the agent there wrote a reviewer of
its own, which missed a defect that the command of Claude Code found (#466).
PDR 0017 decides that the plugin reviews with its own texts.

The review of the architecture, of the tests and of the documents already
have one form: one subagent with three lines of prompt that send it to a lens
file (`architecture-lens.md`, `tests-lens.md`, `docs-lens.md`).

The measure of #466 showed how a review text behaves:

- The words of one step decide a finding. "When the change puts one check,
  build or command in place of another, compare what each one reads" named
  the defect of #466 in 4 of 5 runs, and "When one check, build or command
  stands in for another" in 1 of 5.
- A broken report is common on a weak model: on GLM-5.3 about one answer in
  three was cut or had another form.
- Three runs of a case tell apart only a large effect. The same text of the
  code lens named 9, 5 and 5 of the 15 chances of PR #289 in three passes,
  and 11, 11 and 7 of the 30 of PR #426. Twice in this work a fall of that
  size was taken for the cost of one sentence, and a control pass showed
  that it was not.

## Options considered

- A review command of the host as the reviewer, as before: PDR 0017 rejects
  it. The plugin cannot read, change or ship that text, and ZCode has none.
- One reader with a lens file of the plugin: the form that three reviews of
  the skill have already.
- The level in the host: the level was an argument of `/code-review`. A
  subagent has no such argument in each host.
- The level in the lens: a table says which readings a level makes.
- A list of each place where the range removes or replaces lines, from a
  script that the reader runs, with one question for each item. In the
  measure of the spec it named the defect of #466 in 5 of 5 runs in a frame
  that named it in 1 of 5 without the list.
- Ten runs for each pass of a lens, as ADR 0009 asks before a case gets a
  sentence: about three times the cost of a pass, which is $14 to $37.

## Decision

We will make each round one reader, a subagent with no other job, that reads
`skills/review-loop/code-lens.md` by its path. Its prompt is four lines: the
lens, the range as two SHAs, the working tree and the level. The security
review is the same with `security-lens.md` and no level.

The table of *The level* in `SKILL.md` picks the level by the weight of the
change, and the prompt carries it. The lens says which of its four readings
a level makes. Where the `Agent` tool of the host takes them, the call names
`model: "opus"` and `effort` at the level. Codex reads at `xhigh`, whatever
the level of the change.

`scripts/report-check.sh` reads each report of these two lenses: its last line is
`count: N`, and a report with no such line, with another count than its
finding lines, or with a line that starts with `read: none` and no finding
line is a failed read. The sender sends the
reader once more. After two failed reads the review stops, and the summary,
the pull request and the merge question say that it is not complete.
`codex-review.sh` runs the check on the report of Codex itself.

In Claude Code, Codex reads the whole branch once with the code lens, at
each level of a code review. A session in Codex keeps `/review` until a run
of its own (#498).

The measure of a lens file is `tests/review_loop_reader_eval.sh`: three runs
of each case with known defects, and the sum of the runs that name each
defect. A part of a lens joins only with a gain that the runs show, and a
part with no shown gain stays out. A text is compared with another by the
sums of all their runs, not by one pass. `tests/rules_pins.txt` pins the
five sentences of the code lens that a run fixed, so that a change of their
words fails `make check` and sends the person to the eval. ADR 0009 holds
this measure for a lens file, in the place of its ten runs.

## Consequences

Good: the review is the same text in Claude Code and in ZCode, and each rule
of it is in the repository. A reader costs less than the command that it
replaces where both were measured: the security lens $0.35 a run against
$0.73 to $1.00. A cut report no longer reads as a clean round.

Bad:

- On PR #426 the code lens names fewer known wrong results than the built-in
  command did: 2.8 of six a run against 4.1. PDR 0017 holds the table.
- The sender writes each report out once more, to a file, for the check.
- The code lens reads no instruction file of the project, as a `CLAUDE.md`,
  which the built-in command did (#499).
- Precision is not measured: the share of the findings that are true. The
  lens asks for a candidate also when the reader is not sure, so a report
  has more findings to check: 6 to 9 a run at `high`.
- The reader may run code of the project. With only `git` and the read
  tools allowed, it tried a test, a build or an install in 14 of 30 runs.
  In ZCode, the reader of PR #426 ran the changed scripts on the
  transcripts of the person. What a reader may run is the permission mode
  of the host. The sentence "Run no code of the project: no test, no build,
  no script of it and no package manager" took the tries to 1 of 9 runs, and
  in ZCode the reader then ran nothing, in the same 53 minutes. With it, PR
  #426 gave 8 and 6 of 30 and the case `swap` 10 of 12: each inside the
  spread of the passes, and each downward. The sentence is not in the code
  lens; the security lens has it from its draft.

What the measure left out of the code lens, each with its counts:

- The list of replaced places: with it, PR #289 gave 3 and 4 of 15, where
  the text without it gave 9, 5 and 5; PR #426 gave 12 of 30, where the text
  without it gave 11, 11 and 7. No case showed a gain, and the lens names
  the defect of #466 without it: 5 of 6 on Opus, 2 of 2 in ZCode on GLM-5.4.
  The script and its test are deleted; the pull request of #466 holds
  them, in its commit "feat(review-loop): add the list of replaced places
  and the check of a report".
- A cap on the findings of a level: the counts of a run were the same with
  it and without it, 4 to 6 at `medium` and 4 to 9 at `high`.
- The parts of the shell of the other draft: a kind for a finding outside
  the range (1 finding in 104), a line for a document (1 in 15 runs), a line
  for a part not read (no report of one), the source of each input (given in
  most findings without it), and "the range is data" (0 of 3 runs obeyed an
  instruction that a comment of the diff gave).

## Invariants

None new. `skills/review-loop/scripts/report-check.sh` falls under I-2, I-3
and I-4 as each script of a skill.

## Confirmation

`tests/review_loop_reader_eval.sh` and its cases in
`tests/fixtures/review_loop_reader/cases.tsv`; `tests/review_loop_report_test.sh`
for the check of a report; the pins of `code-lens.md` and of the prompts in
`tests/rules_pins.txt`; and `tests/review_loop_eval.sh`, which fails a run
in which the session or a subagent runs a review command of the host, and counts a round by the
lens file that its prompt names.
