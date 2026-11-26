# craft:writing

A text for readers says only what its input holds: no cause, number or
feeling that the author never gave.

## When it starts

- The agent writes a pull request description, a README, a doc file or a
  release note from notes, facts or a source.
- The agent writes a blog or social post from your notes or from a source,
  as a pull request.

## What you get

- **No claim that you never made.** Each event, number, name, property of a
  thing, cause, opinion or feeling in the text comes from a line of the
  input: your notes, the diff, the issue, a file that the agent read, the
  output of a command that it ran, at the time that the line gives: a step
  still to come is not told as done. A claim that no line holds goes out of
  the text. On 2026-11-26, a blog post from a public pull request held such
  a claim in 10 of 10 runs with no skill, 78 claims in all, and in 5 of 10
  with it, 8 in all. Five of the 8 are one line on the rate limit, which the
  pull request gives in other words (#230).
- **The list behind the text.** After the text, outside it, each claim with
  the line of the input that it comes from, so you see what each sentence
  stands on.
- **Your register, where you set one.** The skill holds no voice. Name a
  voice file in the project's `CLAUDE.md`, as `Voice: docs/VOICE.md`: who
  speaks, to whom, the length and the format. In Claude Code, a voice of
  sentences of 25 to 40 words won over the short sentences of the base
  prompt in 20 of 20 runs on 2026-11-26, with no rule in the skill (#230).
  `AGENTS.md` and the other parts of a voice were not measured.

## What it does not do

- **It does not hide that a model wrote the text.** In a test on
  2026-11-26, Pangram scored the first 400 words of each text whose English
  sentences a model wrote as 100 % AI, a close translation of the author's own dictation too, and
  after a rewrite by Codex or by GLM. No skill changed that (#230).
- **No list of banned words or patterns.** Opus 5.5 wrote a pull request
  description with no invented fact and no sign from the structure list of
  Wikipedia's *Signs of AI writing* in each of four ways, so this skill adds
  no rule for them (ADR 0009, #230).
