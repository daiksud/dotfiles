# 0030: Remap `ctrl+d` to the Delete key in Ghostty

Translate `ctrl+d` into the Delete key (`CSI 3~`) at the terminal layer, and
move EOF to `ctrl+alt+d`, so `ctrl+d` keeps acting as Emacs `delete-char`
instead of triggering destructive dialog actions in GitHub Copilot CLI.

## Status

Accepted

## Context

`dotfiles/zshrc` sets Emacs keybindings with `bindkey -e`, where `ctrl+d` is
`delete-char-or-list` — forward-delete the character under the cursor. This is
a high-frequency, mid-typing editing key, not a command key.

GitHub Copilot CLI (installed via the `copilot-cli` cask, currently 1.0.80)
does not have one keymap. It has a different keymap per input context, and
they disagree about `ctrl+d`:

- **Main composer** — forward-deletes when the buffer has text, and shuts the
  session down only when the buffer is empty. Guarded, and consistent with
  Emacs. A maintainer described exactly this behavior when closing
  [github/copilot-cli#2438](https://github.com/github/copilot-cli/issues/2438).
- **`ask_user` / MCP elicitation *form*** — the multi-field dialog plan mode
  uses for clarifying questions — binds `ctrl+d` to **decline**. In the
  shipped bundle (`~/Library/Caches/copilot/pkg/darwin-arm64/1.0.80/app.js`,
  component `Y_n`) the handler is registered with a hardcoded
  `{isActive: true}` and reads `if (N.ctrl && N.code === "d") { n(); return }`,
  where `n` is `onDecline`. There is no check for the focused field's type and
  no check for whether the buffer is empty, and `onDecline` is invoked with
  zero arguments, so every value typed into the form is discarded and cannot
  be recovered. The footer hint `N["ctrl+d"] = "decline"` is likewise built
  outside every conditional, so it shows even while a plain text field is
  focused.

In practice this means reaching for `delete-char` inside a clarifying question
throws the whole answer away. The behavior is absent from the official
keyboard shortcut reference (which documents only `Ctrl+D | Shutdown.`), absent
from the in-app `?`/`/help` tables, and absent from the changelog; as of
2026-08-18 no issue reports it.

Copilot CLI exposes no keybinding configuration of any kind — no
`keybindings.json`, no setting, no plugin API — and the upstream feature
request for one,
[github/copilot-cli#2259](https://github.com/github/copilot-cli/issues/2259),
is open and unimplemented. Because the CLI is a raw-mode TUI, `stty` and zsh's
`bindkey` cannot reach it either: raw mode clears `ICANON`/`ISIG`/`IEXTEN`, and
the shell is not reading the tty while the CLI is in the foreground. The
terminal emulator is the only layer upstream of the pty, so it is the only
place where the chord can be intercepted.

The same class of collision was resolved once already in
[ADR 0017](./0017-herdr-prefix-ctrl-t.md), which moved herdr's prefix off
`ctrl+b` to keep `backward-char` reachable.

## Decision

In `dotfiles/ghostty/config`:

```ini
keybind = ctrl+d=csi:3~
keybind = ctrl+alt+d=text:\x04
```

and in `dotfiles/zshrc`:

```zsh
bindkey '^[[3~' delete-char
setopt IGNORE_EOF
```

The elicitation form's handler matches only `N.code === "d"` with the control
modifier; it does not intercept `code === "delete"`. The shared text-cursor
hook that every Copilot CLI input uses (`app.js`, `handleCommonKeyPress`) does
handle `code === "delete"` as a forward delete. Sending `CSI 3~` instead of
`0x04` therefore reaches the correct behavior and bypasses the decline handler
entirely — and, as a side effect, also removes the empty-buffer shutdown in the
main composer.

The `bindkey` line is required, not optional: plain zsh leaves `^[[3~` as
`undefined-key`, so without it `ctrl+d` would become inert at the shell prompt.
It also fixes a pre-existing gap, since the physical Delete key (`fn`+`delete`
on this keyboard) did nothing in zsh before.

`ctrl+alt+d` was chosen for EOF because herdr's keyboard reference names
`ctrl+alt` as the one modifier family left alone by macOS, terminals, and the
programs running inside a pane, and because `macos-option-as-alt = true` is
already set in `dotfiles/ghostty/config`, so `alt` chords are usable.

## Alternatives Considered

### Keep `ctrl+d` as-is and retrain onto the Delete key

`fn`+`delete` already forward-deletes correctly inside the form, so no
configuration is strictly necessary. Rejected because the failure mode is
silent and unrecoverable: a single reflexive `ctrl+d` discards an entire
answer with no confirmation and no undo, and muscle memory built over years is
not a reliable guard against a key that is safe in every other program.

### `keybind = ctrl+d=ignore`

Suppresses the chord entirely. Rejected because it is strictly worse than
`csi:3~`: it prevents the decline, but also removes forward-delete everywhere
— `delete-char-or-list` in zsh, the shared cursor's forward-delete in Copilot
CLI, `ctrl+d` half-page-down in `less`, insert-mode dedent in Neovim — while
losing EOF just the same. It trades a destructive binding for a dead key.

### A Ghostty key table, activated only while using Copilot CLI

Ghostty 1.3.0 added key tables (`<table>/<binding>` plus
`activate_key_table:`), which is the only scoping mechanism the terminal has.
Rejected because it is manual: Ghostty cannot detect which program is running
inside the pane, so the table has to be toggled by hand. A protection that
must be remembered before every clarifying question does not protect against a
reflex, and leaving it permanently on is equivalent to the unconditional
binding with extra steps.

### Conditional binding on the foreground process

What tmux would express as
`bind -n C-d if-shell -F '#{==:#{pane_current_command},copilot}' ...`.
Rejected because neither layer supports it. Ghostty 1.3.1's conditional
configuration has exactly two axes, OS theme and build-target OS
(`src/config/conditional.zig`), and herdr's binding engine matches on only
`is_direct()`/`is_prefix()` with no condition field
(`src/config/keybinds.rs`). Emulating it through a herdr `[[keys.command]]`
shell hook that calls `herdr pane process-info` and re-injects with
`herdr pane send-keys` would add a process spawn and two socket round trips to
every `ctrl+d` keypress in every pane, with no ordering guarantee.

### Wait for upstream to fix it

Rejected as the sole response, though it is worth pursuing in parallel.
`#2259` has been open since 2026-03 with no maintainer comment, the repository
has no milestones, and the public roadmap carries no keybinding item. The
sibling bug for `ctrl+g` in the same dialog
([github/copilot-cli#4198](https://github.com/github/copilot-cli/issues/4198))
is still open and still reproducible on 1.0.80 despite a changelog entry
claiming a fix.

## Consequences

- `ctrl+d` forward-deletes in Copilot CLI's elicitation forms instead of
  declining them, and no longer shuts down the CLI from an empty prompt. Use
  `/exit` to quit, and `exit` to leave the `$` interactive shell.
- `ctrl+d` no longer sends EOF. Ending stdin for `cat`, `ssh`, `python`, `wc`,
  `gpg`, and here-documents now requires `ctrl+alt+d`. This is the largest
  behavioral change in this ADR and the one most likely to surprise.
- `setopt IGNORE_EOF` is redundant inside Ghostty, since the shell never
  receives `0x04` there. It is kept as a safety net for sessions where this
  configuration does not apply — SSH targets, other terminals, and recovery
  shells.
- Insert-mode `<C-d>` dedent in Neovim and `ctrl+d` half-page-down in `less`
  are lost. `less` retains `d` for the same action; Neovim retains `<C-t>`/
  `<C-d>` in normal mode via `<<`.
- `ctrl+alt+d` is not validated at load time. Ghostty documents `text:` values
  as unvalidated, so `ghostty +validate-config` will not catch a malformed
  escape — only a live test against `cat` will.
- The remap is unconditional across every program in the terminal. This is
  accepted deliberately: `csi:3~` is a *translation* rather than a
  suppression, so the destination behavior (forward delete) is the one Emacs
  keybindings expect in the first place.
- If Copilot CLI later gains keybinding configuration, or fixes the form's
  handler to respect a non-empty buffer, both Ghostty lines and the `bindkey`
  line can be removed to restore EOF on `ctrl+d`.
