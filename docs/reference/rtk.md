# RTK

RTK is a CLI proxy that filters and compresses shell command output to reduce the number of tokens consumed by an LLM.

## Files

| dotfiles                                                     | Link destination                     |
| ------------------------------------------------------------ | ------------------------------------ |
| `dotfiles/copilot-hooks/rtk-rewrite.json`                    | `~/.copilot/hooks/rtk-rewrite.json`  |
| `dotfiles/copilot-instructions.md` (including the RTK block) | `~/.copilot/copilot-instructions.md` |

## Setup

### Installation

```bash
brew install rtk
```

### Hook for GitHub Copilot (global)

```bash
rtk init --global --copilot
```

Generates `~/.copilot/hooks/rtk-rewrite.json` and the RTK block in `~/.copilot/copilot-instructions.md`.
In this repository, the hook file is managed as `dotfiles/copilot-hooks/rtk-rewrite.json`, and `install.sh` creates the symlink.

## Usage

Just add `rtk` to the beginning of a command.

```bash
# Use instead of the normal command
rtk git status
rtk git log -10
rtk cargo test
rtk docker ps
```

When the hook is enabled, GitHub Copilot CLI automatically runs commands through `rtk` (no manual prefix needed).

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

This removes only `~/.copilot/hooks/rtk-rewrite.json` and the RTK block in `copilot-instructions.md`. Other files are unaffected.

## References

- [RTK official site](https://www.rtk-ai.app/)
- [Configuration for GitHub Copilot](https://www.rtk-ai.app/docs/getting-started/supported-agents/#github-copilot-vs-code-chat--cli)
