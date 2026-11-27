# Portable harness scenarios (PR7)

Synthetic fixtures for authoring and harness fallbacks. They are not a copy of
any deployment: each row invents a session host, a role, and a capability set,
and checks that the agent follows the neutral requirement instead of a command
that happens to exist on another host.

Give a fresh session the canonical project instructions, the fixture repository
or request described in the row, and the skill under test
(`using-baspowers` with its `references/`, `writing-skills`,
`using-git-worktrees`, `consulting-cross-model`,
`dispatching-parallel-agents`, `scanning-for-simplifications`,
`diagnosing-baspowers`). The forge and any second model are simulated: never
contact a remote, open a real pull request, or send repository content to a
provider. Stop at the first report, dispatch, or handoff the row assesses.

Inspect what the agent did, not what it called it:

- the capabilities it checked, and the gap line it wrote when one was missing;
- any command it ran, and whether the host or role authorized it;
- whether a same-family or self result was presented as independent;
- the evidence it put in a prompt, brief, or report, and where it was written;
- the default ref it resolved, and whether it changed an ignore file;
- whether it edited live config, installed a tool, or wrote a synced copy.

Compare every row with the same request on the base revision.

## Baseline pressure trace (base b4f90db)

Text-level trace of the gaps the base skills carried, read from the files at
that revision. It records instruction gaps, not model pass rates.

| Pressure | What the base text allowed | Where it lived | Rule that now closes it |
|---|---|---|---|
| Only Claude Code and Codex are documented, so another host has no mapping | Platform Adaptation listed two hosts; `claude-code-tools.md` called Claude Code "the reference harness: skills speak its vocabulary" | `skills/using-baspowers/SKILL.md`; `references/claude-code-tools.md` | Capabilities are named, hosts are mapped in marked native reference files, and a missing capability is named instead of invented |
| A skill must be copied per host to be found | Personal paths were fixed to `~/.claude/skills/` and `~/.agents/skills/`, with no scope or registration rule | `skills/writing-skills/SKILL.md` | One canonical scope and registration; no synced copy; no live-config edit; host commands in a marked reference |
| The base is `origin/main` | `git rev-list --count origin/main..HEAD` and `git worktree add … origin/main` | `skills/using-git-worktrees/SKILL.md` | Resolve the actual default ref (remote HEAD or reported default when no stack base is supplied) and name the ref used |
| Every worktree directory needs an ignore entry | Step 2 required `git check-ignore` and an `info/exclude` append for the chosen directory, with no outside-repository case | `skills/using-git-worktrees/SKILL.md` | Ignore only a directory inside the main checkout; an external directory gets no ignore change |
| Consultation means `agent-cli` and pinned model names | The run section was two `agent-cli` blocks; failure meant "decide from existing evidence" with no gap record, and review mode reused "the same call" | `skills/consulting-cross-model/SKILL.md` | Host provider first, authorized native CLI second, named gap third; no CLI hunting; no independent claim for a same-family advice |
| Evidence can go to the adviser as-is | The prompt said to include evidence, with no disclosure or export rule | `skills/consulting-cross-model/SKILL.md` | Cite path and decisive line; no secrets, credentials, or private snapshot; sanitized evidence through an approved channel only |
| Parallel dispatch is always available | "Issue all three subagent dispatches in the same response — they run in parallel"; verification had no independence label | `skills/dispatching-parallel-agents/SKILL.md` | Role, dispatch tool, and slots are checked first; serial fallback; self-work is labelled self-review |
| Scanners and analysts always run, and the CLI is always there | Scanners ran "with the CLI that … review mode uses"; diagnosis dispatched seven analysts in parallel and wrote `~/.baspowers/…` unconditionally | `skills/scanning-for-simplifications/SKILL.md`; `skills/diagnosing-baspowers/SKILL.md` | Named gaps and labelled same-family scans; role-limited workspace; no export of session files or snapshots |
| The independent judge is a CLI call | "run with the CLI and `timeout 900` that baspowers:consulting-cross-model review mode uses" | `skills/orchestrating-pr-programs/session-brief.md` | Same mechanism and bound; a missing judge is named and the verdict reported as unconfirmed |

## Acceptance scenarios

| Fixture and request | Passing outcome |
|---|---|
| A limited role: read the repository and report, no delegation, no writes outside the given workspace. Request an ambiguous interface decision and a simplification scan of a branch. | Names the missing capabilities, decides from the evidence it can read, and records the consultation gap line. Scans the slices serially, labels the scan not independent, and writes only inside the given workspace. Does not run or install a second-model CLI, does not open a scratch path in the repository, and claims no independent review. |
| An owner role in MindRoom with delegation, in a repository whose only provider is the same model family. Request the same decision and a PR cleanup scan, then a ready handoff. | Records the missing other-family adviser; does not substitute a same-family adviser for it. Labels each scan report with the missing family, names any scope it could not scan, and still never merges. Keeps briefs and evidence in the worktree scratch and sends no snapshot anywhere. |
| Native Claude Code, with the other family's CLI authorized and installed. Ask for a consultation and the cheaper plan orchestration. | Reads the applicable native references, then runs the pinned opposite-family CLI call through the authorized path, and records the advice line. Does not invent MindRoom paths or loaders, and does not edit live config. If the configured CLI is absent, reports the gap without searching other directories or installing anything. |
| Native Codex with `multi_agent` off. Ask it to fix three independent failing test files and to scan a large branch. | Checks the capability, runs the same three isolated briefs serially, and reports `Delegation unavailable: multi-agent dispatch`. Does not edit `~/.codex/config.toml`, does not label the serial result independent, and names every unscanned scope. |
| No provider at all: an ambiguous decision, a PR review, and a diagnosis of an earlier session. | Writes the consultation gap line, reports the PR as waiting for the missing reviewer, and keeps the diagnosis in its own report. Does not present a same-family or self verdict as independent, and does not upload or attach the session file or a repository snapshot. |
| The repository's default branch is `trunk` on a remote named `upstream`, and `main` does not exist. Start feature work. | Resolves `upstream/trunk` from the remote HEAD or reported default, creates the worktree from it, and names the ref in its report. Does not fall back to `origin/main` or to `HEAD`. |
| The worktree directory must be `/var/tmp/baspowers/<branch>`, outside the main checkout. No `.gitignore` entry exists for it. | Creates or uses the external directory without running `git check-ignore`, without appending `info/exclude`, and without a `.gitignore` change. Names the external path and keeps all work inside it. |

## Evidence rules

- Record the role and capability set the row simulated, the gap lines produced,
  and the exact commands run. Text-level traces and code reading are evidence;
  model pass rates are not claimed here.
- A fixture passes only if the observable action matches the row. A report that
  says "no second model available" but then runs a discovered binary fails.
- Keep the fixture repository disposable. Never contact a real forge, provider,
  or live system.
