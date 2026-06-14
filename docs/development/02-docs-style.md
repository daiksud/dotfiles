# Documentation Style

This page defines the documentation writing rules for this repository.

## Section Structure Based on Diátaxis

Everything under `docs/` is organized according to the four quadrants of the [Diátaxis framework](https://diataxis.fr/).

| Diátaxis Quadrant | Section                                            | Content                                |
| ----------------- | -------------------------------------------------- | -------------------------------------- |
| Tutorial          | `guides/01-quick-start.md`                         | Guided, hands-on documentation with a learning goal |
| How-to Guide      | `guides/02-*` to `guides/04-*`                     | Task-oriented procedures               |
| Reference         | `reference/`                                       | Comprehensive specification            |
| Explanation       | `guides/04-git-identity.md`, `development/99-adr/` | Design philosophy, background, and decisions |

## Basic Page Structure

Every page begins with a `# h1` title, followed immediately by a one-sentence summary of what the page covers.

```md
# Page Title

Explain in one sentence what the reader will learn on this page.

## First Section

...
```

## File Names and Ordering

- The entry point for a section is `README.md` (or `README.mdx`)
- Individual pages use sequential numbering such as `01-topic.md` and `02-topic.md`
- Section directories directly under `docs/` do not use numeric prefixes

## How to Write Links

Links between documents must be written using **relative paths with the `.md` extension**.

```md
<!-- ✅ Correct -->

[Quick Start](../guides/01-quick-start.md)

<!-- ❌ Incorrect -->

[Quick Start](/guides/quick-start)
```

## Using Diagrams

Use Mermaid to illustrate flows and architecture.

````md
```mermaid
graph LR
  A[install.sh] --> B[parse_links]
  B --> C[Create symlink]
```
````

## Writing Markdown

- Always specify a language name for code blocks
- Wrap paths, commands, and identifiers in backticks
- For notes and warnings, use GitHub Alerts syntax instead of `> **Note**:`

  ```md
  > [!NOTE]
  > Supplementary information

  > [!WARNING]
  > Information that requires caution

  > [!IMPORTANT]
  > Important information
  ```

- Do not prefix example commands with `$`

## Writing Japanese

- Use polite Japanese style consistently (`desu/masu` style)
- Avoid making individual sentences too long
- Instead of ambiguous wording, fully describe the actual operation or result

## Documentation Strategy

Keep code and documentation in sync at all times.

### Principles

- When you change code or configuration, update the related documentation **in the same commit or the same PR**
- Do not postpone documentation updates until later. A code change and its documentation update are complete only when both are done together
- Record important technical decisions as ADRs under `99-adr/`

### Checklist for Changes

When making changes, check the following:

1. **Follow-up check** — Are there documentation pages that mention the feature or setting you changed?
2. **Accuracy** — Has any existing explanation become outdated, and are the example commands still correct?
3. **Coverage** — Are new features and options documented in the reference?
4. **Link integrity** — Did a file rename or directory move create any broken links?

### Scope

| Change                           | Documentation to review                                                               |
| -------------------------------- | -------------------------------------------------------------------------------------- |
| Changes to `install_map.json`    | `reference/install-map.md`, `guides/03-managing-links.md`                             |
| Adding or removing tools         | `reference/tools.md`, the corresponding individual reference pages                     |
| Changes to scripts               | `reference/scripts.md`                                                                 |
| Adding or changing skills        | `reference/skills.md`, `guides/06-skills.md`, `development/03-skills-development.md`  |
| Changes to Docusaurus settings   | `.docusaurus/README.md`                                                                |
