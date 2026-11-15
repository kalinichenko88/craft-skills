# Global instructions, part 1 of 2

## The repository's own gate

Before you call a task done, run the repository's own check, as `make check`
or what CI calls, or with none the closest equivalent, and report its actual
outcome.

## A bug fix ships with its test

A bug fix carries the test that would have caught it: written first, seen
failing on the unfixed code, passing after, and asserting the reported
behaviour. Guard each surface the bug shows on.

**The input comes from the source, not from your head.** Before you believe
the report, count how many of a sample of real payloads carry its shape: zero
means that the fix does not need to exist. Else write the case against a
recorded payload, whitespace and all. For a report of data loss or a security
hole, a zero count does not stop the fix. An attacker can make the input, so
the test of that fix uses the input of the report. With no real source to
sample, the count stops nothing, and the test uses the input of the report.
In Claude Code, an `Explore` subagent with `model: "haiku"` counts; check one
or two of its payloads yourself.

## The platform first

Before you write a helper or add a dependency, check in current docs, not
from memory, what the standard library of the pinned version does. A
dependency earns its place only where the platform has no answer: name the
API you checked.

## Code speaks English

Inside the code everything is English, in every project: identifiers, files,
branches, comments and commit messages. Another language appears only in the
data, as user-facing copy and fixtures. The rest of the prose follows what
the repository already does.

## Plain technical prose

Write all prose, in every language, in ASD-STE100 Simplified Technical
English: short sentences, each word only in its direct meaning, no text with
two meanings, no complex grammar.

## An issue by its title

Each time you name an issue, a pull request or a milestone to the person, in
a list too, give its title next to its number at its first mention in the
message: `#44 Store the rate of a partner`, `M1 · First demo`. When you ask
the person to decide on an issue, or you move, take, close or propose it, add
a few words in the person's language on what it changes. Commands and the
text for GitHub keep the form of `craft:github`.

## Docs move with the change

A change that alters user-visible behaviour, a public contract or the install
updates each document that it makes false, in the same change. In Claude
Code, the same kind of subagent finds those documents: give it the change and
its files; it returns each false passage as `file:line`. Before finishing,
name the docs touched, or say "docs impact: none" with a one-line why.

A decision that the person makes in talk can make an open issue false. Correct
each such issue in the same turn, as the github skill's `filing.md` says. Do not
ask first.

<!-- rules.sh splits the rules here: each part stays under 10,000 characters -->

# Global instructions, part 2 of 2

## Code review

Before the first review of a change — `/code-review` or `/security-review` in
Claude Code, `/review` in Codex, a review subagent — and when a person's
review comments arrive, invoke the `craft:review-loop` skill. A read-only
review subagent does not load it. Whoever acts on a finding, with the skill
or without it, first verifies it against the real code.

`craft:review-loop` replaces `superpowers:requesting-code-review` and
`superpowers:receiving-code-review`. In
`superpowers:subagent-driven-development`, the review after each task stays as
that skill sets it, without `craft:review-loop`. Invoke review-loop
after the last task, in place of the final review. In Claude Code, invoke it
also in place of the builder check of `superpowers:brainstorming`, and after
the self-review of `superpowers:writing-plans`.

## Worth before work

Before the first edit of a feature — a new capability, or a change of what the
product does for its users — with no report of it yet, and at each fork in
brainstorming, invoke the `craft:product` skill. Not in a subagent.

## The Boy Scout Rule

Leave the code you touch cleaner than you found it, not rebuilt. A finding in
the task's module that is clear (one way to fix it), smaller than the task
and separable from it goes into this change, listed in the PR description as
not part of the task; one that needs only a choice goes to the person first.
`filing.md` of `craft:github` has the conditions.

## Code conventions

Before the first write or edit to a TypeScript file (`.ts`, `.tsx`, `.mts`,
`.cts`) in a session, invoke the `craft:typescript-conventions` skill.
Before the first write or edit to a React component or hook, invoke
`craft:react-conventions` too. A subagent invokes them itself. No pattern to
copy and no rule to keep the work short skips these calls.

## GitHub

Anything that touches GitHub, as a commit, a pull request, an issue or a
workflow file, goes through the `craft:github` skill, invoked before the
first `git commit`, `gh` call or workflow edit. A
read-only subagent, as a review or an `Explore` subagent, files nothing,
whatever the rules below say. It does not load the skill, and names each
finding in its report. One sent with the skill's `scout.md`, or with the
roadmap skill's `lanes.md`, follows that file instead.

**Out-of-scope findings become issues.** A finding worth fixing outside the
task that the Boy Scout Rule does not take is an issue: do not fix it inline
or ask whether to file it. Where there is no GitHub remote or
`gh auth status` fails, name the finding in the final report instead of
filing it.

**A defect in this plugin goes to its tracker, after the person says yes.**
The plugin is both parts of these rules, the hooks and each `craft:` skill
with its scripts; its tracker is `kalinichenko88/craft-skills`. Unlike the
rule above, ask the person first: show the text that the github skill's
`filing.md` writes.

**Never add a `Co-Authored-By:` trailer** to a commit message.
