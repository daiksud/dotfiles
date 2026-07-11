# ADR 0011: Add a CI workflow with bats-core tests and mise-provisioned lint tools

Add `.github/workflows/ci.yml` covering static checks, a bats-core test suite, and a Docusaurus build check, provisioning all lint/test tools through `mise` instead of separate marketplace actions.

## Status

Accepted

## Context

The repository previously had no CI beyond `.github/workflows/docs.yml`, which
only builds and deploys the documentation site after a push to `main`. There
was no automated verification of `install.sh`, the setup scripts, or the Zsh
plugins, and pull requests received no build feedback for documentation
changes either.

Several constraints shaped the design:

- `dotfiles/zsh/*.zsh` files use Zsh-only syntax (for example `${var:h}`,
  `${var:t}`, and `"$(<file)"`). `shellcheck` has no Zsh dialect, so running it
  against `.zsh` files produces false positives on syntax that is valid Zsh
  but not valid Bash/POSIX sh.
- `scripts/*.sh` perform real installs (Homebrew, apt, network downloads).
  Running them end-to-end on every push/PR would make CI slow and dependent on
  external services staying reachable.
- `dotfiles/zsh/starship-qwt-worktree.sh` is pure logic driven only by the
  local Git repository layout, and its behavior interacts with how Git
  resolves symlinks (`git rev-parse --show-toplevel` resolves them, e.g. macOS
  `/tmp` → `/private/tmp`), which was the root cause of a real bug fixed
  shortly before this ADR. That makes it — and `install.sh`'s symlink/migration
  logic — well suited to hermetic tests that don't touch the real machine.
- `mise.toml` already manages `bun` for the documentation build, and `docs.yml`
  already uses `jdx/mise-action@v4` to provision it.

## Decision

- Add `.github/workflows/ci.yml`, triggered on `push` to `main` and on every
  `pull_request`, with three jobs:
  - `lint` (`ubuntu-slim` only, since static checks are OS-agnostic and
    don't need a full-sized runner):
    `shellcheck` over the Bash/sh scripts (`install.sh`, `scripts/*.sh`,
    `dotfiles/zsh/starship-qwt-worktree.sh`), `zsh -n` over every
    `dotfiles/zsh/*.zsh` file, JSON syntax checks (`jq empty`) over
    `install_map.json`, `package.json`, and
    `dotfiles/copilot-hooks/rtk-rewrite.json`, and TOML syntax checks (Python's
    `tomllib`) over `mise.toml` and `dotfiles/starship.toml`.
  - `test` (matrix of `ubuntu-latest` and `macos-latest`): runs the new
    `bats-core` suite under `tests/`.
  - `docs-build` (`ubuntu-slim` only): builds the Docusaurus site
    (`bun run --cwd .docusaurus build`) without deploying, giving pull requests
    the build feedback that `docs.yml` only provides after merging to `main`.
    Uses `ubuntu-slim` to match the runner `docs.yml` already uses for the
    same build steps.
- Provision `bats`, `shellcheck`, and `python` (for `tomllib`) via `mise.toml`,
  the same way `bun` is already managed, and install them in CI with the
  existing `jdx/mise-action@v4` action. This keeps one source of truth for
  tool versions for both CI and local contributors (`mise install`), instead of
  adding a separate marketplace action per tool.
- Scope automated tests to hermetic, pure-logic behavior:
  `tests/starship_qwt_worktree.bats` (worktree label formatting, including
  subdirectories and slash-containing branch names), `tests/install_symlinks.bats`
  (copies the real `install.sh` into a temp sandbox with a fixture
  `install_map.json`, fixture `dotfiles/`, and an empty `scripts/` directory so
  no real installs run, then exercises symlink creation, idempotent re-runs,
  and the symlinked-parent-directory migration logic), and
  `tests/install_map.bats` (every `install_map.json` entry resolves to a real
  path under `dotfiles/`).

## Alternatives Considered

### Run shellcheck against `.zsh` files too

Rejected. `shellcheck` has no Zsh dialect option; forcing `--shell=bash` on
Zsh-only syntax like `${var:h}` and `"$(<file)"` produces false positives
rather than real findings. `zsh -n` (Zsh's own parse-only syntax check) is the
correct tool for `.zsh` files.

### Use `bats-core/bats-action` (or another per-tool marketplace action)

Works, but introduces a second, independent source of truth for tool versions
alongside `mise.toml`, and doesn't help local contributors run the same
version. Not adopted — `mise` already manages `bun` for this repository, and
its registry has entries for `bats`, `shellcheck`, and `python`, so extending
`mise.toml` keeps versioning and provisioning consistent everywhere.

### Run `scripts/*.sh` end-to-end as a CI smoke test

Would catch real installation regressions, but requires Homebrew/apt/network
access on every run, is slow, and is flaky when upstream installers or mirrors
are temporarily unavailable. Not adopted for now; manual verification on a
real machine remains the way to validate the install scripts themselves. A
scheduled or manually triggered smoke-test workflow could be added later as a
separate, explicit decision.

### Enforce shell formatting with `shfmt`

Not requested, and would immediately flag the existing scripts' formatting,
creating unrelated diff churn unconnected to behavior verification. Not
adopted.

## Consequences

- Pull requests now get automated feedback on shell script correctness (via
  `shellcheck`/`zsh -n`), config file syntax (JSON/TOML), the tested logic
  paths of `install.sh` and `starship-qwt-worktree.sh`, and whether the
  documentation site still builds.
- Contributors can run the same checks locally with `mise install` followed by
  `shellcheck`, `zsh -n`, `bats tests`, and `bun run --cwd .docusaurus build`
  (see [Testing](../04-testing.md)).
- `scripts/*.sh` real-install behavior is still only verified by hand on an
  actual macOS or Codespaces machine; CI does not catch regressions there.
- `mise.toml` gains `bats`, `shellcheck`, and `python` under `[tools]`.
