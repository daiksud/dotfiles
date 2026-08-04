# ADR 0009: Share gh authentication across Git worktrees

Use one GitHub CLI authentication directory for every worktree of a repository, including repository-level `.gh/` storage for gh-qwt.

## Status

Superseded

Superseded by [ADR 0020](./0020-central-gh-account-mapping.md), which replaces
`GH_CONFIG_DIR` with a central account mapping file.

## Context

`gh-config-dir.zsh` previously used `git rev-parse --git-path gh`. Git resolves
that path inside each linked worktree's administrative directory, so every
worktree required a separate `gh auth login`.

This conflicts with the gh-qwt layout: a qwt repository has one shared bare Git
database at `<qwt_root>/<owner>/<repo>/.bare` and branch worktrees below the
same repository directory. Branches of that repository should use one GitHub
account and one Copilot token.

Ordinary repositories can already keep their existing primary-worktree
authentication in `<repo>/.git/gh`. Existing qwt worktree directories may hold
different token files, so selecting or copying one automatically would be
unsafe.

## Decision

- Resolve ordinary repositories from Git's common directory and use its `gh/`
  child. The primary worktree and all linked worktrees share the same existing
  `<repo>/.git/gh` directory.
- Recognize a gh-qwt repository only when the common directory is `.bare/` and
  its parent contains both `.bare/` and a `.git` pointer to `.bare`. Use that
  parent's hidden `.gh/` directory as `GH_CONFIG_DIR`.
- Preserve the existing Git identity, SSH signing key, and Copilot token sync
  after resolving the shared directory.
- Do not migrate or merge old worktree-specific authentication files. Users run
  `gh auth login` once from any existing qwt worktree to initialize the shared
  `.gh/` directory.

## Alternatives Considered

### Keep worktree-specific authentication

This preserves the previous behavior but requires each gh-qwt branch to be
authenticated independently. It is not adopted because branch worktrees are
part of the same repository and should use the same account.

### Use `.bare/gh` for gh-qwt

Git's common directory would make this easy, but it hides authentication inside
the bare database rather than at the requested repository level. It is not
adopted because `<qwt_root>/<owner>/<repo>/.gh` is easier to inspect and moves
with the qwt repository layout.

### Copy an existing worktree's credentials automatically

This could avoid a new login, but old worktrees may contain credentials for
different accounts. Copying OAuth tokens also creates an unnecessary secret
selection and duplication path. It is not adopted.

### Limit shared authentication to gh-qwt

Ordinary linked worktrees have the same problem and can share their existing
primary-worktree authentication through Git's common directory. It is not
adopted because the generalized behavior preserves ordinary repository
credentials while making all worktrees consistent.

## Consequences

- Changing branches or moving between linked worktrees no longer prompts for
  separate authentication within one repository.
- Existing ordinary repository authentication remains at `<repo>/.git/gh`.
- Existing qwt repositories need one explicit `gh auth login`; their old
  worktree-specific credential directories remain untouched.
- The `.bare/` plus `.git` pointer check avoids treating arbitrary bare
  repositories as gh-qwt repositories.
