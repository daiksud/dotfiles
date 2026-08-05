# ADR 0026: Manage Node.js and Bun with Vite+

Use Vite+ as the global owner of Node.js and Bun while retaining mise for the
repository's non-JavaScript development tools.

## Status

Accepted

## Context

The repository previously installed Node.js and Bun from Homebrew and also
declared Bun in `mise.toml`. This gave the same JavaScript toolchain multiple
owners. It also left Vite, package-manager, and runtime commands on separate
installation and update paths.

Vite+ provides one global `vp` entry point for Node.js version management,
package-manager resolution, and web tooling. Its managed mode can select
Node.js per project and can download a declared Bun version for dependency
operations.

Several constraints affect how Vite+ is adopted:

- The Homebrew `vite-plus` formula exists, but depends on Homebrew `node`.
  Installing that formula would preserve the duplicate Node.js owner that this
  change is intended to remove.
- `vp env setup` creates the Node.js-related shims but not a global `bun`
  command. Bun must be installed as a Vite+-managed global package if direct
  `bun` and `bunx` commands are to remain available.
- mise is still the repository's source of truth for `bats`, `shellcheck`,
  Python, and rumdl. A mise postinstall hook that calls `vp` would break CI
  jobs that intentionally install only those tools.
- The repository supports both macOS and Codespaces. A Dev Container build
  runs as root, but its interactive user is `codespace`, so a per-user Vite+
  installation must target the latter user's home.

## Decision

Install Vite+ through its official installer in
`scripts/003-vite-plus.sh`. Enable managed mode, set the global Node.js
default to `lts`, and install `bun@latest` as a Vite+-managed global package
using Node.js LTS.

Use a rolling version policy:

- Vite+ follows the installer's `latest` release.
- Node.js follows the latest LTS release.
- The global Bun command follows `bun@latest`.
- The repository manifests declare Bun compatibility as `^1.3.14` through
  `devEngines.packageManager`.

Install root dependencies from the independent
`scripts/100-vite-plus-project.sh` script. Remove Bun from `mise.toml`, remove
the mise postinstall hook, and stop declaring Bun and Node.js in `Brewfile`.
Existing Homebrew installations are not force-uninstalled because Homebrew may
retain them for unrelated dependents.

Use the SHA-pinned `voidzero-dev/setup-vp` action for documentation CI. The
action provisions latest Vite+, Node.js LTS, and its cache; workflow steps run
an explicit frozen install and the Docusaurus package script through
`vp run build`. mise remains in the lint and test jobs.

Run the shared global setup script with `HOME=/home/codespace` while building
the Dev Container image, then transfer the resulting home directory to the
container user's UID and GID.

Vite+ currently has an upstream managed-`bunx` recursion issue in
[voidzero-dev/vite-plus#2123](https://github.com/voidzero-dev/vite-plus/issues/2123).
Repository commands must not use `bunx`; use `bun x` until the upstream fix is
released.

This ADR supersedes only the Bun provisioning portions of
[ADR 0011](./0011-ci-and-shell-testing.md). Its CI job split and use of mise
for lint and test tools remain accepted.

## Alternatives Considered

### Install the Homebrew `vite-plus` formula

Rejected because the formula has a required Homebrew `node` dependency. It
cannot make Vite+ the sole Node.js owner.

### Install Vite+ through mise's npm backend

Rejected because it installs the CLI as another mise tool rather than adopting
the official managed runtime environment and global shims.

### Keep Homebrew and mise runtimes, then add only `vp`

Rejected because Node.js and Bun would continue to have overlapping owners and
PATH precedence would remain ambiguous.

### Use Vite+ system-first mode

Rejected because `VP_NODE_MANAGER=no` and `vp env off` prefer the existing
system Node.js, contrary to the full-ownership goal.

### Pin exact Vite+, Node.js, and Bun versions

This provides stronger reproducibility, especially for CI, but requires
explicit version maintenance. The rolling policy was selected so setup reruns
track upstream releases automatically.

## Consequences

- Vite+ shims take precedence after Zsh initialization.
- Direct `bun` and `bunx` commands remain available but are owned by Vite+.
- Projects can resolve a compatible managed Bun independently of the global
  Bun version.
- mise remains independent of Vite+ and can provision lint/test CI by itself.
- Setup and CI can change behavior when upstream rolling versions change.
- A compatible cached Bun may continue satisfying `^1.3.14` until Vite+
  needs to resolve another version.
- Removing formulas from `Brewfile` does not delete existing installations.
- The managed `bunx` limitation must be considered until its upstream fix is
  released.
