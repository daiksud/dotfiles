# gh-infra

This is the reference for declarative repository settings management with `.github/settings.yml`.

## Overview

[gh-infra](https://github.com/babarot/gh-infra) (`babarot/gh-infra`) is a GitHub CLI extension for declaratively managing GitHub repository settings in YAML. It is similar to Terraform, but does not require a state file because GitHub itself serves as the source of truth.

In this repository, labels, merge strategies, branch protection (rulesets), security settings, and more are described in `.github/settings.yml` and managed in a reproducible form without manually operating the UI.

## File

`.github/settings.yml` (placed directly in the repository, not as a symbolic link)

## Key settings

These are the main items defined under `spec` in `.github/settings.yml`.

| Section          | Contents                                                                                |
| ---------------- | --------------------------------------------------------------------------------------- |
| `labels`         | Definitions for Issue / PR labels (name, description, color)                            |
| `features`       | Enable / disable `issues`, `projects`, `wiki`, `discussions`, and `pull_requests`      |
| `merge_strategy` | Allow only squash merges, and enable auto-merge and automatic branch deletion after merge |
| `security`       | Enable vulnerability alerts, automated security fixes, and private vulnerability reporting |
| `rulesets`       | Protection for the default branch (described below)                                     |
| `actions`        | Allowed scope for GitHub Actions and default `workflow_permissions`                     |

### Default branch ruleset

The following are enforced on the default branch through `rulesets`.

| Rule                       | Value   | Description                                     |
| -------------------------- | ------- | ----------------------------------------------- |
| `required_linear_history`  | `true`  | Disallow merge commits (enforce linear history) |
| `required_signatures`      | `true`  | Require signed commits                          |
| `non_fast_forward`         | `true`  | Disallow force pushes                           |
| `deletion`                 | `true`  | Disallow branch deletion                        |
| `creation`                 | `false` | Do not restrict branch creation                 |

> [!IMPORTANT]
> Because `required_linear_history` is enabled, you cannot push merge commits to the default branch. When integrating changes locally, use a fast-forward merge (`git merge --ff-only`).

## Setup

The `gh-infra` extension is installed automatically by `scripts/100-gh-extensions.sh` (see [Script list](./scripts.md)). To install it manually:

```bash
gh extension install babarot/gh-infra
```

## Usage

Review the diff with `plan`, then apply it with `apply`. Specify `.github/settings.yml` explicitly.

```bash
# Show the diff between the YAML and the current GitHub settings
gh infra plan .github/settings.yml

# Apply the diff (with confirmation prompt)
gh infra apply .github/settings.yml

# Validate the YAML syntax and schema
gh infra validate .github/settings.yml
```

Use `import` to export the settings of an existing repository as YAML.

```bash
gh infra import daiksud/dotfiles > .github/settings.yml
```

## Command list

| Command           | Description                                                |
| ----------------- | ---------------------------------------------------------- |
| `plan [path]`     | Show the diff between the YAML and the current GitHub settings |
| `apply [path]`    | Apply the diff (with confirmation prompt)                  |
| `import <repo>`   | Export the settings of an existing repository as YAML      |
| `validate [path]` | Validate the YAML syntax and schema                        |

## References

- [gh-infra repository](https://github.com/babarot/gh-infra)
- [gh-infra documentation](https://babarot.github.io/gh-infra/introduction/getting-started/)
- For the background behind this technology choice, see [ADR 0005](../development/99-adr/0005-gh-infra.md)
