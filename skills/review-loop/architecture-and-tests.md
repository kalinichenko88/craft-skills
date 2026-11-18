# The reviews of the architecture and of the tests

*The level* and *The findings* are sections of `SKILL.md`, next to this file,
and a step with a number is a step of *The rounds* there.

## A review of the architecture

*A review of the architecture* in `SKILL.md` says when this step runs. When
the text of a skill or a prompt comes with code, use the level of the code
alone.
Skip it for a move that a script or a test proves unchanged, unless the range
touches the architecture file or an ADR. Start it in the background when
round 1 starts, and change no file while it runs. Its findings go through
*The findings* as findings of round 1: round 1 confirms no defect when
neither review does, and their fixes are one commit. A fix of its finding
that changes code is the fix of a defect: a round reads it, as step 2 says.
A Convention finding is the exception: step 3 decides whether it is a
defect or a nit.
On a change to documents only, that round is `/code-review` at the level of
that code.

The subagent is an `Agent` call of its own, not a job in the prompt of round
1, with `model: "opus"`, and `effort` at the level of round 1, or `high` when
that level is lower or there is none. `<base>` is the base of step 1, and
`<head>` is the SHA of `HEAD` that round 1 reads. It gets this prompt, with
no other job:

```
Read <dir>/architecture-lens.md and do what it says.
Range: <base>..<head>
Tree: <the working tree of the branch>
```

In Codex: `/review` with the same three lines as its custom instructions.

Why: `/code-review` reads the diff and the `CLAUDE.md` files, and none of its
angles reads the architecture file, the ADRs or the conventions skills. Why
`opus`: the step runs at each `high` review there, and `fable` costs 2.5
times as much. Why the conventions here: in real sessions, 0 of 136 review
subagents of a TypeScript change started a conventions skill, 44 of them
`/code-review`. In the runs of #227, no sentence in the global prompt moved a
review subagent past 1 of 5.

## A review of the tests

This step depends on the level of the change in the table of *The level*.
When the text of a skill or a prompt comes with code, use the level of the
code alone. At `high` or `xhigh`, and for a change to tests only, one review
subagent, or `/review` in Codex, reads the tests of the whole branch once. A
change to documents only gets no review of the tests. Start it when the last
pass starts. When the loop had one round, start it when that round confirms
no defect and its nits are committed. When step 4 skips the last pass, skip
this step too. Change no file while it runs.
`<base>` is the base of step 1, and `<head>` is the SHA of `HEAD`. Its
findings go through *The findings*. The subagent gets this prompt:

```
Read <dir>/tests-lens.md and do what it says.
Range: <base>..<head>
Tree: <the working tree of the branch>
```

In Codex: `/review` with the same three lines as its custom instructions.

Why: on nine merged pull requests of three projects, each with a finished
`/code-review` loop, this review found 11 defects in tests that the loop had
not reported, in seven of the nine. Of the 11, six were redundant or heavy
tests. Of the same 11, five came from a fix after round 1: that fix added a
test or changed the code, and an older test stayed, redundant or stale. So
the review reads the branch at the end of the loop, not beside round 1.
Another review, of the change against its issue, found nothing new on the
same nine, so the skill does not run it.
