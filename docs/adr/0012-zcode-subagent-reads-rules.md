# 0012 In ZCode, a hook puts a line into the prompt of each subagent that sends it to rules.md

- Status: accepted
- Date: 2026-11-23

## Context

`hooks/hooks.json` gives both parts of `rules.md` to each subagent on
`SubagentStart` (ADR 0004). ZCode 4.0.0 has no such event. The plugin load
gives the warning `plugin_hook_unsupported_event`, and a subagent starts
with no rules: 2 of 2 probes on ZCode 3.19.0, row 6 of
`docs/research/2026-11-16-zcode-third-host.md`. A subagent that writes then
never reads "A subagent invokes them itself" of the conventions skills, the
gate, the test of a bug fix, or the rule on `Co-Authored-By:`. The person's
flow in ZCode sends such subagents: the implementers of
`superpowers:subagent-driven-development`. ZCode plans `SubagentStart` at
priority P1, with no date.

No hook runs in a ZCode subagent: the runtime of a child gets no hook
configuration (`apps/zcode-cli/packages/core/src/runtime/methods/subagent.ts`
at `fec9759`). A `PreToolUse` hook runs in the main session on each call of
the `Agent` tool, and `hookSpecificOutput.updatedInput` replaces the whole
input of the call. ZCode checks that input against the schema of the tool,
and a wrong one fails the call (`core/src/tool/executor/call-runner.ts:381-399`).
The stdin of a hook is one line of JSON that ends with the tool input
between the keys `"tool_input":` and `,"tool_use_id":`
(`core/src/hooks/configured-runner-input.ts:34-36`). Only ZCode sets
`ZCODE_PLUGIN_ROOT` for a hook.

## Options considered

- A `PreToolUse` hook that puts a line first in the prompt through
  `updatedInput`: no extra call. Three cuts in bash take the input from the
  stdin, but an input of the wrong shape that is valid JSON fails each call
  of a subagent.
- A `PreToolUse` hook that denies a call with no `rules.md` in its input and
  gives the line in its reason: one denied call a session, and the model
  must do what the reason says. The main session then also puts the line
  into the prompt of an `Explore` subagent, and a resumed session can keep
  the path of an older version.
- A sentence for ZCode only that `hooks/rules.sh` adds on `SessionStart`:
  two lines and no new file, but nothing makes the model obey it, and ADR
  0009 gives a rule that a machine can do to a script or a hook.
- A sentence in `rules.md`: the main session of each host reads it, and ADR
  0009 needs a failing run before it.
- A line in `~/.zcode/AGENTS.md`, which a `general-purpose` subagent of ZCode
  reads: the person writes it by hand, and the path of the plugin changes
  with each version.
- Wait for `SubagentStart` in ZCode: it has no date.

## Decision

We will run `hooks/subagent-rules.sh` on `PreToolUse` with the matcher
`Agent|Task`. When `ZCODE_PLUGIN_ROOT` is set and the subagent type is not
`Explore`, the hook gives an `updatedInput`: the tool input as it came, with
"Read `<ZCODE_PLUGIN_ROOT>`/rules.md before you start: it holds the rules of
this session." and an empty line before the prompt. Parameter expansions cut
the input from the stdin. When the cut is not an object with a prompt, the
hook prints nothing. In Claude Code and Codex it prints nothing.

The sign of the host is the environment, not the stdin: the stdin of ZCode
holds the field names of Claude Code too.

Delete the hook and its entry when the lowest version of ZCode that craft
supports has `SubagentStart`, and a run shows that `hooks/rules.sh` gives
the rules there. ZCode gives a child the agent name `zcode-<type>`
(`core/src/runtime/methods/subagent.ts:339`), so the check of `Explore` in
`hooks/rules.sh` needs that run too.

## Consequences

Good: each subagent of ZCode but `Explore` reads `rules.md`, with no step in
a skill and no sentence in `rules.md`. The main session does nothing, and
the path is the current one on each call. When the hook fails, or the part
that it takes from the stdin is not an object with a prompt, the call runs
as it is: the behaviour before.

Bad: the hook depends on the order of the keys in the stdin of ZCode, which
no contract of ZCode fixes. A version that makes the cut a valid object of
another shape fails each call of a subagent. The subagent reads the rules as
a file, not as context, so it can skip the read. Each subagent pays for the
read of about 6,000 characters. Codex lists one more hook for its users to
trust.

## Invariants

I-1 amended: its statement names each script in `hooks/`, as its check
already reads the whole folder.

## Confirmation

`tests/hooks_scripts_test.sh` runs the hook on the input that ZCode 4.0.0
gave for a call of its `Agent` tool, with its paths replaced. It checks that
only the prompt changes, and that an `Explore` call, an input of another
shape and a host with no `ZCODE_PLUGIN_ROOT` give no output. Row 6 of the
research holds two runs in ZCode 4.0.0: in each, the subagent read
`rules.md` first.
