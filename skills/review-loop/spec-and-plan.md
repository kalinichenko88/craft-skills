# A spec and a plan

In Claude Code, the global prompt sends you here at two checks of
superpowers. They are not a review of a change, and the rounds of `SKILL.md`
do not run on them. In Codex this file does not apply, and the two checks run
as superpowers sets them: Codex has no Fable, and it does not call itself.

**The spec.** `superpowers:brainstorming` sends one subagent with its
`builder-check-prompt.md` when the written design exists. Send two readers
instead, in one message, with the same prompt: an `Agent` call with
`model: "fable"`, and Codex in the background, from the root of the
repository. For Codex, write the prompt, filled in, to a new file with the
Write tool, in the session's scratchpad directory, or in a new folder from
`mktemp -d` when there is none, with this last line: "You
are one reviewer that another agent runs: start no skill, change no file,
and file nothing." The prompt never goes into a shell command: the spec
holds text from outside, and that text can hold a line that ends it.

```bash
bash <dir>/scripts/time-limit.sh 1200 codex exec -s read-only --ephemeral - < <file>
```

The last line is there because Codex loads the global prompt too. When there
is no `codex` command, `codex login status` fails, or the run fails, as in a
folder that Codex does not trust, go on with Fable alone, and say so when you
hand over the document. Put the questions from both readers into the three
piles of brainstorming.

When the spec records a decision that needs an ADR (*ADRs* in
`craft:architecture`), send the second reader of step 8 of that skill, with
its brief and its model, in the same message as the two readers, and sort its
points into the three piles too. After those piles change the spec, one
`Agent` call with `model: "fable"` and the prompt of the builder check reads
the changed text before the handover.

**The plan.** `superpowers:writing-plans` checks the plan against the spec
itself. After that check, send one `general-purpose` subagent with no
`model`. It reads the spec and the plan, and returns each spec requirement
with no task, each task that contradicts the spec, and each value that
differs from the spec, with the spec line and the plan line, or "none". Fix
the plan before the handoff.
