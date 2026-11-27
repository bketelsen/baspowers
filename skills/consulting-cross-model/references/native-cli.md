# Native CLI recipes

Native Claude Code and Codex hosts only. These commands are one way to reach the
other model family; they are not a requirement, and the skill works without
them. Run them only where your human partner authorizes the CLI and your role
may execute it. Do not install, upgrade, or configure anything to make them
work.

Codex consults Claude on Opus 5.5 (`claude-opus-5-5`); Claude consults Codex on
GPT-6 Astra (`gpt-6-astra`). Pin the model in every call. Consultation is
advisory, not an authorization and not a substitute for inspecting the
repository.

## Resolve the binary

Use only the preconfigured and authorized commands (or their explicitly
supplied paths). If they are unavailable, record the capability gap; do not
search alternate install directories. Pass `--` after the worktree name so
`agent-cli` does not parse the nested CLI's flags.
`codex exec` also reads stdin when it is not a terminal, so redirect it from
`/dev/null`; a background shell's open stdin otherwise hangs it until the
timeout.

## Synchronous run

`agent-cli dev run` returns the answer directly and does not create a task file.

```bash
# Codex -> Claude
consult_agent_cli=$(command -v agent-cli) || exit 127
consult_claude_cli=$(command -v claude) || exit 127
[ -x "$consult_agent_cli" ] && [ -x "$consult_claude_cli" ] || exit 127
BASPOWERS_CONSULT_DEPTH=1 timeout 300 \
  "$consult_agent_cli" dev run . -- "$consult_claude_cli" \
  -p --model claude-opus-5-5 --output-format text \
  --permission-mode plan "$(<.claude/consultations/question.md)"

# Claude -> Codex
consult_agent_cli=$(command -v agent-cli) || exit 127
consult_codex_cli=$(command -v codex) || exit 127
[ -x "$consult_agent_cli" ] && [ -x "$consult_codex_cli" ] || exit 127
BASPOWERS_CONSULT_DEPTH=1 timeout 300 \
  "$consult_agent_cli" dev run . -- "$consult_codex_cli" \
  exec -m gpt-6-astra --sandbox read-only --color never \
  "$(<.claude/consultations/question.md)" < /dev/null
```

When synchronous output is unavailable, use `agent-cli dev agent .` with the
opposite `--agent`, the same model flag in `--agent-args`, `--no-hooks`,
`-m tmux`, and `--prompt-file`. Require a unique report path. Remove generated
`TASK-*` and consultation files after reading the report.

## Submodules

`agent-cli dev path .` can resolve to a superproject when called inside a
submodule. Compare it with `git rev-parse --show-toplevel`; if they differ, name
the exact nested repository path in the prompt so the adviser inspects the right
tree.
