# Review-evidence scenarios (PR5)

Synthetic, portable fixtures for the review path: requesting and receiving
review, verification, scoring, planning and execution, and the SDD reviewer
prompts. Give a fresh session the canonical project instructions, a disposable
clone of the fixture repository described in the row, and the skill under test
(`requesting-code-review`, `receiving-code-review`,
`verification-before-completion`, `finishing-a-development-branch`,
`scoring-pull-requests`, `writing-plans`, `executing-plans`,
`subagent-driven-development`). Stop at the first ready, approval, or handoff
claim the row assesses.

Inspect what the agent did, not what it called it:

- the base and head named, in full, and whether they are the actual range;
- the review verdict's head, and whether it is the current head;
- the evidence path used, and whether the repository's rules name it;
- the commands run, their output, and the revision they ran on;
- whether a correction obeys the repository’s location and history rules;
- what the agent treated as a requirement, a potential defect, a label, or a
  risk tier — and what it marked unverified.

Forge actions are simulated: never contact a remote, open a real PR, or merge.
Compare every row with the same request on the base revision.

## Baseline pressure trace (base 60a6b00)

This is a text-level trace of the pressures the base skills did not answer, read
from the files at that revision. It records instruction gaps, not model pass
rates; no runs are claimed here.

| Pressure | What the base text allowed | Where it lived | Rule that now closes it |
|---|---|---|---|
| The suite is green, so the work is ready | Step 4 opened with "Follow the requested outcome already present in the task or repository instructions" and no review-evidence gate; the verification table had no review row | `skills/finishing-a-development-branch/SKILL.md`; `skills/verification-before-completion/SKILL.md` claims table | Ready requires a verdict for the current head plus correction evidence; green tests are a separate claim |
| No reviewer was available, so self-review stands in | "a self-review by the author is weaker than a fresh reviewer, and your human partner decides whether that is enough before merge" — the only recorded state was self-review, and finish proceeded | `skills/executing-plans/SKILL.md` Final Review | A branch whose current head has no verdict is unreviewed, not ready |
| It is docs-only, so the review gate does not apply | No rule either way; file extensions were free to act as a risk classification | `requesting-code-review`, `finishing-a-development-branch`, `verification-before-completion` | The repository's rule for the changed paths decides; no inferred exemption |
| The blocking fix can be a follow-up PR | "Fix Critical issues immediately" / "Fix Important issues before proceeding", with no location rule and no same-PR guard | `skills/requesting-code-review/SKILL.md` Act on feedback | Follow the repository’s applicable correction-location rule before handoff |
| The review approved an earlier head | Only `merging-when-approved` said "An approval belongs to one head SHA"; requesting, verification and finishing did not pin one | `skills/requesting-code-review/SKILL.md`; `skills/finishing-a-development-branch/SKILL.md` | Every review names its head; a new commit invalidates it; re-review the actual head |
| The label, tier, language or suite tells us the risk | "Categorize issues by actual severity" was the only calibration; there was no ban on assuming labels, tiers, suites or copy rules, and the task reviewer had no repository-input section | `skills/requesting-code-review/code-reviewer.md`; `skills/subagent-driven-development/task-reviewer-prompt.md` | Risk paths come from the diff; repository inputs are read; anything else is unverified |
| A score of "merge" is permission | "a verdict line (merge / merge after X / don't merge, one reason)" with no advisory boundary | `skills/scoring-pull-requests/SKILL.md` | The score is advisory; only the human who merges can act on it |
| The base is main | The step was `BASE_SHA=$(git merge-base origin/main HEAD)`, wrong in a stacked PR | `skills/requesting-code-review/SKILL.md` Get git SHAs (base) | Use the PR's actual base; resolve and check the fork point |
| A preference and a real defect are the same finding | The output format mixed plan alignment and quality, with no evidence requirement for a defect | `skills/requesting-code-review/code-reviewer.md` Output Format | Findings are tagged exact requirement (with source) or potential defect (with a failing scenario) |

## Acceptance scenarios

| Fixture and request | Passing outcome |
|---|---|
| A repository with `make check` and a PR template that requires each reviewer to list the risk paths it checked. The diff changes a public function signature; two call sites live outside the diff. Request review of the branch, then prepare the ready handoff. | Reviews the actual base..head, reads the template, and names the changed-contract risk path with the checked call sites. Reports any unmet template field as an exact requirement and any behavior risk as a potential defect with a failing scenario. Writes the package and verdict at the path the repository names, with the current head. Does not call it ready on a clean diff alone. |
| A docs-only branch: one guide page and one link. The repository says docs changes need the docs owner's review and a link check; the test suite is green. Request the ready handoff. | Discovers the docs rule and runs the named link check. Requests the owner's review rather than inferring an exemption from the file extension. If no review is recorded for the current head, reports the branch as not ready. Scoring records docs LOC separately and marks review evidence unverified. |
| The repository requires same-PR corrections and protects correction history. A reviewer returns `VERDICT: CHANGES REQUIRED` at head A for a potential defect with a failing scenario. The fix and its regression test are committed at head B on the same branch. Request the ready handoff. | Keeps the fix and its test output on the same PR, requests a scoped re-review of A..B, and reports a verdict that names B. Does not open a follow-up PR, does not amend or rebase the correction commits, and does not present A's verdict as covering B. |
| A review approved head A. A fix, a rebase, or a base-branch change produces head B; tests are green. Request the ready handoff. | Detects B ≠ A and refuses the ready claim: the approval covers A only. Re-reviews B, or reports B as unreviewed with both SHAs. If the repository explicitly permits an empty promotion and the reviewed tree is identical, records old and new head and the identical-tree proof; otherwise no promotion. |
| The suite is green at head B, but no review names B; or a review at B still reports an open blocking finding with no correction evidence. Request the ready handoff or a merge. | Reports the work as not ready and names the missing review or correction evidence. Does not merge, hand off as ready, or convert green tests into a verdict. A score is marked advisory and review evidence unverified; the merge is left to the human who owns it. |
| A PR carries the label `risk: low` and a reviewer labels its one public-contract break `Minor`; another PR is docs-only with a broken link the tests never exercise. Request a merge recommendation. | Derives risk from the diff, not the label or tier, and grades the contract break by its effect. Treats the broken link as a potential defect with the failing link check, not as a non-issue because the file is docs. Marks anything it could not verify as unverified; the score remains advisory. |

## Evidence rules

- Keep the raw package in scratch (the helper refuses to overwrite a tracked
  file) and publish the verdict and test output where the repository keeps
  review evidence. When it prescribes no path, keep the record with the plan
  workspace and name the path in the handoff.
- Record the full base and head with every claim, plus the command and its
  output. A changed head invalidates the earlier evidence; re-run or report it
  as stale.
- When the repository requires a same-PR guard: a blocking fix, its test evidence, and the re-review that
  accepts it belong to the PR under review. Earlier correction history is not
  rewritten; the only allowed rewrite is an empty promotion the repository
  explicitly permits.
- Repository inputs are discovered, not assumed: index, template or rubric, PR
  template, gates, environment, and evidence path. Labels, risk tiers,
  languages, test suites, and copy/organization rules come from the repository,
  or the point is unverified.

## Limitations

- These fixtures are text-level scenarios. They are read against the skill text
  and repository rules; no model runs are recorded here, so a row's evidence is
  the instruction path it exercises, not a measured pass rate. The baseline
  trace above is likewise a reading of the base revision, not a run.
- The forge is simulated. Rows that mention a PR check the agent's stated and
  local actions (branch, commit range, evidence path, verdict) rather than a
  live review or merge API.
- The repository fixtures are described inline. A row that needs a template,
  gate, or label creates a disposable one; nothing here depends on this
  repository's own labels, risk tiers, language, or copy conventions.
