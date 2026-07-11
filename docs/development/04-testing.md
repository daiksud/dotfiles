# Testing

This page explains the automated checks that run in CI and how to run each of them locally before opening a pull request.

## Overview

`.github/workflows/ci.yml` runs on every push to `main` and on every pull
request, with three jobs:

| Job          | Runs on                          | Checks                                                                                 |
| ------------ | --------------------------------- | --------------------------------------------------------------------------------------- |
| `lint`       | `ubuntu-slim`                     | `shellcheck` on Bash/sh scripts, `zsh -n` on Zsh plugins, JSON/TOML config syntax        |
| `test`       | `ubuntu-latest` and `macos-latest` | The `bats-core` suite under `tests/`                                                    |
| `docs-build` | `ubuntu-slim`                     | Builds the Docusaurus site (build only, no deploy)                                       |

See [ADR 0011](./99-adr/0011-ci-and-shell-testing.md) for why the checks are
split this way, and what is intentionally left out (a full `scripts/*.sh`
real-install run).

## Running checks locally

All lint/test tools are managed by [mise](../reference/mise.md), the same way
`bun` is. Install them once with:

```bash
mise install
```

Then, from the repository root:

```bash
# Shellcheck (Bash/sh scripts only — Zsh plugins use a different check below)
shellcheck install.sh scripts/*.sh dotfiles/zsh/starship-qwt-worktree.sh

# Zsh syntax check (parse-only, no execution)
for f in dotfiles/zsh/*.zsh; do zsh -n "$f"; done

# Config file syntax
jq empty install_map.json
python3 -c "import tomllib; tomllib.load(open('dotfiles/starship.toml', 'rb'))"

# bats test suite
bats tests

# Documentation build
bun install --cwd .docusaurus
bun run --cwd .docusaurus build
```

> [!NOTE]
> `shellcheck` has no Zsh dialect. Running it against `dotfiles/zsh/*.zsh`
> files would flag valid Zsh-only syntax (for example `${var:h}` or
> `"$(<file)"`) as errors, so those files are checked with `zsh -n` instead.

## The bats test suite

Tests live under `tests/` as `*.bats` files, with no static fixtures checked
into the repository — each test builds any git repository or sandbox
directory it needs at runtime under a temp directory, then tears it down
afterward. This keeps tests hermetic and independent of the machine running
them.

Current coverage:

- `tests/starship_qwt_worktree.bats` — `dotfiles/zsh/starship-qwt-worktree.sh`
  behavior: the `owner/repo/branch` label at a worktree root, the appended
  subdirectory path from inside a worktree, slash-containing branch names, and
  the non-zero exit outside a qwt worktree or outside Git entirely.
- `tests/install_symlinks.bats` — `install.sh`'s symlink-creation logic,
  exercised against a copy of the real script in an isolated sandbox (fixture
  `install_map.json` and `dotfiles/`, empty `scripts/` so no real installs
  run): link creation, idempotent re-runs, and converting a symlinked parent
  directory into a real one while migrating its existing contents.
- `tests/install_map.bats` — every `install_map.json` entry resolves to a real
  path under `dotfiles/`, and every destination looks like an absolute or
  `~`-rooted path.

### Adding a new test

1. Add a `<name>.bats` file under `tests/` (or a new `@test` block in an
   existing file, if it belongs with an existing suite)
2. Prefer testing pure logic that doesn't require Homebrew, network access, or
   changes to the real machine — build any fixtures the test needs at runtime
   under a temp directory (see the existing `*.bats` files for the pattern)
3. Run `bats tests` locally to confirm it passes before opening a pull request
