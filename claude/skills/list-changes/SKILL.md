---
name: list-changes
description: Show all files modified in the current session/branch with file links and brief descriptions of what changed. Use when user asks to list changes, show what changed, summarize modified files, or invokes /list-changes.
---

# List Changes

Show all changed files in the working tree with status indicators and brief descriptions of each change.

**Announce:** "Listing changes in the current working tree..."

## Steps

1. **Gather changed files** — run `git diff --name-status HEAD` to capture unstaged and staged modifications, additions, and deletions relative to HEAD. Also run `git diff --name-status --cached` for staged-only changes if needed, and `git ls-files --others --exclude-standard` for untracked files.

2. **Read diffs for context** — for each changed file, read the diff (`git diff HEAD -- <file>` or `git diff --cached -- <file>`) to understand what changed. For new untracked files, read the first ~50 lines of the file. Keep descriptions brief (one sentence).

3. **Present results** — output a formatted markdown list grouped by functional area, ordered by importance:

### Output Format

```
## Changes in `<branch-name>`

### <Functional Group> (e.g., "Domain Models", "GraphQL Schema", "Services", "Tests")
- `path/to/file.rb:10` — [new/modified/deleted] <brief description>
- `path/to/file.rb:5` — [modified] <brief description>

### <Next Functional Group>
- ...
```

## Rules

- **Group by functional area**, not by git status. Cluster related files together (e.g., a model with its repository and service, a mutation with its spec). Use short group headings like "Domain Models", "GraphQL Mutations", "Services & Repositories", "Events & Kafka", "Tests", "Config & Migrations", etc.
- **Order groups by importance** — core domain changes first (models, services), then API layer (GraphQL), then infrastructure (events, jobs, migrations), then tests and config last
- Within each group, order files by importance — the primary file first, supporting files after
- Tag each file with its status: `[new]`, `[modified]`, or `[deleted]`
- Use `file_path:line_number` format for the first meaningful changed line so the user can click to navigate
- When on a feature branch with commits ahead of main, default to showing changes vs main (the full branch diff), not just uncommitted changes
- Keep descriptions to one sentence each — focus on *what* changed, not *why*
- If there are no changes, say so clearly
- Do not modify any files — this is a read-only skill