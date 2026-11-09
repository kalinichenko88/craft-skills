---
name: sessions
description: Use when counting what the text of the craft skills costs in the local Claude Code sessions, and which of their scripts failed.
disable-model-invocation: true
argument-hint: "[days]"
---

# Sessions

This skill counts the local Claude Code transcripts of all projects on this
computer. For each skill of craft, it gives what its text costs and which of
its scripts failed. The counts have one correct result, so a script makes
them, and no model reads a transcript.

1. **Count.** `$ARGUMENTS` is the number of days, 14 when it is empty. Run
   `bash <dir>/scripts/count.sh $ARGUMENTS`, where `<dir>` is this skill's
   base directory. The script reads `~/.claude/projects/`. It takes a
   transcript that changed in those days and that a person's session wrote:
   a `claude -p` run is left out. A subagent's transcript is a context of
   its own.
2. **Show the table**, with these meanings:

   | Column | What it counts |
   | --- | --- |
   | `contexts` | the transcripts that loaded the skill's `SKILL.md` |
   | `loads` | all its loads. Claude Code adds a second copy only when the text differs, as with other arguments |
   | `twice` | the contexts that loaded it more than once |
   | `chars` | the characters of `SKILL.md` text that its loads put in the context |
   | `compacted` | the contexts with a compaction after a load. Then Claude Code keeps the first 5,000 tokens of each skill, 25,000 in all |
   | `read` | the characters of the skill's `.md` files that `Read` or a Bash call returned. A Bash call that names such a file counts all its output |
   | `failed` | the calls of its scripts that ended with an error |

   The line under the table gives, for each context that loaded a
   `SKILL.md`, the sum of their characters: the median, the 90th percentile
   and the maximum. Then each script with failed calls.
3. **Read it.** About 3 characters are one token. `tests/rules_test.sh` caps
   each `SKILL.md` at 15,000 characters (ADR 0006). A failed call is a
   candidate, not a defect: `invariants.sh` exits 1 at a failing invariant
   and `take-in-check.sh` at a refusal. Each one is a defect only by *Make
   sure the plugin is wrong* in `skills/github/filing.md`.
4. **The output stays on this computer.** The transcripts are of private
   projects too. A finding goes to the public tracker only as its shape and
   its counts (*Public repositories* in `skills/github/SKILL.md`), and only
   after the person says yes.

Claude Code deletes a transcript after `cleanupPeriodDays`, 30 days by
default, so a count of more days can find fewer transcripts than it asks
for. Codex keeps its sessions as compressed files: the script does not read
them.
