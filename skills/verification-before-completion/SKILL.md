---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
---

# Verification Before Completion

## Overview

**Core principle:** Evidence before claims, always.

**Violating the letter of this rule is violating the spirit of this rule.**

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you cannot claim it passes.

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

## Evidence Has a Path and a Revision

A result is evidence only for the tree it ran on, kept where the repository
says evidence goes:

- **Pin the revision.** Record the commit SHA you verified. For uncommitted
  work, record the diff identity (`git diff HEAD | git hash-object --stdin`)
  plus content digests for any untracked inputs and `git status --porcelain`
  for the path inventory. A later edit makes that evidence stale.
- **Use the repository's path.** Write or quote the output at the path its
  instructions prescribe (review package, PR body, plan workspace, CI
  artifact). If none is prescribed, keep it with the plan's workspace and
  name the path in the claim.
- **Re-run after the tree or head changes.** A fix, rebase, amend, or push
  is a new revision; earlier output no longer proves anything about it.
- **Separate the suites.** The project's test command proves the tests it
  ran. It does not prove a required review happened, that review findings
  were corrected, or that a gate the repository defines was satisfied. Do
  not assume a suite, a language, or a risk tier the repository has not
  named.

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |
| Review approved | A verdict that names the current head SHA | Green tests, an older approval, a self-review presented as independent |
| Review findings corrected | The correction and test output at the current head, where repository rules require them; use the same PR when required | A promise, or evidence outside the required location |
| Branch ready to hand off | Review and correction evidence at the current head, at the repository's evidence path | Green tests, a clean review of a previous head |

## Red Flags - STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", etc.)
- About to commit/push/PR without verification
- Trusting agent success reports
- Relying on partial verification
- Calling a branch ready because its tests are green
- Citing a review, approval, or fix that names a different head
- Trusting a label, PR risk tier, or score as the gate
- Thinking "just this once"
- Tired and wanting work over
- **ANY wording implying success without having run verification**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler |
| "Agent said success" | Verify independently |
| "I'm tired" | Exhaustion ≠ excuse |
| "Partial check is enough" | Partial proves nothing |
| "Tests are green, so the PR is ready" | Green tests are one claim. Review and correction evidence are separate claims on the same head. |
| "The review was clean before the last fix" | The fix made a new head; that verdict covers the old tree. Re-review or report it as unreviewed. |
| "The fix is in a follow-up PR" | If the repository requires same-PR correction, verify the fix and its evidence there. |
| "It's docs-only / low risk, so no review" | The repository's rule decides that, not a file extension or label. |
| "Different words so rule doesn't apply" | Spirit over letter |

## Key Patterns

**Tests:**
```
✅ [Run test command] [See: 34/34 pass] "All tests pass"
❌ "Should pass now" / "Looks correct"
```

**Regression tests (TDD Red-Green):**
```
✅ Write → Run (pass) → Revert fix → Run (MUST FAIL) → Restore → Run (pass)
❌ "I've written a regression test" (without red-green verification)
```

**Build:**
```
✅ [Run build] [See: exit 0] "Build passes"
❌ "Linter passed" (linter doesn't check compilation)
```

**Requirements:**
```
✅ Re-read plan → Create checklist → Verify each → Report gaps or completion
❌ "Tests pass, phase complete"
```

**Agent delegation:**
```
✅ Agent reports success → Check VCS diff → Verify changes → Report actual state
❌ Trust agent report
```

## When To Apply

**ALWAYS before:**
- ANY variation of success/completion claims
- ANY expression of satisfaction
- ANY positive statement about work state
- Committing, PR creation, task completion
- Moving to next task
- Delegating to agents

**Rule applies to:**
- Exact phrases
- Paraphrases and synonyms
- Implications of success
- ANY communication suggesting completion/correctness
