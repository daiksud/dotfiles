# 0020: Select the GitHub account per repository from a central mapping

Record which GitHub account each repository uses in one central mapping file,
and apply that choice per shell through `GH_TOKEN` and `GIT_CONFIG_*` instead of
per-repository GitHub CLI configuration directories.

## Status

Accepted

## Context

[ADR 0009](./0009-shared-worktree-gh-auth.md) gave every repository its own
GitHub CLI configuration directory: `<repo>/.git/gh` for ordinary clones and
`<qwt_root>/<owner>/<repo>/.gh` for gh-qwt repositories, exported as
`GH_CONFIG_DIR`. The active account's identity was then written into
`git config --local`.

That design has three problems:

- It depended on the gh-qwt `.bare` layout. The ghq-compatible layout of
  [ADR 0019](./0019-gh-qwt-ghq-layout.md) has no repository-level `.gh/`
  directory, so the detection rule no longer matches anything and the
  authentication stored under the old layout was left stranded.
- It fragmented the credential store. Each repository needed its own
  `gh auth login`, its own OAuth token on disk, and its own refresh when a scope
  was added.
- It wrote identity into every clone. The same account had to be re-derived for
  each new checkout, and stale values survived an account change.

Meanwhile, the GitHub CLI now supports several accounts per host in its single
user-level configuration, and can return a specific account's token with
`gh auth token --hostname <host> --user <login>`. The remaining problem is no
longer *where credentials live* but *which stored account a given repository
should use*.

## Decision

Keep every account in gh's user-level configuration, and store only the
repository-to-account association.

- Record the mapping in `~/.config/gh/repos.json` (overridable with
  `GH_ACCOUNT_MAP_FILE`), keyed by the canonical lowercase
  `<host>/<owner>/<repo>` identity derived from `origin`, with a `login`, `name`,
  and `email` per entry. Read and write it with `jq`, replacing the file
  atomically.
- Apply the selected account in `dotfiles/zsh/gh-account.zsh`, registered on the
  zsh `chpwd` hook and run once at load, by exporting `GH_TOKEN` (from
  `gh auth token`) plus `COPILOT_GITHUB_TOKEN` for Copilot CLI. Both are shell
  variables, so two terminals in repositories owned by different accounts never
  interfere.
- Inject the Git identity with `GIT_CONFIG_COUNT`, `GIT_CONFIG_KEY_<n>`, and
  `GIT_CONFIG_VALUE_<n>` covering `user.name`, `user.email`, and
  `user.signingkey` (`~/.ssh/<login>.pub`, only when that file exists). Nothing
  is written to `git config --local`.
- Keep upserting `~/.ssh/allowed_signers` per email so local signature
  verification keeps working, and rely on the global `~/.gitconfig` for
  `commit.gpgsign`, `gpg.format`, and `gpg.ssh.allowedSignersFile`.
- Prompt for an unmapped repository with fzf only in interactive shells — not
  inside a zle widget, not when stdin is not a tty, and not when `TERM` is
  `dumb`. Outside a Git worktree, without a usable `origin`, or for a non-GitHub
  host, clear every variable the plugin exported.
- Run every internal `gh` call that must see the stored accounts through
  `env -u GH_TOKEN`, and provide `gh-account-login` as a wrapper that runs
  `gh auth login` without `GH_TOKEN` and `GITHUB_TOKEN`.
- Never set `GH_CONFIG_DIR`, and clear it if a previous shell exported it.

## Alternatives Considered

### `gh auth switch --user`

The GitHub CLI can switch the active account itself. It is not adopted because
the switch is global: two terminals sitting in repositories owned by different
accounts overwrite each other's selection, and a `cd` in one window silently
changes what a command in another window does.

### One `GH_CONFIG_DIR` per account

Keeping a configuration directory per account (for example
`~/.config/gh-accounts/<login>`) would scope the account to the shell as well.
It is not adopted because it re-fragments the credential store that gh already
unified: each directory needs its own login, its own scope refreshes, and its
own token file, for accounts that gh can hold together.

### Keep writing `git config --local`

Continuing to write `user.name`, `user.email`, and `user.signingkey` into each
repository would need no environment variables at all. It is not adopted because
the identity then lives in every clone and drifts: a new checkout of the same
repository starts unconfigured, and a repository whose account changes keeps the
previous values until something rewrites them.

## Consequences

- `GH_TOKEN` masks stored credentials for `gh auth login`, `gh auth logout`,
  `gh auth switch`, and `gh auth status`. Internal calls use `env -u GH_TOKEN`,
  and interactive logins go through `gh-account-login`; a raw `gh auth status`
  reports the environment token instead of the stored accounts.
- The selection is per shell, so already-open shells keep the account they
  resolved. A new shell, or a `cd` that re-triggers `chpwd`, is required.
- Leftover `user.name`, `user.email`, and `user.signingkey` values written by the
  previous design are harmless, because `GIT_CONFIG_*` takes precedence over
  every configuration file. `gh-account-cleanup-local` clears them when tidiness
  is wanted.
- `jq` is a hard requirement of the plugin: without it, `gh-account-sync`
  returns without applying anything. It is already installed from the `Brewfile`.
- One `gh auth login` per account covers every repository that account owns, and
  `git push` and `git fetch` act as the selected account because the
  `gh auth git-credential` helper honors `GH_TOKEN`.
- The mapping file is plain text and holds no secrets — only a login, a display
  name, and a commit email per repository — so it can be inspected and edited
  directly.
- [ADR 0009](./0009-shared-worktree-gh-auth.md) is marked Superseded by this ADR.
