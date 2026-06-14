# ADR 0002: Adopt SSH commit signing

## Status

Accepted

## Context

Git commit signing guarantees authenticity and enables GitHub's "Verified" badge. The traditional approach uses GPG keys, but it has the following issues:

- It requires separate key generation and management
- On macOS, additional installation of `gpg` and `pinentry` is required
- Managing key expiration is cumbersome
- Registering the key with GitHub is required separately from authentication keys

Because developers already have SSH keys for GitHub authentication, reusing them for signing reduces the overhead to zero.

## Decision

Adopt SSH-based commit signing using existing ed25519 SSH keys.

Configured in the global gitconfig:

- `commit.gpgsign = true` — automatically sign all commits
- `gpg.format = ssh` — use SSH format instead of GPG
- `gpg.ssh.allowedSignersFile = ~/.ssh/allowed_signers` — for local signature verification

The repository-specific `user.signingkey` is automatically set by `gh-config-dir.zsh` according to the active GitHub account (`~/.ssh/<login>.pub`).

## Alternatives Considered

### GPG signing

Not adopted — it requires installing additional tools (`gpg`, `pinentry`) and managing an independent key lifecycle, with no practical advantage over SSH signing.

### No signing

Not adopted — in a multi-account workflow, the "Verified" badge is an important way to show commit trustworthiness, and reusing SSH keys makes it effectively free.

## Consequences

- Zero additional setup for developers who already have SSH keys
- Multi-account signing works automatically via `gh-config-dir.zsh`
- `~/.ssh/<login>.pub` for each account must be registered in GitHub Signing Keys
- `allowed_signers` is managed automatically, enabling local signature verification
