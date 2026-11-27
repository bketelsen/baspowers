---
name: scoring-pull-requests
description: Use when asked whether a pull request or change is good, clean, big, risky, over-engineered, or worth merging
---

# Scoring Pull Requests

Answer in under 200 words: a verdict line (looks mergeable / merge after X / not mergeable, one reason; advisory), then this table.
The score reports what the evidence supports. It neither approves a PR nor grants merge authority, and a reviewer or merge gate is not bound by it. A green score with no review of the current head is still not ready; a low score is an argument to investigate, not a command to close.

Size is net production LOC from `git diff --numstat`; tests and docs are not a cost.
Only count what the diff shows. Do not assume a label, risk tier, language, test suite, or copy/organization rule; mark it **unverified** until the repository's own rule or command confirms it.

| Check | Answer |
|---|---|
| Production LOC (net) | |
| Tests / docs LOC | |
| User-visible change | |
| Root cause or bandage | |
| Over-engineered? | |
| Ownership and isolation | |
| Existing behavior changed | |
| Risk paths from the diff | |
| Requirements vs potential defects | |
| Live evidence (command, output, revision) | |
| Review evidence (head SHA, current or stale, path) | |
| Score / confidence (advisory) | |

Mark anything not verified as **unverified**. A review that names another head is **stale**, not evidence for this one.
