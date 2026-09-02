# Agent Personal Instructions

## Commit messages

- Follow the repository's commit-message convention and language. When the
  repository has no convention, use a concise imperative subject.
- Every agent-created commit needs a rationale body; a subject alone is never
  acceptable.
- For a non-trivial commit, include non-empty `Context:`, `Decision:`,
  `Considerations:`, and `Impact:` paragraphs.
  - `Context:` explains the problem, trigger, or constraint.
  - `Decision:` explains what was adopted.
  - `Considerations:` explains options, trade-offs, and risks weighed before
    deciding.
  - `Impact:` explains the resulting constraints, follow-up work, or behavior
    readers must account for.
- A trivial dependency bump, formatter-only change, or typo fix may use a
  one- or two-sentence rationale instead of the labels, but it still must
  explain why the change was made.

## Pull Request skills

Use the matching skill for Pull Request requests:

- Create, open, prepare, or draft a PR: `pr-create`
- Fix, improve, or make a PR mergeable: `pr-fix`
- Merge a ready PR: `pr-merge`

Invoke the skill from the checkout where the request was made.

## Comments on Issues / Pull Requests

When posting a comment or reply on an Issue or Pull Request at the user's
instruction, consult the local GitHub comment policy at
`$XDG_CONFIG_HOME/dotfiles/agent.toml`, or
`~/.config/dotfiles/agent.toml` when `XDG_CONFIG_HOME` is unset. Look up the
base repository organization under `[github.comment_prefixes]`. If it has a
configured prefix, prepend that value and a single space to the comment body.
If no prefix is configured, do not add an organization-specific prefix. If the
file exists but cannot be read or parsed, stop before posting and report the
configuration error.
