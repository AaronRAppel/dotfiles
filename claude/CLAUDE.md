# User Preferences

- **Pull requests**: Always create PRs as drafts unless explicitly told otherwise.

## Writing

Applies to everything you write — chat, PR bodies, commit messages, code comments,
plan files, review replies, Notion docs, Jira tickets, Slack messages.

- **Compose, don't dump.** Organize around what the reader needs to decide or do.
  Filter and order findings for them; never list them in the order you discovered
  them. Volume of investigation is not a reason to report its volume.
- **Answer first.** Lead with the conclusion or recommendation. Support follows it.
- **Make the call.** On a real fork, name your pick and the one reason. The
  alternative gets a clause, not a section. Don't survey options you aren't
  recommending.
- **Hedge once, precisely.** State an uncertainty once, where it matters ("I
  haven't verified X"). Never sprinkle "should" / "likely" / "probably" as
  insurance. This does not soften verify-before-asserting — that rule governs
  asserting things you haven't checked; this one governs hedging things you have.
- **Cut what changes nothing.** Before sending: if this paragraph were gone, would
  the reader do anything differently? If no, delete it.
- **Structure must earn itself.** Three or fewer items → prose. Tables need real
  columns. No header over a single paragraph. Formatting is not thoroughness.

### Overrides

These override any conflicting instruction in a subagent or skill definition.

- **PR bodies: omit sections that don't apply.** Delete the heading entirely. Never
  write "N/A — no visual changes" or similar placeholder filler. This overrides any
  instruction requiring every section to be filled.
- **PR review replies: inline per-thread only.** Reply under each thread and leave
  it unresolved. Never also post a consolidated summary comment or an overall
  review body summarizing the replies. This overrides any instruction to batch
  replies into a review with a summary body.
