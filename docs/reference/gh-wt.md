# gh-wt

This is the reference for fast, disk-efficient git worktrees with the `gh-wt` GitHub CLI extension.

## Overview

[gh-wt](https://github.com/HikaruEgashira/gh-wt) (`HikaruEgashira/gh-wt`) is a GitHub CLI extension for creating and managing git worktrees backed by copy-on-write (CoW): OverlayFS on Linux, and APFS `clonefile(2)` on macOS.

Plain `git worktree add` copies every tracked file into each new worktree, so disk usage grows linearly and creation gets slower as more worktrees are added. `gh-wt` instead shares disk blocks with the source checkout until files diverge. Upstream benchmarks show roughly 8x less disk usage at 10 concurrent worktrees, and 13x less at 20, compared to plain worktrees.

## Setup

The `gh-wt` extension is installed automatically by `scripts/100-gh-extensions.sh` (see [Script list](./scripts.md)). To install it manually:

```bash
gh extension install HikaruEgashira/gh-wt
```

Prerequisites:

- GitHub CLI v2.90.0 or later
- `fzf`, for the interactive worktree picker (already a Brewfile dependency; see [Tool list](./tools.md))
- Linux kernel 5.11+ (OverlayFS) or macOS (APFS), for copy-on-write support

## Usage

```bash
# Create a worktree for a branch
gh wt add feature-branch

# Remove a worktree, picking it interactively
gh wt remove

# Run a command inside a selected worktree (cd into it, then exec)
gh wt -- claude
gh wt -- npm test

# Run a command with the worktree path passed as an argument (no cd)
gh wt code
gh wt cursor
```

The `--` separator controls how the target command receives the worktree: `gh wt -- <command>` changes into the worktree directory and then runs `<command>` there, while `gh wt <command>` (no `--`) runs `<command>` in the current directory with the worktree path appended as its last argument. Use the first form for shell-like commands and the second for editors or other tools that take a path argument.

### Interactive worktree picker

When a subcommand needs a worktree and none is given, `gh-wt` opens an `fzf` picker over the existing worktrees. The picker is skipped when:

- There is only one candidate (`--select-1`)
- `--at <branch|path>` pins the target explicitly
- `GH_WT_NONINTERACTIVE=1` is set, in which case `gh-wt` exits with status `2` and prints the candidate list instead of prompting — useful in CI or agent-driven shells where `/dev/tty` is unavailable

## Command list

| Command                                 | Description                                                                                        |
| --------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `gh wt list`                            | List worktrees                                                                                     |
| `gh wt add [--new\|-b] <branch> [path]` | Add a worktree (refuses to create a new branch unless `--new`/`-b` or `GH_WT_ASSUME_NEW=1` is set) |
| `gh wt remove [target]`                 | Remove a worktree (refuses to remove the main worktree)                                            |
| `gh wt gc`                              | Delete unreferenced cache entries                                                                  |
| `gh wt [--at <wt>] <command>`           | Run `<command>` in or with a worktree                                                              |

## Shell shortcut

For interactive shells, this repository also provides a `gwt` zsh alias (the `go-to-worktree` function, defined in `dotfiles/zsh/go-to-worktree.zsh`). It runs `gh wt list` through the same `fzf` picker and `cd`s directly into the selected worktree, which is a lighter-weight alternative to `gh wt -- $SHELL` when you just want to move your current shell into a worktree. See [Zsh plugins](./zsh/plugins.md) for details.

## Copilot skill

`dotfiles/skills/gh-wt/` provides a Copilot CLI skill, installed from upstream with `gh skill install HikaruEgashira/gh-wt gh-wt`, that lets the agent create, list, and remove worktrees from natural-language requests. See [Copilot Skills](./skills.md) for details.

## Gotchas

> [!WARNING]
> On macOS, the worktree's target path and `gh-wt`'s cache directory must be on the same APFS volume, or `clonefile(2)` fails with `apfs clone failed`. If you hit this, set `GH_WT_CACHE_DIR` to a path on the same volume as the target before running `gh wt add`.

## References

- [gh-wt repository](https://github.com/HikaruEgashira/gh-wt)
- For the background behind this technology choice, see [ADR 0007](../development/99-adr/0007-gh-wt.md)
