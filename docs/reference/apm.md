---
sidebar_position: 1
---

# APM

[APM](https://microsoft.github.io/apm/) manages AI agent packages and deploys
their primitives to supported harnesses. This repository installs the APM CLI
with Homebrew and maintains a global consumer manifest for GitHub Copilot CLI
and OpenAI Codex CLI. Agent skills and instructions are authored in
[daiksud/agents](https://github.com/daiksud/agents).

## Managed configuration

| Location | Owner | Purpose |
| --- | --- | --- |
| `dotfiles/apm/apm.yml` | This repository | Canonical global consumer manifest |
| `~/.apm/apm.yml` | Bootstrap script | Symbolic link to the canonical manifest |
| `~/.apm/apm.lock.yaml`, `config.json`, caches, modules, lifecycle files | APM | Local runtime state; not version controlled |
| `daiksud/agents` | Its repository | APM package containing skills and instructions |

`install.sh` links the canonical global manifest into `~/.apm/`.
`scripts/100-apm.sh` verifies the link, then runs:

```bash
apm install --global
apm compile --global
```

The manifest pins `daiksud/agents` to an immutable commit. APM owns the
runtime lockfile it creates under `~/.apm/`, while the agents repository owns
the package source and its update history.

## Package ownership

Do not add skills or instructions under `dotfiles/`. Add and version them in
[`daiksud/agents`](https://github.com/daiksud/agents) using its `.apm/` source
tree. After publishing a new commit there, update the pinned dependency in
`dotfiles/apm/apm.yml`.

`apm install --global` deploys primitives supported natively by each target.
`apm compile --global` renders root-context files for unscoped package
instructions on targets such as Codex.

## First-run migration

When `~/.apm/apm.yml` already exists outside this
dotfiles setup, the script copies it to a private directory under:

```text
~/.apm/backups/dotfiles-apm-*/
```

It then activates the canonical manifest as a symbolic link and writes an
ownership marker. Later runs replace only the managed manifest and do not
create additional backups.
The script never removes `config.json`, caches, modules, lifecycle state, or
unrelated skills.

## Updating the dependency

1. Commit and push the primitive change in
   [`daiksud/agents`](https://github.com/daiksud/agents).
2. Update the commit SHA for `daiksud/agents` in `dotfiles/apm/apm.yml`.
3. Rerun `install.sh` to replace the global manifest and install the new
   package revision.
