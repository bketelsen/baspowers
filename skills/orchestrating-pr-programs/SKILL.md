---
name: orchestrating-pr-programs
description: Use when one thread coordinates several agent sessions that each deliver their own pull request, such as a refactor program, fixes from an issue sweep, or follow-ups to merged pull requests, including when a session reports ready, a review finding needs a ruling, or a pull request merges
---

# Orchestrating PR Programs

## Overview

You run the program; sessions write the code, one pull request each.
The program ends when every item and every follow-up fix has merged or stopped, and no merged or stopped item's leftovers are still to collect.

## Launch

1. Before launching, record which follow-up fixes, issue actions and posting the human authorized. A merge or release is a human action, not a program step.
2. Go through the items in any order and start each one whose files no started, unfinished item owns and whose prerequisites have merged and been observed as step 9 requires; repeat this pass whenever an item merges or stops.
   An item owns its files from its start until it merges or stops; when a prerequisite stops, stop the items that build on it.
   When a session asks for a file outside its list, give it only if no other started, unfinished item owns it.
   Authorized follow-up fix sessions start by the same rule.
3. Brief each session with [session-brief.md](session-brief.md) and everything that brief says the session gets.
   When the host cannot run every session that may start, start the next one whenever a slot frees, never in fixed waves.
4. A session is idle only when its thread is not running, none of its sub-agents runs, and its last message waits on nothing.

## Gate and handoff

5. Check gate 9 of the session brief yourself; if it fails, send the session back with what is missing.
   When the session's verdict from gate 10 is positive, its judge agrees, and you agree, report the pull request as ready to your human partner with its base, head SHA and evidence path; you never merge.
   When any of the three says no, stop its work, leave the pull request open, and report why.
6. When a session asks you to rule on a review finding, use the bar in gate 7 of the session brief; if the reviewer still holds the finding after your ruling, ask your human partner.
7. Forward every security hole a session reports to your human partner privately at once, never into an issue, pull request, or comment.
8. You never merge, in any repository: no local integration, no forge merge, no direct push to a default branch, no `--admin`, no delegated one-off.
   Before reporting a pull request ready, confirm that its head contains the current base (`git merge-base --is-ancestor` is a read, not a merge).
   If the base moved and the head does not contain it, the head is new evidence: the session updates the branch and gate 9's review and checks re-run on the new head.
   No approval, owner instruction or trivial-diff claim is a shortcut around that.
   After a new head, report it as unready until the gates pass at that head.

## Follow up

9. After a pull request merges or stops, once its session is idle, ask it for everything it left open.
   A session's report that it merged is not evidence: observe the merge in the repository — the base branch contains the merge commit and the pull request is closed as merged — before starting anything that depends on it.
   A release dependency starts only after you observe the release itself; a merge is not a release.
10. Leave security holes out; step 7 covers them.
    Keep the failures that meet the bar in gate 7 of the session brief and the fixes on that gate's cheap list; decline the rest in a comment on that pull request, one line each, only where posting is authorized.
11. Open one issue with the kept items, linking that pull request, only when your human partner authorizes opening issues; otherwise report the kept items and leave the issue to them.
    Start one fix session as step 2 allows only if follow-up implementation was authorized. Issue creation alone does not authorize implementation. If item counts stop shrinking, use baspowers:stopping-runaway-prs before starting a fix.
12. When that fix lands and you observe it, close the issue with a comment that settles each item only when closing is authorized, then run steps 9 to 11 for the fix.

## Ask your human partner

13. Write each decision in plain words: what it is, the options with their cost, your recommendation, and your confidence in it as a percentage.
    Each time you raise a pending decision again, restate it in full; a bare label such as "A or B?" means nothing to a partner who has been away.
    Keep every other item running while you wait.

## Red Flags

| Thought | Reality |
|---|---|
| "The session says it merged, so the dependent can start" | A report is not the repository state. Observe the merge on the base branch first, and observe a release for a release dependency. |
| "The owner said to go ahead and merge it" | You never merge in any repository. Report the ready head and hand off. |
| "The base moved, but the owner approved the old head" | A new head re-runs gate 9. There is no shortcut around a stale approval. |
| "Start no other work; scheduling the fixes is the owner's call" | Start only follow-up fixes that the human authorized and that step 11 allows. |
| "Valid finding, the fourth of one class: stop patching and redesign" | Rule on it with gate 7 of the session brief first: below the bar, decline it; at or above it, baspowers:stopping-runaway-prs decides before any patch. |
| "Any push voids every gate; restart from the cleanup scan" | Gate 9 of the session brief: one scan, then a review round for each later fix, and live evidence on the final head. |
