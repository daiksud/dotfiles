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

All lint/test tools are managed by [mise](../reference/mise.md), the same way
`bun` is. Install them once with:

```bash
mise install
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

- `tests/agent_configuration.bats` — the root and GitHub Actions canonical
  `AGENTS.md` files, exact synchronization of their inline Copilot mirrors,
  the Claude import adapters, and the legacy personal Copilot adapter's
  forward reference to canonical personal instructions.
- `tests/gh_account.bats` — `dotfiles/zsh/gh-account.zsh` behavior, loaded in a
  non-interactive `zsh -c` subshell with a scratch mapping file
  (`GH_ACCOUNT_MAP_FILE`) so no real `gh` account or credential is touched:
  remote-URL normalization into a lowercase `<host>/<owner>/<repo>` identity
  (and rejection of unusable URLs), creating, reading, updating, and forgetting
  mapping entries without disturbing the others, the `GIT_CONFIG_*` and token
  variables exported when an identity is applied, the extra `user.signingkey`
  entry plus `allowed_signers` upsert when the key file exists, clearing every
  exported variable outside Git or for a non-GitHub remote, and that an
  unmapped repository never prompts in a non-interactive shell. Two cases build
  a real temporary repository to confirm that the `chpwd` hook function applies
  a mapped account and that the injected environment configuration overrides
  leftover `git config --local` identity values.
- `tests/herdr_launch.bats` — `dotfiles/ghostty/herdr-launch.sh` behavior,
  with `herdr` and the login shell stubbed under a temp directory (via
  `HERDR_LAUNCH_BREW_BINS` and `SHELL`, so no real Homebrew install or herdr
  binary is required): resolving and launching herdr from a Homebrew-style
  bin directory, falling back to a login shell when herdr is not found, and
  falling back instead of nesting when already inside a herdr pane
  (`HERDR_ENV=1`).
- `tests/install_symlinks.bats` — `install.sh`'s symlink-creation logic,
  exercised against a copy of the real script in an isolated sandbox (fixture
  `install_map.json` and `dotfiles/`, empty `scripts/` so no real installs
  run): single- and multi-destination link creation, per-skill links into every
  `skill_targets` root, idempotent re-runs, preservation of unrelated skills,
  resolving relative parent links, converting valid symlinked parents while
  migrating their contents, preserving valid Copilot, Codex, and Claude
  configuration-root links, and preserving dangling or non-directory parent
  links on failure. Failure cases cover invalid JSON, invalid skill-target
  schema, and path-resolution helper errors before cleanup. Migration tests
  also verify that the legacy Copilot skill link remains available until every
  replacement link succeeds, throughout those failures, and whenever a
  whole-directory replacement alias may depend on it. They also verify
  idempotent re-runs of that alias case and that an empty skill-target list
  does not remove the only legacy discovery path.
- `tests/install_map.bats` — every `links` source resolves to a real path under
  `dotfiles/`, destination values have the supported string or string-array
  shape, the shared personal instruction destinations are present, and skill
  targets include the common and Claude discovery roots using valid paths.

### Adding a new test

1. Add a `<name>.bats` file under `tests/` (or a new `@test` block in an
   existing file, if it belongs with an existing suite)
2. Prefer testing pure logic that doesn't require Homebrew, network access, or
   changes to the real machine — build any fixtures the test needs at runtime
   under a temp directory (see the existing `*.bats` files for the pattern)
3. Run `bats tests` locally to confirm it passes before opening a pull request
