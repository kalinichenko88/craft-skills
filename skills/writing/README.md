# craft:writing

A text for readers says only what its input holds: no cause, number or
feeling that the author never gave.

## When it starts

- The agent writes a pull request description, a README, a doc file or a
  release note from notes, facts or a source.
- The agent writes a blog or social post from your notes.

## What you get

- **No claim that you never made.** Each event, number, name, cause or
  opinion in the text comes from a line of the input: your notes, the diff,
  the issue, a file that the agent read, the output of a command that it
  ran. A claim that no line holds goes out of the text. When the text
  needs a fact that the input lacks, the agent asks you for it.
- **The list behind the text.** After the text, outside it, each claim with
  the line of the input that it comes from, so you see what each sentence
  stands on.
- **Your register, where you set one.** The skill holds no voice. Name a
  voice file in the project's `CLAUDE.md` or `AGENTS.md`, as
  `Voice: docs/VOICE.md`: who speaks, to whom, the length and the format.
  The agent follows it over the plain technical English of the base prompt,
  with no rule in the skill: in 20 of 20 runs on 2026-11-26 (#230). With no
  voice file, the text is plain technical English.

## What it does not do

- **It does not hide that a model wrote the text.** In a test on
  2026-11-26, Pangram scored each text whose English sentences a model wrote
  as 100 % AI, a close translation of the author's own dictation too, and
  after a rewrite by a second model. No skill changes that; only the
  author's own sentences do.
- **No list of banned words or patterns.** Opus 5.5 wrote a pull request
  description with no invented fact and no sign from the structure list of
  Wikipedia's *Signs of AI writing* in each of four ways, so this skill adds
  no rule for them (ADR 0009, #230).
