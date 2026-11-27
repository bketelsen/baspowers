---
name: scanning-for-simplifications
description: Use when asked to find behavior-preserving simplifications at scale, such as a cleanup pass over a large pull request before it is called ready, or a codebase or architecture scan that may feed several parallel refactor pull requests
---

# Scanning for Simplifications

## Overview

Read-only scanners with independent context find more than one careful reader, and their proposals are untrusted until proven.
Scanners anchored on earlier passes propose cosmetic edits, and unverified proposals quietly change behavior.

The most productive lens is **two owners of one fact**: state, rules, or logic kept in two places, plus the code that keeps them in step.
Deriving one from the other deletes the copy and the sync code, and often a bug.

Run read-only scanners, surveyors, and refuters from another model family where
the host exposes one, through the mechanism of baspowers:consulting-cross-model
review mode, started from the snapshot, with a 900-second bound, the filled-in
brief as the whole prompt, the brief kept outside the snapshot, and no
consultation limit.
A timeout, an error, or a report that does not cover its scope means that scope
was not scanned: rerun it, narrower if needed.

When no other-family provider is available, use the strongest independent
scanner the host and your role allow: a fresh-context subagent from your own
family per slice, with every report labelled with the missing family. With no
delegation at all, scan the slices serially yourself and say the scan is not
independent. Name what you could not run; a scope with no scanner is a named
gap, not a completed scope.
The scan is complete only when every scope was scanned, or when your human
partner accepts the gap after a scope failed the same way twice.

Keep secrets, session data, and unrelated repository content out of the briefs;
send nothing to a provider your organization has not approved, and never export
or upload the snapshot.

**Not for:** bug hunts or performance work.

## PR mode: cleanup scan before ready

Run it last, once everything else is done; checks that wait on shared resources may run once afterwards, on the final head.

1. **Freeze.** Check out the pushed head in a detached, read-only snapshot outside the live worktree.
   If your role cannot create one, read that head in the worktree you were given, change nothing, and say the isolation is weaker.
2. **Slice.** Take every file the PR adds or changes, tests included; scanners read each file whole, not as hunks.
   Group the files into slices of related files: one slice for a small PR, otherwise about one per package or concern, and at most six.
3. **Brief.** Fill in [scanner-brief.md](scanner-brief.md) and append only the project's own must-stay-unchanged rules to its behavior line.
   Mention no earlier rounds, reviews, or known findings, and set no cap on proposals; deduplicate at triage instead.
4. **Launch the scanners together**, within the role and slot limit.
   Per slice, one scanner from each available model family on the same slice, plus one pair over the whole diff with the duplication scope from the brief.
   If the host cannot run them all at once, start the next one whenever a slot frees, and wait for every report.
5. **Triage.** If your human partner asked only for findings, report them and stop.
   Otherwise deduplicate, verify each proposal in the code, and accept only those that are clearly simpler with behavior unchanged; give each rejection a one-line reason.
   Bugs go to a separate list: fix test-first the ones the PR introduced, and report the rest.
   If the accepted set grows production code overall, baspowers:stopping-runaway-prs applies.
6. **Apply** in small commits.
   Break each rewritten, not deleted, code path and confirm a test fails.
   If none fails, add a test that passes on the pre-cleanup head and fails on the broken rewrite, or drop the rewrite.
   Run the full suite, the required gates, and any benchmark the cleanup's paths fall under.
7. **Review fresh** with steps 1 to 4 and 5 of baspowers:merging-when-approved, and hand the reviewed head to the human; the agent never merges.
   The scan runs once: approvals from before it count only if it changed nothing, and fixes from this review need no new scan.

## Architecture mode: survey, then refactor programs

1. **Survey.** Pin one SHA in a read-only snapshot.
   Run one surveyor per area of about 30k lines, plus one whole-codebase surveyor on the two-owners lens, each with [survey-brief.md](survey-brief.md).
2. **Refute.** For each finding you might launch, a fresh agent from another available model family, or a labelled fresh-context agent from your own, runs the refuter brief in [survey-brief.md](survey-brief.md).
   Check each refutation in the code before dropping the finding.
   When a design choice hinges on a cost, measure the real end-to-end path first, not one step of it.
3. **Select.** Write the ranked list to a file.
   If your human partner asked only for the scan, send the top five with the file's path, and stop.
   Otherwise select a finding only when it deletes enough to matter, and report real bugs to your human partner instead.
4. **Run** the selected findings as one program with baspowers:orchestrating-pr-programs, one session and pull request per finding.
