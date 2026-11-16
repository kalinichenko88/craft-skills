# Continuing the work

`take-in.md` sends you here when `take-in-check.sh` printed
`continue #91 on <branch>`. The session that worked on the issue can still be
open, and git does not show it. In Claude Code, look for it first:
`ListAgents` lists your other open sessions, not this one, and the plugin's
hook names a session `#91 <the start of its title>` when a message to it was
the issue alone. When such a session is listed and not `offline`, the work
runs there: give its name, and stop. A session under another name, as one
started with "take #91", is not found this way, and a Codex session is not
listed. So the line that says the work continues comes first: when the person
then says that a session is open, stop this one.

Read the branch next, from any checkout: `git fetch origin <branch>`, then
`git log <branch>..origin/<branch>` for commits pushed from somewhere else
since the check, and `git log origin/<branch>..<branch>` for commits that
GitHub does not have. Commits from somewhere else: the work runs there too, so
say so, and stop.

Then run `bash <dir>/scripts/worktree.sh 91 <branch> --local`. When the path
it prints is not where the session is, move into it: in Claude Code with
`EnterWorktree`, in Codex as the `workdir` of every command. There,
`git status --short` shows the changes. Name once the command that opens the
old session with its context, so that the person can go on there instead: in
the main checkout, `claude --resume`, which lists the sessions of the
repository's worktrees too, or `claude --from-pr <PR>` with an open pull
request; in Codex, `codex resume --all`. Two sessions can carry the name
`#91`: the old one is the older.

Changes, and commits that GitHub does not have, are work in progress: finish
it, and it goes through `craft:review-loop` before any merge question.
With an open pull request, read also what reached it after its `## Review`:
`gh pr view <PR> --comments`, and the comments on lines in
`gh api repos/{owner}/{repo}/pulls/<PR>/comments`. A person's review comments
go through `craft:review-loop`. Then go on from the first step that
`## Review` does not show as run, or, when all ran, from the open questions
and the merge question. Without a pull request, run *The tracker is read
next* and *Its duplicates close first* of `take-in.md`, then go on there from
"Then read what points at it", and skip the check of the issue's citations:
the first take-in did it, and the worktree holds the work. In *Taking neighbours
along*, an issue whose `status:` is `assigned to you, label in progress` was
taken along by the first session: give it its verdict, as to a free issue.
