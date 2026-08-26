---
name: changes
description: Walk through the changes on a branch or PR file by file, explaining why each file is shaped the way it is — the design rationale and the load-bearing constraints, not just what changed. Use when the user asks to explain a branch or PR, walk me through these changes, why is this file like this, explain the design of this change, or invokes /changes. Opens with a grouped summary of every changed file, then goes file by file. Accepts a PR number, PR URL, branch name, or nothing (current branch). Read-only. Distinct from summarize-changes (stats and commit messages only) and review-changes/review-pr (find problems — this skill does not).
argument-hint: "[PR number | PR URL | branch] [--non-spec | --pack <name>]"
allowed-tools: Bash, Read, Grep, Glob, AskUserQuestion
---

# Changes

Explain a change so a reviewer — or the author a week later — understands **why each file is shaped
the way it is**. Not what changed; the diff already says that.

This skill does not find problems. If you notice a bug, note it in one line at the end under
"Not part of the walkthrough" and move on. For review, the user wants `review-changes` or `review-pr`.

**Read-only. Never edit, commit, push, or post.**

## 1. Resolve the target and the merge base

Stacked PRs are common. **Never assume `main`.**

- **Argument is a number, or a GitHub PR URL** → take the number out of the URL
  (`.../pull/<n>` — trailing segments like `/files` or `/changes` are noise, drop them), then
  `gh pr view <n> --json number,title,body,baseRefName,headRefName,url,state`.
  The base is `baseRefName` from the PR itself. Fetch both refs, then:
  `git merge-base origin/<baseRefName> origin/<headRefName>`.
  - **If the PR is merged or closed, that fails** — the head branch is usually deleted, so
    `origin/<headRefName>` no longer resolves. Get the recorded SHAs instead:
    `gh api repos/<owner>/<repo>/pulls/<n> --jq '.base.sha, .head.sha'`, then
    `git merge-base <base.sha> <head.sha>`. Use `.head.sha` as the head ref everywhere below.
    Check `state` before you pick a path; don't wait for the error.
- **Argument is a branch name** → `gh pr list --head <branch> --json number,baseRefName --state all`.
  If a PR exists, use its `baseRefName`. If not, fall back to the branch's tracked upstream, then to
  `main` — and *say which fallback you used*.
- **No argument** → current branch (`git rev-parse --abbrev-ref HEAD`), then as above.

Compute `BASE=$(git merge-base <base-ref> <head-ref>)` once and use `$BASE..<head-ref>` for every
subsequent diff. Two-dot against the merge base, so commits that landed on the base branch after the
branch point don't leak in.

If the resolved base is not `main`, state it in one line before the walkthrough:
`Stacked on <baseRefName> — base is not main.`

Also read the PR body if there is one. It often states the rationale directly. **But it is a claim,
not evidence** — every rationale you repeat must be backed by a file you read.

## 2. Read the files, not just the hunks

`git diff --name-status $BASE..HEAD` for the file list, then for each in-scope file:

- **Modified** → `git diff $BASE..HEAD -- <file>` *and* read the file at head. A hunk shows the
  change; the surrounding code shows why it had to be that shape.
- **New** → `git show "<head-ref>:<file>"` in full — quoted, per the zsh trap below.

Rationale lives in the code around the diff, in sibling files, and in the pack's `CLAUDE.md` /
`package.yml`. Read those when a file's shape depends on them.

### Find the call sites

For every file in scope, establish **who calls into it** — a shape is only justified by the caller
it serves. Do this before writing anything; the call graph is also what the data-flow line is made of.

- **Grep the head ref's tree, not the working tree.** The checkout is often on a different branch, so
  the new files don't exist locally: `git grep -n "<pattern>" <head-ref> -- <pathspec>`.
- **Match the pathspec to the repo's languages, not to Ruby.** `-- '*.rb'` finds nothing in a
  TypeScript repo. Take the extensions from the diff's own file list — e.g.
  `-- '*.ts' '*.tsx' '*.js' '*.jsx'`, or drop the pathspec entirely when unsure.
- **Two zsh traps that fail silently rather than loudly:**
  - Quote the pathspec. An unquoted `--include=*.rb` or `-- *.rb` gets glob-expanded against the
    working directory and matches nothing — no error, just empty output you'll read as "no callers".
  - Brace the ref in `git show`: write `git show "${H}:${path}"`, never `git show $H:$path`. In zsh
    `$H:a` is a history-modifier expansion, so `$H:apps/foo.ts` silently becomes an absolute path
    and git reports "unknown revision" for something you never asked for.
- **Grep the qualified path or the method name, never the bare class name.** A bare constant collides
  across namespaces. Grepping `EmployerTaxes` in this repo returns ~100 hits — an unrelated
  `EmployerTaxesService` in bookkeeping, a `Column::EmployerTaxes` in custom reports, a
  `Feature::ComputeEmployerTaxes` in pay_services — and exactly 3 real callers. Grep
  `CostBasis::EmployerTaxes` or `.for(amounts_by_jurisdiction` instead, and read enough of each hit
  to confirm it's a call and not a name collision.
- **Trace up to the production trigger.** Follow callers outward until you reach something that fires
  on its own — a job, a resolver, a controller, a rake task, a consumer. "Called from a private method
  in the same file" is not an answer; keep going.
- **Separate callers added by this change from pre-existing ones.** A new API whose only caller arrived
  in the same diff has no proven second use — say so, it's a real reviewer signal. A modified method
  with callers *outside* the diff is a blast-radius fact the reviewer needs.
- **Zero callers is a finding.** Say plainly that nothing calls it, and whether that reads as
  scaffolding for a follow-up or as a leftover.
- Exclude specs when counting callers, but note it if the *only* caller is a spec.

## 3. Scope

Default to all files. Offer the scope choice with `AskUserQuestion` **only when the change has more
than ~8 files or spans more than one pack**; below that, just do all of them.

- **All files** (default)
- **Non-spec only** — first-class, this is the usual ask. Excludes `spec/`, `test/`, `__tests__/`,
  `*_spec.rb`, `*_test.*`, `*.test.*`. Say how many spec files you skipped.
- **One pack / directory** — take the path prefix from the argument or the answer.

Generated files (`CODEOWNERS`, lockfiles, generated schemas, `.rbi`) get one line each and stay in
their GitHub path position — don't collect them into a trailing "Mechanical" section, since that
breaks the side-by-side read. In this repo `CODEOWNERS` is generated by `bin/codeownership validate`
— never describe it as a hand edit.

## 4. Output

### Open with the data flow — one line

A single arrow chain naming the real files or types in order, so the file list has a spine:

> `payroll SQL → jurisdiction lookup → two-column split → report row`

Build it from the call graph you established in step 2, so it's traced rather than guessed. If you
can't write that line, you haven't understood the change yet. Go back to step 2.

This line carries the whole load of explaining execution order, because the file entries below are in
GitHub's path order rather than flow order. When a file sits far from its caller in path order, say
where it fits — "third step of the flow above" — so the reader can place it.

### Then the summary — every changed file, one line each

Before the walkthrough, give the whole shape at a glance. This is the part a reader skims to decide
where to look; the walkthrough below is what they read once they've decided.

- **One header line of totals**, and only here: `18 files, all new, +5120/-0 — of which 4410 lines
  are generated RBIs`. Call out generated volume separately when it dominates the diff, so nobody
  reads 5k lines as 5k lines of judgment.
- **Group by functional area, not by git status.** Cluster files that are read together — a model
  with its concern, a mutation with its resolver. Short headings: "Domain Models", "GraphQL",
  "Services & Repositories", "Events & Kafka", "Tests", "Config & Migrations", "Generated".
- **Order groups by importance** — core domain first, then API layer, then infrastructure, then
  tests, then generated last. Within a group, primary file first.
- **One line per file**: markdown link, then `— [new/modified/deleted, +N/-M]`, then one sentence of
  *what* changed. No why here — the why is the walkthrough's job.
- **Collapse repetition.** Three near-identical factories or per-model RBIs get one line covering
  all of them with the paths inline. Never emit twenty lines that say the same thing.
- **Say what's missing** when the change obviously depends on something absent from it — a migration,
  a caller, a flag flip. One line, at the end of the summary.

The summary is grouped and ranked; the walkthrough below is in git order. They deliberately disagree,
so a file's position differs between them — that's fine, and it's why every summary line is a link.

### Then one entry per file — the walkthrough

**A human reads this.** Each file gets a short prose description carrying the *why*, then bullets for
the moving parts. Prose for judgment, bullets for inventory — don't force either into the other.

```
**`path/to/file.rb`** — new, +117

One or two sentences: what this file is and why it's shaped this way. This is where the
design rationale goes, and the alternative it rejects if there's an obvious one.

- `methodName` — what it does, one line → `caller.rb:34`
- `otherMethod` — ... → no callers outside its own spec
- **Load-bearing:** what breaks if someone simplifies it
```

- **The description is prose, 1–2 sentences.** Never more than three. This is the part worth reading
  slowly, so it carries the reasoning — not a list of the methods below it.
- **Bullets are the inventory:** one per new or changed method, constant group, or exported symbol.
  Name in backticks first so the left edge scans. Skip anything the diff didn't touch.
- **Call site goes on the method's own bullet**, after a `→`, as `file:line`. The reader should never
  hold a method in their head while hunting for who calls it. Add `(new in this change)` or
  `(pre-existing)` only when it changes the meaning.
- **`→ no callers` is a bullet.** State it; the description above already framed whether that reads
  as scaffolding or a leftover.
- **At most one `**Load-bearing:**` bullet**, only when there is one, one sentence, specific about
  the failure: not "keep the fetch", but "`fetch` not `[]`, so a third jurisdiction value names the
  bucket it couldn't find instead of dying as `NoMethodError` on nil".
- **Bullets are optional.** A file whose whole story is one sentence gets the sentence and nothing
  else. Never pad to fill the shape.
- **Cap the bullets at six.** More than that means the file is doing too much — say so in the
  description rather than enumerating.
- **Order files exactly as GitHub's "Files changed" tab does**, so the reader can follow along side
  by side in the PR review UI. That order is just git's own: emit files in the order
  `git diff --name-status $BASE..HEAD` returns them and never re-sort. Do not hand-sort
  alphabetically — git sorts byte-wise on the full path, so `app-reports-apis/` comes *before*
  `app-reports/` (`-` is 0x2D, `/` is 0x2F). Trust the command's output over your intuition.
- **No `###` grouping headings by default.** They fight the GitHub order. Group only if the user asks
  for a thematic read rather than a side-by-side one.

| Don't | Do |
|---|---|
| Four-sentence paragraph per file, no bullets | 1–2 sentence description, then method bullets |
| Every line a bullet, including the file summary | Prose for the why, bullets for the parts |
| A description that just lists the methods below it | Description carries the reasoning; bullets carry the names |
| Method names buried mid-sentence | Method name in backticks, first on the bullet |
| Call sites collected in a trailing bullet | `→ file:line` on the method's own bullet |
| Repeating one rationale across three files | Say it once, on the file that owns it |

### Close with the one design point worth reviewer attention

Exactly one. The single judgment call most likely to be challenged — the place where a reasonable
reviewer could say "why did you do it that way?". State the tension, both sides, and where the code
actually landed. Not a list of concerns; one point.

## 5. Then stay available

End by inviting follow-ups. Do not summarize what you just said.

## Answering follow-ups — the part that matters

When asked "why is this X instead of Y?", **verify against this codebase before answering.
Answering from general knowledge is the failure mode**, even when the general knowledge is correct.

Every follow-up answer needs both halves:

1. **The semantics** — what the language/framework actually does. State it precisely.
2. **The local convention** — grep the sibling files and *cite counts and paths*.

A correct-but-unverified answer is a failure. Worked example:

> **Q:** Why `private_class_method` instead of a `private` section?
>
> **Weak (semantics only):** "`private` doesn't affect `def self.` methods."
>
> **Right:** "`private` doesn't apply to `def self.` methods — it sets default visibility for
> instance methods, so a `private` section above `def self.foo` leaves `foo` public. And it's the
> local convention: `grep -rln private_class_method` in this same directory returns
> `zp_entity_adapter.rb`, `tracker_workweek_adapter.rb`, `time_off_adapter.rb` — three siblings,
> plus this file, and zero bare `private` sections in the directory."

The grep is what makes it credible. Do it every time.

## Rules

- **Never invent a claim.** If you can't point at a file, don't say it. No "presumably", no
  "likely intended to".
- **Distinguish deliberate from incidental**, and say plainly when something looks like an accident:
  a leftover, an unreachable branch, an inconsistency with its siblings. Flag unreachable-by-
  construction defensive code as exactly that — it may still be deliberate belt-and-braces, but the
  reviewer should know it's unreachable.
- **Cite `file:line`** for anything a reviewer would want to check. Use markdown links relative to
  the repo root.
- **Bullets over prose.** Short lines a human can scan. Tables only with real columns and >2 rows.
- **No preamble.** Don't open with "This PR contains…" or restate the request. Totals belong on
  the summary's one header line and nowhere else — never as an opening paragraph, never repeated
  in the walkthrough or the closing point.
- Repo-agnostic by default. The Packwerk/pack details above are this repo's shape; on another repo,
  read whatever the local equivalent is (module boundaries, ownership files, dependency manifests).
