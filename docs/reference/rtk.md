# RTK

RTK is a CLI proxy that filters and compresses shell command output to reduce the number of tokens consumed by an LLM.

## Files

| Canonical file | Link destination |
| -------------- | ---------------- |
| `dotfiles/copilot-hooks/rtk-rewrite.json` | `~/.copilot/hooks/rtk-rewrite.json` |
| `dotfiles/agent-instructions.md` (including shared RTK guidance) | `~/.copilot/copilot-instructions.md`, `~/.codex/AGENTS.md`, and `~/.claude/CLAUDE.md` |

## Setup

### Installation

```bash
brew install rtk
```

### Hook for GitHub Copilot (global)

```bash
rtk init --global --copilot
```

This upstream command generates `~/.copilot/hooks/rtk-rewrite.json` and RTK
instructions for GitHub Copilot. In this repository, the hook remains a
Copilot-specific file at `dotfiles/copilot-hooks/rtk-rewrite.json`, while the
portable RTK guidance is maintained once in `dotfiles/agent-instructions.md`.
`install.sh` creates all corresponding links.

## Usage

Just add `rtk` to the beginning of a command.

```bash
# Use instead of the normal command
rtk git status
rtk git log -10
rtk cargo test
rtk docker ps
```

When the hook is enabled, GitHub Copilot CLI automatically runs commands
through `rtk` (no manual prefix needed). Codex and Claude Code receive the
shared usage and safety guidance, but this Copilot hook is not installed into
their product-specific configuration.

### Machine-readable output

Bypass RTK filtering whenever command output or exit status will be parsed, compared for equality, preserved for migration, or otherwise used for a safety decision. Either set `RTK_DISABLED=1` for the command or use `rtk proxy` for a simple command, then consume only the raw output and original exit status:

```bash
RTK_DISABLED=1 git status --porcelain=v1 -z
rtk proxy gh qwt list --all github.com/owner/repo/branch --exact --full-path
```

This exception applies to the status, diff, ref, path, and list probes used by the interactive `gh-qwt` safety workflow.

## Meta commands

```bash
rtk gain              # Dashboard for token reduction
rtk gain --history    # Reduction history by command
rtk discover          # Detect commands not using rtk
rtk proxy <cmd>       # Run without filtering (record usage only)
rtk init --show       # Check hook status
```

## Uninstall

```bash
rtk init --uninstall --global --copilot
```

This upstream command targets the Copilot hook and the instructions reached
through `~/.copilot/copilot-instructions.md`. Because that instruction path is
a link to the shared canonical file in this repository, review the resulting
change before using it; removing shared RTK guidance affects all three agents.

## References

- [RTK official site](https://www.rtk-ai.app/)
- [Configuration for GitHub Copilot](https://www.rtk-ai.app/docs/getting-started/supported-agents/#github-copilot-vs-code-chat--cli)
