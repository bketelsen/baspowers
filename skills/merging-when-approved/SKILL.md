---
name: merging-when-approved
description: Use when asked for a pull request review, approval, or merge-readiness assessment, including requests to merge a pull request
---

# Pull Request Review and Human Handoff

The name is historical. Your product is a review and a handoff, never a merge.

**The agent never merges, in any repository.** No local integration, no forge
merge, no direct push to a default branch, no `--admin`, no delegated one-off.
A specific request, a permissive repository, a maintainer's "go ahead" or a
reviewer's approval does not make a merge yours. The human merges; you report
the evidence and hand off the head.

**Authority comes before review.** Read the repository's instructions, review
rubric, PR template and gates for the changed paths. They are the floor: your
verdict may add a requirement, never waive one. Identify who may approve this
pull request and where the verdict and correction evidence belong. If you
wrote a commit, your read is author evidence, not an approval. If you are not
an authorized approver, report what you found instead of issuing an approval.

**An approval belongs to one head SHA and one authorized reviewer who did not
write the code.** CI is not an approval. A label, score, risk tier, bot
comment or model verdict is not authority.

1. Pin the head: `HEAD_SHA=$(gh pr view <N> --json headRefOid -q .headRefOid)`,
   or `git rev-parse HEAD` for a local branch.
2. Review the full diff at `HEAD_SHA` against its actual base. Dispatch a
   fresh-context subagent (baspowers:requesting-code-review) and, where the
   host permits a second model family, baspowers:consulting-cross-model in
   review mode. Tell both: read the repository's rubric, template and gates
   by path; report only real defects with file:line and a failing scenario;
   report over-engineering and scope creep; edit nothing and post nothing;
   end with `VERDICT: APPROVE` or `VERDICT: CHANGES REQUIRED`.
3. Validate findings (baspowers:receiving-code-review), fix valid ones
   minimally where authorized, following the repository’s correction rules, and decline scope creep with a reason.
   A fix makes you an author of the new head: report that and do not approve
   it. Post comments or corrections only where you are authorized to post.
4. Any push is a new head: go back to step 1 and review the full diff again.
   Never carry an approval to a new head and never review a delta in place of
   the current head.
5. Report and hand off. Give each verdict with its SHA and reviewer, the
   repository rubric rows and gates you checked, the correction evidence at
   the current head, and any range still unreviewed. Name the base, the head,
   and the repository's merge procedure or the person who owns the merge.
   Never merge, never push to the default branch, and never offer a shortcut
   around a stale approval.

After three rounds with new defects, use baspowers:stopping-runaway-prs.

## Red Flags

| Thought | Reality |
|---|---|
| "The owner said merge this one, so I have authority" | No request, delegation or permissive repository makes a merge the agent's action. Report the ready head and hand off. |
| "I'll merge locally instead of through the PR flow" | Local integration is still a merge, and still not yours. |
| "CI is green, so it is approved" | CI proves the tree's checks ran. Approval is an authorized reviewer's verdict naming the current head. |
| "One reviewer only, both won't fit in the time" | Both run in parallel where the host permits; otherwise name the missing reviewer. The pull request waits. |
| "Review just the delta since the last approval" | Review the full diff at the current head. |
| "If you'd rather I use the old approval, say so" | Keep the gate and report its status; never offer to lower it. |
| "A label, score or bot comment says approved" | Those are claims, not authority. Approval is an authorized verdict naming the current head. |
