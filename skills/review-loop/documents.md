# A change to documents, or to the text of a skill or a prompt

*The level*, *The rounds* and *The findings* are sections of `SKILL.md`, next
to this file.

A change to documents only takes no code review: one review subagent reads
the text the range changes, with this prompt alone, and no limit on its
report:

```
Read <dir>/docs-lens.md and do what it says.
Range: <the range of the round>
Tree: <the working tree of the branch>
```

In Codex: `/review` with the same three lines as its custom instructions.
The change gets one round, as *A change to documents only* says. The text of
a skill or a prompt, as a `SKILL.md` or `rules.md`, counts as a document,
though it is the product.
Why: on a skill's own branch, eight runs of `/code-review high` found 9 or 10
findings each. From the second run on, most were in the sentences the run
before had written. The rounds stopped only when the person stopped them.

When that text comes with code, each range of the rounds and the last pass
goes to one review or to both, by what it changes. The code review, the
reader with `code-lens.md` at the level of the code alone or `/review` in
Codex, reads each range that changes anything but that text. The agent does not act on
its findings in that text, and does not count them. The subagent reads each
range that changes that text, or code that the text names, as a script or a
flag. It reviews the text the range changes and the text that names the code
it changes, as for a change to documents only. A round confirms no defect
when neither review does. Other documents next to code stay with the code
review, with no subagent.

## A change to documents only

A change to documents only, as *The level* says, gets one round:

1. **One round.** The review subagent reads the whole branch, as step 1 of
   *The rounds* says. When the range touches the architecture file or an
   ADR, the review of the architecture runs beside it. The fixes of their
   confirmed findings and their nits are one commit. No round reads that
   commit, except as `architecture-and-tests.md` says, and no last pass
   follows.
2. **One read by Codex**, when the branch changes the text of a skill or a
   prompt, or a spec: the design document that `superpowers:brainstorming`
   writes, as `docs/superpowers/specs/*.md`. In Claude Code, run it once,
   when the rounds end, so Codex reads their fixes in place: after round 1
   and its fix commit, when there is one. When the person asked for more
   rounds before then, run it after the last of them. A Codex read that has
   run does not run again:

   ```bash
   bash <dir>/scripts/codex-review.sh --docs <base>
   ```

   `<base>`, where it runs and its exits are as in `codex.md`. Change no
   file while it runs. Its findings go through *The findings*. Its fixes are
   one commit, and no round reads it.
   Other documents, as a README or a note in `docs/`, get no Codex read. In
   Codex, there is no Codex read.
3. **No security review.** The security lens reads no document.
4. **A person's review comments** go through *The findings*. Their fixes are
   one commit, and no round reads it.

When the person asks for more, as more rounds, a last pass or a security
review, that step and the rounds on its fixes run as the sections of
`SKILL.md` say.
