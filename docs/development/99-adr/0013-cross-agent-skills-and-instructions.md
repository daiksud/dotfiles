# ADR 0013: Share Agent Skills and instructions across coding agents

Use product-neutral canonical files with thin adapters so GitHub Copilot,
Codex, and Claude Code follow the same skills and instructions.

## Status

Accepted

## Context

The repository originally installed its skills and personal instructions only
into GitHub Copilot paths. The skill procedures themselves use the portable
Agent Skills `SKILL.md` format, but Codex and Claude Code discover skills from
different directories. Each agent also has different conventions for personal,
repository, and path-scoped instructions.

Maintaining independent copies would allow safety rules and PR workflows to
drift. Linking an entire skill root is also unsafe: an agent may keep built-in
or independently installed skills in that directory, and replacing the root
would hide or remove them. Hooks, manifests, permissions, and similar
integrations cannot be normalized in the same way because their schemas and
execution models are product-specific.

## Decision

Adopt a canonical-plus-adapter architecture:

- `dotfiles/skills/` is the only maintained source for shared Agent Skills.
  `install.sh` creates a link for each individual skill under
  `~/.agents/skills/` for GitHub Copilot and Codex, and under
  `~/.claude/skills/` for Claude Code. Missing destination roots are created as
  real directories, and an existing root is never replaced wholesale.
- `dotfiles/agent-instructions.md` is the only maintained source for personal
  instructions. It is linked to `~/.copilot/copilot-instructions.md`,
  `~/.codex/AGENTS.md`, and `~/.claude/CLAUDE.md`.
- The former `dotfiles/copilot-instructions.md` source remains as a thin
  migration adapter so an existing Copilot link is not left dangling between
  pulling the repository and rerunning the installer. New installs do not
  target that adapter.
- Root `AGENTS.md` is the canonical repository instruction file. Root
  `CLAUDE.md` and `.github/copilot-instructions.md` are thin adapters that
  import or point to it instead of duplicating its rules.
- `.github/workflows/AGENTS.md` is the canonical path-scoped instruction file
  for GitHub Actions workflows. `.github/instructions/actions.instructions.md`
  and `.claude/rules/github-actions.md` are thin Copilot and Claude adapters.
- `install_map.json` accepts either a string or an array of strings for each
  `links` value. A separate top-level `skill_targets` array declares skill
  discovery roots, and the installer expands it into per-skill links.
- Shared skills and instructions use product-neutral capability language.
  Product-specific hooks, manifests, permission settings, and integrations
  remain in vendor-specific files.

Canonical files hold policy and procedure. Adapters contain only the minimum
syntax required to make a product load the nearest canonical file.

## Alternatives Considered

### Keep GitHub Copilot as the source and add product-specific copies

This is straightforward initially, but every policy or workflow change would
need to be applied consistently in three places. Silent drift is especially
risky for worktree safety and PR automation, so this was not adopted.

### Link the complete canonical skills directory into every product

This would make installation simple, but it would replace each product's skill
root. Built-in, system, or separately installed skills could be hidden or
removed, so only per-skill links are created.

### Generate every adapter from canonical files

Generation can support products that cannot import another file, but it adds a
build step and generated-file synchronization checks. The current products can
use small checked-in adapters, so generation is not needed now.

### Force hooks and manifests into one common format

The products do not share compatible schemas or lifecycle semantics for these
features. A common wrapper would obscure product behavior without removing the
need for vendor-specific configuration, so these files remain separate.

## Consequences

- Skill procedures, personal guidance, repository rules, and workflow-specific
  rules each have one clear source of truth.
- GitHub Copilot gives a same-named skill under `~/.copilot/skills/` priority
  over the shared `~/.agents/skills/` copy. Because independently managed
  Copilot content is preserved, users must remove or rename a conflicting
  entry when they want the canonical shared skill.
- Installing one canonical personal file to multiple paths requires
  string-array values in `links`.
- Installing skills requires dedicated `skill_targets` processing and tests
  that verify unrelated destination entries are preserved.
- Skill authors must avoid product-specific invocation syntax and provide
  capability-based fallbacks when an optional helper is unavailable.
- Thin adapters must be kept valid for their host products, but ordinary rule
  changes are made only in the canonical file.
- Existing Copilot personal links continue through the compatibility adapter
  until the installer replaces them with a direct canonical link.
- Vendor-specific hooks and manifests still require separate maintenance and
  testing.
- A shared skill change should be exercised in GitHub Copilot, Codex, and
  Claude Code when it affects discovery or host-dependent behavior.
