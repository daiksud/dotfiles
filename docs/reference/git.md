# Git

This is the reference for the global Git configuration (`~/.gitconfig`).

## File

`dotfiles/gitconfig` → `~/.gitconfig`

## Settings list

| Section       | Key                  | Value                    | Description                                          |
| ------------- | -------------------- | ------------------------ | ---------------------------------------------------- |
| `[push]`      | `autosetupremote`    | `true`                   | Automatically set the remote tracking branch on push |
| `[push]`      | `default`            | `current`                | Push to the remote branch with the same name         |
| `[commit]`    | `gpgsign`            | `true`                   | Automatically sign all commits                       |
| `[core]`      | `quotepath`          | `false`                  | Display Japanese file names without escaping         |
| `[gpg]`       | `format`             | `ssh`                    | Use SSH for signing                                  |
| `[gpg "ssh"]` | `allowedsignersfile` | `~/.ssh/allowed_signers` | Allowed signers file for signature verification      |
| `[init]`      | `defaultbranch`      | `main`                   | Default branch name for new repositories             |
| `[pull]`      | `rebase`             | `true`                   | Rebase instead of merge on pull                      |
| `[rebase]`    | `autosquash`         | `true`                   | Automatically arrange `fixup!` / `squash!` commits   |

## Authentication helper

As the equivalent of `gh auth setup-git`, `gh auth git-credential` is used as the credential helper for GitHub and Gist.
`gh` is resolved from `PATH` rather than an absolute path, so it does not depend on the installation location.

| Target                    | helper                    |
| ------------------------- | ------------------------- |
| `https://github.com`      | `!gh auth git-credential` |
| `https://gist.github.com` | `!gh auth git-credential` |

## What is not configured globally

The following are not written globally because `gh-config-dir.zsh` sets them automatically locally for each repository:

- `user.name`
- `user.email`
- `user.signingkey`

For details, see [Automatic Git identity switching](../guides/04-git-identity.md).
