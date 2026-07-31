# ADR 0015: Adopt herdr as the terminal multiplexer

Use herdr to run and supervise terminal sessions, including multiple coding
agents running in parallel.

## Status

Accepted

## Context

Coding agents are increasingly run interactively inside a terminal, often
several at once across different projects. That workflow needs a terminal
multiplexer that can:

- Keep panes running after the terminal window closes, and reattach later,
  including over SSH.
- Show, at a glance, which of several running agents is blocked, working, or
  done, instead of requiring every pane to be checked manually.
- Split panes and navigate between them without leaving the keyboard.

## Decision

Adopt herdr (`herdrdev/herdr`) as the terminal multiplexer.

- Install it via `brew "herdr"` in `Brewfile`.
- Keep configuration minimal in `dotfiles/herdr.toml` (linked to
  `~/.config/herdr/config.toml`): skip first-run onboarding, and set
  `theme.name = "tokyo-night"` to match the Tokyo Night Storm theme used
  throughout this repository (see [Concept](../../guides/05-concept.md)).
  Everything else — pane splits, pane navigation, and vi-style copy mode —
  stays at herdr's built-in defaults.
- Keep the server resident with `brew services start herdr` on macOS
  (`scripts/100-herdr.sh`), so panes and agents keep running independently of
  any single terminal window. Start the client by running `herdr` explicitly;
  no shell starts it automatically. See the
  [herdr reference](../../reference/herdr.md) for the resulting file layout and
  behavior.

> [!NOTE]
> Ghostty now starts the client automatically instead; see
> [ADR 0016](./0016-ghostty-herdr-autostart.md).
>
> The prefix key is no longer herdr's default `ctrl+b`; see
> [ADR 0017](./0017-herdr-prefix-ctrl-t.md).

## Alternatives Considered

### tmux

A mature, widely used terminal multiplexer. Rejected because it has no
awareness of what is running inside a pane: seeing which of several coding
agents needs attention requires a plugin-driven status bar and manual
per-pane checks. herdr is built specifically as an "agent multiplexer" with
built-in agent state detection (blocked/working/done) surfaced in a sidebar.

### No terminal multiplexer

Running each agent in its own unmanaged terminal window. Rejected because
panes would not survive closing a window, could not be reattached, and there
would be no consolidated view across agents.

## Consequences

- The prefix key is herdr's default at the time, `ctrl+b`. (Superseded by
  [ADR 0017](./0017-herdr-prefix-ctrl-t.md), which moves it to `ctrl+t`.)
- Panes advertise a fixed `TERM=xterm-256color` / `COLORTERM=truecolor`; herdr
  has no `default-terminal`-equivalent setting.
- Status is shown in herdr's sidebar rather than a dedicated status bar.
- Opening a terminal does not attach to herdr automatically; `herdr` is run
  explicitly when needed. (Superseded for Ghostty by
  [ADR 0016](./0016-ghostty-herdr-autostart.md); other launch paths are
  unaffected.)
- herdr is pre-1.0 (`v0.7.5`) and may introduce breaking configuration or
  keybinding changes between releases.
