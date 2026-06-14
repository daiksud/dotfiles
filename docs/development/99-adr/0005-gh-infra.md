# ADR 0005: Manage repository settings declaratively with gh-infra

Manage repository settings as code using `.github/settings.yml` and the `gh-infra` extension.

## Status

Accepted

## Context

Managing repository labels, merge strategies, branch protection, and security settings manually in the GitHub Web UI has the following issues.

- Settings are not version-controlled, so it is impossible to track when and why they changed
- The same settings cannot be reproduced or migrated easily
- Changes are applied immediately without review or preview

We want to manage these declaratively while staying within the `gh` CLI ecosystem.

## Decision

Describe repository settings in YAML in `.github/settings.yml` and apply them with `gh-infra` (`babarot/gh-infra`).

- Run `gh extension install babarot/gh-infra` in `scripts/100-gh-extensions.sh`
- Review the diff with `gh infra plan` before applying it with `gh infra apply`
- Do not maintain a state file; treat GitHub's current state as the source of truth

## Alternatives Considered

### Terraform GitHub Provider

Considered — it is a standard choice for GitHub-as-Code, but it requires provider installation, HCL, state files, and state locking, which is too much overhead for a personal repository.

### Probot Settings / GitHub App approaches

Not adopted — they require operating a GitHub App or server, and they apply changes immediately without a `plan` preview.

### Manual management in the Web UI (status quo)

Not adopted — it provides no version control, reproducibility, or change history, so it does not satisfy the motivation of this ADR.

## Consequences

- `.github/settings.yml` becomes the source of truth for repository settings
- Installing the `gh-infra` extension becomes a prerequisite (automated in `scripts/100-gh-extensions.sh`)
- Configuration changes follow the `plan` → `apply` flow so the diff can be reviewed
- Because `required_linear_history` / `required_signatures` are enforced on the default branch, merge commits and unsigned commits cannot be pushed
- Operational guidance is documented in [reference/gh-infra.md](../../reference/gh-infra.md)
