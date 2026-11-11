# 0008 The flows are specified as host-neutral scenarios, and a run is checked by the words that the person reads

- Status: accepted
- Date: 2026-11-11

## Context

ADR 0003 put the scenarios of the flows in `scenarios/`, and
`tests/scenarios_eval.sh` checks craft against them from the log of a
`claude -p` run. Its probe gave no verdict on the two gist items of *A free
task*: the message before the first tool call was in the log only as a
thinking block in other words, without the task's id and title. ADR 0003
took this as a limit of the log: "the log cannot show what it told". The
closing comment of #206 said the same: the person saw the summary in full,
and the record reworded it.

On 2026-11-11, with Claude Code 2.1.322, the take-in of #242 showed the
opposite. The agent wrote the gist before its first tool call: the number,
the title and three sentences. The session's transcript holds one thinking
block in other words, with no number and no title. The person looked at the
screen at that place: it showed the short words of the transcript, not the
agent's text. So the log holds what the person read.

`--output-format stream-json` marks such a block. Its record has
`thinking_display: "updates"` and `narration_block_indexes`, the indexes of
the blocks in its content that the person reads. In the logs of the recorded
runs of dup, busy and inws, each of the 4 thinking blocks with words in the
main session has the mark. The transcript in `~/.claude/projects` keeps the
block and `thinkingDisplay`, but not the mark. The log of the free run of
2026-11-03 is gone, so that run was made again. Not every message before a
tool call becomes a narration: in 4 short `claude -p` runs that asked for an
id and a title before the first tool call, the text stayed a text block.

## Options considered

- Read a thinking block that `narration_block_indexes` names as a message,
  in the words that the log holds: the same log, one field more.
- Run the eval with `CLAUDE_CODE_THINKING_DISPLAY_UPDATES=0`, which the code
  of Claude Code 2.1.322 reads to turn that display off: the eval then
  checks a display that the person does not have by default. Not measured.
- A fake person who reads the terminal of an interactive session: the same
  words as the log, at the cost of a terminal driver, its dialogs and a
  screen that redraws.
- A hook: a hook gets the path of the transcript, and the transcript holds
  the block without the mark.
- Keep SKIP, as ADR 0003 did: the log holds the words that the person read,
  so SKIP hides a defect. 4 of 4 recorded runs with a narration first fail
  the gist.

## Decision

We will keep the scenarios as ADR 0003 decided: one Markdown file for each
flow, at `scenarios/<skill>/<flow>.md`, in the shape that
`scenarios/README.md` gives, with the words of `scenarios/TERMS.md`, and no
agent host, command or subagent in them. craft is one implementation of
them. Where the README of a skill or a picture differs from a scenario, the
scenario holds. The conventions skills get no scenarios.

`tests/scenarios_eval.sh` reads a message to the person from each text block
of the main session, and from each thinking block that
`narration_block_indexes` names, in the words of the log. Other thinking
with words stays a think line: an item that only such a line can decide
gives SKIP. A check finds a message about a task by its id, its title or the
words of its defect, as the body of the task gives them: a narration can
drop the id and the title.

## Consequences

Good: the gist items give a verdict. In the four recorded runs whose first
message about #91 is a narration (free, dup, busy, inws), 7 gist items fail:
the person reads the defect without the task's title, and in free and dup
without its id too (#317). The
check reads what the person reads, not what the agent meant to write.

Bad: the mark is a field of stream-json that the docs of Claude Code do not
name. A version without it makes a narration a think line again, and its
items give SKIP. The words of a defect are a check of one fixture task, not
a rule. The evals of the rules, architecture and github modules still read
a message only from a text block (#318). As in ADR 0003: a change of a
flow edits two texts, and the text eval in CI ties them in one direction only
(ADR 0007); `TERMS.md` repeats some
meanings of the skills; the shape fits a flow that a text of the person
starts; the word "scenario" also names the picture sections of the READMEs;
and the folder installs with the plugin.

## Invariants

None. `scenarios/` holds Markdown, which the checks read as data.

## Confirmation

`tests/scenarios_runner_test.sh` gives a stub's narration block to the eval
and checks that it becomes a text line, and its other thinking a think line.
`tests/scenarios_checks_test.sh` checks the verdicts of the recorded runs,
that a think line before the first message about #91 gives SKIP, and that
each scenario that the eval names is a heading of
`scenarios/github/take-in.md`. The `scenarios` target of the `Makefile`
checks the shape and the host words of each scenario file.
