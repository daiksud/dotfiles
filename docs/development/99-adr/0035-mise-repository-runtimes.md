---
type: Decision
description: Discontinue Vite+ and manage repository-required Node.js and Bun with mise.
---

# ADR 0035: Manage repository runtimes with mise

## Status

Accepted. Supersedes [ADR 0026](./0026-vite-plus-toolchain.md) and the runtime
provisioning portions of [ADR 0011](./0011-ci-and-shell-testing.md).

## Context

The owner wants to discontinue Vite+ and manage tools required by this
repository with mise. Docusaurus still requires Node.js `>=24.0`, and the root
and documentation projects already use Bun dependency lockfiles. Removing the
runtime provider alone would break bootstrap, Codespaces, and documentation CI.

Homebrew continues to manage the existing CLI formulas. Its no-Cask policy and
existing installations remain unchanged.

## Decision

Declare Node.js `lts` and Bun `latest` in the repository's `mise.toml`, alongside
existing lint and test tools. Record resolved versions and platform downloads
in `mise.lock`. The initial runtime lock selects Node.js 24.21.0 and Bun 1.4.2.

Use direct Bun commands for dependency installation and package scripts,
preserving both existing Bun lockfiles. Remove Vite+'s package-manager download
metadata from the manifests. Documentation CI uses the existing SHA-pinned
mise-action to install Node.js and Bun from the root config and lock, followed
by a frozen dependency install and the Docusaurus build.

Keep runtime provisioning and the frozen root dependency install in
`scripts/100-mise.sh`, in that order and from the repository root. Do not attach
a package-install postinstall hook to mise. The Dev Container preinstalls tools
from the same config and lock into its existing shared mise data directory.

Remove both Vite+ setup scripts and tracked Zsh Vite+ environment sourcing.
Runtimes are selected within this repository through mise shell activation or
`mise exec`; repository setup does not set global runtime defaults.

## Alternatives Considered

### Restore Homebrew Node.js and Bun provisioning

This would retain a separate runtime owner from repository lint and test tools.
The owner selected mise for tools required by this repository.

### Replace Bun with another package manager

This would require a dependency-lock migration without helping the Vite+
removal goal. Bun remains the package manager.

### Run provisioning and dependency installation in separate parallel scripts

This would allow dependency installation to start before runtimes are ready.
One script expresses the required order without changing the installer scheduler.

## Consequences

- Contributors, CI, and Codespaces use the same repository runtime declarations.
- Dependency installs fail on lockfile disagreement instead of updating dependencies.
- mise activation no longer competes with tracked Vite+ PATH initialization.
- Existing Vite+ software and installer-written shell settings are not uninstalled
  or modified by this change; they remain outside repository management.
- Global runtime defaults can still be configured separately by the user.
