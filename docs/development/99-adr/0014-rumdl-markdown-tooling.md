# ADR 0014: Use rumdl for Markdown Formatting and Linting

Use one mise-managed rumdl installation to format and lint every Markdown file,
with tables standardized on the MD060 `compact` style.

## Status

Accepted

## Context

The repository contained tables whose columns were padded to different visual
widths. Editing one long cell could therefore change spacing across every row,
creating noisy diffs without changing rendered output. There was also no
repository-wide Markdown formatter or CI lint check to prevent styles from
drifting again.

Table formatting can be enforced with markdownlint's MD060 rule, while general
formatting is often delegated to Prettier. That combination requires two tools,
two dependency and configuration paths, and coordination where their fixes
overlap. The repository already uses mise to give local development and CI the
same tool versions.

## Decision

Adopt rumdl as the only repository Markdown formatter and linter.

- Pin rumdl `0.2.44` in `mise.toml`.
- Keep repository-wide rules in `.rumdl.toml` and parse Markdown as GitHub
  Flavored Markdown, with MDX enabled for `*.mdx`.
- Enable the opt-in MD060 rule in its `compact` mode. Compact tables keep one
  space around cell content without padding columns to equal widths.
- Disable only MD013 for line length and MD034 for bare URLs. Long command,
  path, and URL lines are intentionally preserved where wrapping would make
  them harder to copy or maintain.
- Keep MD033 enabled and allow only the `<details>` and `<summary>` elements.
  Parse JSX components in `.mdx` files as MDX rather than raw HTML.
- Require fenced code blocks through MD046, and do not keep per-file rule
  exceptions. Existing documents and instruction adapters conform to the same
  repository-wide rules.
- Provide `mise run markdown:format` for automatic fixes and
  `mise run markdown:lint` for non-mutating validation.
- Run the lint task in the existing CI lint job.
- Ignore rumdl's local cache directory.

## Alternatives Considered

### Use markdownlint and Prettier

This provides familiar JavaScript tooling, but it splits lint and formatting
between two programs. Their dependency updates, configuration, file discovery,
and overlapping fixes would need to remain synchronized. A single rumdl binary
provides both functions and the required MD060 behavior, so the two-tool option
was not adopted.

### Keep aligned tables

Aligned tables can be easier to scan in plain text, but their padding makes
unrelated rows change when a cell width changes and produces very wide source
lines. The compact style keeps cell boundaries clear while minimizing diff
noise, so aligned tables were not retained.

### Add linting without a formatter

A check alone would identify inconsistent tables but require contributors to
repair spacing manually. Because MD060 compact violations are safely fixable,
the repository exposes rumdl's formatter as the normal editing workflow.

## Consequences

- Markdown tables have a stable compact representation across documentation,
  instructions, skills, and repository metadata.
- Contributors need only one command to format Markdown and one command to
  reproduce the CI lint check.
- CI installs the pinned rumdl release through mise and rejects formatting or
  lint drift.
- A rumdl version update may change formatter output and must be reviewed as a
  deliberate repository-wide tooling change.
- The initial adoption touches many Markdown files mechanically even though
  their rendered table content is unchanged.
