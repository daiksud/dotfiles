# Agent Personal Instructions

## Herdr subagent fan-out

- When deploying one or more subagents while `HERDR_ENV=1`, use the
  `herdr-subagents` skill instead of the host's in-process or background
  subagent facility. It assigns each subagent a Herdr pane or tab, preserves
  the caller's focus, collects the results, and safely cleans up the layout.
- For a `copilot` subagent, require a nonempty parent
  `COPILOT_GITHUB_TOKEN` and inject it through the secure temporary Zsh
  bootstrap defined by `herdr-subagents`. Pass only its non-secret `ZDOTDIR`
  path to Herdr; never put the token in command arguments, output, prompts, or
  persistent files. Do not log in, select another user, or change the GitHub
  host.
- If the current shell is not Herdr-managed, the `herdr` CLI is unavailable,
  or the requested agent cannot start, use the host's native subagent facility
  instead and state the fallback reason. Never control a Herdr session from
  outside a Herdr-managed pane.

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

When posting a comment or reply on an Issue or Pull Request at the user's instruction, always prefix it with `:robot:`.
