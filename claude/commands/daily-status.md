Aggregate my work status across GitHub PRs and Jira tickets, then optionally DM a summary to me on Slack (user ID: U06KCRZQ51S).

## Prerequisites

Before running any Bash commands, verify both tools are available:

```bash
command -v gh >/dev/null 2>&1 || echo "MISSING: gh (GitHub CLI)"
command -v acli >/dev/null 2>&1 || echo "MISSING: acli (Atlassian CLI)"
```

If either tool is missing, inform me and skip that data source. Continue with whatever is available.

## Workflow

### 1. Fetch Data (in parallel)

Run all three of these Bash commands simultaneously:

**My open PRs:**
```bash
gh pr list --author "@me" --state open --json number,title,url,reviewDecision,statusCheckRollup,updatedAt
```

**PRs awaiting my review:**
```bash
gh pr list --search "review-requested:@me" --state open --json number,title,author,url,updatedAt
```

**My Jira tickets:**
```bash
acli jira workitem search --jql "assignee = currentUser() AND resolution = Unresolved"
```

### 2. Format & Display

Present a clean, readable summary with these sections:

#### My Open PRs
For each PR show:
- PR number and title (as a link)
- Review status: APPROVED, CHANGES_REQUESTED, REVIEW_REQUIRED, or pending
- CI status: passing, failing, or pending
- Last updated (relative, e.g. "2 hours ago")

#### PRs Needing My Review
For each PR show:
- PR number and title (as a link)
- Author
- How long it's been waiting (relative)

#### My Jira Tickets
For each ticket show:
- Ticket key (e.g. TC-1234)
- Summary
- Status (e.g. In Progress, To Do)

If any section has no items, show "None" for that section.

### 3. Offer Slack DM

After displaying the summary, ask:

> Want me to DM this summary to you on Slack?

### 4. Send Slack DM (if accepted)

1. Send the summary as a DM using `mcp__slackgustoofficialmcp__slack_send_message` with `channel_id` set to my user ID (U06KCRZQ51S)
2. Use standard markdown formatting:
   - **bold** for section headers
   - Bullet lists for items
   - `[text](url)` for links
   - Keep it concise — this is a DM, not a report

## Error Handling

- If `gh` is not authenticated: suggest `gh auth login`
- If `acli` is not authenticated: suggest `acli login`
- If a command fails, show the error and continue with other data sources
- Never fail completely — show whatever data you can gather
