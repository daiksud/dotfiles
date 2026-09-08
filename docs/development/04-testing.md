# Testing

This page explains the automated checks that run in CI and how to run each of them locally before opening a pull request.

## Overview

`.github/workflows/ci.yml` runs on every push to `main` and on every pull
request, with three jobs:

| Job | Runs on | Checks |
| ------------ | --------------------------------- | --------------------------------------------------------------------------------------- |
| `lint` | `ubuntu-slim` | rumdl Markdown lint, `shellcheck`, Zsh syntax, and JSON/TOML config syntax |
| `test` | `ubuntu-latest` and `macos-latest` | The `bats-core` suite under `tests/` |
| `docs-build` | `ubuntu-slim` | Builds the Docusaurus site (build only, no deploy) |

See [ADR 0011](./99-adr/0011-ci-and-shell-testing.md) for why the checks are
split this way, and what is intentionally left out (a full `scripts/*.sh`
real-install run).

## Running checks locally

Lint and test tools are managed by [mise](../reference/mise.md). Node.js, Bun,
and JavaScript dependencies are managed by
[Vite+](../reference/vite-plus.md). Install both tool groups with:

```bash
mise install
bash scripts/003-vite-plus.sh
. "$HOME/.vite-plus/env"
vp run docs:install
```

Then, from the repository root:

```bash
# Format Markdown
mise run markdown:format

# Markdown lint
mise run markdown:lint

# Shellcheck (Bash/sh scripts only — Zsh plugins use a different check below)
shellcheck install.sh scripts/*.sh dotfiles/ghostty/herdr-launch.sh

# Zsh syntax check (parse-only, no execution)
for f in dotfiles/zsh/*.zsh; do zsh -n "$f"; done

# Config file syntax
jq empty install_map.json package.json .docusaurus/package.json
python3 -c "import tomllib; [tomllib.load(open(f, 'rb')) for f in ['.rumdl.toml', 'mise.toml', 'dotfiles/starship.toml']]"

# bats test suite
bats tests

# Documentation build
vp run docs:install
vp run docs:build
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

- `tests/apm_global.bats` — `scripts/100-apm.sh` behavior, using a temporary
  repository, home directory, and stubbed APM binary: canonical global
  manifest/lockfile copying, the frozen global install invocation, first-run
  backup of unmanaged configuration, idempotent reruns, missing source
  failures, path-collision rejection, and APM failure propagation.
- `tests/gh_account.bats` — `dotfiles/zsh/gh-account.zsh` behavior, loaded in a
  non-interactive `zsh -c` subshell with a scratch mapping file
  (`GH_ACCOUNT_MAP_FILE`) so no real `gh` account or credential is touched:
  remote-URL normalization into a lowercase `<host>/<owner>/<repo>` identity
  (and rejection of unusable URLs), host-qualified owner derivation, creating,
  reading, updating, and forgetting mapping entries without disturbing the
  others, owner defaults, repository overrides and their precedence, scoped
  selection and fallback behavior, the `GIT_CONFIG_*` and token variables
  exported when an identity is applied, the extra `user.signingkey` entry plus
  `allowed_signers` upsert when the key file exists, clearing every exported
  variable outside Git or for a non-GitHub remote, and that an unmapped
  repository never prompts in a non-interactive shell. Cases build real
  temporary repositories to confirm that the `chpwd` hook applies an owner
  default across repositories, applies a repository override, and makes the
  injected environment configuration override leftover `git config --local`
  identity values.
- `tests/herdr_launch.bats` — `dotfiles/ghostty/herdr-launch.sh` behavior,
  with `herdr` and the login shell stubbed under a temp directory (via
  `HERDR_LAUNCH_BREW_BINS` and `SHELL`, so no real Homebrew install or herdr
  binary is required): resolving and launching herdr from a Homebrew-style
  bin directory, falling back to a login shell when herdr is not found, and
  falling back instead of nesting when already inside a herdr pane
  (`HERDR_ENV=1`).
- `tests/herdr_service.bats` — `scripts/100-herdr.sh` behavior with fake
  Homebrew and Herdr commands: platform gating, starting and verifying a
  missing service, preserving healthy protocol-compatible services, targeting
  the Homebrew-managed default session, refusing self-terminating handoffs from
  Herdr panes, handing off an incompatible server in the required order,
  serializing concurrent destructive decisions, preserving externally
  recovered services, restoring a stopped job after a query failure, and
  propagating a start failure.
- `tests/install_symlinks.bats` — `install.sh`'s ordinary symlink-creation
  logic and its APM-before-independent-`100-*` scheduling, exercised against a
  copy of the real script in an isolated sandbox.
- `tests/install_map.bats` — every `links` source resolves to a real path under
  `dotfiles/`, and destination values have the supported string or
  string-array shape.
- `tests/repository_select.bats` — `dotfiles/zsh/repository-select.zsh`
  behavior: the plugin parses as valid Zsh, and a missing `fzf` produces a
  clear, immediate error instead of a bare `command not found`.

### Adding a new test

1. Add a `<name>.bats` file under `tests/` (or a new `@test` block in an
   existing file, if it belongs with an existing suite)
2. Prefer testing pure logic that doesn't require Homebrew, network access, or
   changes to the real machine — build any fixtures the test needs at runtime
   under a temp directory (see the existing `*.bats` files for the pattern)
3. Run `bats tests` locally to confirm it passes before opening a pull request
