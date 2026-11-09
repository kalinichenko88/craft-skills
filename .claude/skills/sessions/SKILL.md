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

1. **Count.** The argument is a number of days, 14 when there is none. Run
   `bash <dir>/scripts/count.sh <days>` with a timeout of 10 minutes, where
   `<dir>` is this skill's base directory: 14 days take about 40 seconds.
   The script reads `~/.claude/projects/`. It takes a transcript that
   changed in those days and that a person's session wrote: a `claude -p`
   run is left out. A subagent's transcript is a context of its own.
2. **Show the table**, with these meanings:

   | Column | What it counts |
   | --- | --- |
   | `contexts` | the transcripts that loaded the skill, by the `Skill` tool or by a command that the person typed |
   | `loads` | all its loads. Claude Code adds a second copy only when the text differs, as with other arguments |
   | `twice` | the contexts that loaded it more than once |
   | `chars` | the characters that its loads put in the context: the line with the base directory, the text of `SKILL.md` with no front matter, and the `ARGUMENTS:` line when the load has arguments. Not the copies that a compaction attaches again |
   | `compacted` | the contexts with a compaction after a load. Then Claude Code attaches the last load of each skill again, the newest first: the first 20,000 characters of each, and about 100,000 in all, shared by every skill that the context loaded, from a plugin or not. An older skill that does not fit drops out whole |
   | `read` | the characters of the skill's `.md` files that `Read` returned, and the output of each Bash call in which a `cat`, `sed`, `head`, `tail`, `grep` or `awk` command names one of them. A call has one output, so all of it but the line with the exit code counts, for the skill of the first of these files that such a command names, also when the call runs a script too |
   | `failed` | the Bash calls that ran one of its scripts, with `bash` or by its path, and ended with an exit code other than 0. A call has one exit code, so it counts only for the script that its last command runs, as in `bash x.sh` or `for n in 1 2; do bash x.sh $n; done`, not in `bash x.sh \| tail -5`. An assignment, a `cd`, a comment, and `done` or `fi` with their redirections are no last command here. A call or a `Read` that ended with an error and no exit code, as one that the harness, a hook or the person stopped, counts neither here nor in `read` |

   The line under the table gives, for each context that loaded a
   `SKILL.md`, the sum of their characters: the median, the 90th percentile
   and the maximum. Then each script with failed calls.
3. **Read it.** About 3 characters are one token of the model.
   `tests/rules_test.sh` caps each `skills/*/SKILL.md` at 20,000 characters
   (ADR 0006), with a debt list of the files over it. A failed call is a
   candidate, not a defect: `invariants.sh` exits 1 at a failing invariant
   and `take-in-check.sh` at a refusal. Each one is a defect only by *Make
   sure the plugin is wrong* in `skills/github/filing.md`.
4. **The output stays on this computer.** The transcripts are of private
   projects too. A finding goes to the public tracker only as its shape and
   its counts (*Public repositories* in `skills/github/SKILL.md`). Ask the
   person before you file it, unlike a defect that you find in the code of
   this checkout: the counts come from the private transcripts of other
   projects.

Claude Code deletes a transcript after `cleanupPeriodDays`, 30 days by
default, so a count of more days can find fewer transcripts than it asks
for. Codex keeps its sessions as compressed files: the script does not read
them.
