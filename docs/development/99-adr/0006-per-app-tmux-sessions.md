# ADR 0006: Per-application tmux sessions on terminal launch

Group auto-started tmux sessions by terminal application instead of sharing a single `main` session.

## Status

Accepted

## Context

`.zshrc` auto-started tmux by attaching every shell to one hard-coded session:

```zsh
exec tmux new-session -A -s main
```

Because the name was always `main`, every terminal application — Ghostty, the
VS Code integrated terminal, and any other emulator — attached to the **same**
session. Opening a second window mirrored the first, so different applications
could not keep independent layouts and working directories.

The goal is to keep each terminal application in its own session while avoiding a
buildup of orphaned, detached sessions.

## Decision

Derive the session from the terminal application, exposed through the
`TERM_PROGRAM` environment variable, and reuse detached sessions before creating
new ones.

On shell startup (when not already inside tmux):

1. Compute an app key from `${TERM_PROGRAM}`, lowercased and sanitized to
   `[a-z0-9-]` (fallback `term` when unset).
2. If a session of the same application is **detached**
   (`#{session_attached}` is `0`), reattach to it.
3. Otherwise create a new session named `<app>-<n>`, where `n` is the lowest free
   index for that application.

The logic lives in an anonymous function so its helper variables stay local, and
`exec` replaces the shell with tmux as before. See
[tmux reference](../../reference/tmux.md) for the full snippet.

## Alternatives Considered

### Keep a single shared `main` session

Not adopted — it is exactly the behavior being replaced. Different applications
cannot stay separate, and every window mirrors the same session.

### One shared session per application (e.g. all Ghostty windows share `ghostty`)

Considered — simpler than per-window sessions. Rejected because every window of
the same application would still mirror one session, which prevents independent
layouts per window.

### Per-window unique session with no reuse

Considered — give every window a brand-new session and never reattach. Rejected
because closing and reopening windows would accumulate orphaned detached
sessions over time.

### Per-window unique session with detached reuse (chosen)

Each window gets its own independent session, but a detached session of the same
application is reattached first. This keeps windows independent while recycling
freed sessions, so orphans do not pile up.

## Consequences

- Ghostty, VS Code, and other applications run in separate sessions named by app
  (`ghostty-1`, `vscode-1`, …).
- Each window is independent rather than a mirror of a shared session.
- Detached sessions are recycled, so reopening a window reuses a freed session
  instead of leaving an orphan.
- The session name now depends on `TERM_PROGRAM`; terminals that do not set it
  fall back to the `term` key.
- Two windows opening at the exact same moment could both grab the same detached
  session (mirroring them). This race is rare and accepted as-is.
