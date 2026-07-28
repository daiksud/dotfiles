# ADR 0013: Share Agent Skills and instructions across coding agents

Use product-neutral canonical files with host-compatible imports or verified
inline mirrors so GitHub Copilot, Codex, and Claude Code follow the same skills
and instructions.

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

Adopt a canonical-plus-delivery architecture:

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
  `CLAUDE.md` imports it. Copilot Code Review requires instructions inline in
  `.github/copilot-instructions.md`, so that file is a checked-in exact mirror
  guarded by `tests/agent_configuration.bats`.
- `.github/workflows/AGENTS.md` is the canonical path-scoped instruction file
  for GitHub Actions workflows. `.claude/rules/github-actions.md` imports it.
  The body of `.github/instructions/actions.instructions.md`, after its
  required Copilot frontmatter, is a checked-in exact mirror guarded by the
  same synchronization test.
- `install_map.json` accepts either a string or an array of strings for each
  `links` value. A separate top-level `skill_targets` array declares skill
  discovery roots, and the installer expands it into per-skill links.
- Existing `~/.copilot`, `~/.codex`, and `~/.claude` directory symlinks are
  preserved so the shared personal instructions are installed through a
  deliberately relocated or synced configuration root.
- Shared skills and instructions use product-neutral capability language.
  Product-specific hooks, manifests, permission settings, and integrations
  remain in vendor-specific files.

Canonical files hold policy and procedure. A product uses an import adapter
when it supports one; otherwise it receives an inline mirror whose equality is
enforced by tests.

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
script and another contributor step. Because Copilot Code Review consumes the
checked-in files, generated output would still need to be committed. A small
exact-content test catches drift without adding a generator.

### Use import syntax in every product-specific file

Claude supports importing the canonical files, but Copilot Code Review reads
its recognized repository and path-specific instruction files as
natural-language Markdown and does not promise to dereference an `@` import or
a Markdown link. This would silently omit repository and immutable-action
guidance during review, so Copilot receives inline mirrors.

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
- Canonical rule changes require updating the corresponding Copilot mirror;
  the Bats synchronization test fails if either mirror drifts.
- Existing Copilot personal links continue through the compatibility adapter
  until the installer replaces them with a direct canonical link.
- Relocated Copilot, Codex, and Claude configuration roots remain symlinks
  during installation. Dangling links and links to non-directories stop safely
  without being replaced.
- Vendor-specific hooks and manifests still require separate maintenance and
  testing.
- A shared skill change should be exercised in GitHub Copilot, Codex, and
  Claude Code when it affects discovery or host-dependent behavior.
