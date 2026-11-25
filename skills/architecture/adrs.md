# ADRs

A decision needs an ADR when:

1. it changes the structure, the direction of a dependency, a public
   interface, or a quality goal;
2. it is costly to undo, or it adds an external dependency;
3. it sets a pattern that later code must follow: without the ADR, a reviewer
   would see two competing ways;
4. it reverses or narrows an accepted ADR, or amends an invariant. A
   reversal or a narrowing rewrites that ADR in its own file (*A changed
   ADR*): no ADR supersedes another.

No ADR when none of the four holds: the choice is local and cheap to undo, or
a lint rule or a documented convention already enforces it. The four win: a
new external dependency needs an ADR, however small. An option that the
person rejects for a lasting reason gets an ADR with the status `rejected`,
so that the next agent does not offer it again.

**A changed ADR.** An accepted ADR says what holds now. When a sentence of
it is false now, correct it in place. It is a fact when code that kept the
decision before the correction keeps it after, and code that broke it still
breaks it; else it is the decision. A fact: in the change that makes it
false; else in a later change, as its task or as a finding outside its
task. When that fact was a reason for the decision, also file an issue that
asks whether the decision is still right. A decision: by the steps of *The
moment of a decision* in `SKILL.md`, in the pull request of the work that
carries it out.
Rewrite the title and each section that the decision changes, and put the
old choice into *Options considered* with the reason that it was dropped.
Each correction, of a fact or of the decision, adds a line under
`## Updates`, a heading right after the Status and Date lines:
`- YYYY-MM-DD <source>: <section>. Was: "<the old words>".`
For a changed decision, the section is *Decision*, and the old words are the
sentence that held the old choice. The source is the issue, the pull request or the run that
shows the new fact or decision. The Status line stays, but a Status
`accepted, narrowed by NNNN` becomes `accepted` when the rewrite takes the
narrowed point into the ADR, with a line for the section *Status*. A later
correction adds a line; no line is rewritten.

One decision per file, `NNNN-name.md`, numbered after the highest one in the
folder; the name gives the question, not the answer, as `0007-ui-library.md`.
A file is never renamed or deleted, so a link to it does not rot. The
template:

```markdown
# NNNN Title

- Status: accepted | rejected
- Date: YYYY-MM-DD

## Context

## Options considered

- <option>: <one line>
- <option>: <one line>

## Decision

We will …

## Consequences

Good: …
Bad: …

## Invariants

I-n, added or amended, or none.

## Confirmation

The check that enforces it: a `Check:` line, a lint rule, a test, or "review
only".
```

At least two options, one line each, and both good and bad consequences: one
decision a file, no policy in disguise, no option with no cost. Add an
accepted ADR to the index of the architecture file, and change its line with
a new title, in the same commit.
