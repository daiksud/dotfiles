---
sidebar_position: 1
---

# APM

[APM](https://microsoft.github.io/apm/) manages AI agent packages and deploys
their primitives to supported harnesses. This repository installs the APM CLI
with Homebrew and maintains one global configuration for GitHub Copilot CLI and
OpenAI Codex CLI.

## Managed configuration

| Location | Owner | Purpose |
| --- | --- | --- |
| `dotfiles/apm/apm.yml` | This repository | Canonical APM manifest |
| `dotfiles/apm/apm.lock.yaml` | This repository | Pinned dependency and content hashes |
| `~/.apm/apm.yml` | Bootstrap script | Runtime copy of the canonical manifest |
| `~/.apm/apm.lock.yaml` | Bootstrap script and APM | Runtime lockfile copy |
| `~/.apm/config.json`, caches, modules, lifecycle files | APM | Local runtime state; not version controlled |

`scripts/100-apm.sh` copies the two canonical files to `~/.apm/` and runs:

```bash
apm install --global --frozen
```

The `--frozen` flag prevents the bootstrap from resolving newer dependencies.
It deploys the initial managed skill to:

```text
~/.agents/skills/skill-creator/
```

APM uses this shared skill location for both the `copilot` and `codex` targets,
so the skill is installed once rather than duplicated per harness.

## First-run migration

When `~/.apm/apm.yml` or `~/.apm/apm.lock.yaml` already exists outside this
dotfiles setup, the script copies those files to a private directory under:

```text
~/.apm/backups/dotfiles-apm-*/
```

It then activates the canonical configuration and writes an ownership marker.
Later runs replace only the two managed runtime copies and do not create
additional backups. The script never removes `config.json`, caches, modules,
lifecycle state, or unrelated skills.

## Updating managed packages

The initial package is
`anthropics/skills/skills/skill-creator`, pinned to an immutable commit in
`dotfiles/apm/apm.yml`. To add or update a managed package:

1. Update the canonical manifest with an explicit commit SHA.
2. Generate and review a new canonical `apm.lock.yaml` in an isolated `HOME`
   using the final manifest and `apm install --global`.
3. Commit both files. The next `install.sh` copies them into `~/.apm/` and
   deploys the exact locked content.

Do not run an unfrozen update against `~/.apm/` as the way to manage this
configuration: its result is runtime state and will be replaced by the
canonical files during the next dotfiles installation.
