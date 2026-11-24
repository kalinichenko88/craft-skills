# 0010 The recorded size of a text is its exact size, and a flow is a list of files

- Status: accepted
- Date: 2026-11-15

## Updates

- 2026-11-16 #415: Options considered, a flow as a list of files. Was: "the check asks only that each file of the list has a line".
- 2026-11-16 #415: Decision. Was: "We will record a flow as a line that names its files, with no number." and "The target of a flow still goes into the record when its map gives one, as ADR 0009 says; #415 gives its line a form."
- 2026-11-24 #485: Decision. Was: "This narrows one point of ADR 0009: there, a text below its recorded size passed.", "This narrows a second point of ADR 0009, which recorded a size for a flow." and "The rest of ADR 0009 holds: the admission rule, the budgets, and a recorded size for `rules.md`, each `SKILL.md` and each side file."

## Context

ADR 0009 decided that each text of the plugin has a recorded size, and that
"a text that grows past its recorded size fails `make check` until the same
pull request changes the record". It also gave a flow a recorded size of its
own. #412 built the check, `tests/text_size_test.sh`, with the record in
`tests/text_size.txt`.

Two reviews of that check named a gap. A pull request that cuts a text can
leave its line as it is. A later pull request can then grow the text back to
the old number, and no line of its diff shows the growth. The debt list of
`tests/rules_test.sh` showed the same drift: it held 33,516 for a file of
33,493 characters.

With an exact size on the line of each file, the size of a flow is the sum
of the lines of its files. A number of its own can fail only on its
arithmetic, each edit of a file of the flow changes two numbers, and two
branches that edit two files of one flow conflict on the line of the flow.

## Options considered

- A ceiling, as ADR 0009 wrote it: a cut needs no edit of the record, and
  the record goes stale after each cut.
- The exact size: each change of the size of a text, a cut too, changes its
  line. The failure prints the new number.
- A ceiling, and a note when a text is below it: the note fails nothing, and
  each run of `make check` prints it until someone lowers the number.
- A flow with a number of its own: the three costs above.
- A flow as a list of files: the check asks that each file of the list has a
  line, and that the line has its target. A file that joins the flow is a
  change of its line.
- The files of a flow from the rows of `tests/scenarios_text_eval.sh`: a row
  names the files of one skill that the text eval reads against a scenario.
  A take-in also puts `rules.md` and the review-loop `SKILL.md` into the
  session (#275), and a subagent reads `scout.md`, not the session.

## Decision

We will fail `make check` on a text whose size is not its recorded size,
above it or below it. The person chose it on 2026-11-15.

We will record a flow as a line that names its files, with no size of its
own: its one number is its target. Its size is the sum of the lines of its
files. Since #415, a flow gets its line with its map, so each line holds its
target, in the form `flow <name> <target> <path>...`.

ADR 0009 holds the admission rule, the budgets, and the texts and flows
that the record holds.

## Consequences

Good: the record holds the size of each text, so an issue or a review can
quote it. Each growth of a text or of a flow is a changed line in a diff,
also after a cut.

Bad: each pull request that changes the size of a text edits the record
too, and two branches conflict when they edit one text, or two texts on
neighbouring lines of the record, as the files of one skill. The check does
not add up a flow: a reader does. A line of a flow with no file passes.

## Invariants

None: no `Check:` line sees a `.md` file.

## Confirmation

`tests/text_size_test.sh`, on small trees and on the repository.
