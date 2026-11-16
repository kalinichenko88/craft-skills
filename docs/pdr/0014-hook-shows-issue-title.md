# 0014 The hook shows the number and the title of an issue that a prompt names alone

- Status: accepted
- Level: feature
- Date: 2026-11-16

## Decision

We will show the person the number and the whole title of an issue from a
hook, before the agent's first message. When the prompt is the issue alone,
as `#91` or its URL, `hooks/session-title.sh` names the session, as before,
and also returns a `systemMessage`: `#91 <the title>`. Claude Code shows it
as `UserPromptSubmit says: #91 <the title>`. The gist of
`skills/github/take-in.md` stays as it is, for Codex and for a prompt as
"take #91". `tests/scenarios_eval.sh` keeps the notice as a line of its
own: the gist items take the title from it, and still need a message of
the run with the words of the defect from the body of the task, before
the first change.

On a continue, the line that says that the work continues stays as it is.
The narration of it names the branch and says that the run works there, as
"I'm fixing it on branch `fix/91-typo`", so the person reads where the work
goes on. The item of the eval that looks for the word "continues" keeps its
FAIL.

## Rests on

- Claude Code can give a message before a tool call as a narration: a
  thinking block in other words, which the person reads (ADR 0008). In the
  transcripts of 14 days on one computer, to 2026-11-16, the first message
  of 166 of 211 interactive take-ins from a prompt `#N` was a narration. 61
  of the 166 kept the number; almost none kept the title. In the session of
  this decision, a gist with the number and the title reached the person as
  one sentence with the number and no title.
- The agent cannot choose the words of a narration: the API writes them. A
  rule in the text of the skill cannot make the title reach the person.
- A message that ends a turn is never a narration: 0 of 3,865 in the
  sessions of Opus of the last 10 days of those transcripts. But a gist that ends the turn makes each take-in wait for the
  person's answer before its work.
- The `systemMessage` of a `UserPromptSubmit` hook reaches the person
  (https://code.claude.com/docs/en/hooks). In a run of `claude -p` of Claude
  Code 2.1.325, it reached stream-json as a `system` event of the subtype
  `informational`.

## Revisit when

Claude Code stops giving a message before a tool call as a narration, so
that the person reads the title twice; or a take-in from a prompt that is
not the issue alone shows a narration with no title, twice.

## Options considered

- The notice of the hook: chosen.
- The title in a code span in the gist, which a narration can keep: no run
  shows that it does, and a measure costs about $13 in runs of Opus.
- The gist in a message that ends the turn: each take-in then waits for an
  answer.
- `CLAUDE_CODE_THINKING_DISPLAY_UPDATES=0` in the person's settings: a
  plugin cannot set it, and it changes how the person sees each session.
- Close: the person wrote the number, and the name of the session holds a
  short form of the title. But the gist items of the eval fail in 14 cases.
- For the continue line, an item of the eval that also takes a verb of the
  work: a check made to fit the words of a narration.

## Links

#317, #349, ADR 0008, `hooks/session-title.sh`, `tests/hooks_scripts_test.sh`,
`tests/scenarios_eval.sh`
