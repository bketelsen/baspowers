---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
---

# Requesting Code Review

Dispatch a code reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation — never your session's history.

**Core principle:** Review early, review often. A review is evidence about one commit range, not a badge the change carries forward.

## When to Request Review

**Mandatory:**
- After completing major feature
- Before marking a PR ready, when the repository or the requested outcome
  requires an independent review
- Before merging to the branch's target base

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing complex bug

## How to Request

**1. Pin the actual range:**
```bash
BASE_SHA="<the PR's actual base, or the BASE recorded before the task>"
HEAD_SHA=$(git rev-parse HEAD)
```

Use the PR's actual base. In a stacked PR, `git merge-base origin/main HEAD` includes the parent PR's commits and reviews the wrong change; on a short branch it can also resolve to the head itself. For a whole branch with no parent PR, resolve the fork point and check it against the branch's upstream and the repository's default branch before using it. Never default to `HEAD~1`: it silently drops every commit but the last.

Record both SHAs in full, with the package path, in the handoff. A review covers the head it was given: any later commit, amend, rebase or push makes the findings stale. Re-review the new head before merge.

**2. Discover the repository's review inputs before dispatch:**

Read the canonical instructions and name the paths the reviewer must follow: the local skill/docs index, the PR template, the review rubric, the gates and commands that apply to the changed paths, the environment they run in, and the path where the project keeps review evidence. Pass those paths; do not paraphrase them from memory. Do not assume a label, risk tier, language, test suite, or copy/organization rule the repository has not stated.

**3. Dispatch code reviewer subagent:**

Dispatch a `general-purpose` subagent, filling the template at [code-reviewer.md](code-reviewer.md)

**Placeholders:**
- `[DESCRIPTION]` - Brief summary of what you built
- `[PLAN_OR_REQUIREMENTS]` - What it should do
- `[REPO_INPUTS]` - Paths to the index/template/rubric, applicable gates and environment, and the evidence path
- `[BASE_SHA]` - Starting commit
- `[HEAD_SHA]` - Ending commit

**4. Act on feedback:**
- Fix Critical issues immediately
- Fix Important issues before proceeding
- Note Minor issues for later
- Push back if reviewer is wrong (with reasoning)

Keep the reviewer's two kinds of finding apart. An **exact requirement** is quoted from the spec, plan, brief, or repository rule; it gates. A **potential defect** needs a concrete failing scenario or test; if the reviewer supplies none, reproduce it before you accept it. Neither the severity label nor a PR label decides the gate — you re-grade by effect.

**Repository correction rules:** If the repository requires same-PR fixes,
verify the correction and required evidence there before calling it addressed.
Follow local history-retention rules, including any expressly permitted empty
promotion. Record both heads and verify identical trees for such a promotion.
Otherwise do not invent a same-PR or no-rewrite rule. A verdict never transfers
to a different head; obtain any required fresh verdict.


## Example

```
[Just completed Task 2: Add verification function]

You: Let me request code review before proceeding.

BASE_SHA=a7981ec  # the BASE recorded before Task 2
HEAD_SHA=$(git rev-parse HEAD)

[Dispatch code reviewer subagent]
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types
  PLAN_OR_REQUIREMENTS: Task 2 in the selected brief; local requirement at <path>@<revision>
  REPO_INPUTS: AGENTS.md, .github/PULL_REQUEST_TEMPLATE.md, CONTRIBUTING review rubric, `make check`
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661

[Subagent returns]:
  Strengths: Clean architecture, real tests
  Issues:
    Important: Missing progress indicators
    Minor: Magic number (100) for reporting interval
  Assessment: Ready to proceed

You: [Fix progress indicators]
[Continue to Task 3]
```

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "I'll just review the diff myself instead of dispatching a reviewer" | You're the coordinator — reviewing the diff inline burns the context window you need to keep driving the work. Dispatch a reviewer subagent: the diff and the evaluation live in its context, and only the findings come back to you. |
| "The reviewer needs my whole session history to understand the change" | Hand it precisely crafted context, never your session's history. That keeps the reviewer on the work product, not your thought process. |
| "Tests are green, so the review is a formality" | A green suite proves the tree's tests passed. It does not prove the requirements were met or that the change is ready. |
| "It's docs-only, so skip the review" | Whether a docs-only change needs review is the repository's rule. File extensions are not a risk classification. |
| "The blocking fix can be a follow-up PR" | If local rules require the correction on this PR, a follow-up cannot satisfy the gate. |
| "The review approved the previous head" | An approval belongs to the SHA it saw. Any new commit invalidates it. |
| "The label says low risk / Minor" | Labels and tiers are claims. Grade by the effect a person gets, not by the label. |
| "The score says merge" | Scoring is advisory. Merge authority stays with the repository's merge gate. |

## Red Flags

**Never:**
- Skip review because "it's simple"
- Ignore Critical issues
- Proceed with unfixed Important issues
- Argue with valid technical feedback
- Claim a review covers a head it never saw, or a fix that landed after it

**If reviewer wrong:**
- Push back with technical reasoning
- Show code/tests that prove it works
- Request clarification

See template at: [code-reviewer.md](code-reviewer.md)
