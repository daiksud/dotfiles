# 0017: Change herdr's prefix key to `ctrl+t`

Remap herdr's prefix key from its built-in default `ctrl+b` to `ctrl+t`, so
`ctrl+b` stays available for the Emacs `backward-char` binding used elsewhere.

## Status

Accepted

## Context

[ADR 0015](./0015-herdr-terminal-multiplexer.md) adopted herdr with its
built-in default prefix, `ctrl+b`, and left every keybinding at that default.
A multiplexer's prefix key is intercepted before it reaches the programs
running inside a pane, so herdr's `ctrl+b` shadows every other use of that
chord in every pane, everywhere, including the copy mode built into herdr
itself:

- `dotfiles/zshrc` sets Emacs keybindings with `bindkey -e`, where `ctrl+b` is
  `backward-char` (move the cursor one character back). This is one of the
  most frequently used line-editing keys.
- `dotfiles/nvim/lua/config/keymaps.lua` binds insert-mode `<C-b>` to `<Left>`
  for the same purpose.
- herdr's own copy mode binds `ctrl+b` / `ctrl+f` for page-up/page-down, but
  the prefix takes priority: with the default prefix, `ctrl+b` enters prefix
  mode instead of paging up (documented at
  [herdr's keyboard reference](https://herdr.dev/docs/keyboard/)).

## Decision

Set `keys.prefix = "ctrl+t"` in `dotfiles/herdr.toml`, overriding herdr's
built-in default. See the [herdr reference](../../reference/herdr.md#basic-settings)
for the resulting keybinding table.

`ctrl+t` was chosen because:

- It is not bound anywhere else in this repository: `dotfiles/zsh/` only
  binds `ctrl+r` (`fzf-select-history`) and `ctrl+]`
  (`go-to-qwt-repository`); fzf's own stock key-bindings file (which would
  otherwise claim `ctrl+t`) is not sourced; and `dotfiles/ghostty/config`
  only unbinds `super+*` chords, none of which overlap.
- herdr's keyboard reference lists `ctrl+<letter>` as one of the most
  reliable direct-chord families, alongside function keys, unaffected by the
  terminal/OS interference that `alt`- and `cmd`-based chords risk.
- In zsh's Emacs keybindings, `ctrl+t` is `transpose-chars`, a far less
  frequently used binding than `backward-char`.

## Alternatives Considered

### Keep `ctrl+b`

The status quo from ADR 0015. Rejected because it permanently shadows
`backward-char`/`<Left>` in every pane, which is used far more often than any
herdr prefix action, on every keystroke that needs to correct a typo.

### `ctrl+a`

Common alternate tmux prefix (`screen`'s default). Rejected because `ctrl+a`
is `beginning-of-line` in the same Emacs keybindings this repository relies
on (`bindkey -e`) — replacing one frequently used line-editing chord with
another does not solve the problem.

### `ctrl+space`

Free of Emacs line-editing conflicts. Rejected because `ctrl+space` is a
common IME/input-source toggle on macOS and a completion trigger in several
editors and shells, so it is not reliably free either, and herdr's own
guidance calls out modifier-plus-punctuation chords as terminal-dependent.

### `f12`

Free of any Emacs or shell binding. Rejected in favor of a `ctrl+<letter>`
chord: function keys are easy to hit accidentally with other function-row
shortcuts (brightness, media keys) on some keyboards and are less
discoverable than a `ctrl` chord for muscle memory built around tmux-style
prefixes.

### A `ctrl+alt+*` chord

herdr's own documentation recommends `ctrl+alt` as the safest family for
*direct* (non-prefix) chords, since it is left alone by most terminals, shells,
and window managers. Rejected specifically for the *prefix* key: herdr's
keyboard reference only shows `ctrl+alt` used for supplementary direct
bindings layered on top of an existing prefix, not as the prefix value
itself, and an extra modifier makes the single most-used chord (the prefix)
harder to reach than a plain `ctrl+<letter>`.

## Consequences

- `ctrl+b` reaches `backward-char` in zsh and `<Left>` in Neovim's insert mode
  again, and reaches herdr's own copy-mode page-up instead of entering prefix
  mode.
- `ctrl+t` no longer reaches panes directly; it is `transpose-chars` in zsh's
  Emacs keybindings. Pressing the prefix twice (`ctrl+t ctrl+t`) still sends
  the literal key to the pane, so `transpose-chars` stays reachable.
- Adopting fzf's stock key-bindings file in the future (which binds its
  file-widget to `ctrl+t`) would need a different fzf binding or a different
  herdr prefix; today that file is not sourced, so there is no live conflict.
- `docs/reference/herdr.md` and ADR 0015 no longer describe the prefix as
  herdr's unmodified default; see the `> [!NOTE]` added to ADR 0015.
