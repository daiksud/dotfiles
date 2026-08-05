# Vite+

This page describes how Vite+ owns Node.js and Bun across the local machine,
repository commands, CI, and Codespaces.

## Ownership

| Concern | Owner |
| --- | --- |
| Vite+ CLI and Node.js | Vite+ official installer |
| Global `bun` and `bunx` commands | Vite+ global packages |
| Project Bun version | `devEngines.packageManager` resolved by Vite+ |
| Lint and test tools | mise |
| General CLI and GUI packages | Homebrew |

[`scripts/003-vite-plus.sh`](https://github.com/daiksud/dotfiles/blob/main/scripts/003-vite-plus.sh)
installs the latest Vite+, enables managed mode, selects Node.js LTS as the
global default, and installs the latest global Bun through Vite+.

[`scripts/100-vite-plus-project.sh`](https://github.com/daiksud/dotfiles/blob/main/scripts/100-vite-plus-project.sh)
then performs a frozen dependency install at the repository root.

## Version policy

The global toolchain intentionally follows rolling versions:

| Tool | Policy |
| --- | --- |
| Vite+ | `latest` |
| Node.js | `lts` |
| Global Bun | `latest` |
| Repository Bun | `^1.3.14` |

A compatible Bun already present in Vite+'s package-manager cache can continue
to satisfy the repository range. The global Bun installation is managed
separately and is refreshed when the setup script runs.

## Shell integration

The official installer writes environment files below `~/.vite-plus` and may
configure detected shells. For example, it can update `~/.zshenv` and create
Fish's `conf.d/vite-plus.fish`.

The tracked `dotfiles/zshrc` also sources `~/.vite-plus/env` when that file
exists. It does so after mise activation, which gives Vite+ runtime shims PATH
precedence.

After running the setup script in an existing shell, load the generated
environment without restarting:

```bash
. "$HOME/.vite-plus/env"
```

## Inspecting the environment

```bash
vp --version
vp env current
vp env doctor
vp list -g bun
command -v vp node bun bunx
```

`vp env on` enables managed mode. `vp env off` switches to system-first mode
without uninstalling Vite+, but system-first mode is not the configuration
managed by these dotfiles.

Rerun the global setup to update rolling versions:

```bash
bash scripts/003-vite-plus.sh
```

## Project commands

Use Vite+ to select and invoke the declared package manager:

```bash
vp install --frozen-lockfile
vp run docs:build
```

`vp run <name>` explicitly runs a package script. This distinction matters for
names such as `build`, because `vp build` invokes Vite+'s built-in build command
instead. The root documentation wrappers use Vite+'s `-C` option to target the
`.docusaurus` project without nesting an ambiguous `vp run` command.

## Known `bunx` limitation

Vite+ currently has an upstream managed-`bunx` recursion issue in
[voidzero-dev/vite-plus#2123](https://github.com/voidzero-dev/vite-plus/issues/2123).
Use `bun x` instead of `bunx` until the upstream fix is released. Repository
scripts do not invoke `bunx`.

## Existing Homebrew installations

Node.js and Bun are no longer declared in `Brewfile`, but `brew bundle` does
not remove formulas that are already installed. Homebrew may also retain
Node.js as a dependency of another formula. Vite+'s PATH precedence makes its
managed runtime active without destructively removing those installations.

See [ADR 0026](../development/99-adr/0026-vite-plus-toolchain.md) for the
decision and rejected alternatives.
