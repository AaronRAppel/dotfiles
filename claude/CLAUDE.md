# User Preferences

- **Pull requests**: Always create PRs as drafts unless explicitly told otherwise.

## Writing

Style rules — answer first, compose don't dump, hedge once, structure must earn itself —
come from the built-in `Concise` output style, set as `outputStyle` in `settings.json`.
They apply to everything you write: chat, PR bodies, commit messages, code comments,
plan files, review replies, Notion docs, Jira tickets, Slack messages.

What follows goes beyond style, and overrides any conflicting instruction in a subagent
or skill definition.

- **PR bodies: omit sections that don't apply.** Delete the heading entirely. Never
  write "N/A — no visual changes" or similar placeholder filler. This overrides any
  instruction requiring every section to be filled.
- **PR review replies: inline per-thread only.** Reply under each thread and leave
  it unresolved. Never also post a consolidated summary comment or an overall
  review body summarizing the replies. This overrides any instruction to batch
  replies into a review with a summary body.
