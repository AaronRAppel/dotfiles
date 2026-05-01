Review the code changes in the current branch and generate a PR description.

**Instructions:**
1. Use the format above
2. Output the description in markdown
3. Keep the description clear and concise
4. Include a link to the Jira ticket at the top of the "Why is this change being made?" section
5. If a section is N/A, remove the section. For example, if there are no screenshots, remove the screenshots section

**Context:**
This should add all the necessary information and context to the PR description without anything unhelpful or too much about the process we took to get there. Stick to the what and the why.

**Format inside the ```:**
```
## What is this change doing?

## Why is this change being made?

## How did you test this change?

- [ ] **I did test my change**
  - [ ] Local smoke test (manual verification)
  - [ ] Unit / integration tests added or updated
  - [ ] Offline Gus evaluations

### Offline Gus Evaluations

If your PR impacts Gus behavior it is recommended to run the offline evals
before and after your change to assess impact.

<!--
Run them with `OTEL_SDK_DISABLED=true uv run flask offline-evals --json`
-->

What got better? What got worse?

<!--
Questions about how to use evals? #core-x-ai-evaluations
-->

### Screenshots (if appropriate)
