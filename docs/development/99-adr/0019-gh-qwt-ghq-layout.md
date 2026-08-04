# 0019: Follow gh-qwt's ghq-compatible layout

Adapt the shell, prompt, and tooling integrations to the ghq-compatible
directory layout introduced by gh-qwt v0.16.0, instead of the previous `.bare`
repository layout.

## Status

Accepted

## Context

[ADR 0008](./0008-gh-qwt.md) adopted [gh-qwt](https://github.com/daiksud/gh-qwt)
as the single tool for cloning repositories and managing per-branch worktrees.
Its original layout placed everything below one qwt root:
`<qwt_root>/<owner>/<repo>/` held a `.bare/` bare Git database, a `.git`
pointer file, a shared `.gh/` GitHub CLI configuration directory, and one
directory per branch. The root came from `QWT_ROOT`, then `git config qwt.root`,
defaulting to `~/qwt`.

gh-qwt v0.16.0 replaced that with a ghq-compatible layout:

```text
<ghq-root>/github.com/<owner>/<repo>/                      primary checkout, real .git directory
<ghq-root>-worktrees/github.com/<owner>/<repo>/<branch>/   linked worktree, .git pointer file
```

The change is breaking in several ways at once:

- There is no `.bare` directory anywhere. A primary checkout is an ordinary
  clone, and linked worktrees are external worktrees that share the primary
  checkout's Git common directory.
- Roots follow ghq's `GHQ_ROOT` and `ghq.root`. `QWT_ROOT` no longer exists.
- `gh qwt list` is scoped to the current repository and needs `--all` for a
  cross-repository listing. Its output is host-qualified
  (`github.com/<owner>/<repo>/<branch>`).
- `gh qwt path` requires a host-qualified spec, and it also prints deterministic
  paths for worktrees that do not exist yet.
- Managed repositories record `qwt.managed`, `qwt.identity`,
  `qwt.defaultbranch`, and `qwt.worktreeroot` in repository-local Git
  configuration, readable from every linked worktree. This replaces `.bare`
  detection.
- Legacy repositories are never opened implicitly; `gh qwt migrate` inspects or
  migrates them explicitly.

Every dotfiles integration that encoded the old layout broke:

- The `ggr` and `egr` pickers passed bare `gh qwt list` output to fzf and
  prefixed non-absolute selections with `gh qwt root`, which no longer produces
  a valid path.
- The Starship prompt derived an `owner/repo/branch` label, a branch segment,
  and a "behind the base branch" warning from a helper script that detected the
  `.bare` layout and parsed the path.
- `dotfiles/zsh/ghq.zsh` defined a shadow `ghq` function that dispatched to
  `gh qwt`, from a time when the two layouts were unrelated.
- The GitHub CLI configuration directory used for authentication was resolved
  from `.bare` (see [ADR 0009](./0009-shared-worktree-gh-auth.md), superseded by
  [ADR 0020](./0020-central-gh-account-mapping.md)).

## Decision

Follow the upstream layout rather than reconstructing the old one.

- Select checkouts through one shared helper, `qwt-select-path` in
  `dotfiles/zsh/qwt-select.zsh`. It runs `gh qwt list --all`, hides the
  `github.com/` prefix from the fzf display while keeping the canonical
  host-qualified spec in a hidden field, resolves the selection with
  `gh qwt path`, and confirms the resulting directory exists.
- Use that helper from `go-to-qwt-repository.zsh` (`ggr`, `C-]`) and
  `edit-qwt-repository.zsh` (`egr`), so both share one selection and resolution
  path.
- Detect a managed repository from the `qwt.managed` and `qwt.identity` Git
  configuration keys instead of a `.bare` directory. They are repository-local,
  so every linked worktree reads the same values.
- Remove all gh-qwt customization from Starship: `custom.cwd` becomes the
  built-in `[directory]`, `custom.git_branch` becomes the built-in
  `[git_branch]`, and the `custom.qwt_base_warning` module is deleted. Delete
  `dotfiles/zsh/starship-qwt-worktree.sh` and `tests/starship_qwt_worktree.bats`
  with it, and drop the helper from the `shellcheck` invocation in
  `.github/workflows/ci.yml`.
- Install the real `ghq` binary from the `Brewfile` and delete
  `dotfiles/zsh/ghq.zsh`, so the `ghq` name no longer shadows a different tool
  now that gh-qwt uses ghq's own roots.
- Treat host-qualified specs as the only supported form when calling
  `gh qwt path`, and migrate legacy `~/qwt` repositories explicitly with
  `gh qwt migrate`.
- Add an "Ensure zsh is available" step to the `test` job's `ubuntu-latest`
  leg in `.github/workflows/ci.yml`, matching the one already used by `lint`.
  `tests/gh_account.bats` (see
  [ADR 0020](./0020-central-gh-account-mapping.md)) is the first `tests/`
  suite that executes `zsh` rather than only parsing it, and the
  `ubuntu-latest` runner image does not provide `zsh` by default; the
  `macos-latest` leg already has it preinstalled, so the guard is a no-op
  there.

## Alternatives Considered

### Rebuild the prompt label from `qwt.identity`

The `owner/repo/branch` prompt label could be reconstructed from the
`qwt.identity` Git configuration key plus the current branch. It is not adopted:
the path no longer encodes owner, repository, and branch, so the label would
need an extra subprocess on every prompt render purely to restate what the
built-in `[directory]` and `[git_branch]` modules already show.

### Pair `gh qwt list --all` with `gh qwt list --all --full-path`

Reading both listings and matching them line by line would avoid one
`gh qwt path` call per selection. It is not adopted because the two listings are
sorted differently — by name versus by absolute path — so the lines do not
correspond and the pairing would silently select the wrong worktree.

### Feed raw absolute paths to fzf

Selecting directly from `gh qwt list --all --full-path` would remove the
resolution step entirely. It is not adopted because every line then starts with
a long, identical root prefix, which pollutes fuzzy matching and pushes the part
the user actually types against off the visible width.

## Consequences

- `gh qwt path` succeeding is not proof of existence. It prints deterministic
  paths for worktrees that have not been created, so callers must check the
  directory separately before using it.
- Host-qualified specs are mandatory. `<owner>/<repo>/<branch>` alone no longer
  resolves, and every selection carries `github.com/` even when it is hidden
  from the display.
- Cross-repository selection requires `--all`, because plain `gh qwt list` only
  reports the current repository and fails outside the ghq roots.
- The prompt no longer shows a qwt-specific label or the `origin/main +N`
  behind-the-base warning. Starship's built-in modules render the path and
  branch instead, and one shell script plus its bats suite are gone.
- The real `ghq` binary is available again, and `ghq` no longer runs `gh qwt`.
- Existing `~/qwt` repositories keep working only after an explicit
  `gh qwt migrate`; they are never picked up implicitly.
- [ADR 0010](./0010-pr-skills-gh-qwt.md) keeps its worktree-only policy, but its
  mechanical details (path resolution, registration checks, and repository
  detection) follow this layout.
