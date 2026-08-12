# 0029: Use owner defaults with repository overrides for GitHub accounts

Use a host-qualified owner mapping by default while retaining explicit repository exceptions.

## Status

Accepted

## Context

[ADR 0020](./0020-central-gh-account-mapping.md) centralized GitHub account
credentials in the user-level `gh` configuration and recorded the chosen
account per `<host>/<owner>/<repo>` in `repos.json`. That eliminated
per-checkout credential stores and local Git identity drift, but it still asks
for the same account once for every repository owned by the same organization
or user.

Most owners use one account across all of their repositories. A few
repositories legitimately need another account, such as a release repository
or a customer-owned fork. The mapping therefore needs a shared default without
removing the ability to express a repository-specific exception.

Existing local mapping files contain only flat repository keys. A new storage
format or automatic migration would make an otherwise compatible behavior
change riskier and would need to distinguish old repository entries from newly
created explicit overrides.

## Decision

- Keep `~/.config/gh/repos.json` and `GH_ACCOUNT_MAP_FILE` unchanged. Store
  owner defaults at canonical lowercase `<host>/<owner>` keys and optional
  repository overrides at `<host>/<owner>/<repo>` keys in the same flat JSON
  object.
- Resolve a repository override first, then its owner default. Both key forms
  include the host, so GitHub.com and each GitHub Enterprise Server remain
  independent.
- Make `gh-account-select` and its `ghu` alias select the current owner by
  default. Support `--repo` for a repository override and `--owner` for an
  explicit owner selection. The automatic picker for an unmapped repository
  uses the owner scope.
- Scope `--forget` the same way: the default removes the owner default, and
  `--repo --forget` removes only the repository override. After either
  operation, resolve and apply the current repository again without prompting,
  so any remaining higher-priority or fallback mapping takes effect
  immediately.
- Keep old repository entries valid as overrides. Do not add a schema version,
  migration command, or startup migration to the plugin.
- Run a one-time local migration outside the repository implementation. Back
  up the user's `repos.json`, then consolidate a group into an owner default
  only when every repository entry for that host and owner has identical
  `login`, `name`, and `email` values. Leave conflicting groups unchanged.
- Preserve ADR 0020's user-level `gh` credentials, shell-scoped `GH_TOKEN`,
  environment-injected Git identity, signing-key handling, and separation from
  `COPILOT_GITHUB_TOKEN`.

## Alternatives Considered

### Keep repository-only mappings

This keeps every choice explicit and needs no precedence rule, but repeats the
same picker interaction and mapping data for every repository of an owner. It
was rejected because the common case is one account per owner.

### Use owner-only mappings

This minimizes mapping data, but cannot safely represent repositories that
must use another account. It was rejected because users need an explicit
exception mechanism.

### Introduce nested `owners` and `repositories` JSON objects

Separate top-level objects would make the distinction visually explicit, but
would break direct compatibility with existing flat files and require durable
migration state. It was rejected in favor of unambiguous key lengths in the
existing JSON object.

### Infer a default from conflicting existing entries

Selecting a majority account could silently change a repository that was
intentionally configured differently. It was rejected; the one-time local
migration only consolidates fully identical groups.

## Consequences

- Entering a second repository for an already mapped owner no longer prompts
  for an account.
- A repository override remains independent even when it currently names the
  same account as its owner; a later owner change does not overwrite that
  explicit choice.
- Existing repository entries remain active as overrides until users remove
  them or consolidate them locally.
- `repos.json` remains safe to inspect and edit manually because it contains
  only account metadata, not tokens.
- ADR 0020 is superseded by this ADR. Its central credential and
  shell-environment design remains part of the current implementation unless
  this ADR changes it explicitly.
