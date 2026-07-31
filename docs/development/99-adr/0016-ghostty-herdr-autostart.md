# 0016: Auto-start herdr from Ghostty

Attach to herdr automatically when Ghostty opens a new window or tab, instead
of requiring a manual `herdr` command every time.

## Status

Accepted

## Context

[ADR 0015](./0015-herdr-terminal-multiplexer.md) adopted herdr as the
terminal multiplexer but deliberately kept terminal startup unchanged: opening
a terminal started a plain shell, and attaching to herdr required running
`herdr` explicitly. In practice, nearly every local Ghostty window is meant to
end up inside herdr anyway, for persistent panes, agent-state detection, and
reattach-after-close — running `herdr` by hand in every window is pure
friction with no real benefit.

Ghostty's `command` setting controls what runs in every new terminal surface,
but Ghostty's own GUI process does not inherit a login shell's `PATH`. On this
machine it starts with `PATH=/usr/bin:/bin:/usr/sbin:/sbin` (confirmed by
inspecting the running process), so a bare `command = herdr` cannot resolve a
Homebrew-installed binary.

## Decision

Add `dotfiles/ghostty/herdr-launch.sh`, a POSIX `sh` wrapper that:

- Prepends the common Homebrew bin directories (`/opt/homebrew/bin`,
  `/usr/local/bin`, `/home/linuxbrew/.linuxbrew/bin`) to `PATH`. The list is
  overridable through `HERDR_LAUNCH_BREW_BINS` so tests can point it at a
  sandboxed stub instead of touching real Homebrew paths.
- Falls back to `exec "$SHELL" -l` (a login shell) when herdr cannot be
  found, or when already running inside a herdr pane (`HERDR_ENV=1`, the same
  signal herdr's own nested-launch guard checks), so the wrapper never
  triggers herdr's rejection of nested launches.
- Otherwise `exec herdr`, replacing the wrapper process itself.

Point Ghostty at it with `command = shell:~/.config/ghostty/herdr-launch.sh`
in `dotfiles/ghostty/config`. The `shell:` prefix forces Ghostty to route the
value through `/bin/sh -c`, which is what expands the leading `~`; a bare
single-word command value can be exec'd directly and skip that expansion.

Because the wrapper replaces itself with `herdr` via `exec`, detaching
(`prefix+q`) or otherwise exiting herdr closes the Ghostty surface, while the
server and its panes keep running in the background — `scripts/100-herdr.sh`
already keeps the server resident via `brew services start herdr`,
independent of any one client.

The change is scoped to Ghostty only: `dotfiles/zshrc` is unchanged, so VS
Code's integrated terminal, GitHub Codespaces, and any zsh started another
way keep starting a plain login shell. `ghostty -e zsh` (Ghostty's `-e` /
`initial-command`) remains available as a deliberate one-off escape hatch
that skips the wrapper for a single surface; no dedicated opt-out environment
variable is introduced.

## Alternatives Considered

### Auto-attach from `dotfiles/zshrc`

Guarding an `exec herdr` near the top of `.zshrc` with a `HERDR_ENV` check
would auto-attach from every zsh login shell, not just Ghostty. Rejected
because it would also fire inside VS Code's integrated terminal, GitHub
Codespaces, and plain SSH sessions, none of which run Ghostty or benefit from
herdr's pane/agent model. Scoping it there would need extra
environment-detection logic in a file every interactive shell sources, where
Ghostty's `command` setting already limits the effect to surfaces Ghostty
itself creates.

### Hardcoding an absolute path in `command`

Setting `command` directly to something like `/opt/homebrew/bin/herdr` would
avoid a wrapper script entirely. Rejected because it hardcodes a Homebrew
prefix that does not hold on every machine or OS (Linux uses
`/home/linuxbrew/.linuxbrew/bin`), leaves no fallback when herdr is not
installed (Ghostty would simply fail to start the surface), and does not
guard against herdr's nested-launch rejection when `command` also applies to
panes or tabs opened from inside an existing herdr pane.

### Opt-out environment variable

A dedicated escape hatch such as `HERDR_AUTOSTART=0` was considered for
per-window opt-out. Rejected in favor of documenting `ghostty -e zsh`, which
already gives the same one-off plain shell without adding a new configuration
surface or a code path in the wrapper that most users would never set.

## Consequences

- Opening a new Ghostty window or tab attaches to herdr's default session
  immediately; there is no longer a manual `herdr` step for the common case.
- Detaching or otherwise exiting herdr closes the Ghostty surface; the server
  and its panes are unaffected, since they are owned by the resident
  `brew services` server, not by any one client.
- A plain shell is still reachable when genuinely needed, via `ghostty -e
  zsh`, or automatically as a fallback when herdr is not installed.
- `dotfiles/ghostty/herdr-launch.sh` is a new maintenance surface: shellchecked
  in CI and covered by `tests/herdr_launch.bats`, following the same pattern
  as `dotfiles/zsh/starship-qwt-worktree.sh`.
- ADR 0015's "opening a terminal does not attach to herdr automatically"
  statement is superseded for Ghostty specifically; other launch paths keep
  that original behavior.
